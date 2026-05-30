---
title: 🙈 Syntax Highlighter
parent: ⭐ Features
nav_order: 1
layout: default
has_children: true
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# 🙈 Syntax Highlighter
{: .no_toc }

[Rouge](http://rouge.jneen.net/) is a pure Ruby syntax highlighter. It can highlight [over 200 different languages](https://rouge-ruby.github.io/docs/file.Languages.html), and output HTML or ANSI 256-color text. Its HTML output is compatible with stylesheets designed for [Pygments](http://pygments.org/).

{% include toc.md %}

---

Dr. Jekyll uses Rouge for syntax highlighting in code blocks and inline code. Include the language after the opening backticks to enable syntax highlighting:

{% highlight markdown %}

```ruby
def hello_world
  puts "Hello, world!"
end
```

{% endhighlight %}

This will render as:

```ruby
def hello_world
  puts "Hello, world!"
end
```

You can also use `liquid` for syntax highlighting in Jekyll templates:

```liquid
{% raw %}
{% highlight liquid %}
  {% assign name = "Dr. Jekyll" %}
  Hello, {{ name }}!
{% endhighlight %}
{% endraw %}
```

This will render as:

```liquid
{% raw %}
{% assign name = "Dr. Jekyll" %}
Hello, {{ name }}!
{% endraw %}
```

---

Dr. Jekyll's extended language support includes:

- [Jupyter Notebooks](ipynb.md)
<!-- - [Mermaid Diagrams](mermaid.md)
- [PlantUML Diagrams](plantuml.md) -->
- [YAML Front Matter](frontmatter/index.md)
- [Tree View](treeview.md)
- [Cliff TOML](cliff.md)
- [Tera Templates](tera.md)
