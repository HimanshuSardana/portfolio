---
title: flashkv
date: 2026-04-14
---

FlashKV is a lightweight, Redis-inspired key-value server written in Go.
It provides a simple TCP text protocol, an interactive client mode, and append-only-file (AOF) persistence.

## Project Summary

FlashKV is designed as a minimal, high-performance learning/experimentation project for in-memory key-value storage with concurrency and durability basics:
- In-memory map with thread-safe access (`sync.RWMutex`)
- TCP server with concurrent connection handling
- Basic commands: `SET`, `GET`, `DEL`
- AOF persistence with periodic async flush and startup replay
- Benchmark script for concurrent pipelined load testing

---

## Features

- **Simple text command protocol** over TCP (`\n`-delimited commands)
- **Concurrent request handling** (goroutine per client connection)
- **Thread-safe in-memory store**
- **AOF durability** (`appendonly.aof`) for write operations
- **Interactive CLI client mode**
- **Python benchmark script** for throughput/stress testing

---

## Architecture

### Top-level structure

- `main.go` - CLI entrypoint (`-server` / `-client`)
- `server.go` - TCP listener, connection handling, command execution
- `client.go` - interactive client REPL
- `store.go` - in-memory key-value store with locking
- `parser.go` - command parsing (`strings.Fields`)
- `aof.go` - append-only-file persistence and replay
- `benchmarks/benchmark.py` - concurrent pipelined benchmark script
- `Makefile` - build/run/release convenience commands

---

## Requirements

- Go toolchain (module declares `go 1.26.2` in `go.mod`)
- Python 3 (optional, for running benchmark script)
- UPX (optional, only for `build-release`)

> Note: If your local Go version differs, use a compatible version for your environment.

---

## Installation / Build

Clone and build:

```bash
git clone https://github.com/HimanshuSardana/flashkv.git
cd flashkv
go build .
```

This produces the `flashkv` binary.

### Using Makefile

```bash
make build
```

`build-release` (optional optimized build + UPX pack):

```bash
make build-release
```

> Known issue: `make run` currently uses `go run main.go`, which does not include all package files and fails.
> Use `go run . -server` or `go run . -client` instead.

---

## Quick Start

### 1) Start server

```bash
go run . -server
```

By default, server listens on `127.0.0.1:6379`.

### 2) Start client (new terminal)

```bash
go run . -client
```

You should see an interactive prompt.

### 3) Try commands

```text
> SET name flashkv
OK
> GET name
flashkv
> DEL name
OK
> GET name
ERR not found
> QUIT
Goodbye!
```

---

## Command Reference

### `SET key value`
Set a string value for a key.

- Success: `OK`
- Usage error: `ERR usage: SET key value`

### `GET key`
Get value for a key.

- Success: `<value>`
- Missing key: `ERR not found`
- Usage error: `ERR usage: GET key`

### `DEL key`
Delete a key.

- Success: `OK`
- Missing key: `ERR not found`
- Usage error: `ERR usage: DEL key`

---

## Protocol Notes

- Commands are plain text, one command per line.
- Command name is case-insensitive (`set` and `SET` both work).
- Arguments are split by whitespace.

Because parsing uses whitespace splitting:
- Values **cannot include spaces** directly.
- There is no quoting/escaping support.
- Protocol is not Redis RESP.

---

## Persistence (AOF)

FlashKV persists write operations (`SET`, `DEL`) to an append-only file:

- File path: `appendonly.aof` (project working directory)
- On startup in server mode, AOF is replayed to rebuild state
- Writes are buffered and flushed periodically (~100ms)
- Final flush happens on close

Operational note:
- Running from different working directories creates/uses different `appendonly.aof` files.

---

## Benchmarking

A benchmark script is provided:

```bash
python3 benchmarks/benchmark.py
```

Default benchmark configuration (in script):
- Host: `127.0.0.1`
- Port: `6379`
- Iterations/client: `10000` for SET + `10000` for GET
- Concurrent clients: `10`
- Pipeline size: `100`

Start the server first, then run the benchmark.

---

## Configuration

Current configuration is code-level constants (no env vars yet):

- Server host: `127.0.0.1`
- Server port: `:6379`
- AOF path: `appendonly.aof`

### Environment variables

No environment-variable configuration is implemented at this time.

---

## Development Workflow

### Run locally

```bash
go run . -server
go run . -client
```

### Build

```bash
go build .
```

### Tests

Currently, no Go test files are present in the repository.

```bash
go test ./...
```

(Will report no tests unless tests are added.)

### Lint/format

No lint configuration is currently committed.

```bash
go fmt ./...
```

---

## Known Limitations

- Hardcoded bind address and client target (`127.0.0.1:6379`)
- No authentication/TLS/access control
- No expiration/TTL support
- No transactions or advanced data structures
- No replication/clustering
- Basic parser: no quoted values or escaping
- Not RESP-compatible
- AOF rewrite/compaction is not implemented
- Graceful shutdown flow is minimal (server runs accept loop indefinitely)

---

## Roadmap (TODO)

> TODO: Confirm and publish maintainers' prioritized roadmap.

Potential next steps inferred from current design:
- [ ] Configurable host/port/AOF path via flags or env vars
- [ ] RESP protocol compatibility
- [ ] TTL / expiration
- [ ] Better shutdown handling and signal support
- [ ] AOF compaction / rewrite
- [ ] Automated tests and CI
- [ ] Linting/static analysis integration
- [ ] Docker/devcontainer support

---

## Contributing

> TODO: Add contribution guidelines (`CONTRIBUTING.md`), coding style, and PR process.

For now:
1. Fork the repo
2. Create a feature branch
3. Make focused changes with clear commit messages
4. Open a pull request

---

## License

> TODO: Add LICENSE file and update this section with the chosen license.
