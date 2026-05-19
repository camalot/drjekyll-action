---
title: ⚠️ GitHub Alerts
nav_order: 4
layout: default
parent: ⭐ Features
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# ⚠️ GitHub Alerts
{: .no_toc }

Dr. Jekyll supports GitHub-style alert blocks, which allow you to create visually distinct sections in your documentation to highlight important information, tips, warnings, and more. These alert blocks are rendered with specific styles that make them stand out, helping users quickly identify critical content. For more information, you can see the [GitHub Admonitions documentation](https://github.com/Helveg/jekyll-gfm-admonitions#readme) for details on how to use and customize these alerts in your Dr. Jekyll documentation.

{% include toc.md %}

---

## Supported Alert Types

| Type | Markdown |
| --- | --- |
| NOTE | `> [!NOTE]` |
| TIP | `> [!TIP]` |
| IMPORTANT | `> [!IMPORTANT]` |
| WARNING | `> [!WARNING]` |
| CAUTION | `> [!CAUTION]` |

## Usage

``` markdown
> [!NOTE]
> Highlights information that users should take into account, even when skimming.
> And supports multi-line text.

> [!TIP]
> Optional information to help a user be more successful.

> [!IMPORTANT]
> Crucial information necessary for users to succeed.

> [!WARNING]
> Critical content demanding immediate user attention due to potential risks.

> [!CAUTION]
> Negative potential consequences of an action.
```

> [!NOTE]
> Highlights information that users should take into account, even when skimming.
> And supports multi-line text.

> [!TIP]
> Optional information to help a user be more successful.

> [!IMPORTANT]
> Crucial information necessary for users to succeed.

> [!WARNING]
> Critical content demanding immediate user attention due to potential risks.

> [!CAUTION]
> Negative potential consequences of an action.
