---
title: 📋 Embedded Frontmatter Table
nav_order: 4
layout: default
parent: ⭐ Features
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# 📋 Embedded Frontmatter Table
{: .no_toc }

Dr. Jekyll can detect YAML metadata blocks embedded inside a page's content and automatically render them as styled tables. This is useful for documenting structured metadata inline — for example, Agent Skill definitions, plugin manifests, or configuration schemas.

{% include toc.md %}

---

## How It Works

Any YAML block delimited by `---` that appears in your page content (after the primary Jekyll frontmatter) is detected and rendered as a table at build time. Keys become column headers; values fill the single data row beneath them.

```markdown
---
title: My Skill Page
nav_order: 1
layout: default
---

---
name: my-skill
description: Does something awesome.
version: 1.0.0
---

# My Skill

The rest of your page content continues here.
```

The `---` block above renders as:

| name | description | version |
| --- | --- | --- |
| my-skill | Does something awesome. | 1.0.0 |

---

## Supported Value Types

| YAML Type | Example | Rendered As |
| --- | --- | --- |
| String | `label: hello` | `hello` |
| Number | `version: 42` | `42` |
| Boolean true | `enabled: true` | `true` |
| Boolean false | `deprecated: false` | `false` |
| Null | `notes: ~` | *(empty cell)* |
| Array | `tags: [a, b, c]` | `a, b, c` |
| Nested hash | `config: {key: val}` | `key: val` |

---

## Code Fence Safety

Blocks inside fenced code examples are **not** converted. Writing documentation that shows what an embedded frontmatter block looks like is safe:

````markdown
Here is an example block:

```yaml
---
name: example
description: This will NOT be converted to a table.
---
```
````

The plugin tracks fence state line-by-line and skips any `---` block inside a `` ``` `` or `~~~` fence.

---

## Configuration

### Per-Page Opt-Out

Add `render_embedded_frontmatter: false` to a page's primary frontmatter to disable processing for that page:

```yaml
---
title: My Page
render_embedded_frontmatter: false
---
```

### Global Config

In `_config.yml`:

```yaml
embedded_frontmatter:
  enabled: true          # set to false to disable site-wide (default: true)
  css_class: frontmatter-table   # CSS class on the wrapping <div> (default: frontmatter-table)
```

---

## Limitations

- **Array-of-objects**: A top-level YAML array (e.g. `- name: x\n  value: y`) is not converted — it passes through unchanged. Only top-level hashes produce a table.
- **Liquid includes**: Blocks inside `{% raw %}{% include %}{% endraw %}` files are not processed in the parent page's context, since the plugin runs before Liquid resolves includes.
- **Deeply nested YAML**: Nested hashes are flattened to `key: value` strings. Sub-tables are not rendered.
