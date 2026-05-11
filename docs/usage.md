---
title: ℹ️ Usage
nav_order: 2
layout: default
---

# ℹ️ Usage
{: .no_toc }

<details open markdown="block">
  <summary>Table of contents</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

---

## Prerequisites

- A GitHub repository with **GitHub Pages** enabled (Settings → Pages → Source: **GitHub Actions**).
- A `docs/` directory (or another directory of your choice) containing at least `index.md` and `_config.yml`.

---

## Repository Layout

``` tree
my-repo/
├── .github/
│   └── workflows/
│       └── docs.yml        # deployment workflow
└── docs/
    ├── _config.yml         # site configuration
    ├── index.md            # home page
    └── ...                 # additional pages
```

---

## Workflow

The full recommended workflow is shown below. Each step is explained in the sections that follow.

```yaml
---
name: Deploy Documentation

on:
  # Trigger automatically on pushes to the default branch:
  # push:
  #   branches:
  #     - "main"

  # Or trigger manually from the Actions tab:
  workflow_dispatch:

permissions: {}

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    permissions:
      contents: read   # to check out the repository
      pages: write     # required by actions/configure-pages
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        with:
          persist-credentials: false
          fetch-depth: 0

      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v6

      - name: Dr. Jekyll Build
        uses: camalot/drjekyll-action@v1
        env:
          JEKYLL_ENV: production
        with:
          input_dir: ./docs
          output_dir: ./_site
          url: ${{ steps.pages.outputs.base_url }}
          baseurl: ""

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v5

  deploy:
    permissions:
      pages: write      # to deploy to GitHub Pages
      id-token: write   # to authenticate with GitHub Pages
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v5
```

### Checkout

```yaml
- name: Checkout
  uses: actions/checkout@v6
  with:
    persist-credentials: false
    fetch-depth: 0
```

A full history checkout (`fetch-depth: 0`) is recommended so that Jekyll can read Git metadata (e.g. page last-modified dates) if your theme uses it.

### Setup Pages

```yaml
- name: Setup Pages
  id: pages
  uses: actions/configure-pages@v6
```

`actions/configure-pages` configures the GitHub Pages deployment and exposes the site's `origin` as a step output. The `id: pages` is required so the output can be referenced in the next step.

### Dr. Jekyll Build

```yaml
- name: Dr. Jekyll Build
  uses: camalot/drjekyll-action@v1
  env:
    JEKYLL_ENV: production
  with:
    input_dir: ./docs
    output_dir: ./_site
    url: "{% raw %}${{ ${{ steps.pages.outputs.origin }} }}{% endraw %}"
    baseurl: "{% raw %}${{ ${{ steps.pages.outputs.base_path }} }}{% endraw %}"
```

This is the core step. See [Inputs](#inputs) below for full details.

{: .important }
> Always set `url` to `{% raw %}${{ ${{ steps.pages.outputs.origin }} }}{% endraw %}` when deploying to GitHub Pages. Use `{% raw %}${{ ${{ steps.pages.outputs.base_path }} }}{% endraw %}` for the `baseurl` when deploying to enterprise or custom domains. This ensures Jekyll generates correct absolute URLs for stylesheets, scripts, and links. Leaving it empty will cause assets to fail to load on the deployed site.
>
> If you are deploying to a custom domain or organization Pages site, set `baseurl: ""` to avoid double slashes in URLs. If deploying to a user Pages site, set `baseurl` to the repository name with `{% raw %}${{ ${{ steps.pages.outputs.base_path }} }}{% endraw %}`.

### Upload & Deploy

```yaml
- name: Upload artifact
  uses: actions/upload-pages-artifact@v5
```

Packages the `output_dir` as a Pages artifact. The `deploy` job then picks it up via `actions/deploy-pages`.

---

## Inputs

| Input | Description | Required | Default |
| --- | --- | --- | --- |
| `input_dir` | Path to your Jekyll source directory, relative to the repository root. | No | `.` |
| `output_dir` | Path where the built site is written, relative to the repository root. | No | `_site` |
| `url` | Full URL of the deployed site (e.g. `https://my-org.github.io`). Use `{% raw %}${{ ${{ steps.pages.outputs.origin }} }}{% endraw %}`. | No | `` |
| `baseurl` | Base path appended to the URL (e.g. `/my-repo`). Leave empty `""` when deploying to a custom domain or organization Pages site. Use `{% raw %}${{ ${{ steps.pages.outputs.base_path }} }}{% endraw %}` for the `baseurl` when deploying to user GitHub Pages. | No | `/` |

---

## Writing Pages

Pages are standard Markdown files with Jekyll front matter:

```markdown
---
title: My Page
nav_order: 2
---

# My Page

Content goes here.
```

### Navigation Order

Pages appear in the sidebar sorted by `nav_order`. Lower values appear first. The home page (`index.md`) should use `nav_order: 1`.

### Child Pages

Use `parent` in the front matter to nest a page under another:

```markdown
---
title: Sub-topic
parent: My Page
nav_order: 1
---
```

---

## Callouts

The following callout types are available:

```markdown
{: .note }
This is a note.
```

{: .note }
This is a note.

```markdown
{: .new }
This is a new.
```

{: .new }
This is a new.

```markdown
{: .highlight }
This is a highlight.
```

{: .highlight }
This is a highlight.

```markdown
{: .tip }
This is a tip.
```

{: .tip }
This is a tip.

```markdown
{: .warning }
This is a warning.
```

{: .warning }
This is a warning.

```markdown
{: .caution }
This is a caution.
```

{: .caution }
This is a caution.

```markdown
{: .important }
This is important.
```

{: .important }
This is important.
