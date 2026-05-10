#!/usr/bin/env bash

# This script is the entry point for the GitHub Action. It sets up the environment, builds the Jekyll site to the specified output directory, and handles any necessary configuration.


# Set the input and output directories. The input directory is set on the action as an input as input_dir. The output directory is set on the action as an input as output_dir.

INPUT_DIR="${INPUT_INPUT_DIR:-.}"
OUTPUT_DIR="${INPUT_OUTPUT_DIR:-_site}"
DRJEKYLL_DOCS_DIR="/app/docs"

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

  # check if INPUT_DIR exists
  if [ ! -d "$INPUT_DIR" ]; then
    echo "Input directory '$INPUT_DIR' does not exist." >&2
    exit 1
  fi

  # check if DRJEKYLL_DOCS_DIR exists
  if [ ! -d "$DRJEKYLL_DOCS_DIR" ]; then
    echo "Dr. Jekyll docs directory '$DRJEKYLL_DOCS_DIR' does not exist." >&2
    exit 1
  fi

  # Merge the input directory with the drjekyll docs directory. This will allow the Jekyll build to find the necessary configuration and assets. We will copy the contents of the input directory to the drjekyll docs directory, overwriting any existing files. This will allow the user to override any configuration or assets that are provided by drjekyll.

  # input_dir/_includes/footer_custom.html and input_dir/_includes/header_custom.html and copy them to the drjekyll docs directory as _includes/user_footer_custom.html and _includes/user_header_custom.html. They are then included in the drjekyll header and footer includes, allowing the user to customize the header and footer of their site without modifying the drjekyll includes.

  echo "Merging input directory '$INPUT_DIR' with Dr. Jekyll docs directory '$DRJEKYLL_DOCS_DIR'..."
  # need to ignore Gemfile, Gemfile.lock, and _config-drjekyll.yml, as well as the _includes/footer_custom.html and _includes/header_custom.html files, as they are handled separately
  rsync -av --exclude='Gemfile' --exclude='Gemfile.lock' --exclude='_config-drjekyll.yml' --exclude='_includes/footer_custom.html' --exclude='_includes/header_custom.html' "$INPUT_DIR/" "$DRJEKYLL_DOCS_DIR/"

  setup_user_header_footer

  # if user has their own Gemfile, we need to make sure that the packages that are required by drjekyll are included in the user's Gemfile. We will check if the user's Gemfile includes the necessary packages, and if not, we will add them to the user's Gemfile. This will allow the user to use their own Gemfile while still ensuring that the necessary packages for drjekyll are installed.
  local USER_GEMFILE="$INPUT_DIR/Gemfile"
  local TEMP_GEMFILE="$DRJEKYLL_DOCS_DIR/UserGemfile"

  cp "$USER_GEMFILE" "$TEMP_GEMFILE"
  USER_GEMFILE="$TEMP_GEMFILE"

  local drjekyll_packages=()
  mapfile -t drjekyll_packages < <(get_drjekyll_packages)
  for package in "${drjekyll_packages[@]}"; do
    local package_name="${package%%:*}"
    local package_version="${package#*:}"
    if ! gemfile_contains "$USER_GEMFILE" "$package_name"; then
      add_package_to_gemfile "$USER_GEMFILE" "$package_name" "$package_version"
    else
      echo "Package '$package_name' is already included in the user's Gemfile. Skipping."
    fi
  done
  # After ensuring that the user's Gemfile includes the necessary packages for drjekyll, we will install the gems using Bundler. We will specify the user's Gemfile as the Gemfile to use for the installation, and we will install the gems to a local directory called vendor/bundle. This will allow us to use the installed gems for the Jekyll build without affecting the global gem environment.
  # Install the necessary gems for the Jekyll build. We will use Bundler to install the gems specified in the user's Gemfile, which now includes the necessary packages for drjekyll.
  echo "Installing gems for Jekyll build..."
  bundle install --gemfile="$USER_GEMFILE" --path vendor/bundle
}

function build_docs() {
  # Check if the output directory exists, if it does, remove it
  if [ -d "$OUTPUT_DIR" ]; then
    echo "Output directory '$OUTPUT_DIR' already exists. Removing it." >&2
    rm -rf "$OUTPUT_DIR"
  fi

  # if the user files does not include a _config.yml file, we need to fail. DrJekyll does not define all the necessary configuration for Jekyll to build the site, so we need to ensure that the user provides a _config.yml file with the necessary configuration. If the user does not provide a _config.yml file, we will not be able to build the site, and we will fail with an error message.
  if [ ! -f "$DRJEKYLL_DOCS_DIR/_config.{yml,yaml}" ]; then
    echo "Input directory '$INPUT_DIR' does not contain a _config.{yml,yaml} file. Please provide a _config.{yml,yaml} file with the necessary configuration for Jekyll to build the site." >&2
    exit 1
  fi

  # normalize the _config file name to _config.yml, as Jekyll will look for _config.yml by default. If the user provides a _config.yaml file, we will copy it to _config.yml in the drjekyll docs directory. This will allow Jekyll to find the configuration file and build the site successfully.
  if [ -f "$DRJEKYLL_DOCS_DIR/_config.yaml" ] && [ ! -f "$DRJEKYLL_DOCS_DIR/_config.yml" ]; then
    echo "Copying '$DRJEKYLL_DOCS_DIR/_config.yaml' to '$DRJEKYLL_DOCS_DIR/_config.yml'..."
    cp "$DRJEKYLL_DOCS_DIR/_config.yaml" "$DRJEKYLL_DOCS_DIR/_config.yml"
  fi

  # Check if the input files contain the necessary configuration for drjekyll. If not, we will add the necessary configuration to the drjekyll docs directory. This will allow the Jekyll build to succeed even if the user does not provide the necessary configuration.

  # Build the Jekyll site
  echo "Building Jekyll site from '$INPUT_DIR' to '$OUTPUT_DIR'..."
  jekyll build \
    --source "$INPUT_DIR" \
    --destination "$OUTPUT_DIR" \
    --config "$DRJEKYLL_DOCS_DIR/_config.yml,$DRJEKYLL_DOCS_DIR/_config-drjekyll.yml"
}


function main() {
  setup_drjekyll
  build_docs
}

main "$@"