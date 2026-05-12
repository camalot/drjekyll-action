#!/usr/bin/env bash

set -u  # Fail on undefined variables
# (Removed 'e' and 'o pipefail' to allow commands with non-zero exits to be handled explicitly)

# This script is the entry point for the GitHub Action. It sets up the environment, builds the Jekyll site to the specified output directory, and handles any necessary configuration.

# Set the input and output directories. The input directory is set on the action as an input as input_dir. The output directory is set on the action as an input as output_dir.
# All paths are relative to GITHUB_WORKSPACE, which defaults to the current directory if not set.

function resolve_workspace_path() {
  local raw_path="$1"
  local resolved
  # Keep absolute paths untouched; resolve relative paths under GITHUB_WORKSPACE.
  if [[ "$raw_path" = /* ]]; then
    resolved="$raw_path"
  else
    resolved="$GITHUB_WORKSPACE/$raw_path"
  fi
  # Normalize away any ./ or ../ segments without requiring the path to exist.
  realpath -m "$resolved"
}

GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-.}"
INPUT_DIR="$(resolve_workspace_path "${INPUT_INPUT_DIR:-.}")"
OUTPUT_DIR="$(resolve_workspace_path "${INPUT_OUTPUT_DIR:-_site}")"
INPUT_URL="${INPUT_URL:-}"
INPUT_BASEURL="${INPUT_BASEURL:-}"
# DRJEKYLL_DOCS_DIR: override to point at a local drjekyll/ directory when running outside the action container.
# Defaults to /app/docs (the path baked into the Docker image).
DRJEKYLL_DOCS_DIR="${DRJEKYLL_DOCS_DIR:-/app/docs}"
# DRJEKYLL_SERVE: set to 'true' to run 'jekyll serve' instead of building and copying output.
# Useful for local development. Serves on 0.0.0.0 so the host can reach it.
DRJEKYLL_SERVE="${DRJEKYLL_SERVE:-false}"
# DRJEKYLL_WORK_DIR: staging directory used only in serve mode. DRJEKYLL_DOCS_DIR and INPUT_DIR
# are merged here so neither source directory is modified. Should be git-ignored.
DRJEKYLL_WORK_DIR="$(resolve_workspace_path "${DRJEKYLL_WORK_DIR:-.drjekyll-local}")"


function timestamp_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

function log_info() {
  echo "[$(timestamp_utc)] [INFO] $*"
}

function log_warn() {
  echo "[$(timestamp_utc)] [WARN] $*" >&2
}

function log_error() {
  local msg="$*"
  echo "[$(timestamp_utc)] [ERROR] $msg" >&2
  echo "::error::$msg"
}

function group_start() {
  echo "::group::$1"
}

function group_end() {
  echo "::endgroup::"
}

function path_exists_msg() {
  local path="$1"
  if [ -e "$path" ]; then
    echo "yes"
  else
    echo "no"
  fi
}

function log_directory_snapshot() {
  local title="$1"
  local dir="$2"
  local max_entries="${3:-200}"

  group_start "$title"
  if [ ! -d "$dir" ]; then
    log_warn "Directory '$dir' does not exist; skipping snapshot."
    group_end
    return
  fi

  log_info "Snapshot directory: $dir"
  log_info "Top-level listing:"
  ls -la "$dir"

  local total_entries
  total_entries=$(find "$dir" -mindepth 1 | wc -l | tr -d ' ')
  log_info "Total entries under '$dir': $total_entries"

  log_info "First $max_entries entries (sorted):"
  find "$dir" -mindepth 1 | sort | head -n "$max_entries"
  if [ "$total_entries" -gt "$max_entries" ]; then
    log_warn "Snapshot truncated at $max_entries entries."
  fi
  group_end
}

function log_environment_context() {
  group_start "Runtime context"
  log_info "PWD: $(pwd)"
  log_info "INPUT_DIR: $INPUT_DIR"
  log_info "OUTPUT_DIR: $OUTPUT_DIR"
  log_info "DRJEKYLL_DOCS_DIR: $DRJEKYLL_DOCS_DIR"
  log_info "DRJEKYLL_SERVE: $DRJEKYLL_SERVE"
  log_info "DRJEKYLL_WORK_DIR: $DRJEKYLL_WORK_DIR"
  log_info "GITHUB_ACTION: ${GITHUB_ACTION:-<unset>}"
  log_info "GITHUB_WORKSPACE: ${GITHUB_WORKSPACE:-<unset>}"
  log_info "GITHUB_REPOSITORY: ${GITHUB_REPOSITORY:-<unset>}"
  log_info "GITHUB_REF: ${GITHUB_REF:-<unset>}"
  log_info "Ruby version: $(ruby --version 2>/dev/null || echo unavailable)"
  log_info "Bundler version: $(bundle --version 2>/dev/null || echo unavailable)"
  group_end
}

function log_output_summary() {
  group_start "Build output summary"
  if [ ! -d "$OUTPUT_DIR" ]; then
    log_error "Output directory '$OUTPUT_DIR' was not created."
    group_end
    return 1
  fi

  local file_count
  local dir_count
  file_count=$(find "$OUTPUT_DIR" -type f | wc -l | tr -d ' ')
  dir_count=$(find "$OUTPUT_DIR" -type d | wc -l | tr -d ' ')

  log_info "Output directory exists: $OUTPUT_DIR"
  log_info "Output size: $(du -sh "$OUTPUT_DIR" | awk '{print $1}')"
  log_info "Output file count: $file_count"
  log_info "Output directory count: $dir_count"

  if [ -f "$OUTPUT_DIR/index.html" ]; then
    log_info "index.html found at '$OUTPUT_DIR/index.html'"
  else
    log_warn "index.html was not found in '$OUTPUT_DIR'"
  fi

  log_directory_snapshot "Output directory tree" "$OUTPUT_DIR" 300
  group_end
}


function get_drjekyll_packages() {
  # get the list of packages that are required by drjekyll from the drjekyll Gemfile. We will use this list to check if the user's Gemfile includes these packages, and if not, we will add them to the user's Gemfile.
  # should return a list of packages in the format "package:version", where version is optional. For example:
  # jekyll:~> 4.2.0
  # jekyll-remote-theme:~> 0.4.0
  local DRJEKYLL_GEMFILE="$DRJEKYLL_DOCS_DIR/Gemfile"
  local packages=()
  local gem_with_version_re="^gem[[:space:]]+['\"]([^'\"]+)['\"][[:space:]]*,[[:space:]]*['\"]([^'\"]+)['\"]"
  local gem_only_re="^gem[[:space:]]+['\"]([^'\"]+)['\"]"
  if [ -f "$DRJEKYLL_GEMFILE" ]; then
    while IFS= read -r line; do
      if [[ "$line" =~ $gem_with_version_re ]]; then
        packages+=("${BASH_REMATCH[1]}:${BASH_REMATCH[2]}")
      elif [[ "$line" =~ $gem_only_re ]]; then
        packages+=("${BASH_REMATCH[1]}")
      fi
    done < "$DRJEKYLL_GEMFILE"
  else
    log_warn "DrJekyll Gemfile '$DRJEKYLL_GEMFILE' was not found."
  fi
  printf '%s\n' "${packages[@]}"
}

function gemfile_contains() {
  local gemfile="$1"
  local package="$2"
  if [ -f "$gemfile" ]; then
    if grep -q "$package" "$gemfile"; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

function add_package_to_gemfile() {
  local gemfile="$1"
  local package="$2"
  local version="$3"
  if [ -f "$gemfile" ]; then
    echo "Adding package '$package' to Gemfile '$gemfile'..."
    if [ -n "$version" ]; then
      echo "gem '$package', '$version'" >> "$gemfile"
    else
      echo "gem '$package'" >> "$gemfile"
    fi
  else
    echo "Gemfile '$gemfile' does not exist. Creating it and adding package '$package'..."
    echo "source 'https://rubygems.org'" > "$gemfile"
    if [ -n "$version" ]; then
      echo "gem '$package', '$version'" >> "$gemfile"
    else
      echo "gem '$package'" >> "$gemfile"
    fi
  fi
}

function setup_gems() {
  local target_dir="$1"
  local TEMP_GEMFILE="$target_dir/UserGemfile"
  local USER_GEMFILE="$INPUT_DIR/Gemfile"

  if [ ! -f "$USER_GEMFILE" ]; then
    cp "$target_dir/Gemfile" "$TEMP_GEMFILE"
    USER_GEMFILE="$TEMP_GEMFILE"
    log_info "No user Gemfile found. Using DrJekyll Gemfile: $USER_GEMFILE"
  fi

  cp "$USER_GEMFILE" "$TEMP_GEMFILE"
  USER_GEMFILE="$TEMP_GEMFILE"
  log_info "Using temporary Gemfile: $USER_GEMFILE"

  local drjekyll_packages=()
  mapfile -t drjekyll_packages < <(get_drjekyll_packages)
  log_info "Resolved ${#drjekyll_packages[@]} DrJekyll package requirement(s)."
  if [ "${#drjekyll_packages[@]}" -gt 0 ]; then
    printf '%s\n' "${drjekyll_packages[@]}" | sed 's/^/[PKG] /'
  fi

  for package in "${drjekyll_packages[@]}"; do
    local package_name="${package%%:*}"
    local package_version="${package#*:}"
    if ! gemfile_contains "$USER_GEMFILE" "$package_name"; then
      add_package_to_gemfile "$USER_GEMFILE" "$package_name" "$package_version"
    else
      echo "Package '$package_name' is already included in the user's Gemfile. Skipping."
    fi
  done

  group_start "Bundle install"
  log_info "Installing gems with Gemfile '$USER_GEMFILE' into '$target_dir/vendor/bundle'..."
  if ! BUNDLE_GEMFILE="$USER_GEMFILE" BUNDLE_PATH="$target_dir/vendor/bundle" bundle install; then
    log_error "Bundle install failed with exit code $?"
    group_end
    exit 1
  fi
  log_info "Bundle install complete."
  export BUNDLE_GEMFILE="$USER_GEMFILE"
  export BUNDLE_PATH="$target_dir/vendor/bundle"
  group_end
}

function setup_user_header_footer() {
  # copy the input_dir/_includes/footer_custom.html and input_dir/_includes/header_custom.html to the drjekyll docs directory as _includes/user_footer_custom.html and _includes/user_header_custom.html
  if [ -f "$INPUT_DIR/_includes/footer_custom.html" ]; then
    echo "Copying '$INPUT_DIR/_includes/footer_custom.html' to '$DRJEKYLL_DOCS_DIR/_includes/user_footer_custom.html'..."
    cp "$INPUT_DIR/_includes/footer_custom.html" "$DRJEKYLL_DOCS_DIR/_includes/user_footer_custom.html"
  else
    touch "$DRJEKYLL_DOCS_DIR/_includes/user_footer_custom.html"
  fi

  if [ -f "$INPUT_DIR/_includes/header_custom.html" ]; then
    echo "Copying '$INPUT_DIR/_includes/header_custom.html' to '$DRJEKYLL_DOCS_DIR/_includes/user_header_custom.html'..."
    cp "$INPUT_DIR/_includes/header_custom.html" "$DRJEKYLL_DOCS_DIR/_includes/user_header_custom.html"
  else
    touch "$DRJEKYLL_DOCS_DIR/_includes/user_header_custom.html"
  fi
}

function setup_drjekyll() {
  group_start "Setup DrJekyll"
  log_info "Starting setup phase."

  # check if INPUT_DIR exists
  if [ ! -d "$INPUT_DIR" ]; then
    log_error "Input directory '$INPUT_DIR' does not exist."
    group_end
    exit 1
  fi

  # check if DRJEKYLL_DOCS_DIR exists
  if [ ! -d "$DRJEKYLL_DOCS_DIR" ]; then
    log_error "Dr. Jekyll docs directory '$DRJEKYLL_DOCS_DIR' does not exist."
    group_end
    exit 1
  fi

  log_directory_snapshot "Input directory before merge" "$INPUT_DIR" 120
  log_directory_snapshot "DrJekyll docs before merge" "$DRJEKYLL_DOCS_DIR" 120

  # Merge the input directory with the drjekyll docs directory. This will allow the Jekyll build to find the necessary configuration and assets. We will copy the contents of the input directory to the drjekyll docs directory, overwriting any existing files. This will allow the user to override any configuration or assets that are provided by drjekyll.

  # input_dir/_includes/footer_custom.html and input_dir/_includes/header_custom.html and copy them to the drjekyll docs directory as _includes/user_footer_custom.html and _includes/user_header_custom.html. They are then included in the drjekyll header and footer includes, allowing the user to customize the header and footer of their site without modifying the drjekyll includes.

  log_info "Merging input directory '$INPUT_DIR' with Dr. Jekyll docs directory '$DRJEKYLL_DOCS_DIR'..."
  # need to ignore Gemfile, Gemfile.lock, and _config-drjekyll.yml, as well as the _includes/footer_custom.html and _includes/header_custom.html files, as they are handled separately
  group_start "Rsync merge details"
  if ! rsync -avL --ignore-times --exclude='Gemfile' --exclude='Gemfile.lock' --exclude='_config-drjekyll.yml' --exclude='_includes/footer_custom.html' --exclude='_includes/header_custom.html' "$INPUT_DIR/" "$DRJEKYLL_DOCS_DIR/"; then
    log_error "rsync merge failed with exit code $?"
    group_end
    group_end
    exit 1
  fi
  group_end

  group_start "DrJekyll docs immediately after merge"
  log_info "Key files in input directory:"
  log_info "INPUT _config.yml present: $(path_exists_msg "$INPUT_DIR/_config.yml")"
  log_info "INPUT _config.yaml present: $(path_exists_msg "$INPUT_DIR/_config.yaml")"
  log_info "INPUT index.md present: $(path_exists_msg "$INPUT_DIR/index.md")"
  log_info "Key files in merged working directory:"
  log_info "MERGED _config.yml present: $(path_exists_msg "$DRJEKYLL_DOCS_DIR/_config.yml")"
  log_info "MERGED _config.yaml present: $(path_exists_msg "$DRJEKYLL_DOCS_DIR/_config.yaml")"
  log_info "MERGED index.md present: $(path_exists_msg "$DRJEKYLL_DOCS_DIR/index.md")"
  group_end

  # Ensure user config is present in the merged working directory.
  # This explicitly copies the user's config to override any defaults.
  if [ -f "$INPUT_DIR/_config.yml" ]; then
    log_info "Syncing user config '$INPUT_DIR/_config.yml' to '$DRJEKYLL_DOCS_DIR/_config.yml'"
    user_title="$(yq eval '.title // "NOTITLE"' "$INPUT_DIR/_config.yml")"
    log_info "User _config.yml title value: '$user_title'"
    if ! cp "$INPUT_DIR/_config.yml" "$DRJEKYLL_DOCS_DIR/_config.yml"; then
      log_error "Failed to copy user config _config.yml"
      group_end
      exit 1
    fi
  elif [ -f "$INPUT_DIR/_config.yaml" ]; then
    log_info "Syncing user config '$INPUT_DIR/_config.yaml' to '$DRJEKYLL_DOCS_DIR/_config.yaml'"
    user_title="$(yq eval '.title // "NOTITLE"' "$INPUT_DIR/_config.yaml")"
    log_info "User _config.yaml title value: '$user_title'"
    if ! cp "$INPUT_DIR/_config.yaml" "$DRJEKYLL_DOCS_DIR/_config.yaml"; then
      log_error "Failed to copy user config _config.yaml"
      group_end
      exit 1
    fi
  else
    log_warn "No _config.yml or _config.yaml found in input directory '$INPUT_DIR' during setup."
  fi

  group_start "DrJekyll docs after config sync"
  log_info "Config exists after sync: _config.yml=$(path_exists_msg "$DRJEKYLL_DOCS_DIR/_config.yml"), _config.yaml=$(path_exists_msg "$DRJEKYLL_DOCS_DIR/_config.yaml")"
  log_info "Top-level merged docs listing after sync:"
  ls -la "$DRJEKYLL_DOCS_DIR"
  group_end

  group_start "User customizations and dependencies"
  setup_user_header_footer

  log_info "Header/footer customization files:"
  log_info "user_footer_custom.html present: $(path_exists_msg "$DRJEKYLL_DOCS_DIR/_includes/user_footer_custom.html")"
  log_info "user_header_custom.html present: $(path_exists_msg "$DRJEKYLL_DOCS_DIR/_includes/user_header_custom.html")"

  # if user has their own Gemfile, we need to make sure that the packages that are required by drjekyll are included in the user's Gemfile.
  setup_gems "$DRJEKYLL_DOCS_DIR"
  group_end

  log_directory_snapshot "DrJekyll docs after setup" "$DRJEKYLL_DOCS_DIR" 150
  group_end
}

function get_config_title() {
  # Returns the first non-empty 'title' value found in the user's config files only.
  # User's _config.yml/_config.yaml always take precedence over drjekyll defaults.
  # Only falls back to _config-drjekyll.yml if user has not provided a config.
  # NOTE: This function is called inside $() so logging must use >&2 to avoid capture.
  local active_dir="$1"
  local title=""

  # Check user configs first (should have been merged in by setup_drjekyll)
  if [ -f "$active_dir/_config.yml" ]; then
    title="$(yq eval '.title // ""' "$active_dir/_config.yml")"
    if [ -n "$title" ] && [ "$title" != "null" ]; then
      echo "[$(timestamp_utc)] [INFO] Title resolved from _config.yml: '$title'" >&2
      echo "$title"
      return
    fi
  fi

  if [ -f "$active_dir/_config.yaml" ]; then
    title="$(yq eval '.title // ""' "$active_dir/_config.yaml")"
    if [ -n "$title" ] && [ "$title" != "null" ]; then
      echo "[$(timestamp_utc)] [INFO] Title resolved from _config.yaml: '$title'" >&2
      echo "$title"
      return
    fi
  fi

  # Only use drjekyll defaults if user hasn't provided their own config
  if [ -f "$active_dir/_config-drjekyll.yml" ]; then
    title="$(yq eval '.title // ""' "$active_dir/_config-drjekyll.yml")"
    if [ -n "$title" ] && [ "$title" != "null" ]; then
      echo "[$(timestamp_utc)] [WARN] No user title found; using drjekyll default title: '$title'" >&2
      echo "$title"
      return
    fi
  fi

  echo "[$(timestamp_utc)] [WARN] No 'title' found in any config file." >&2
  echo ""
}

function replace_template_vars() {
  local active_dir="$1"
  group_start "Replace template variables"

  # Debug: check what config files exist
  log_info "Checking for config files in: $active_dir"
  log_info "_config.yml exists: $(path_exists_msg "$active_dir/_config.yml")"
  log_info "_config.yaml exists: $(path_exists_msg "$active_dir/_config.yaml")"
  log_info "_config-drjekyll.yml exists: $(path_exists_msg "$active_dir/_config-drjekyll.yml")"

  if [ -f "$active_dir/_config.yml" ]; then
    log_info "Contents of _config.yml (first 10 lines):"
    head -n 10 "$active_dir/_config.yml" | sed 's/^/  /'
  fi

  local title
  title="$(get_config_title "$active_dir")"

  if [ -z "$title" ] || [ "$title" = "null" ]; then
    log_warn "No 'title' found in any config file; '{{ config.title }}' placeholders will remain unreplaced."
    log_warn "get_config_title returned: '$title'"
    group_end
    return
  fi

  log_info "Replacing '{{ config.title }}' with '$title' in template files..."

  local template_files=(
    "$active_dir/assets/css/_components.scss"
  )

  for file in "${template_files[@]}"; do
    if [ -f "$file" ]; then
      log_info "Processing template file: $file"
      sed -i "s|{{ config.title }}|$title|g" "$file"
    else
      log_warn "Template file not found, skipping: $file"
    fi
  done

  group_end
}

function build_docs() {
  group_start "Build docs"
  # Check if the output directory exists, if it does, remove it
  if [ -d "$OUTPUT_DIR" ]; then
    log_warn "Output directory '$OUTPUT_DIR' already exists. Removing it."
    rm -rf "$OUTPUT_DIR"
  fi

  # Validate that user input has config and that merged working directory has config.
  if [ ! -f "$INPUT_DIR/_config.yml" ] && [ ! -f "$INPUT_DIR/_config.yaml" ]; then
    log_error "Input directory '$INPUT_DIR' does not contain _config.yml or _config.yaml."
    group_end
    exit 1
  fi

  # DrJekyll working directory must contain the merged config used for build.
  if [ ! -f "$DRJEKYLL_DOCS_DIR/_config.yml" ] && [ ! -f "$DRJEKYLL_DOCS_DIR/_config.yaml" ]; then
    log_error "Merged docs directory '$DRJEKYLL_DOCS_DIR' does not contain _config.yml or _config.yaml after sync."
    log_error "Input config presence: _config.yml=$(path_exists_msg "$INPUT_DIR/_config.yml"), _config.yaml=$(path_exists_msg "$INPUT_DIR/_config.yaml")"
    group_end
    exit 1
  fi

  # normalize the _config file name to _config.yml, as Jekyll will look for _config.yml by default. If the user provides a _config.yaml file, we will copy it to _config.yml in the drjekyll docs directory. This will allow Jekyll to find the configuration file and build the site successfully.
  if [ -f "$DRJEKYLL_DOCS_DIR/_config.yaml" ] && [ ! -f "$DRJEKYLL_DOCS_DIR/_config.yml" ]; then
    log_info "Copying '$DRJEKYLL_DOCS_DIR/_config.yaml' to '$DRJEKYLL_DOCS_DIR/_config.yml'..."
    cp "$DRJEKYLL_DOCS_DIR/_config.yaml" "$DRJEKYLL_DOCS_DIR/_config.yml"
  fi

  # Jekyll builds into a writable temp dir inside the container first.
  # We then copy the result to OUTPUT_DIR so that Jekyll never needs write access
  # to the (possibly permission-restricted) host-mounted workspace during the build.
  local BUILD_TMP_DIR
  BUILD_TMP_DIR="$(mktemp -d /tmp/jekyll-build-XXXXXX)"
  log_info "Jekyll will build into temporary directory: $BUILD_TMP_DIR"

  # Update destination, url, and baseurl in _config-drjekyll.yml with runtime values.
  log_info "Setting destination in _config-drjekyll.yml to '$BUILD_TMP_DIR' using yq..."
  if ! yq eval ".destination = \"$BUILD_TMP_DIR\"" -i "$DRJEKYLL_DOCS_DIR/_config-drjekyll.yml"; then
    log_error "yq update of destination failed with exit code $?"
    group_end
    exit 1
  fi

  log_info "Setting url in _config-drjekyll.yml to '$INPUT_URL' using yq..."
  if ! yq eval ".url = \"$INPUT_URL\"" -i "$DRJEKYLL_DOCS_DIR/_config-drjekyll.yml"; then
    log_error "yq update of url failed with exit code $?"
    group_end
    exit 1
  fi

  log_info "Setting baseurl in _config-drjekyll.yml to '$INPUT_BASEURL' using yq..."
  if ! yq eval ".baseurl = \"$INPUT_BASEURL\"" -i "$DRJEKYLL_DOCS_DIR/_config-drjekyll.yml"; then
    log_error "yq update of baseurl failed with exit code $?"
    group_end
    exit 1
  fi

  # Build the Jekyll site into the temp directory.
  log_info "Building Jekyll site from '$DRJEKYLL_DOCS_DIR' to '$BUILD_TMP_DIR'..."
  log_info "Final output will be copied to: $OUTPUT_DIR"
  log_info "Jekyll config chain: $DRJEKYLL_DOCS_DIR/_config.yml,$DRJEKYLL_DOCS_DIR/_config-drjekyll.yml"
  log_info "BUNDLE_GEMFILE: $BUNDLE_GEMFILE"
  log_info "BUNDLE_PATH: $BUNDLE_PATH"
  if ! bundle exec jekyll build \
    --source "$DRJEKYLL_DOCS_DIR" \
    --destination "$BUILD_TMP_DIR" \
    --config "$DRJEKYLL_DOCS_DIR/_config.yml,$DRJEKYLL_DOCS_DIR/_config-drjekyll.yml"; then
    log_error "Jekyll build failed."
    rm -rf "$BUILD_TMP_DIR"
    group_end
    exit 1
  fi

  log_info "Jekyll build succeeded. Copying output from '$BUILD_TMP_DIR' to '$OUTPUT_DIR'..."
  mkdir -p "$OUTPUT_DIR"
  if ! rsync -a --delete "$BUILD_TMP_DIR/" "$OUTPUT_DIR/"; then
    log_error "Failed to copy build output to '$OUTPUT_DIR'. Check that the directory is writable."
    rm -rf "$BUILD_TMP_DIR"
    group_end
    exit 1
  fi
  rm -rf "$BUILD_TMP_DIR"
  log_info "Output successfully written to '$OUTPUT_DIR'."

  # Ensure the output directory and its contents are readable by the runner user.
  # The container runs as root, so files may be created with restrictive permissions
  # that prevent subsequent steps (e.g. upload-pages-artifact) from accessing them.
  log_info "Setting read permissions on '$OUTPUT_DIR' for all users..."
  chmod -R a+rX "$OUTPUT_DIR"

  log_output_summary
  group_end
}


function setup_work_dir() {
  group_start "Setup local work directory"
  log_info "Creating/refreshing work directory '$DRJEKYLL_WORK_DIR'..."
  rm -rf "$DRJEKYLL_WORK_DIR"
  mkdir -p "$DRJEKYLL_WORK_DIR"

  # Layer 1: seed with drjekyll theme/framework files (exclude vendor to avoid copying large gem trees).
  log_info "Seeding work dir from DrJekyll docs '$DRJEKYLL_DOCS_DIR'..."
  if ! rsync -a --exclude='vendor/' "$DRJEKYLL_DOCS_DIR/" "$DRJEKYLL_WORK_DIR/"; then
    log_error "rsync of DrJekyll docs into work dir failed with exit code $?"
    group_end
    exit 1
  fi

  # Layer 2: overlay user input files (same exclusions as the action merge).
  log_info "Overlaying input directory '$INPUT_DIR' onto work dir..."
  if ! rsync -avL --ignore-times \
      --exclude='Gemfile' \
      --exclude='Gemfile.lock' \
      --exclude='_config-drjekyll.yml' \
      --exclude='_includes/footer_custom.html' \
      --exclude='_includes/header_custom.html' \
      "$INPUT_DIR/" "$DRJEKYLL_WORK_DIR/"; then
    log_error "rsync of input dir into work dir failed with exit code $?"
    group_end
    exit 1
  fi

  # Ensure user config lands in the work dir.
  if [ -f "$INPUT_DIR/_config.yml" ]; then
    cp "$INPUT_DIR/_config.yml" "$DRJEKYLL_WORK_DIR/_config.yml"
  elif [ -f "$INPUT_DIR/_config.yaml" ]; then
    cp "$INPUT_DIR/_config.yaml" "$DRJEKYLL_WORK_DIR/_config.yaml"
  fi

  # Normalize to _config.yml.
  if [ -f "$DRJEKYLL_WORK_DIR/_config.yaml" ] && [ ! -f "$DRJEKYLL_WORK_DIR/_config.yml" ]; then
    cp "$DRJEKYLL_WORK_DIR/_config.yaml" "$DRJEKYLL_WORK_DIR/_config.yml"
  fi

  # Handle user header/footer customizations.
  if [ -f "$INPUT_DIR/_includes/footer_custom.html" ]; then
    cp "$INPUT_DIR/_includes/footer_custom.html" "$DRJEKYLL_WORK_DIR/_includes/user_footer_custom.html"
  else
    touch "$DRJEKYLL_WORK_DIR/_includes/user_footer_custom.html"
  fi
  if [ -f "$INPUT_DIR/_includes/header_custom.html" ]; then
    cp "$INPUT_DIR/_includes/header_custom.html" "$DRJEKYLL_WORK_DIR/_includes/user_header_custom.html"
  else
    touch "$DRJEKYLL_WORK_DIR/_includes/user_header_custom.html"
  fi

  log_directory_snapshot "Work directory after merge" "$DRJEKYLL_WORK_DIR" 150

  setup_gems "$DRJEKYLL_WORK_DIR"
  group_end
}

function serve_docs() {
  group_start "Serve docs"

  if [ ! -f "$INPUT_DIR/_config.yml" ] && [ ! -f "$INPUT_DIR/_config.yaml" ]; then
    log_error "Input directory '$INPUT_DIR' does not contain _config.yml or _config.yaml."
    group_end
    exit 1
  fi

  if [ ! -f "$DRJEKYLL_WORK_DIR/_config.yml" ] && [ ! -f "$DRJEKYLL_WORK_DIR/_config.yaml" ]; then
    log_error "Work directory '$DRJEKYLL_WORK_DIR' does not contain _config.yml or _config.yaml."
    group_end
    exit 1
  fi

  local SERVE_DEST="$DRJEKYLL_WORK_DIR/_site"

  log_info "Setting destination in work dir _config-drjekyll.yml to '$SERVE_DEST' using yq..."
  if ! yq eval ".destination = \"$SERVE_DEST\"" -i "$DRJEKYLL_WORK_DIR/_config-drjekyll.yml"; then
    log_error "yq update of destination failed with exit code $?"
    group_end
    exit 1
  fi

  log_info "Setting url in work dir _config-drjekyll.yml to '$INPUT_URL' using yq..."
  if ! yq eval ".url = \"$INPUT_URL\"" -i "$DRJEKYLL_WORK_DIR/_config-drjekyll.yml"; then
    log_error "yq update of url failed with exit code $?"
    group_end
    exit 1
  fi

  log_info "Setting baseurl in work dir _config-drjekyll.yml to '$INPUT_BASEURL' using yq..."
  if ! yq eval ".baseurl = \"$INPUT_BASEURL\"" -i "$DRJEKYLL_WORK_DIR/_config-drjekyll.yml"; then
    log_error "yq update of baseurl failed with exit code $?"
    group_end
    exit 1
  fi

  # Build the config chain: user config, drjekyll base config, then local overrides if present.
  local SERVE_CONFIG="$DRJEKYLL_WORK_DIR/_config.yml,$DRJEKYLL_WORK_DIR/_config-drjekyll.yml"
  if [ -f "$DRJEKYLL_WORK_DIR/_config-drjekyll-local.yml" ]; then
    SERVE_CONFIG="$SERVE_CONFIG,$DRJEKYLL_WORK_DIR/_config-drjekyll-local.yml"
    log_info "Local config override found: $DRJEKYLL_WORK_DIR/_config-drjekyll-local.yml"
  fi

  log_info "Serving Jekyll site from work dir '$DRJEKYLL_WORK_DIR'..."
  log_info "Config chain: $SERVE_CONFIG"
  log_info "BUNDLE_GEMFILE: $BUNDLE_GEMFILE"
  log_info "BUNDLE_PATH: $BUNDLE_PATH"

  bundle exec jekyll serve \
    --source "$DRJEKYLL_WORK_DIR" \
    --destination "$SERVE_DEST" \
    --config "$SERVE_CONFIG" \

  group_end
}

function main() {
  group_start "DrJekyll action startup"
  log_environment_context
  group_end

  if [ "$DRJEKYLL_SERVE" = "true" ]; then
    setup_work_dir
    replace_template_vars "$DRJEKYLL_WORK_DIR"
    serve_docs
    log_info "Jekyll serve exited."
  else
    setup_drjekyll
    replace_template_vars "$DRJEKYLL_DOCS_DIR"
    build_docs
    log_info "Action completed successfully."
  fi
}

main "$@"
