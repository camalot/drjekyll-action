---
title: State Diagram
parent: Mermaid Diagrams
nav_order: 15
layout: default
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# [State Diagram](https://mermaid.ai/open-source/syntax/stateDiagram.html)

{% highlight markdown %}

```mermaid

stateDiagram-v2
    [*] --> Still
    Still --> [*]

    Still --> Moving
    Moving --> Still
    Moving --> Crash
    Crash --> [*]
```

{% endhighlight %}

```mermaid
stateDiagram-v2
    [*] --> Still
    Still --> [*]

    Still --> Moving
    Moving --> Still
    Moving --> Crash
    Crash --> [*]
```

---

{% highlight markdown %}

```mermaid

stateDiagram
    [*] --> Still
    Still --> [*]

    Still --> Moving
    Moving --> Still
    Moving --> Crash
    Crash --> [*]
```

{% endhighlight %}

```mermaid
stateDiagram
    [*] --> Still
    Still --> [*]

    Still --> Moving
    Moving --> Still
    Moving --> Crash
    Crash --> [*]
```
