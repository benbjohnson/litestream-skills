# Heartbeat Monitoring

Litestream can send HTTP heartbeat pings to external monitoring services when replication is healthy.

## Overview

The heartbeat feature sends periodic HTTP requests to a configured URL when all databases have synced successfully. This integrates with uptime monitoring services like:

- Healthchecks.io
- Cronitor
- Better Uptime
- Dead Man's Snitch
- Custom monitoring endpoints

## Configuration

### Basic Setup

```yaml
heartbeat-url: "https://hc-ping.com/your-uuid-here"

dbs:
  - path: /data/app.db
    replica:
      url: s3://bucket/backup
```

### With Interval

```yaml
heartbeat-url: "https://hc-ping.com/your-uuid-here"
heartbeat-interval: 5m    # Check every 5 minutes (default)

dbs:
  - path: /data/app.db
    replica:
      url: s3://bucket/backup
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `heartbeat-url` | (none) | URL to ping when healthy |
| `heartbeat-interval` | `5m` | How often to check/send heartbeat |

**Note**: Minimum heartbeat interval is 1 minute. Values below this are clamped to 1 minute.

## How It Works

1. **Check Interval**: Every `heartbeat-interval`, Litestream checks all databases
2. **Health Check**: For each database, verify last successful sync is within interval
3. **All Healthy**: If ALL databases synced recently, send HTTP GET to heartbeat URL
4. **Rate Limiting**: Heartbeats are sent at most once per minute

### Health Criteria

A database is considered healthy when:
- It has synced at least once
- Last successful sync was within `heartbeat-interval`

### Failure Behavior

If any database is unhealthy:
- No heartbeat is sent
- Monitoring service detects missed ping
- Alerts trigger based on service configuration

## Service Integration

### Healthchecks.io

1. Create a check at [healthchecks.io](https://healthchecks.io)
2. Copy the ping URL
3. Configure Litestream:

```yaml
heartbeat-url: "https://hc-ping.com/your-uuid-here"
heartbeat-interval: 5m
```

4. Set check period to match or exceed interval (e.g., 10 minutes)
5. Set grace period for acceptable delay (e.g., 5 minutes)

### Cronitor

```yaml
heartbeat-url: "https://cronitor.link/p/your-key/your-monitor"
heartbeat-interval: 5m
```

### Better Uptime

```yaml
heartbeat-url: "https://betteruptime.com/api/v1/heartbeat/your-token"
heartbeat-interval: 5m
```

### Custom Endpoint

Any HTTP endpoint that accepts GET requests:

```yaml
heartbeat-url: "https://your-service.com/health/litestream"
heartbeat-interval: 1m
```

## Examples

### Single Database

```yaml
heartbeat-url: "https://hc-ping.com/abc123"
heartbeat-interval: 5m

dbs:
  - path: /data/app.db
    replica:
      url: s3://bucket/backup
```

### Multiple Databases

All databases must be healthy for heartbeat to send:

```yaml
heartbeat-url: "https://hc-ping.com/abc123"
heartbeat-interval: 5m

dbs:
  - path: /data/app.db
    replica:
      url: s3://bucket/app-backup

  - path: /data/users.db
    replica:
      url: s3://bucket/users-backup
```

### Production Setup

```yaml
heartbeat-url: "https://hc-ping.com/prod-litestream"
heartbeat-interval: 1m    # Frequent checks for production

dbs:
  - path: /data/production.db
    replica:
      url: s3://prod-bucket/backup
      sync-interval: 1s
```

## Monitoring Best Practices

### Set Appropriate Intervals

| Environment | Heartbeat Interval | Service Period |
|-------------|-------------------|----------------|
| Development | 15m | 30m |
| Staging | 5m | 15m |
| Production | 1m | 5m |

### Alert Configuration

Configure monitoring service alerts:
- **Warning**: After 1 missed heartbeat
- **Critical**: After 2-3 missed heartbeats
- **Escalation**: After 5+ missed heartbeats

### Multiple Monitoring Services

For critical systems, use multiple services:

```yaml
# Primary monitoring
heartbeat-url: "https://hc-ping.com/primary"

# Note: Litestream only supports one heartbeat URL.
# For multiple services, use a webhook aggregator or
# configure the monitoring service to forward alerts.
```

## Troubleshooting

### No Heartbeats Received

1. **Check configuration**: Verify `heartbeat-url` is set correctly
2. **Check connectivity**: Ensure Litestream can reach the URL
3. **Check logs**: Look for heartbeat-related errors
4. **Check database sync**: Verify databases are syncing (use `litestream status`)

### Intermittent Heartbeats

1. **Sync issues**: Database sync may be failing occasionally
2. **Network issues**: Transient connectivity problems
3. **Increase interval**: If sync takes longer than interval

### Heartbeat URL Not Called

Verify:
- URL is reachable from Litestream host
- No firewall blocking outbound HTTP
- DNS resolution works
- TLS certificates are valid (for HTTPS)

## Logging

Heartbeat activity appears in logs:

```
level=INFO msg="heartbeat sent" url="https://hc-ping.com/abc123"
level=WARN msg="heartbeat skipped" reason="database not synced" db="/data/app.db"
level=ERROR msg="heartbeat failed" url="https://hc-ping.com/abc123" error="connection refused"
```

## See Also

- [Monitoring](monitoring.md)
- [Troubleshooting](troubleshooting.md)
- [Status Command](../commands/status.md)
