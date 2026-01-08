# VFS (Virtual File System) Support

Litestream's VFS allows SQLite to read (and optionally write) directly from cloud storage without maintaining a local database copy.

## Overview

The VFS intercepts SQLite's file operations and:
- **Reads**: Fetches pages from cloud storage, caching them locally
- **Writes**: Buffers changes and syncs them periodically to cloud storage
- **Polling**: Detects new data from other writers

This enables:
- Read replicas that stay synchronized with the primary
- Serverless applications reading from cloud storage
- Time-travel queries to any point in history

## Use Cases

### Read Replicas

Multiple application instances can read from the same cloud-stored database:

```
Primary (writes) → S3 bucket ← Read Replica 1
                            ← Read Replica 2
                            ← Read Replica 3
```

### Serverless Applications

Edge functions or serverless workers can read databases without local storage:

```go
// Open database directly from S3
db, err := sql.Open("litestream-vfs", "s3://bucket/mydb")
```

### Time-Travel Queries

Query the database at any historical point:

```go
// Read database as it was at a specific time
vfs.SetTargetTime(ctx, time.Parse(time.RFC3339, "2024-01-15T10:30:00Z"))
```

## Configuration

### Read-Only VFS

```yaml
dbs:
  - path: /data/app.db
    replica:
      url: s3://bucket/backup
      vfs:
        enabled: true
        poll-interval: 1s      # Check for new data every second
        cache-size: 10MB       # LRU cache for pages
```

### Read-Write VFS

```yaml
dbs:
  - path: /data/app.db
    replica:
      url: s3://bucket/backup
      vfs:
        enabled: true
        write: true                    # Enable writes
        write-sync-interval: 1s        # Sync dirty pages every second
        write-buffer-path: /tmp/buf    # Durability buffer location
        poll-interval: 1s
        cache-size: 10MB
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `enabled` | `false` | Enable VFS mode |
| `poll-interval` | `1s` | How often to check for remote changes |
| `cache-size` | `10MB` | LRU cache size for pages |
| `write` | `false` | Enable write support |
| `write-sync-interval` | `1s` | How often to sync dirty pages |
| `write-buffer-path` | (temp) | Location for write buffer file |

## How It Works

### Page Cache

The VFS maintains an LRU cache of recently accessed pages:

1. SQLite requests a page
2. VFS checks LRU cache
3. Cache hit → return immediately
4. Cache miss → fetch from cloud storage
5. Store in cache and return

### Polling for Changes

Background polling detects new LTX files:

1. Poll remote storage every `poll-interval`
2. If new LTX files found, update page index
3. Invalidate cached pages that were updated
4. Next read gets fresh data

### Write Support

When writes are enabled:

1. SQLite writes a page
2. VFS stores in dirty page buffer (local file for durability)
3. Background sync creates LTX file from dirty pages
4. LTX file uploaded to cloud storage
5. Dirty buffer cleared on successful sync

### Conflict Detection

For concurrent writes, VFS validates expected TXID:

1. Track last known remote TXID
2. Before committing, verify remote TXID matches
3. If mismatch → another writer modified database
4. Abort and reload (application handles retry)

## Time-Travel Queries

Query the database at any historical point:

### Set Target Time

```go
// Go to specific point in time
err := vfsFile.SetTargetTime(ctx, targetTime)
if err != nil {
    return err
}

// Queries now return data as of targetTime
rows, err := db.Query("SELECT * FROM users")
```

### Reset to Latest

```go
// Return to current state
err := vfsFile.ResetTime(ctx)
```

### How It Works

1. Find LTX files with timestamps ≤ target time
2. Build page index from those files only
3. Queries read from that point-in-time view
4. Later files are ignored until ResetTime()

## Building with VFS Support

VFS requires the `vfs` build tag:

```bash
# Build Litestream with VFS support
go build -tags vfs -o bin/litestream-vfs ./cmd/litestream-vfs

# Or use Docker image with VFS
docker pull litestream/litestream:0.5-vfs
```

## Performance Considerations

### Latency

- First page access: Cloud storage latency (~50-200ms)
- Cached access: Memory speed (<1ms)
- Tune `cache-size` based on working set

### Network Usage

- Each cache miss = one network request
- Compacted LTX files reduce requests
- Consider read patterns when sizing cache

### Write Throughput

- Writes buffered locally (fast)
- Sync interval controls upload frequency
- Higher sync interval = better throughput, more data at risk

## Limitations

1. **Not for high-write workloads**: Cloud latency limits write performance
2. **Single writer recommended**: Multi-writer requires coordination
3. **Cache memory**: Large databases need significant cache
4. **Build tag required**: VFS not in default Litestream binary

## Troubleshooting

### Stale Data

- Check `poll-interval` is appropriate
- Verify network connectivity
- Check for LTX file upload issues on primary

### Write Conflicts

- Ensure single writer or coordinate access
- Monitor for conflict errors in logs
- Implement retry logic in application

### High Latency

- Increase `cache-size` for better hit rate
- Use storage backend with edge caching (CloudFront, etc.)
- Consider colocating application with storage

## See Also

- [Replication](replication.md)
- [Compaction](compaction.md)
- [Architecture](architecture.md)
