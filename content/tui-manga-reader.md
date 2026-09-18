---
title: Why I built a manga reader for the terminal
date: 2025-03-02
tags: [go, tui]
---

I live in the terminal, so context-switching to a browser to read manga felt wrong. [manga-tui](https://github.com/HimanshuSardana/manga-tui) is a Bubbletea-based reader: search, track your library, cache chapters, read offline.

## Stack

- **Bubbletea + Lipgloss** for the TUI
- SQLite for library + progress
- Image rendering via sixel/kitty graphics with ASCII fallback

## Hard parts

- Image protocols differ per terminal — detect and degrade gracefully.
- Caching aggressively so re-reads are instant.
- Keybindings that don't fight vim muscle memory.

Repo: [github.com/HimanshuSardana/manga-tui](https://github.com/HimanshuSardana/manga-tui)
