# Litestream Skills

AI agent skills for [Litestream](https://github.com/benbjohnson/litestream) v0.5.x - SQLite disaster recovery and streaming replication to cloud storage.

## Installation

### Claude Code

```bash
/plugin marketplace add benbjohnson/litestream-skills
/plugin install litestream
```

### OpenAI Codex CLI

```bash
$skill-installer install https://github.com/benbjohnson/litestream-skills/tree/main/skills/litestream
```

## What's Included

### Concepts
- **Architecture** - System layers, components, data flow
- **Replication** - WAL monitoring, sync process
- **Compaction** - Level-based (L0-L9) file merging
- **LTX Format** - Immutable transaction file specification
- **SQLite WAL** - Write-ahead log structure
- **VFS Support** - Read/write replicas from cloud storage

### Configuration
- **S3** - AWS S3 and S3-compatible (R2, Tigris, MinIO, etc.)
- **GCS** - Google Cloud Storage
- **Azure Blob Storage** - With managed identity support
- **SFTP** - SSH file transfer
- **NATS** - JetStream object store
- **Alibaba OSS** - Object Storage Service
- **WebDAV** - WebDAV servers
- **Local File** - Filesystem replication

### Commands
- `replicate` - Continuous replication daemon
- `restore` - Point-in-time recovery
- `status` - Replication health monitoring
- `ltx` - Backup catalog inspection
- `databases` - List configured databases

### Operations
- **Troubleshooting** - Common issues and fixes
- **Recovery** - Point-in-time recovery procedures
- **Monitoring** - Prometheus metrics
- **Heartbeat** - HTTP health ping integration

### Deployment
- Docker
- Fly.io
- Kubernetes
- systemd

### Integrations
- **MCP Server** - AI tool integration (5 MCP tools)

## Key Features Covered

- All 8 storage backends with complete configuration options
- VFS read/write replica support for serverless applications
- Time-travel queries for point-in-time database access
- MCP server integration for AI-assisted database management
- Distributed leasing for multi-instance deployments
- Server-side encryption (SSE-S3, SSE-KMS, SSE-C)

## Repository Structure

```
litestream-skills/
├── .claude-plugin/
│   └── marketplace.json       # Claude Code marketplace config
├── .codex/
│   └── skills/
│       └── litestream/        # Codex skill (copy)
├── scripts/
│   └── sync-to-codex.sh       # Sync script for Codex
├── skills/
│   └── litestream/
│       ├── SKILL.md           # Main skill entry point
│       ├── commands/          # CLI command reference
│       ├── concepts/          # Architecture and internals
│       ├── configuration/     # Storage backend configs
│       ├── deployment/        # Platform deployment guides
│       ├── operations/        # Monitoring and recovery
│       ├── integrations/      # MCP server docs
│       └── scripts/           # Helper scripts
├── LICENSE
└── README.md
```

## Keeping Skills Updated

When updating skills, run the sync script to keep Codex in sync:

```bash
./scripts/sync-to-codex.sh
```

## Links

- [Litestream Documentation](https://litestream.io)
- [Litestream GitHub](https://github.com/benbjohnson/litestream)
- [Claude Code Plugin Docs](https://code.claude.com/docs/en/plugin-marketplaces)
- [Codex Skills Docs](https://developers.openai.com/codex/skills/)

## License

Apache 2.0 - see [LICENSE](LICENSE)
