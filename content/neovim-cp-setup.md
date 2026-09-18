---
title: My Neovim setup for competitive programming
date: 2024-11-20
tags: [neovim, cp]
---

Two configs: a daily driver ([nvim-config](https://github.com/HimanshuSardana/nvim-config)) and a lean CP one ([nvim-cp-config](https://github.com/HimanshuSardana/nvim-cp-config)). Plus [cpos](https://github.com/HimanshuSardana/cpos) to pull Codeforces/CSES problems and run tests without leaving the editor.

## The loop

- `CposFetch <url>` — scaffolds solution + samples
- One key to compile, run all samples, diff output
- Snippets for DSU, segtree, modint

## Tips

- Keep the CP config plugin-free-ish: startup time matters mid-contest.
- Template with fast I/O baked in.
- Separate leader keys for test vs submit.
