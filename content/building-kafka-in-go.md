---
title: Building a minimal Kafka clone in Go
date: 2025-06-14
tags: [go, kafka]
---

For [camus](https://github.com/HimanshuSardana/camus) I wanted to actually understand Kafka, not just use it. So I re-implemented the core: topics, partitions, an append-only log, and consumer groups.

## What I built

- Partitioned append-only log with segment files
- Simple TCP wire protocol for produce / fetch
- Consumer-group coordination with offset commits

## Lessons

- **Batching is everything** — fsync per message kills throughput; group commit saves you.
- **Offsets are just integers** — most of Kafka's magic is bookkeeping done well.
- Go's `net` package plus goroutines make the broker surprisingly compact (~1k LOC for the core).

```go
// sketch: append to a partition log
func Append(batch []Record) (int64, error) {
    // lock, encode, fsync in batches
    return baseOffset, nil
}
```

Repo: [github.com/HimanshuSardana/camus](https://github.com/HimanshuSardana/camus)
