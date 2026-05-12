---
title: Mermaid Diagrams
parent: 💹 Diagrams
nav_order: 1
layout: default
---

[Mermaid](https://mermaid.ai/open-source/intro/) is a JavaScript-based diagramming and charting tool that allows you to create diagrams using a simple markdown-like syntax. It supports various types of diagrams, including flowcharts, sequence diagrams, class diagrams, state diagrams, and more.

To use Mermaid in Dr. Jekyll, you can include your Mermaid code within a code block and specify `mermaid` as the language:

## Example Mermaid Diagram

### Graph

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

### Sequence diagram - [[docs](https://mermaid.js.org/syntax/sequenceDiagram.html)]

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

### Flowchart - [[docs](https://mermaid.js.org/syntax/flowchart.html)]

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

### Gantt chart - [[docs](https://mermaid.js.org/syntax/gantt.html)]

{% highlight markdown %}

```mermaid
gantt
    section Section
    Completed :done,    des1, 2014-01-06,2014-01-08
    Active        :active,  des2, 2014-01-07, 3d
    Parallel 1   :         des3, after des1, 1d
    Parallel 2   :         des4, after des1, 1d
    Parallel 3   :         des5, after des3, 1d
    Parallel 4   :         des6, after des4, 1d
```

{% endhighlight %}

```mermaid
gantt
    section Section
    Completed :done,    des1, 2014-01-06,2014-01-08
    Active        :active,  des2, 2014-01-07, 3d
    Parallel 1   :         des3, after des1, 1d
    Parallel 2   :         des4, after des1, 1d
    Parallel 3   :         des5, after des3, 1d
    Parallel 4   :         des6, after des4, 1d
```
