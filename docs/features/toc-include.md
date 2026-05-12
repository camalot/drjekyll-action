---
title: 📋 Table of Contents
nav_order: 3
layout: default
parent: ⭐ Features
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# 📋 Table of Contents
{: .no_toc }

Dr. Jekyll provides a convenient way to include a table of contents (TOC) in your documentation pages. By using the `{% include toc.md %}` tag, you can automatically generate a TOC based on the headings in your Markdown files. This makes it easy for readers to navigate through your documentation and find the information they need quickly.

## How to Include a TOC

To include a TOC in your page, simply add the following line where you want the TOC to appear:

```markdown
{% include toc.md %}
```

## How to Customize the TOC

In your `docs/` directory, you can create a `_includes/toc.md` file to customize the appearance and behavior of the TOC. For example, you can change the summary text or add custom styling. Here's an example of a custom `toc.md`:

```markdown
<!-- markdownlint-disable-next-line MD033 MD041 -->
<details open markdown="block">
  <!-- markdownlint-disable-next-line MD033 -->
  <summary>Table of Contents</summary>
  {: .text-delta }
1. TOC
{:toc}
</details>
```
