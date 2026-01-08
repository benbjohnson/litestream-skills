# Level-Based Compaction

Litestream uses a multi-level compaction system to efficiently manage LTX files and reduce storage overhead.

## Overview

LTX files are organized into levels (L0-L9), where each level contains progressively larger time ranges of data:

- **Level 0 (L0)**: Raw transaction files from WAL sync (smallest, most frequent)
- **Levels 1-8**: Progressively compacted files with configurable intervals
- **Level 9**: Full database snapshots (largest, least frequent)

## How Compaction Works

### File Flow

```
SQLite WAL → L0 (raw) → L1 → L2 → ... → L8 → L9 (snapshot)
```

1. **L0 Creation**: Every sync creates a new L0 LTX file containing recent transactions
2. **Compaction**: Background process merges files from lower levels into higher levels
3. **Deduplication**: When pages appear multiple times, only the latest version is kept
4. **Cleanup**: Old files at lower levels are deleted after retention period

### Storage Layout

```
.db-litestream/
└── ltx/
    ├── 0/                    # L0 files (raw sync)
    │   ├── 0000000001-0000000001.ltx
    │   ├── 0000000002-0000000002.ltx
    │   └── ...
    ├── 1/                    # L1 files (first compaction)
    │   └── 0000000001-0000001000.ltx
    ├── 2/                    # L2 files
    │   └── 0000000001-0000010000.ltx
    └── 9/                    # Snapshots
        └── 0000000001-0123456789.ltx
```

### File Naming

LTX files are named by their transaction range:

```
{MinTXID}-{MaxTXID}.ltx
```

Examples:
- `0000000001-0000000001.ltx` - Single transaction (L0)
- `0000000001-0000001000.ltx` - Transactions 1-4096 (compacted)

## Configuration

### Compaction Levels

Configure compaction intervals in your config file:

```yaml
dbs:
  - path: /data/app.db
    replica:
      url: s3://bucket/backup
      levels:
        - interval: 30s    # L1: Compact every 30 seconds
        - interval: 5m     # L2: Compact every 5 minutes
        - interval: 1h     # L3: Compact every hour
        - interval: 24h    # L4: Compact daily
```

### L0 Retention

Control how long L0 files are kept after compaction:

```yaml
l0-retention: 5m                    # Keep L0 files for 5 minutes after compaction
l0-retention-check-interval: 15s    # Check retention every 15 seconds
```

**Why retain L0 files?** VFS read replicas may still be reading from L0 files. The retention window gives them time to observe new data before files are deleted.

### Snapshots

Configure full database snapshots:

```yaml
snapshot:
  interval: 24h      # Create snapshot every 24 hours
  retention: 24h     # Keep snapshots for 24 hours
```

Snapshots are stored at Level 9 and provide:
- Faster restore (single file instead of many LTX files)
- Baseline for compaction cleanup
- Point-in-time recovery anchors

## Page Deduplication

When compacting, if a page was modified multiple times, only the final version is kept:

```
Before compaction (L0):
  File 1: Page 5 (version A), Page 10 (version A)
  File 2: Page 5 (version B)
  File 3: Page 5 (version C), Page 10 (version B)

After compaction (L1):
  Single File: Page 5 (version C), Page 10 (version B)
```

This deduplication significantly reduces storage for write-heavy workloads.

## Best Practices

### High-Frequency Writes

For databases with frequent writes, use shorter compaction intervals:

```yaml
levels:
  - interval: 15s    # More frequent L1 compaction
  - interval: 2m
  - interval: 30m
```

### Long-Term Retention

For compliance or audit requirements:

```yaml
levels:
  - interval: 1m
  - interval: 15m
  - interval: 6h
  - interval: 24h

snapshot:
  interval: 168h     # Weekly snapshots
  retention: 720h    # Keep for 30 days
```

### Minimize Storage Costs

For cost-sensitive deployments:

```yaml
levels:
  - interval: 30s
  - interval: 5m
  - interval: 1h

l0-retention: 2m    # Delete L0 quickly after compaction
```

## Monitoring Compaction

Use `litestream ltx` to inspect compaction state:

```bash
litestream ltx /data/app.db

# Output shows files at each level:
level  min_txid              max_txid              size     created
0      0000000000001234      0000000000001234      4096     2024-01-15T10:00:00Z
0      0000000000001235      0000000000001235      4096     2024-01-15T10:00:01Z
1      0000000000001000      0000000000001233      32768    2024-01-15T09:59:30Z
2      0000000000000001      0000000000000999      65536    2024-01-15T09:55:00Z
```

## Timestamp Preservation

During compaction, original timestamps are preserved:

- **CreatedAt**: When the original transaction was written
- Used for point-in-time recovery (`-timestamp` flag)
- Preserved through all compaction levels

This allows restoring to any point in time, regardless of which compaction level the data resides in.

## See Also

- [LTX Format](ltx-format.md)
- [Replication](replication.md)
- [Recovery](../operations/recovery.md)
