---
title: Writing a static site generator in Go
date: 2024-08-11
tags: [go, ssg]
---

[kite](https://github.com/HimanshuSardana/kite) is my minimal, blazingly fast SSG: Markdown in, HTML out. No JS bundler, no 900 deps. (And yes — this very site is built with it.)

## Design

- Frontmatter + Markdown rendered through `html/template`
- Single binary: `kite build` and `kite serve` (with live reload)
- Themeable via plain HTML templates — no new templating language to learn

```sh
$ kite build
Compiling Writing a static site generator in Go (2ms)
All files processed!
Home page written to output/index.html
```

It also powers [bonsai](https://github.com/HimanshuSardana/bonsai), my minimal git frontend.
