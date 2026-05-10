# Dr. Jekyll Action

A GitHub Action that builds a Jekyll documentation site using the Dr. Jekyll theme and deploys it to GitHub Pages.

Full documentation is available at **https://iman-srecore.github.io/drjekyll-action**.

---

## Quick Start

```yaml
- name: Setup Pages
  id: pages
  uses: actions/configure-pages@v6

- name: Dr. Jekyll Build
  uses: iman-srecore/drjekyll-action@v1
  env:
    JEKYLL_ENV: production
  with:
    input_dir: ./docs
    output_dir: ./_site
    url: ${{ steps.pages.outputs.base_url }}
    baseurl: ""
```

## Inputs

| Input | Description | Required | Default |
|---|---|---|---|
| `input_dir` | Directory containing your Jekyll source files | No | `.` |
| `output_dir` | Directory where the built site is written | No | `_site` |
| `url` | Full URL of the deployed site (e.g. `https://org.github.io`) | No | `` |
| `baseurl` | Base path for the site (e.g. `/my-repo`) | No | `/` |

## Example Workflow

```yaml
---
name: Deploy Documentation

on:
  workflow_dispatch:

permissions: {}

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    permissions:
      contents: read
      pages: write
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
        uses: iman-srecore/drjekyll-action@v1
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
      pages: write
      id-token: write
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

## Repository Layout

Place your documentation source in a directory (typically `docs/`) alongside a `_config.yml`:

```
docs/
  _config.yml      # Jekyll site configuration
  index.md         # Site home page
  ...              # Additional pages and assets
```

## Site Configuration

Create a `_config.yml` inside your `input_dir`:

```yaml
---
title: My Project
description: A short description of the site.

logo: /assets/images/icon.svg

aux_links:
  "GitHub":
    - "https://github.com/my-org/my-repo"

aux_links_new_tab: true
```

See the full [Configuration reference](https://iman-srecore.github.io/drjekyll-action/configuration) for all available options.
