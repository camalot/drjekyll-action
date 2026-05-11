---
layout: home
title: 🏠 Home
nav_order: 1
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# Dr. Jekyll Action

Dr. Jekyll is a GitHub Action that builds a Jekyll documentation site using an opinionated, pre-configured theme and deploys it to GitHub Pages — with zero theme boilerplate required in your repository.

You provide a directory of Markdown files and a `_config.yml`. Dr. Jekyll handles the rest: theme, plugins, syntax highlighting, search, math rendering, and more.

---

## Features

- **Just the Docs theme** — clean, responsive documentation layout with built-in search
- **Syntax highlighting** — powered by Rouge with multiple color schemes
- **Math rendering** — KaTeX support out of the box
- **Callouts** — note, tip, warning, caution, important, and more
- **Dark/light themes** — multiple color schemes included
- **Zero theme files in your repo** — the action provides all theme assets

---

## Quick Start

**1.** Enable GitHub Pages in your repository settings (source: GitHub Actions).

`Repository settings > Pages > Source > GitHub Actions`

**2.** Add a `docs/` directory with an `index.md` and a `_config.yml`:

``` tree
docs/
  _config.yml
  index.md
```

**3.** Create `.github/workflows/docs.yml`:

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

**4.** Trigger the workflow from the **Actions** tab.

---

## Next Steps

- [Usage](usage) — full workflow walkthrough and input reference
- [Configuration](configuration) — `_config.yml` options
