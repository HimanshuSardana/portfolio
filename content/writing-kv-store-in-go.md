---
title: Writing a KV Store in Go
date: 2026-04-14
---

### Why

Mostly to get familiar with network programming in Go, felt like a good toy project.

## How does a Key-value Store Work?

A key-value store, at its core is a simple hashmap, storing keys along with their corresponding values.

```json
{
    "key1": "value1",
    "key2": "value2",
    "key3": "value3",
}
```

Following this, a simple key value store in Go would look like this

```go
store := make(map[string]string)
store["key1"] = "value1"
```

Instead of manually working with a Hashmap, we'll create a `Store` struct with methods to `GET`, `SET` and `DEL`

```go
type KVStore struct {
    data map[string]string
}

func NewKVStore() *KVStore {
    return &KVStore{
        data: make(map[string]string),
    }
}

func (s *KVStore) Set(key, value string) {
    s.data[key] = value
}

func (s *KVStore) Get(key string) (string, bool) {
    val, ok := s.data[key]
    return val, ok
}

func (s *KVStore) Delete(key string) bool {
    _, ok := s.data[key]
    if ok {
        delete(s.data, key)
    }
    return ok
}
```

### Building the Server

However, this hashmap is scoped only to the current file, if we wish to use this as a Redis-like KV Store, We need to set this up as a proper server, continuously listening for connections and commands from clients. We'll create a server that listens on port `6379` (Redis' default port).

```go
const (
    Host = "127.0.0.1"
    Port = ":6379"
)

func RunServer(store *KVStore) {
    addr := Host + Port
    listener, err := net.Listen("tcp", addr)
    if err != nil {
        log.Fatalf("Failed to listen: %v", err)
    }
    log.Printf("Server listening on %s", addr)

    for {
        conn, err := listener.Accept()
        if err != nil {
            log.Printf("Failed to accept connection: %v", err)
            continue
        }
        go handleConnection(conn, store)
    }
}
```

### Building the Client

With the server ready to accept connections, we can now shift our focus to building a client. Like Redis, we'll implement a REPL that accepts GET, SET and DEL commands and calls the respective method on the Store.

#### Command Parser

We'll break a command into 2 parts, the command itself `Cmd` and its arguments `Args`. For `GET` and `DELETE` commands, we'll only have one argument, the key to be retrieved/deleted.

```go
func ParseCommand(line string) (*Command, error) {
    fields := strings.Fields(line)
    if len(fields) == 0 {
        return nil, nil
    }

    cmd := strings.ToUpper(fields[0])
    args := fields[1:]

    return &Command{
        Cmd:  cmd,
        Args: args,
    }, nil
}
```

We'll validate and execute the command on the server.

```go
func executeCommand(cmd *Command, store *KVStore) string {
    switch cmd.Cmd {
    case "SET":
        key, value := cmd.Args[0], cmd.Args[1]
        store.Set(key, value)
        if aof != nil {
            aof.Write(cmd.Cmd + " " + key + " " + value)
        }
        return "OK"

    case "GET":
        key := cmd.Args[0]
        value, ok := store.Get(key)
        if !ok {
            return "ERR not found"
        }
        return value

    case "DEL":
        key := cmd.Args[0]
        ok := store.Delete(key)
        if aof != nil {
            aof.Write(cmd.Cmd + " " + key)
        }
        if !ok {
            return "ERR not found"
        }
        return "OK"

    default:
        return fmt.Sprintf("ERR unknown command: %s", cmd.Cmd)
    }
}
```

We now have a simple REPL that can interact with the server

```text
> SET name Himanshu
OK
> GET name
Himanshu
> DEL name
OK
```

## Mutexes

Go's Maps are not thread-safe by default, meaning if multiple clients were to write to the same value at once, we run the risk of losing data (aka a race condition occurs) We'll use `sync.RWMutex` to ensure only one client can write at a given time (while multiple readers may read at once).

```go
type KVStore struct {
    mu   sync.RWMutex
    data map[string]string
}
```

We'll add an `RLock` for the `GET` command and a `Lock` for `DEL` and `SET`.

```go
func executeCommand(cmd *Command, store *KVStore) string {
    switch cmd.Cmd {
    case "SET":
        store.mu.Lock()
        defer store.mu.Unlock()
        // ...

    case "GET":
        store.mu.RLock()
        defer store.mu.RUnlock()
        // ...

    case "DEL":
        store.mu.Lock()
        defer store.mu.Unlock()
        // ...

    default:
        return fmt.Sprintf("ERR unknown command: %s", cmd.Cmd)
    }
}
```

At this point, we have a working server, but it violates one of the core guarantees of reliable systems: durability.

## Adding Persistence

Currently, each time we restart the server, all the data is lost and we start out with an empty hashmap, We need this to act as a sort of database, i.e for data to persist between runs. We'll achieve this via an AOF (Append-only File)

### Append Only File

An **AOF (Append-only File)** is a log of all **mutation** (SET, DEL) commands that the server receives.

A simple AOF might look like:

```text
SET key1 value1
SET key2 value2
DEL key2
SET key3 value3
```

When the server restarts, it can simply reread and re-execute all the commands in the AOF to return to its previous state.

**NOTE:** Another popular method of ensuring persistence is via **RDB (Redis Database) Snapshots**, wherein the entire contents of the hashmap are dumped into a file, which is then read at startup, it is faster since unlike AOF, it does not require re-executing all statements. However, the occasional write is expensive since it dumps the entire RAM. Also, owing to the low frequency of writing, we run the risk of losing data between writes.

### Compaction

As the number of operations grow, so will the file-size, we might observe multiple SETs to the same key. In such a case, it does not make sense to store all logs, but rather just the latest SET statements for all keys.

```text
SET key1 value1
SET key1 value2
SET key1 value3
```

Since we're only concerned with the latest value of each key, this can be shortened to

```text
SET key1 value3
```

Compaction can run either on restart or as a background thread at a fixed interval.

**NOTE**: During my implementation of AOF, I accidentally made it so that when the log file was initially being read, it would write those commands to the AOF too, causing it to double in size infinitely.

## Durability

**Durability** refers to the guarantee of data being persisted (i.e it does not disappear when the server crashes unexpectedly)

However, there exists a trade-off between the durability and write speed. With higher durability often slowing down writes. Since these writes are first written to an **AOF** log.

### How often do we write to the AOF?

There exist multiple strategies on how often we write to the AOF:

- **Always**: Write after each operation. (Increases durability but reduces write speeds)

- **Batched Writes**: Instead of writing after each operation, we set a threshold, either by number of requests (write after each 100 requests) or by time (write every 100ms). This strikes an optimal balance between durability and Disk I/O.

- **Shutdown**: Write when the server shuts down, This ensures the highest write speeds but is unacceptable for durability.

I opted to go for batched writes, flushing every 100ms.

```go
func (a *AOF) flushLoop() {
    ticker := time.NewTicker(100 * time.Millisecond)
    defer ticker.Stop()
    // ...
}
```

## Benchmarks

I wrote a simple Python script to stress-test this implementation, it features 10 concurrent clients, each making 10000 requests, with a pipeline size of 100 (i.e send 100 requests before waiting for a response). The server batches requests with a buffer size of 16KB, flushed every 100ms.

The results were:

```text
Total SET: 154,902 ops/sec
Total GET: 182,056 ops/sec
Combined: 336,958 ops/sec
```

These seem good for a toy implementation.

## Future Improvements

- **Replication**: Maintain copy of the data, currently even with an AOF, data loss can still occur.
- **TTL/Expiration**: Auto-delete keys after a set duration. (For session tokens, request counts etc.)

The entire code for this project can be found [here](https://github.com/HimanshuSardana/flashkv)
