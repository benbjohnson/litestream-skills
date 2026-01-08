# MCP Server Integration

Litestream includes a Model Context Protocol (MCP) server for AI tool integration, allowing AI assistants to manage database backups and recovery.

## Overview

The MCP server exposes Litestream functionality as tools that AI agents can call:

- List databases and their replication status
- View available backups (LTX files, snapshots)
- Restore databases to specific points in time
- Query backup metadata

## Enabling MCP Server

Add the `mcp-addr` configuration to enable the MCP server:

```yaml
mcp-addr: "localhost:8080"

dbs:
  - path: /data/app.db
    replica:
      url: s3://bucket/backup
```

Or via command line:

```bash
litestream replicate -config /etc/litestream.yml -mcp-addr localhost:8080
```

## Available MCP Tools

### litestream_databases

List all monitored databases and their replicas.

**Input**: None

**Output**:
```json
{
  "databases": [
    {
      "path": "/data/app.db",
      "replicas": [
        {
          "name": "s3",
          "type": "s3",
          "url": "s3://bucket/backup"
        }
      ]
    }
  ]
}
```

### litestream_ltx

List LTX files for a database or replica.

**Input**:
```json
{
  "database": "/data/app.db",
  "replica": "s3",           // optional
  "level": 0,                // optional, filter by level
  "limit": 100               // optional, max results
}
```

**Output**:
```json
{
  "files": [
    {
      "level": 0,
      "min_txid": "0000000000001234",
      "max_txid": "0000000000001234",
      "size": 4096,
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### litestream_snapshots

List available snapshots for a database.

**Input**:
```json
{
  "database": "/data/app.db",
  "replica": "s3"            // optional
}
```

**Output**:
```json
{
  "snapshots": [
    {
      "txid": "0000000000123456",
      "size": 1048576,
      "created_at": "2024-01-15T00:00:00Z"
    }
  ]
}
```

### litestream_restore

Restore a database from backup.

**Input**:
```json
{
  "database": "/data/app.db",
  "output": "/tmp/restored.db",
  "timestamp": "2024-01-15T10:30:00Z",  // optional
  "txid": "0000000000001234"             // optional, alternative to timestamp
}
```

**Output**:
```json
{
  "restored_path": "/tmp/restored.db",
  "txid": "0000000000001234",
  "size": 1048576
}
```

### litestream_generations

List generations for a database (legacy compatibility).

**Input**:
```json
{
  "database": "/data/app.db",
  "replica": "s3"            // optional
}
```

**Note**: This tool exists for backward compatibility. In v0.5.x, the generations concept has been replaced with level-based compaction.

## Usage Examples

### AI Assistant Querying Backups

```
User: "What backups are available for my production database?"

AI calls: litestream_databases
AI calls: litestream_ltx { "database": "/data/production.db" }

AI: "I found your production database with backups to S3. You have
     LTX files spanning from TXID 1 to 123456, with the latest
     backup at 10:30:00 UTC today."
```

### AI Assistant Restoring Database

```
User: "Restore my database to yesterday at noon"

AI calls: litestream_restore {
  "database": "/data/app.db",
  "output": "/tmp/restored.db",
  "timestamp": "2024-01-14T12:00:00Z"
}

AI: "I've restored your database to /tmp/restored.db. The restore
     includes all transactions up to TXID 98765 from January 14th
     at noon."
```

## Security Considerations

### Network Binding

By default, bind to localhost only:

```yaml
mcp-addr: "localhost:8080"   # Only local connections
# mcp-addr: "0.0.0.0:8080"   # All interfaces (not recommended)
```

### Authentication

The MCP server does not include built-in authentication. For production:

1. Use localhost binding with a local AI agent
2. Put behind a reverse proxy with authentication
3. Use network-level access controls

### Restore Permissions

The restore tool can write to any path the Litestream process can access. Ensure:

- Litestream runs with minimal required permissions
- Output paths are validated by calling application
- Consider read-only MCP mode if only querying

## Connecting AI Tools

### Claude Desktop

Add to Claude Desktop configuration:

```json
{
  "mcpServers": {
    "litestream": {
      "url": "http://localhost:8080"
    }
  }
}
```

### Custom Integration

Connect via HTTP:

```bash
# List databases
curl http://localhost:8080/mcp/tools/litestream_databases

# Call a tool
curl -X POST http://localhost:8080/mcp/tools/litestream_ltx \
  -H "Content-Type: application/json" \
  -d '{"database": "/data/app.db"}'
```

## Troubleshooting

### Connection Refused

- Verify `mcp-addr` is configured
- Check Litestream is running
- Verify firewall allows connection

### Tool Not Found

- Ensure using correct tool name (e.g., `litestream_databases`)
- Check Litestream version supports MCP

### Restore Fails

- Verify output path is writable
- Check backup files exist
- Verify timestamp/TXID is within backup range

## See Also

- [Status Command](../commands/status.md)
- [Restore Command](../commands/restore.md)
- [LTX Command](../commands/ltx.md)
