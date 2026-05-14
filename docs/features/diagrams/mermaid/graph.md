---
title: Graph
parent: Mermaid Diagrams
nav_order: 7
layout: default
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# [Graph](https://mermaid.ai/open-source/syntax/graph.html)

{% highlight markdown %}

```mermaid
graph TD
    A[Start] --> B{Is it working?}
    B -- Yes --> C[Great!]
    B -- No --> D[Check the code]
    D --> B
```

{% endhighlight %}

```mermaid
graph TD
    A[Start] --> B{Is it working?}
    B -- Yes --> C[Great!]
    B -- No --> D[Check the code]
    D --> B
```
