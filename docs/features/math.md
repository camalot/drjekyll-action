---
title: 🧮 Math
parent: ⭐ Features
nav_order: 4
layout: default
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# 🧮 Math

Dr. Jekyll supports rendering mathematical expressions using [KaTeX](https://katex.org/) syntax. You can include inline math by wrapping your [KaTeX](https://katex.org/) code in single dollar signs (`$...$`) or display math by using double dollar signs (`$$...$$`).

---

$$\text{EMA}_t = 0.3 \cdot x_t + 0.7 \cdot \text{EMA}_{t-1}$$

---

$$\displaystyle \frac{1}{\Bigl(\sqrt{\phi \sqrt{5}}-\phi\Bigr) e^{\frac25 \pi}} = 1+\frac{e^{-2\pi}} {1+\frac{e^{-4\pi}} {1+\frac{e^{-6\pi}} {1+\frac{e^{-8\pi}} {1+\cdots} } } }$
        $$\displaystyle \left( \sum_{k=1}^n a_k b_k \right)^2 \leq \left( \sum_{k=1}^n a_k^2 \right) \left( \sum_{k=1}^n b_k^2 \right)$$
        $$\displaystyle {1 +  \frac{q^2}{(1-q)}+\frac{q^6}{(1-q)(1-q^2)}+\cdots }= \prod_{j=0}^{\infty}\frac{1}{(1-q^{5j+2})(1-q^{5j+3})}, \quad\quad \text{for }\lvert q\rvert<1.$$

---

## References

- [KaTeX Supported Functions](https://katex.org/docs/supported)
- [KaTeX Support Table](https://katex.org/docs/support_table)
