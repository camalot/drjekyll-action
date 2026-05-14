---
title: Flowchart
parent: Mermaid Diagrams
nav_order: 4
layout: default
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# [Flowchart](https://mermaid.ai/open-source/syntax/flowchart.html)

{% highlight markdown %}

```mermaid
flowchart LR

A[Hard] -->|Text| B(Round)
B --> C{Decision}
C -->|One| D[Result 1]
C -->|Two| E[Result 2]
```

{% endhighlight %}

```mermaid
flowchart LR
A[Hard] -->|Text| B(Round)
B --> C{Decision}
C -->|One| D[Result 1]
C -->|Two| E[Result 2]
```
