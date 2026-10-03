---
title: camus
date: 2026-04-03
---

A Kafka clone written in Go.

## Features

- **Topics & Partitions** - Create topics with configurable partitions
- **Produce/Consume** - CLI and TCP network interface
- **Batched Log Writes** - Configurable batch size and flush interval for efficient disk I/O
- **Consumer Groups** - Multiple consumers share work with automatic partition assignment
- **Rebalancing** - Automatic partition redistribution when consumers join or leave
- **Offset Management** - Persistent offset tracking via `__consumer_offsets` topic
- **Round-Robin Assignment** - Even partition distribution across group members

## Quick Start

```bash
go build .

./camus create-topic orders
./camus server &
./camus produce orders "order-1"

./camus consume mygroup orders 0

./camus consumer-join mygroup consumer-1 orders
./camus consumer-leave mygroup consumer-1
```

## Commands

| Command | Description |
|---------|-------------|
| `create-topic <name>` | Create topic with 3 partitions |
| `produce <topic> <data>` | Send message to topic |
| `consume <group> <topic> <partition>` | Read messages from partition |
| `consumer-join <group> <member> <topic>` | Join consumer group |
| `consumer-leave <group> <member>` | Leave consumer group |
| `server` | Start TCP server on port 6969 |

## Configuration

Batch writer settings in `pkg/storage/log.go`:
- `DefaultBatchSize = 100` - Flush after 100 records
- `DefaultFlushInterval = 100ms` - Flush every 100ms if batch not full

## Benchmarks

```bash
uv run benchmarks/producer.py
uv run benchmarks/consumer.py
```
