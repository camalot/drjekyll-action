# Plan: Second Frontmatter Table Rendering

## Overview

Extend the `drjekyll` Jekyll theme to detect "second frontmatter" YAML blocks that appear in page content (after the primary Jekyll frontmatter) and automatically render them as styled HTML tables. This is useful for documenting structured metadata inline with page content — for example, Agent Skill definitions or plugin manifests.

### Example Input

```markdown
---
title: My Page With FrontMatter
nav_order: 1
layout: default
---

---
name: my-skill
description: my awesome skill ...
---

# My Skill
...
```

### Expected Output

The second `---` block is rendered as a table on the page:

| name | description |
| --- | --- |
| my-skill | my awesome skill ... |

---

## User Story

As a documentation author, I want to embed structured YAML metadata blocks in my markdown pages (e.g., Agent Skill definitions) and have Jekyll automatically render those blocks as clean tables — without requiring me to manually write HTML or maintain duplicate content.

---

## Technical Design

### Processing Stage

Jekyll processes documents in this order:

1. Read file → strip primary frontmatter → store as `doc.data`, body as `doc.content`
2. `:pre_render` hook fires → content is raw markdown/Liquid
3. Liquid rendering
4. Markdown → HTML conversion (Kramdown)
5. Layout wrapping

We intercept at **stage 2 (`:pre_render`)** and replace YAML blocks in `doc.content` with HTML table markup before Kramdown can misinterpret `---` as a thematic break (`<hr>`).

### Detection Strategy

Detection uses a **line-by-line stateful parser** rather than a simple regex `gsub`. This is necessary for two critical reasons:

1. **Code fence awareness**: A regex cannot distinguish `---` blocks inside fenced code examples (` ``` ` or `~~~`) from real second frontmatter. A documentation author writing an example of the very feature being documented would have their code example consumed and converted to a table.

2. **Block boundary enforcement**: The opening `---` must be preceded by a blank line (or be at the start of content) to avoid matching Setext-style heading underlines (`My Heading\n---`).

The parser:
- Tracks fence state (inside ` ```/~~~ ` block = skip all detection)
- Tracks YAML collection state (between `---` delimiters)
- Only starts collecting on `---` preceded by blank/start-of-content
- Validates collected content with `YAML.safe_load`; keeps block unchanged on failure

### Table Format

Keys become **column headers** (`<th>`). Values are rendered in a single row below. This matches the user's specification:

```
| name | description |
| --- | --- |
| my-skill | my awesome skill ... |
```

### Value Serialization

| Value Type | Rendering |
|---|---|
| String / Number | As-is (HTML-escaped) |
| Boolean (`true`/`false`) | Literal `"true"` or `"false"` (not blank) |
| Array | Comma-joined: `item1, item2` |
| Hash / nested object | Serialized as `key: value` pairs (newline-separated) |
| `nil` | Rendered as empty string |

### HTML Escaping

All values and all YAML keys will be run through `CGI.escapeHTML`. The `css_class` config value is also escaped before interpolation into the `class` attribute.

### Multiple Blocks Per Page

The parser processes the entire document from top to bottom, transforming each valid YAML block in turn.

### Bootstrap Styling

The project uses Bootstrap 5.3.3. The generated table uses Bootstrap table classes (`table table-bordered table-sm`) wrapped in a `<div class="frontmatter-table">`. The generated HTML is wrapped in blank lines (`\n\n`) to ensure Kramdown treats it as a block element and does not wrap it in `<p>` tags.

### Opt-in / Opt-out

By default, the plugin scans **all pages and documents**. A page-level frontmatter flag disables per-page:

```yaml
---
render_embedded_frontmatter: false
---
```

A global site-level config option:

```yaml
# _config.yml
embedded_frontmatter:
  enabled: true          # default: true
  css_class: frontmatter-table
```

---

## Implementation Steps

### Step 1 — Ruby Plugin

**File:** `drjekyll/_plugins/frontmatter_table.rb`

```ruby
# frozen_string_literal: true

require 'yaml'
require 'cgi'

module Jekyll
  module FrontmatterTable
    FENCE_PATTERN  = /\A(`{3,}|~{3,})/
    OPEN_PATTERN   = /\A---\s*\z/
    CLOSE_PATTERN  = /\A---[ \t]*\z/

    def self.process(content, css_class)
      lines        = content.lines
      result       = []
      in_fence     = false
      collecting   = false
      yaml_lines   = []
      prev_blank   = true   # treat start-of-content as preceded by blank

      lines.each do |line|
        # Track fenced code blocks (backtick or tilde, any length >= 3)
        if !collecting && line.match?(FENCE_PATTERN)
          in_fence = !in_fence
          result << line
          prev_blank = false
          next
        end

        if in_fence
          result << line
          next
        end

        if !collecting && line.match?(OPEN_PATTERN) && prev_blank
          # Begin collecting a potential YAML block
          collecting  = true
          yaml_lines  = []
          prev_blank  = false
          next
        end

        if collecting
          if line.match?(CLOSE_PATTERN)
            # End of block — attempt YAML parse
            yaml_str = yaml_lines.join
            begin
              data = YAML.safe_load(yaml_str, permitted_classes: [Date, Time, Symbol])
              if data.is_a?(Hash) && !data.empty?
                result << "\n\n#{generate_table(data, css_class)}\n\n"
              else
                # Not a hash — restore original text unchanged
                result << "---\n" << yaml_lines << "---\n"
              end
            rescue Psych::SyntaxError, Psych::DisallowedClass
              result << "---\n" << yaml_lines << "---\n"
            end
            collecting = false
            yaml_lines = []
            prev_blank = line.strip.empty?
          else
            yaml_lines << line
            prev_blank = line.strip.empty?
          end
          next
        end

        result << line
        prev_blank = line.strip.empty?
      end

      # Unclosed block — restore unchanged
      if collecting
        result << "---\n"
        result.concat(yaml_lines)
      end

      result.join
    end

    def self.generate_table(data, css_class)
      safe_class = CGI.escapeHTML(css_class.to_s)
      headers    = data.keys
      values     = headers.map { |k| serialize_value(data[k]) }

      th_cells = headers.map { |h| "<th>#{CGI.escapeHTML(h.to_s)}</th>" }.join
      td_cells = values.map  { |v| "<td>#{CGI.escapeHTML(v)}</td>" }.join

      <<~HTML
        <div class="#{safe_class}">
          <table class="table table-bordered table-sm">
            <thead><tr>#{th_cells}</tr></thead>
            <tbody><tr>#{td_cells}</tr></tbody>
          </table>
        </div>
      HTML
    end

    def self.serialize_value(value)
      case value
      when Array    then value.map(&:to_s).join(', ')
      when Hash     then value.map { |k, v| "#{k}: #{v}" }.join("\n")
      when NilClass then ''
      else value.to_s
      end
    end
  end
end

Jekyll::Hooks.register [:pages, :documents], :pre_render do |doc|
  next if doc.content.nil?

  site_config = doc.site.config['embedded_frontmatter'] || {}
  next unless site_config.fetch('enabled', true)
  next if doc.data['render_embedded_frontmatter'] == false

  css_class  = site_config.fetch('css_class', 'frontmatter-table')
  doc.content = Jekyll::FrontmatterTable.process(doc.content, css_class)
end
```

**Key design notes:**
- The fence tracker handles both `` ``` `` and `~~~` openers of any length ≥ 3.
- `prev_blank = true` at start-of-content means a `---` at the very beginning of the document body is valid (it is preceded by nothing, which counts as blank).
- `false` and `true` are handled by `value.to_s` in the `else` branch — they render as `"false"` and `"true"`, not as empty strings.
- `YAML.safe_load` with `permitted_classes: [Date, Time, Symbol]` prevents `Psych::DisallowedClass` errors from common YAML types in Psych 4 (Ruby 3.1+).
- `CGI.escapeHTML` is applied to keys, values, and the `css_class` config value.
- The replacement block is wrapped in `\n\n` so Kramdown processes it as a block element, not inline content that would be wrapped in `<p>`.

### Step 2 — SCSS Styles

**File:** `drjekyll/assets/css/_frontmatter-table.scss`

All partials live directly in `drjekyll/assets/css/` (no subdirectory). The SCSS uses theme SCSS variables (`$theme-bootstrap-secondary-bg`, `$theme-bootstrap-body-color`) rather than CSS custom properties (`var(--bs-*)`) to ensure correct compilation per theme into the `theme-*.scss` files.

```scss
.frontmatter-table {
  margin: 1rem 0 1.5rem;
  overflow-x: auto;

  table {
    width: auto;
    min-width: 50%;

    thead th {
      background-color: $theme-bootstrap-secondary-bg;
      color: $theme-bootstrap-body-color;
      font-weight: 600;
      white-space: nowrap;
    }

    td {
      font-family: $mono-font-family;
      font-size: 0.9em;
    }
  }
}
```

**Modify:** `drjekyll/assets/css/_theme.scss` — add import at the end:

```scss
@import 'frontmatter-table';
```

### Step 3 — Documentation Page

**File:** `docs/features/frontmatter-table.md`

Contents:
- Feature description and motivation
- Syntax / usage example (raw markdown with second frontmatter)
- Rendered output example (showing the resulting table)
- Supported value types with rendering table
- Per-page opt-out: `render_embedded_frontmatter: false`
- Global config options (`embedded_frontmatter.enabled`, `embedded_frontmatter.css_class`)
- Known limitations section (see below)

### Step 4 — Update Feature Index

**Modify:** `docs/features/index.md`

Add an entry for the Frontmatter Table feature.

---

## File Change Summary

| File | Action | Purpose |
|---|---|---|
| `drjekyll/_plugins/frontmatter_table.rb` | CREATE | Core plugin logic |
| `drjekyll/assets/css/_frontmatter-table.scss` | CREATE | Table styles using theme SCSS variables |
| `drjekyll/assets/css/_theme.scss` | MODIFY | Add `@import 'frontmatter-table'` |
| `docs/features/frontmatter-table.md` | CREATE | Feature documentation |
| `docs/features/index.md` | MODIFY | Add feature to index |

---

## Edge Cases & Design Decisions

| Scenario | Decision | Reason |
|---|---|---|
| `---` inside fenced code block | Skip — fence state tracked per line | Prevents documentation examples of the feature from self-applying |
| `---` not preceded by blank line | Skip — `prev_blank` guard enforced | Prevents Setext heading underlines (`Heading\n---`) from triggering collection |
| `---` as markdown horizontal rule | Skip — YAML parse yields non-Hash | A lone `---` has no key-value content between delimiters |
| YAML parse error | Restore block unchanged | Fail-safe; never corrupt page content |
| Psych 4 `DisallowedClass` on Date/Time | Restore block unchanged after rescue | `permitted_classes:` covers common types; all else fails gracefully |
| `false` / `true` boolean values | Rendered as `"false"` / `"true"` | `nil.to_s` → `""`, `false.to_s` → `"false"` — distinguishable |
| `nil` values | Rendered as empty string | Intent: field present but unset |
| Multiple blocks per page | All processed by the line-by-line pass | Each block independently transformed |
| Values with HTML characters | `CGI.escapeHTML` applied to all keys/values | XSS prevention |
| `css_class` from config | `CGI.escapeHTML` applied before interpolation | Prevents attribute injection if config is externally sourced |
| `doc.content` is nil | `next` guard before processing | Generated/pagination pages may have nil content at `:pre_render` |
| Page opts out | `render_embedded_frontmatter: false` in frontmatter | Per-page control |
| Site-wide disable | `embedded_frontmatter.enabled: false` in `_config.yml` | Global toggle |
| Array-of-objects top-level YAML | Block passes through unchanged | See Limitations |
| Multi-document YAML (`---` separator) | First block consumed; orphaned `---` treated as HR by Kramdown | See Limitations |
| Included pages (`{% include %}`) | Not processed | See Limitations |
| HTML `<div>` wrapped in `<p>` | Prevented by `\n\n` wrapping in replacement | Kramdown needs blank lines to treat block HTML as block-level |

---

## Limitations & Future Work

1. **Array-of-objects YAML**: A top-level YAML array (`- name: x\n  description: y\n`) is not a Hash and will pass through unchanged. Kramdown will render `---` as `<hr>` and the YAML as prose. Future work: detect top-level arrays and render multi-row tables.

2. **Multi-document YAML**: If an author writes two `---`-delimited YAML documents back-to-back with no blank line between (which is non-standard in markdown context), only the first block is processed; the orphaned closing `---` becomes an `<hr>`. This is an edge case unlikely to appear in practice.

3. **Liquid includes**: The `:pre_render` hook fires before Liquid resolves `{% include %}` tags. Second frontmatter blocks inside included files are not processed in the parent page's context. Handling this case would require either: (a) a custom Liquid tag `{% frontmatter_table %}` wrapper, or (b) a `:post_render` HTML parse pass.

4. **Deeply nested YAML**: Nested hashes are serialized as flat `key: value` strings. A future enhancement could render nested structures as sub-tables.

5. **No per-block label**: The table appears with no visible label indicating it is metadata. A future enhancement could add a configurable title row or badge (e.g., "Skill Metadata").

---

## Documentation Plan

| Document | Section | Content |
|---|---|---|
| `docs/features/frontmatter-table.md` | Overview | What the feature does and when to use it |
| `docs/features/frontmatter-table.md` | Usage | Raw markdown source + rendered output example |
| `docs/features/frontmatter-table.md` | Value types | Table of supported YAML value types and how they render |
| `docs/features/frontmatter-table.md` | Configuration | Per-page and global config options with examples |
| `docs/features/frontmatter-table.md` | Limitations | Array, multi-doc, includes limitation, nested YAML |
| `docs/features/index.md` | Features list | Add frontmatter-table entry with brief description |

---

## Critique Matrix

The implementation was rubber-ducked with a technical critique sub-agent. The following table records each suggestion, whether it was adopted, and the reasoning.

| # | Suggestion | Severity | Adopted | Reasoning |
|---|---|---|---|---|
| 1 | Code fence detection: regex matches YAML inside fenced code, converting doc examples to tables | Critical | **Yes** | Replaced `gsub` regex approach with line-by-line stateful parser that tracks fence state |
| 2 | Regex block boundary: opening `---` not required to be preceded by blank line; Setext heading underlines can create false matches | Critical | **Yes** | Added `prev_blank` tracking in line-by-line parser; opening `---` only triggers collection when preceded by blank line or start-of-content |
| 3 | Use `Regexp.last_match(1)` instead of `$1` inside `gsub` block to avoid clobbering by internal regex | Important | **N/A** | Line-by-line parser eliminates `gsub` entirely; `$1` concern is moot |
| 4 | Psych 4 raises `DisallowedClass` on Date/Time fields; add `permitted_classes:` | Important | **Yes** | Added `permitted_classes: [Date, Time, Symbol]` and rescue of `Psych::DisallowedClass` |
| 5 | Document asymmetry between opening (`---\n`) and closing (`---[ \t]*\z`) delimiter patterns | Important | **Yes** | Documented in code comments and Edge Cases table; patterns use `OPEN_PATTERN` / `CLOSE_PATTERN` named constants |
| 6 | Multi-document YAML orphaned `---` becomes `<hr>` via Kramdown | Important | **Partial** | Documented in Limitations. Full fix would require detecting back-to-back YAML streams; too complex for initial scope |
| 7 | `false` serializes to empty string, indistinguishable from `nil` | Important | **Yes** | `false.to_s` → `"false"`, `true.to_s` → `"true"` handled by `else` branch; only `NilClass` special-cased to `""` |
| 8 | Array-of-objects YAML silently passes through, producing `<hr>` garbage | Important | **Partial** | Block passes through unchanged (no corruption); explicitly documented in Limitations. Full multi-row table support deferred to future work |
| 9 | `doc.content` can be nil; `.gsub` raises `NoMethodError` | Important | **Yes** | Added `next if doc.content.nil?` guard |
| 10 | `css_class` config value interpolated into HTML without escaping | Important | **Yes** | `CGI.escapeHTML` applied to `css_class` via `safe_class` local before interpolation |
| 11 | SCSS in `partials/` subdirectory that does not exist; import target is `_theme.scss`, not `style.scss` | Important | **Yes** | File placed at `drjekyll/assets/css/_frontmatter-table.scss`; imported in `_theme.scss` matching all existing partial conventions |
| 12 | `var(--bs-secondary-bg)` bypasses per-theme SCSS compilation; use `$theme-bootstrap-secondary-bg` | Minor | **Yes** | Updated SCSS to use `$theme-bootstrap-secondary-bg` and `$theme-bootstrap-body-color` SCSS variables |
| 13 | Missing `# frozen_string_literal: true` comment, inconsistent with other plugins | Minor | **Yes** | Added to top of plugin file |
| 14 | Replacement HTML needs `\n\n` wrapping to prevent Kramdown from wrapping `<div>` in `<p>` | Minor | **Yes** | Replacement string wrapped with `\n\n` before and after |
| 15 | Use named capture groups instead of `_match` + `$1` | Minor | **N/A** | Line-by-line parser eliminates the gsub/capture pattern entirely |
| 16 | No test step; plugin has significant branching logic | Minor | **Deferred** | Existing plugins have no tests; adding a test harness is out of scope for this feature but acknowledged as technical debt. Key test cases documented in the table above for manual verification |
