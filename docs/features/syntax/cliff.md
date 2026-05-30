---
title: 🪨 Cliff TOML
parent: 🙈 Syntax Highlighter
nav_order: 3
layout: default
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# 🪨 Cliff TOML
{: .no_toc }

Cliff TOML is the configuration format for [git-cliff](https://git-cliff.org/), a changelog generator. Dr. Jekyll includes a custom Rouge lexer that understands the full `cliff.toml` structure: TOML sections and key-value pairs, embedded [Tera](tera.md) templates in triple-quoted strings, regex patterns, and capture-group replacement syntax.

{% include toc.md %}

---

## How to Use

Use the `cliff` language tag on a fenced code block:

{% highlight markdown %}

```cliff
[changelog]
header = """
# Changelog
"""
```

{% endhighlight %}

The alias `cliff-toml` is also accepted.

---

## Section Headers

Sections use TOML's `[table]` and `[[array-of-tables]]` syntax and are highlighted as named anchors:

{% highlight markdown %}

```cliff
[changelog]

[[git.commit_parsers]]
```

{% endhighlight %}

```cliff
[changelog]

[[git.commit_parsers]]
```

---

## Key-Value Pairs

Keys and the `=` separator are highlighted as property names. String, number, and boolean values each receive distinct token types:

{% highlight markdown %}

```cliff
[git]
conventional_commits = true
filter_unconventional = true
split_commits = false
topo_order = false
sort_commits = "oldest"
tag_pattern = "v[0-9]*"
skip_tags = "v0.1.0-beta.1"
ignore_tags = ""
```

{% endhighlight %}

```cliff
[git]
conventional_commits = true
filter_unconventional = true
split_commits = false
topo_order = false
sort_commits = "oldest"
tag_pattern = "v[0-9]*"
skip_tags = "v0.1.0-beta.1"
ignore_tags = ""
```

---

## Tera Template Strings

Any triple-quoted string value (`"""..."""`) is treated as an embedded [Tera](tera.md) template. Keywords, filters, variables, and delimiters are all highlighted within the template body:

{% highlight markdown %}

```cliff
[changelog]
body = """
{% if version %}
## [{{ version | trim_start_matches(pat="v") }}] - {{ timestamp | date(format="%Y-%m-%d") }}
{% else %}
## [unreleased]
{% endif %}
{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | striptags | trim | upper_first }}
{% for commit in commits %}
- {% if commit.scope %}*({{ commit.scope }})* {% endif %}\
{{ commit.message | upper_first }}
{% endfor %}
{% endfor %}
"""
```

{% endhighlight %}

```cliff
[changelog]
body = """
{% if version %}
## [{{ version | trim_start_matches(pat="v") }}] - {{ timestamp | date(format="%Y-%m-%d") }}
{% else %}
## [unreleased]
{% endif %}
{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | striptags | trim | upper_first }}
{% for commit in commits %}
- {% if commit.scope %}*({{ commit.scope }})* {% endif %}\
{{ commit.message | upper_first }}
{% endfor %}
{% endfor %}
"""
```

---

## Regex Fields

The keys `pattern`, `message`, `body`, `footer`, and `tag_pattern` receive regex highlighting — metacharacters (`( ) { } [ ] | ^ $ . * + ?`) are styled distinctly from literal text:

{% highlight markdown %}

```cliff
[git]
tag_pattern = "v[0-9]*"

[[git.commit_parsers]]
message = "^feat"
group = "Features"

[[git.commit_parsers]]
message = "^fix"
group = "Bug Fixes"
```

{% endhighlight %}

```cliff
[git]
tag_pattern = "v[0-9]*"

[[git.commit_parsers]]
message = "^feat"
group = "Features"

[[git.commit_parsers]]
message = "^fix"
group = "Bug Fixes"
```

---

## Replace Fields

The keys `replace` and `href` support capture-group back-references (`$1`, `${2}`), which are highlighted as variables. These fields commonly appear inside inline-table arrays:

{% highlight markdown %}

```cliff
[changelog]
postprocessors = [
  { pattern = '<REMOTE_URL>', replace = "https://github.com" },
  { pattern = '#\d+', replace = '' },
  { pattern = '!#!(\d+)', replace = '#$1' },
]

[git]
link_parsers = [
  { pattern = '#(\d+)', text = '!#!$1', href = "<REPO>/issues/$1" },
  { pattern = 'RFC\(?(\d+)\)?', text = "ietf-rfc$1", href = "https://datatracker.ietf.org/doc/html/rfc$1" },
]
```

{% endhighlight %}

```cliff
[changelog]
postprocessors = [
  { pattern = '<REMOTE_URL>', replace = "https://github.com" },
  { pattern = '#\d+', replace = '' },
  { pattern = '!#!(\d+)', replace = '#$1' },
]

[git]
link_parsers = [
  { pattern = '#(\d+)', text = '!#!$1', href = "<REPO>/issues/$1" },
  { pattern = 'RFC\(?(\d+)\)?', text = "ietf-rfc$1", href = "https://datatracker.ietf.org/doc/html/rfc$1" },
]
```

---

## Full Example

{% highlight markdown %}

```cliff
# git-cliff configuration

[remote.github]
owner = "owner"
repo = "repo"

[changelog]
body = """
{#- MACROS -#}
{%- macro remote_url() -%}
  {{ "<REMOTE_URL>/" ~ remote.github.owner ~ "/" ~ remote.github.repo -}}
{%- endmacro -%}
{#- MACROS END -#}

{%- if version %}
## [{{ version | trim_start_matches(pat="v") }}] - {{ timestamp | date(format="%Y-%m-%d") }}
{%- else %}
## [unreleased]
{%- endif %}

{%- for group, commits in commits | group_by(attribute="group") %}
### {{ group | striptags | trim | upper_first }}
{%- for commit in commits %}
- {% if commit.scope %}*({{ commit.scope }})* {% endif %}\
  {{ commit.message | upper_first }}
{%- endfor %}
{%- endfor %}
"""
trim = true

postprocessors = [
  { pattern = '<REMOTE_URL>', replace = "https://github.com" },
  { pattern = '#\d+', replace = '' },
  { pattern = '!#!(\d+)', replace = '#$1' },
]

[git]
conventional_commits = true
filter_unconventional = true
split_commits = true
protect_breaking_commits = false
filter_commits = false
topo_order = false
sort_commits = "oldest"
tag_pattern = "v[0-9]+\\.[0-9]+\\.[0-9]+$"

commit_parsers = [
  { message = '(?i)^.*!:', group = "💥 Breaking Change" },
  { message = '(?i)^feat', group = "🚀 Features" },
  { message = '(?i)^fix', group = "🐛 Bug Fixes" },
  { message = '(?i)^docs?', group = "📚 Documentation" },
  { message = '(?i)^chore\(release\): prepare for', skip = true },
  { body = '(?i).*security', group = "🛡️ Security" },
]

commit_preprocessors = [
  { pattern = '(?m)^\s*[\*-]\s*', replace = "" },
]

link_parsers = [
  { pattern = '#(\d+)', text = '!#!$1', href = "<REPO>/issues/$1" },
]
```

{% endhighlight %}

```cliff
# git-cliff configuration

[remote.github]
owner = "owner"
repo = "repo"

[changelog]
body = """
{#- MACROS -#}
{%- macro remote_url() -%}
  {{ "<REMOTE_URL>/" ~ remote.github.owner ~ "/" ~ remote.github.repo -}}
{%- endmacro -%}
{#- MACROS END -#}

{%- if version %}
## [{{ version | trim_start_matches(pat="v") }}] - {{ timestamp | date(format="%Y-%m-%d") }}
{%- else %}
## [unreleased]
{%- endif %}

{%- for group, commits in commits | group_by(attribute="group") %}
### {{ group | striptags | trim | upper_first }}
{%- for commit in commits %}
- {% if commit.scope %}*({{ commit.scope }})* {% endif %}\
  {{ commit.message | upper_first }}
{%- endfor %}
{%- endfor %}
"""
trim = true

postprocessors = [
  { pattern = '<REMOTE_URL>', replace = "https://github.com" },
  { pattern = '#\d+', replace = '' },
  { pattern = '!#!(\d+)', replace = '#$1' },
]

[git]
conventional_commits = true
filter_unconventional = true
split_commits = true
protect_breaking_commits = false
filter_commits = false
topo_order = false
sort_commits = "oldest"
tag_pattern = "v[0-9]+\\.[0-9]+\\.[0-9]+$"

commit_parsers = [
  { message = '(?i)^.*!:', group = "💥 Breaking Change" },
  { message = '(?i)^feat', group = "🚀 Features" },
  { message = '(?i)^fix', group = "🐛 Bug Fixes" },
  { message = '(?i)^docs?', group = "📚 Documentation" },
  { message = '(?i)^chore\(release\): prepare for', skip = true },
  { body = '(?i).*security', group = "🛡️ Security" },
]

commit_preprocessors = [
  { pattern = '(?m)^\s*[\*-]\s*', replace = "" },
]

link_parsers = [
  { pattern = '#(\d+)', text = '!#!$1', href = "<REPO>/issues/$1" },
]
```

---

## References

- [git-cliff Documentation](https://git-cliff.org/docs/)
- [git-cliff Configuration Reference](https://git-cliff.org/docs/configuration)
- [Tera Syntax Highlighting](tera.md)
