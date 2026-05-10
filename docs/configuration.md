---
title: ⚙️ Configuration
nav_order: 3
---

# ⚙️ Configuration
{: .no_toc }

<details open markdown="block">
  <summary>Table of contents</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>

---

Dr. Jekyll reads a `_config.yml` (or `_config.yaml`) from your `input_dir`. This file is merged on top of the Dr. Jekyll base configuration, so you only need to specify the values you want to change.

---

## Minimal Configuration

```yaml
---
title: My Project
description: A short description of my project.
```

---

## Full Example

```yaml
---
# Site identity
title: My Project
description: A short description of my project.

# Logo displayed in the header (path relative to the built site root)
logo: /assets/images/icon.svg

# Links shown in the top navigation bar
aux_links:
  "GitHub":
    - "https://github.com/my-org/my-repo"

aux_links_new_tab: true
```

---

## Options

### `title`

**Type:** string

The name of the site, displayed in the browser tab and in the header navigation bar.

```yaml
title: My Project
```

### `description`

**Type:** string

A short description of the site, used in `<meta>` tags for SEO.

```yaml
description: Documentation for My Project.
```

### `logo`

**Type:** string (URL path)

Path to a logo image displayed in the site header, relative to the site root. SVG and PNG formats are recommended.

```yaml
logo: /assets/images/icon.svg
```

Place the image file in `docs/assets/images/` and it will be copied to the built site automatically.

### `aux_links`

**Type:** map of label → list of URLs

Links rendered as buttons in the top navigation bar. Each key is the button label; the value is a list containing the URL.

```yaml
aux_links:
  "GitHub":
    - "https://github.com/my-org/my-repo"
  "Changelog":
    - "https://github.com/my-org/my-repo/releases"
```

### `aux_links_new_tab`

**Type:** boolean — default `true`

When `true`, `aux_links` URLs open in a new browser tab.

```yaml
aux_links_new_tab: true
```

---

## Inherited Options

The following options are provided by the Dr. Jekyll base configuration and can be overridden in your `_config.yml`.

### `color_scheme`

**Type:** string — default `dracula`

The colour scheme applied to the site. Available built-in schemes:

| Scheme | Description |
|---|---|
| `breeze` | Light blue and white |
| `cyberpunk2077` | High-contrast neon yellow on dark |
| `dracula` | Purple-tinted dark theme |
| `fairy-floss-dark` | Pastel dark theme |
| `gogh` | Warm dark theme |
| `grass` | Green-tinted dark theme |
| `grayscale` | Neutral greyscale |
| `harper` | Warm amber dark theme |
| `horizon-bright` | Light horizon theme |
| `horizon-dark` | Dark horizon theme |
| `hotdog` | Red and yellow |
| `material` | Material Design dark |
| `matrix` | Green-on-black |
| `mono-amber` | Monochrome amber |
| `mono-cyan` | Monochrome cyan |
| `mono-green` | Monochrome green |
| `mono-red` | Monochrome red |
| `mono-white` | Monochrome white |
| `mono-yellow` | Monochrome yellow |
| `tokyo-night` | Tokyo Night dark theme |
| `tron` | Cyan on dark blue |
| `ubuntu` | Ubuntu terminal-inspired |

```yaml
color_scheme: dracula
```

### `search_enabled`

**Type:** boolean — default `true`

Enables the full-text search box in the navigation bar.

```yaml
search_enabled: true
```

### `math`

**Type:** string — default `katex`

Math rendering engine. Set to `katex` to enable KaTeX rendering of LaTeX expressions.

```yaml
math: katex
```

Inline math: `` $E = mc^2$ ``  
Display math:

```
$$
\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}
$$
```

### `nav_sort`

**Type:** string — default `case_insensitive`

Controls how navigation items are sorted. `case_insensitive` sorts alphabetically without regard to case.

```yaml
nav_sort: case_insensitive
```

---

## Theme Configuration Reference

Dr. Jekyll is built on [Just the Docs](https://just-the-docs.com). Any option supported by Just the Docs can be set in your `_config.yml` and it will take effect in the built site.
