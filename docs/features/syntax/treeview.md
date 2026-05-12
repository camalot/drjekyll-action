---
title: 🌳 Tree View
parent: 🙈 Syntax Highlighter
nav_order: 2
layout: default
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# 🌳 Tree View
{: .no_toc }

Tree View is a syntax highlighting feature in Dr. Jekyll that allows you to display hierarchical data structures in a visually appealing way. It is particularly useful for representing file systems, organizational charts, or any data that can be represented as a tree.

{% include toc.md %}

---

## How to Use Tree View

To use Tree View in your documentation, you can create a code block with the language set to `tree`. Inside the code block, you can represent your hierarchical data using indentation and special characters to indicate branches and leaves. For example:

{% highlight markdown %}

```tree
.
├── src
│   ├── main.rb
│   └── utils.rb
├── README.md
└── LICENSE
```

{% endhighlight %}

``` tree
.
├── src
│   ├── main.rb
│   └── utils.rb
├── README.md
└── LICENSE

```

## Generating Tree View from the Command Line

You can also generate a Tree View from the command line using the `tree` command. This command is available on most Unix-like systems and can be installed on Windows using tools like Cygwin or WSL. To generate a Tree View of your project directory, simply run:

```bash
tree -L 2
```

> {: .note }
> See the [Tree Command Documentation](https://linux.dietrichrebholz.de/tree/) for more options and usage details.
>
> `man tree` or `tree --help` will also provide usage information in your terminal.
