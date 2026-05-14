---
title: Sequence Diagram
parent: Mermaid Diagrams
nav_order: 14
layout: default
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# [Sequence Diagram](https://mermaid.ai/open-source/syntax/sequenceDiagram.html)

{% highlight markdown %}

```mermaid
sequenceDiagram
Alice->>John: Hello John, how are you?
loop HealthCheck
    John->>John: Fight against hypochondria
end
Note right of John: Rational thoughts!
John-->>Alice: Great!
John->>Bob: How about you?
Bob-->>John: Jolly good!
```

{% endhighlight %}

```mermaid
sequenceDiagram
Alice->>John: Hello John, how are you?
loop HealthCheck
    John->>John: Fight against hypochondria
end
Note right of John: Rational thoughts!
John-->>Alice: Great!
John->>Bob: How about you?
Bob-->>John: Jolly good!
```
