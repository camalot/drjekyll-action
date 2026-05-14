---
title: Mermaid Diagrams
parent: 💹 Diagrams
nav_order: 1
layout: default
---

[Mermaid](https://mermaid.ai/open-source/intro/) is a JavaScript-based diagramming and charting tool that allows you to create diagrams using a simple markdown-like syntax. It supports various types of diagrams, including flowcharts, sequence diagrams, class diagrams, state diagrams, and more.

To use Mermaid in Dr. Jekyll, you can include your Mermaid code within a code block and specify `mermaid` as the language:

## Example Mermaid Diagram

{% include mermaid/graph.md %}

---

{% include mermaid/sequenceDiagram.md %}

---

{% include mermaid/flowchart.md %}

---

{% include mermaid/gantt.md %}

---

{% include mermaid/classDiagram.md %}

---

{% include mermaid/stateDiagram.md %}

---

{% include mermaid/entityRelationship.md %}
