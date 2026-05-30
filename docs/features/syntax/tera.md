---
title: 🧱 Tera Templates
parent: 🙈 Syntax Highlighter
nav_order: 4
layout: default
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# 🧱 Tera Templates
{: .no_toc }

[Tera](https://keats.github.io/tera/) is a template engine for Rust, inspired by Jinja2 and Django templates. Dr. Jekyll includes a custom Rouge lexer that highlights Tera's expression blocks (`{% raw %}{{ }}{% endraw %}`), statement tags (`{% raw %}{% %}{% endraw %}`), and comment blocks (`{% raw %}{# #}{% endraw %}`), while treating surrounding content as plain text.

> {: .note }
> Tera syntax is also highlighted automatically inside triple-quoted (`"""`) values in [Cliff TOML](cliff.md) files.

{% include toc.md %}

---

## How to Use

Use the `tera` language tag on a fenced code block:

{% highlight markdown %}
{% raw %}

```tera
{{ page.title }}
```

{% endraw %}
{% endhighlight %}

---

## Expression Blocks

Expression blocks evaluate a variable or expression and output the result. Use `{{` and `}}` as delimiters; the whitespace-stripping variants `{{-` and `-}}` trim surrounding whitespace:

{% highlight markdown %}
{% raw %}

```tera
{{ user.name }}
{{ version | trim_start_matches(pat="v") }}
{{- timestamp | date(format="%Y-%m-%d") -}}
{{ "<REMOTE_URL>/" ~ remote.github.owner ~ "/" ~ remote.github.repo -}}
```

{% endraw %}
{% endhighlight %}

```tera
{% raw %}
{{ user.name }}
{{ version | trim_start_matches(pat="v") }}
{{- timestamp | date(format="%Y-%m-%d") -}}
{{ "<REMOTE_URL>/" ~ remote.github.owner ~ "/" ~ remote.github.repo -}}
{% endraw %}
```

The `~` operator concatenates strings.

---

## Statement Tags

Statement tags control template logic. Use `{% raw %}{%{% endraw %}` and `{% raw %}%}{% endraw %}` as delimiters:

### Conditionals

{% highlight markdown %}
{% raw %}

```tera
{% if user.is_admin %}
  <p>Welcome, admin.</p>
{% elif user.is_logged_in %}
  <p>Welcome, {{ user.name }}.</p>
{% else %}
  <p>Please log in.</p>
{% endif %}
```

{% endraw %}
{% endhighlight %}

```tera
{% raw %}
{% if user.is_admin %}
  <p>Welcome, admin.</p>
{% elif user.is_logged_in %}
  <p>Welcome, {{ user.name }}.</p>
{% else %}
  <p>Please log in.</p>
{% endif %}
{% endraw %}
```

### Loops

{% highlight markdown %}
{% raw %}

```tera
{% for commit in commits %}
- {{ commit.message | upper_first }}
{% endfor %}
```

{% endraw %}
{% endhighlight %}

```tera
{% raw %}
{% for commit in commits %}
- {{ commit.message | upper_first }}
{% endfor %}
{% endraw %}
```

### Variable Assignment

{% highlight markdown %}
{% raw %}

```tera
{% set greeting = "Hello, " ~ user.name ~ "!" %}
{{ greeting }}

{% set_global counter = 0 %}
```

{% endraw %}
{% endhighlight %}

```tera
{% raw %}
{% set greeting = "Hello, " ~ user.name ~ "!" %}
{{ greeting }}

{% set_global counter = 0 %}
{% endraw %}
```

### Template Inheritance

{% highlight markdown %}
{% raw %}

```tera
{% extends "base.html" %}

{% block content %}
  <h1>{{ page.title }}</h1>
  {{ super() }}
{% endblock content %}
```

{% endraw %}
{% endhighlight %}

```tera
{% raw %}
{% extends "base.html" %}

{% block content %}
  <h1>{{ page.title }}</h1>
  {{ super() }}
{% endblock content %}
{% endraw %}
```

---

## Comment Blocks

Comment blocks are not rendered in the output. Use `{#` and `#}` as delimiters:

{% highlight markdown %}
{% raw %}

```tera
{# This is a comment and will not appear in the rendered output #}
{#- Whitespace-stripping comment -#}
```

{% endraw %}
{% endhighlight %}

```tera
{% raw %}
{# This is a comment and will not appear in the rendered output #}
{#- Whitespace-stripping comment -#}
{% endraw %}
```

---

## Filters

Filters transform a value using the pipe `|` operator. Chaining is supported:

{% highlight markdown %}
{% raw %}

```tera
{{ commits | group_by(attribute="group") }}
{{ message | striptags | trim | upper_first }}
{{ body | truncate(length=200) }}
{{ items | sort | first }}
{{ count | round(method="ceil", precision=2) }}
{{ r.contributors | filter(attribute="is_first_time", value=true) }}
{{ input | trim_start_matches(pat='"') | trim_end_matches(pat='"') }}
```

{% endraw %}
{% endhighlight %}

```tera
{% raw %}
{{ commits | group_by(attribute="group") }}
{{ message | striptags | trim | upper_first }}
{{ body | truncate(length=200) }}
{{ items | sort | first }}
{{ count | round(method="ceil", precision=2) }}
{{ r.contributors | filter(attribute="is_first_time", value=true) }}
{{ input | trim_start_matches(pat='"') | trim_end_matches(pat='"') }}
{% endraw %}
```

> {: .note }
> `filter` is also a block-level statement tag (`{% raw %}{% filter lower %}...{% endfilter %}{% endraw %}`). When used after a pipe `|` it acts as a collection filter; the lexer highlights it as a control keyword in both cases.

---

## Macros

Macros are reusable template fragments. `self::macro_name()` calls a macro defined in the same template:

{% highlight markdown %}
{% raw %}

```tera
{%- macro user_url(name) -%}
  [@{{ name | lower }}](https://github.com/{{ name | lower }})
{%- endmacro -%}

{%- macro plural(count, singular, plural) -%}
  {%- if count == 1 -%}{{ singular }}{%- else -%}{{ plural }}{%- endif -%}
{%- endmacro -%}

{{ self::user_url(name=commit.remote.username) }}
{{ self::plural(count=s_commit_count, singular="commit", plural="commits") }}
```

{% endraw %}
{% endhighlight %}

```tera
{% raw %}
{%- macro user_url(name) -%}
  [@{{ name | lower }}](https://github.com/{{ name | lower }})
{%- endmacro -%}

{%- macro plural(count, singular, plural) -%}
  {%- if count == 1 -%}{{ singular }}{%- else -%}{{ plural }}{%- endif -%}
{%- endmacro -%}

{{ self::user_url(name=commit.remote.username) }}
{{ self::plural(count=s_commit_count, singular="commit", plural="commits") }}
{% endraw %}
```

---

## Built-in Functions and Tests

{% highlight markdown %}
{% raw %}

```tera
{% set nums = range(end=5) %}
{% set ts = now(timestamp=true) %}

{% if value is defined %}{{ value }}{% endif %}
{% if count is odd %}odd{% endif %}
{% if name is starting_with("v") %}versioned{% endif %}
```

{% endraw %}
{% endhighlight %}

```tera
{% raw %}
{% set nums = range(end=5) %}
{% set ts = now(timestamp=true) %}

{% if value is defined %}{{ value }}{% endif %}
{% if count is odd %}odd{% endif %}
{% if name is starting_with("v") %}versioned{% endif %}
{% endraw %}
```

---

## Full Example

{% highlight markdown %}
{% raw %}

```tera
{# Changelog body template for git-cliff #}
{% if version %}
## [{{ version | trim_start_matches(pat="v") }}] - {{ timestamp | date(format="%Y-%m-%d") }}
{% else %}
## [unreleased]
{% endif %}

{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | striptags | trim | upper_first }}

{% for commit in commits %}
- {% if commit.scope %}*({{ commit.scope }})* {% endif %}\
  {% if commit.breaking %}[**breaking**] {% endif %}\
  {{ commit.message | upper_first }} — \
  [{{ commit.id | truncate(length=7, end="") }}]({{ commit.remote.link }})
{% endfor %}
{% endfor %}
```

{% endraw %}
{% endhighlight %}

```tera
{% raw %}
{# Changelog body template for git-cliff #}
{% if version %}
## [{{ version | trim_start_matches(pat="v") }}] - {{ timestamp | date(format="%Y-%m-%d") }}
{% else %}
## [unreleased]
{% endif %}

{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | striptags | trim | upper_first }}

{% for commit in commits %}
- {% if commit.scope %}*({{ commit.scope }})* {% endif %}\
  {% if commit.breaking %}[**breaking**] {% endif %}\
  {{ commit.message | upper_first }} — \
  [{{ commit.id | truncate(length=7, end="") }}]({{ commit.remote.link }})
{% endfor %}
{% endfor %}
{% endraw %}
```

---

## References

- [Tera Documentation](https://keats.github.io/tera/docs/)
- [Tera Template Syntax](https://keats.github.io/tera/docs/#templates)
- [Cliff TOML Syntax Highlighting](cliff.md)
