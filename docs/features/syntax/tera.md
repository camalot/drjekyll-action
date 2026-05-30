---
title: 🧱 Tera Templates
parent: 🙈 Syntax Highlighter
nav_order: 4
layout: default
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# 🧱 Tera Templates
{: .no_toc }

[Tera](https://keats.github.io/tera/) is a template engine for Rust, inspired by Jinja2 and Django templates. Dr. Jekyll includes a custom Rouge lexer that highlights Tera's expression blocks (`{{ }}`), statement tags (`{% %}`), and comment blocks (`{# #}`), while treating surrounding content as plain text.

> {: .note }
> Tera syntax is also highlighted automatically inside triple-quoted (`"""`) values in [Cliff TOML](cliff.md) files.

{% include toc.md %}

---

## How to Use

Use the `tera` language tag on a fenced code block:

{% highlight markdown %}

```tera
{{ page.title }}
```

{% endhighlight %}

---

## Expression Blocks

Expression blocks evaluate a variable or expression and output the result. Use `{{` and `}}` as delimiters; the whitespace-stripping variants `{{-` and `-}}` trim surrounding whitespace:

{% highlight markdown %}

```tera
{{ user.name }}
{{ version | trim_start_matches(pat="v") }}
{{- timestamp | date(format="%Y-%m-%d") -}}
{{ "<REMOTE_URL>/" ~ remote.github.owner ~ "/" ~ remote.github.repo -}}
```

{% endhighlight %}

```tera
{{ user.name }}
{{ version | trim_start_matches(pat="v") }}
{{- timestamp | date(format="%Y-%m-%d") -}}
{{ "<REMOTE_URL>/" ~ remote.github.owner ~ "/" ~ remote.github.repo -}}
```

The `~` operator concatenates strings.

---

## Statement Tags

Statement tags control template logic. Use `{%` and `%}` as delimiters:

### Conditionals

{% highlight markdown %}

```tera
{% if user.is_admin %}
  <p>Welcome, admin.</p>
{% elif user.is_logged_in %}
  <p>Welcome, {{ user.name }}.</p>
{% else %}
  <p>Please log in.</p>
{% endif %}
```

{% endhighlight %}

```tera
{% if user.is_admin %}
  <p>Welcome, admin.</p>
{% elif user.is_logged_in %}
  <p>Welcome, {{ user.name }}.</p>
{% else %}
  <p>Please log in.</p>
{% endif %}
```

### Loops

{% highlight markdown %}

```tera
{% for commit in commits %}
- {{ commit.message | upper_first }}
{% endfor %}
```

{% endhighlight %}

```tera
{% for commit in commits %}
- {{ commit.message | upper_first }}
{% endfor %}
```

### Variable Assignment

{% highlight markdown %}

```tera
{% set greeting = "Hello, " ~ user.name ~ "!" %}
{{ greeting }}

{% set_global counter = 0 %}
```

{% endhighlight %}

```tera
{% set greeting = "Hello, " ~ user.name ~ "!" %}
{{ greeting }}

{% set_global counter = 0 %}
```

### Template Inheritance

{% highlight markdown %}

```tera
{% extends "base.html" %}

{% block content %}
  <h1>{{ page.title }}</h1>
  {{ super() }}
{% endblock content %}
```

{% endhighlight %}

```tera
{% extends "base.html" %}

{% block content %}
  <h1>{{ page.title }}</h1>
  {{ super() }}
{% endblock content %}
```

---

## Comment Blocks

Comment blocks are not rendered in the output. Use `{#` and `#}` as delimiters:

{% highlight markdown %}

```tera
{# This is a comment and will not appear in the rendered output #}
{#- Whitespace-stripping comment -#}
```

{% endhighlight %}

```tera
{# This is a comment and will not appear in the rendered output #}
{#- Whitespace-stripping comment -#}
```

---

## Filters

Filters transform a value using the pipe `|` operator. Chaining is supported:

{% highlight markdown %}

```tera
{{ commits | group_by(attribute="group") }}
{{ message | striptags | trim | upper_first }}
{{ body | truncate(length=200) }}
{{ items | sort | first }}
{{ count | round(method="ceil", precision=2) }}
{{ r.contributors | filter(attribute="is_first_time", value=true) }}
{{ input | trim_start_matches(pat='"') | trim_end_matches(pat='"') }}
```

{% endhighlight %}

```tera
{{ commits | group_by(attribute="group") }}
{{ message | striptags | trim | upper_first }}
{{ body | truncate(length=200) }}
{{ items | sort | first }}
{{ count | round(method="ceil", precision=2) }}
{{ r.contributors | filter(attribute="is_first_time", value=true) }}
{{ input | trim_start_matches(pat='"') | trim_end_matches(pat='"') }}
```

> {: .note }
> `filter` is also a block-level statement tag (`{% filter lower %}...{% endfilter %}`). When used after a pipe `|` it acts as a collection filter; the lexer highlights it as a control keyword in both cases.

---

## Macros

Macros are reusable template fragments. `self::macro_name()` calls a macro defined in the same template:

{% highlight markdown %}

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

{% endhighlight %}

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

---

## Built-in Functions and Tests

{% highlight markdown %}

```tera
{% set nums = range(end=5) %}
{% set ts = now(timestamp=true) %}

{% if value is defined %}{{ value }}{% endif %}
{% if count is odd %}odd{% endif %}
{% if name is starting_with("v") %}versioned{% endif %}
```

{% endhighlight %}

```tera
{% set nums = range(end=5) %}
{% set ts = now(timestamp=true) %}

{% if value is defined %}{{ value }}{% endif %}
{% if count is odd %}odd{% endif %}
{% if name is starting_with("v") %}versioned{% endif %}
```

---

## Full Example

{% highlight markdown %}

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

{% endhighlight %}

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

---

## References

- [Tera Documentation](https://keats.github.io/tera/docs/)
- [Tera Template Syntax](https://keats.github.io/tera/docs/#templates)
- [Cliff TOML Syntax Highlighting](cliff.md)
