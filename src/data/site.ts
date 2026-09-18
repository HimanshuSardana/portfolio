export interface Project {
  name: string;
  description: string;
  language: string;
  url: string;
  tags: string[];
  featured?: boolean;
}

export const projects: Project[] = [
  { name: "manga-tui", description: "A TUI manga reader written in Go — read manga without leaving the terminal.", language: "Go", url: "https://github.com/HimanshuSardana/manga-tui", tags: ["tui", "bubbletea", "manga"], featured: true },
  { name: "camus", description: "A minimal Apache Kafka clone written in Go. Topics, partitions, consumer groups from scratch.", language: "Go", url: "https://github.com/HimanshuSardana/camus", tags: ["kafka", "distributed-systems"], featured: true },
  { name: "kite", description: "A minimal and blazingly fast static site generator written in Go.", language: "Go", url: "https://github.com/HimanshuSardana/kite", tags: ["ssg", "cli"], featured: true },
  { name: "bonsai", description: "Minimal Git frontend served via a Go SSG — browse repos in the browser.", language: "Go", url: "https://github.com/HimanshuSardana/bonsai", tags: ["git", "frontend"], featured: true },
  { name: "cpos", description: "Capture Codeforces & CSES problems, run tests, and submit from VS Code or the terminal. On the VS Code Marketplace + Chrome Web Store.", language: "TypeScript", url: "https://github.com/HimanshuSardana/cpos", tags: ["vscode", "competitive-programming"], featured: true },
  { name: "rss-reader", description: "Three-pane desktop RSS reader (Tauri v2 + Svelte) with sqlite storage and full-text extraction.", language: "Svelte", url: "https://github.com/HimanshuSardana/rss-reader", tags: ["tauri", "rss"], featured: true },
  { name: "vectra", description: "A TUI wrapper over ChromaDB — browse and query your vector DB from the terminal.", language: "Python", url: "https://github.com/HimanshuSardana/vectra", tags: ["tui", "rag", "chromadb"] },
  { name: "flashkv", description: "A fast persistent key-value store written in Go.", language: "Go", url: "https://github.com/HimanshuSardana/flashkv", tags: ["database", "kv-store"] },
  { name: "tiet-notegen", description: "Scrapes Thapar's question-paper archive and classifies questions into topics with the Gemini API.", language: "Python", url: "https://github.com/HimanshuSardana/tiet-notegen", tags: ["gemini", "scraper", "edtech"] },
  { name: "groq.nvim", description: "Neovim plugin for code generation and explanation using the Groq API.", language: "Python", url: "https://github.com/HimanshuSardana/groq.nvim", tags: ["neovim", "llm"] },
  { name: "matchmyresume", description: "Resume ↔ job-description matcher: scraper + website that scores fit.", language: "TypeScript", url: "https://github.com/HimanshuSardana/matchmyresume-website", tags: ["nlp", "jobs"] },
  { name: "chessalyze", description: "A hobby project to improve my chess, similar to Lichess studies.", language: "TypeScript", url: "https://github.com/HimanshuSardana/chessalyze", tags: ["chess", "lichess"] },
  { name: "origin", description: "Experiments in Go — systems programming playground.", language: "Go", url: "https://github.com/HimanshuSardana/origin", tags: ["go", "systems"] },
  { name: "wsend", description: "Minimal file sharing over the wire, written in Go.", language: "Go", url: "https://github.com/HimanshuSardana/wsend", tags: ["cli", "networking"] },
  { name: "yaav", description: "Yet another audio visualizer.", language: "Go", url: "https://github.com/HimanshuSardana/yaav", tags: ["audio", "tui"] },
  { name: "yapp", description: "Yet another PGN parser, written in Go.", language: "Go", url: "https://github.com/HimanshuSardana/yapp", tags: ["chess", "parser"] },
  { name: "summize", description: "An RSS reader that converts posts to Markdown and mails them to you daily.", language: "Python", url: "https://github.com/HimanshuSardana/summize", tags: ["rss", "automation"] },
  { name: "ezlc", description: "Next.js frontend + Python scraper for LeetCode-style practice (ezlc).", language: "TypeScript", url: "https://github.com/HimanshuSardana/ezlc", tags: ["nextjs", "leetcode"] },
  { name: "nvim-config", description: "My personal Neovim setup — and a separate modular config geared for competitive programming.", language: "Lua", url: "https://github.com/HimanshuSardana/nvim-config", tags: ["neovim", "dotfiles"] },
  { name: "hyprland-dots", description: "Personal Hyprland setup: waybar, hyprlock, rofi, dunst.", language: "Lua", url: "https://github.com/HimanshuSardana/hyprland-dots", tags: ["hyprland", "rice"] },
  { name: "hk-cheat-gui", description: "A GUI trainer for Hollow Knight written in Python.", language: "Python", url: "https://github.com/HimanshuSardana/hk-cheat-gui", tags: ["gaming", "gui"] },
  { name: "ppt-gen", description: "Because I'm too lazy to make PPTs — generate them programmatically in Go.", language: "Go", url: "https://github.com/HimanshuSardana/ppt-gen", tags: ["automation", "cli"] },
];

export const posts = [
  { slug: "building-kafka-in-go", title: "Building a minimal Kafka clone in Go", date: "2025-06-14", excerpt: "What I learned re-implementing topics, partitions and consumer groups for camus.", tags: ["go", "kafka"] },
  { slug: "tui-manga-reader", title: "Why I built a manga reader for the terminal", date: "2025-03-02", excerpt: "Bubbletea, caching, image-to-terminal rendering and offline reading.", tags: ["go", "tui"] },
  { slug: "neovim-cp-setup", title: "My Neovim setup for competitive programming", date: "2024-11-20", excerpt: "Snippets, runners, and fast test-case switching for Codeforces/CSES.", tags: ["neovim", "cp"] },
  { slug: "go-ssg-from-scratch", title: "Writing a static site generator in Go", date: "2024-08-11", excerpt: "How kite renders Markdown to HTML in milliseconds — and why.", tags: ["go", "ssg"] },
];
