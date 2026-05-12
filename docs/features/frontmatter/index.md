---
title: 📋 Frontmatter Table
nav_order: 4
layout: default
parent: ⭐ Features
has_children: true
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# 📋 Frontmatter Table
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
| Number | `version: 42` | `<code>42</code>` |
| Boolean | `enabled: true` | `<code>true</code>` |
| Null | `notes: ~` | *(empty cell)* |
| Array of strings | `tags: [a, b, c]` | Unordered list |
| Array of objects | `inputs: [{name: x, required: true}]` | Nested table |
| Nested hash | `permissions: {network: true}` | `network: true` |

### Array of Objects

When a YAML value is an array of objects, it renders as a nested table inside the cell. All keys across all objects in the array are unioned to form the nested column headers; missing values render as empty cells.

```yaml
---
name: my-skill
inputs:
  - name: target
    description: The target system.
    required: true
  - name: environment
    description: Deployment environment.
    required: false
    default: dev
---
```

The `inputs` cell renders as a nested table:

| name | description | required | default |
| --- | --- | --- | --- |
| target | The target system. | true | |
| environment | Deployment environment. | false | dev |

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

- **Liquid includes**: Blocks inside `{% raw %}{% include %}{% endraw %}` files are not processed in the parent page's context, since the plugin runs before Liquid resolves includes.
- **Deeply nested values**: Values nested inside an array-of-objects are serialized with `.to_s` — sub-tables are not rendered recursively.
