---
title: rss-reader
date: 2026-09-15
---

Three-pane desktop RSS reader: sources sidebar, posts list, 60% reading pane.
Successor to the Python/blessed prototype (preserved in git history under
`bdebc00`..`3d5b407`).

## Stack

- **Tauri v2** - system webview + Rust shell (~10MB binary, ~50MB RAM vs ~200MB+ on Electron)
- **Svelte 5 + Vite** frontend
- **tauri-plugin-sql** - sqlite storage, same schema as the prototype (`rss.db` files are interchangeable)
- **tauri-plugin-http** - feed + article downloads (bypasses feed CORS restrictions)
- **@mozilla/readability** - full-text article extraction

## Prerequisites

```bash
# system webview (Arch) - required to compile the Rust shell
sudo pacman -S webkit2gtk-4.1

# toolchains: Rust (rustup or pacman) + bun
```

## Run

```bash
bun install
bun run tauri dev      # dev window with hot reload
bun run tauri build    # release bundle
```

Frontend-only check (no Rust needed):

```bash
bun run build
```

## Sharing data with the old TUI

`Database.load("sqlite:rss.db")` resolves inside Tauri's app-data dir. To reuse
an existing database, copy it there:

```bash
cp /path/to/old/rss.db ~/.local/share/com.rssreader.app/rss.db
```

## Keys (mirrors the TUI)

`1/2/3` panes · `h/l` panes · `j/k` move · `enter` open · `F` full-text ·
`r/R` refresh one/all · `a` add feed · `d` delete source · `M` mark source read ·
`u` toggle unread. Everything is also clickable.
