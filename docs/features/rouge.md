---
title: 🙈 Syntax Highlighter
parent: ⭐ Features
nav_order: 1
layout: default
has_children: true
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# 🙈 Syntax Highlighter

[Rouge](http://rouge.jneen.net/) is a pure Ruby syntax highlighter. It can highlight [over 200 different languages](https://rouge-ruby.github.io/docs/file.Languages.html), and output HTML or ANSI 256-color text. Its HTML output is compatible with stylesheets designed for [Pygments](http://pygments.org/).

Dr. Jekyll uses Rouge for syntax highlighting in code blocks and inline code. Include the language after the opening backticks to enable syntax highlighting:

```markdown
\`\`\`ruby
def hello_world
  puts "Hello, world!"
end
\`\`\`
```

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
{% assign name = "Dr. Jekyll" %}
Hello, {{ name }}!
```

---

Dr. Jekyll's extended language support includes:

- [Jupyter Notebooks](ipynb.md)
<!-- - [Mermaid Diagrams](mermaid.md)
- [PlantUML Diagrams](plantuml.md) -->
- [TaskIgnore](taskignore.md)
<!-- - [YAML Front Matter](yaml.md) -->
- [Tree View](treeview.md)
