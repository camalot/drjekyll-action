---
layout: default
title: 🪐 Jupyter Notebook Test
nav_order: 99
---

<!-- markdownlint-disable-next-line MD025 MD022 -->
# Jupyter Notebook

Jupyter Notebooks can be included in your Dr. Jekyll docs in two ways: as a file or inline. The file method allows you to include an entire notebook from your docs directory, while the inline method lets you embed notebook content directly within your markdown files.

## FILE

``` liquid
{% raw %}{% ipynb_file /path/to/notebook.ipynb %}{% rawend %}
```

{% ipynb_file /assets/notebooks/test.ipynb %}

## INLINE

``` liquid
{% raw %}{% ipynb %}
{
  "cells": [
    {
      "cell_type": "markdown",
      "metadata": {},
      "source": [
        "# This is a markdown cell\n",
        "\n",
        "You can write **markdown** content here."
      ]
    },
    {
      "cell_type": "code",
      "execution_count": null,
      "metadata": {},
      "outputs": [],
      "source": [
        "# This is a code cell\n",
        "\n",
        "print('Hello, Dr. Jekyll!')"
      ]
    }
  ],
  "metadata": {
    "language_info": {
      "name": "python"
    }
  },
  "nbformat": 4,
  "nbformat_minor": 5
}
{% endipynb %}{% rawend %}
```

{% ipynb %}
{
 "cells": [
  {
   "cell_type": "markdown",
   "id": "8eb721cd",
   "metadata": {},
   "source": [
    "# TEST MARKDOWN\n",
    "\n",
    "This is a test markdown file to demonstrate the recent edits made to the project. The edits include changes to the configuration file and the head custom HTML file."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "6173648f",
   "metadata": {
    "vscode": {
     "languageId": "shellscript"
    }
   },
   "outputs": [],
   "source": [
    "#!/usr/bin/env bash\n",
    "\n",
    "set -u\n",
    "\n",
    "echo \"Running tests for drjekyll-action...\""
   ]
  }
 ],
 "metadata": {
  "language_info": {
   "name": "python"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}

{% endipynb %}
