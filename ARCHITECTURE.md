# Docker Architecture

## System Overview

This document explains how the application is architected differently for development and production environments.

## Development Architecture (Neon Local)

```
┌─────────────────────────────────────────────────────────┐
│                   Docker Host (Your PC)                  │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │          Docker Compose Network (dev)              │  │
│  │                                                     │  │
│  │  ┌──────────────────────┐  ┌──────────────────┐   │  │
│  │  │   app (container)    │  │  neon-local      │   │  │
│  │  │                      │  │  (container)     │   │  │
│  │  │  Node.js App         │  │                  │   │  │
│  │  │  - Hot Reload ON     │  │  Neon Proxy      │   │  │
│  │  │  - Port: 3000        │──┼─▶Port: 5432      │   │  │
│  │  │  - Volumes mounted   │  │                  │   │  │
│  │  │                      │  │                  │   │  │
│  │  └──────────────────────┘  └────────┬─────────┘   │  │
│  │                                      │             │  │
│  └──────────────────────────────────────┼─────────────┘  │
│                                         │                │
└─────────────────────────────────────────┼────────────────┘
                                          │
                                          │ HTTPS
                                          │
                    ┌─────────────────────▼─────────────────┐
                    │         Neon Cloud API                │
                    │                                       │
                    │  Creates/Manages:                     │
                    │  - Ephemeral Branch (auto-created)    │
                    │  - Auto-deleted on stop               │
                    │  - Fresh data every time              │
                    └───────────────────────────────────────┘
```

### Development Flow

1. **Container Start**: `docker-compose up`
   - Neon Local container starts first
   - Connects to Neon Cloud API using `NEON_API_KEY`
   - Creates a new ephemeral branch from `PARENT_BRANCH_ID`
   - Opens Postgres proxy on port 5432

2. **App Connection**:
   - App container starts after Neon Local is healthy
   - Connects to `neon-local:5432` via Docker network
   - Uses standard Postgres connection string
   - Neon Local proxies queries to cloud branch

3. **Development**:
   - Code changes trigger hot reload
   - Database operations use ephemeral branch
   - Each developer gets isolated data

4. **Container Stop**: `docker-compose down`
   - App container stops
   - Neon Local deletes ephemeral branch
   - Clean state for next start

## Production Architecture (Neon Cloud)

```
┌─────────────────────────────────────────────────────────┐
│              Production Server / Cloud VM                │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │           Docker Compose Network (prod)            │  │
│  │                                                     │  │
│  │  ┌──────────────────────┐                          │  │
│  │  │   app (container)    │                          │  │
│  │  │                      │                          │  │
│  │  │  Node.js App         │                          │  │
│  │  │  - Production build  │                          │  │
│  │  │  - Non-root user     │                          │  │
│  │  │  - Port: 3000        │                          │  │
│  │  │  - Health checks     │                          │  │
│  │  │  - Resource limits   │                          │  │
│  │  │                      │                          │  │
│  │  └──────────┬───────────┘                          │  │
│  │             │                                       │  │
│  └─────────────┼───────────────────────────────────────┘  │
│                │                                          │
└────────────────┼──────────────────────────────────────────┘
                 │
                 │ Direct HTTPS Connection
                 │ (no proxy)
                 │
    ┌────────────▼────────────┐
    │   Neon Cloud Database   │
    │                         │
    │  Production Branch      │
    │  - Persistent data      │
    │  - Auto-scaling         │
    │  - High availability    │
    │  - Backups enabled      │
    └─────────────────────────┘
```

### Production Flow

1. **Container Start**: `docker-compose -f docker-compose.prod.yml up`
   - Single app container starts
   - No Neon Local proxy needed
   - Connects directly to Neon Cloud

2. **App Connection**:
   - Uses `DATABASE_URL` pointing to `*.neon.tech`
   - Direct Postgres connection over TLS
   - Neon handles connection pooling and scaling

3. **Production Operation**:
   - App runs as non-root user
   - Health checks monitor container
   - Resource limits prevent runaway processes
   - Persistent database with backups

## Network Comparison

### Development Network

```
┌─────────────────────────────────────────┐
│      Docker Bridge Network (dev)        │
│                                         │
│  app ──────▶ neon-local:5432           │
│  (10.0.1.2)   (10.0.1.3)               │
│                                         │
│  Service discovery via DNS             │
└─────────────────────────────────────────┘
```

### Production Network

```
┌─────────────────────────────────────────┐
│      Docker Bridge Network (prod)       │
│                                         │
│  app ──────▶ Internet ──────▶ Neon     │
│  (10.0.2.2)               (ep-*.neon.tech)
│                                         │
│  Direct connection, no proxy           │
└─────────────────────────────────────────┘
```

## File System Layout

### Development Container

```
/app
├── node_modules/          (from npm ci)
├── src/                   (mounted volume - hot reload)
│   ├── index.js
│   ├── server.js
│   └── app.js
├── drizzle/              (mounted volume)
├── package.json
└── package-lock.json
```

### Production Container

```
/app
├── node_modules/          (production only deps)
├── src/                   (copied, not mounted)
│   ├── index.js
│   ├── server.js
│   └── app.js
├── drizzle/              (copied)
├── package.json
└── package-lock.json
```

## Database Branch Lifecycle

### Development (Ephemeral)

```
Start Containers                    Stop Containers
       ↓                                   ↓
   Create Branch ──▶ Use Branch ──▶ Delete Branch
   (auto)            (develop)        (auto)
       ↓                                   ↓
   Fresh Data                        Clean Slate
```

### Production (Persistent)

```
Create Branch              Use Branch
(manual, once)     ────▶   (forever)
       ↓                       ↓
   Schema Migrations      Daily Operations
   (controlled)           (transactions)
```

## Environment Variable Flow

### Development

```
.env.development
     │
     ├──▶ NEON_API_KEY ──────────▶ neon-local container
     │                              (authenticates with Neon)
     ├──▶ NEON_PROJECT_ID ────────▶ neon-local container
     │                              (selects project)
     ├──▶ PARENT_BRANCH_ID ───────▶ neon-local container
     │                              (creates child branch)
     └──▶ DATABASE_URL ───────────▶ app container
                                    (connects to neon-local:5432)
```

### Production

```
.env.production
     │
     └──▶ DATABASE_URL ──────────▶ app container
                                   (connects directly to neon.tech)
```

## Security Model

### Development

- **Network**: Isolated Docker network
- **Credentials**: API keys for Neon Cloud (read/write branches)
- **SSL**: Self-signed cert (Neon Local)
- **User**: Root user in container (acceptable for dev)
- **Data**: Ephemeral, destroyed on stop

### Production

- **Network**: Public internet with TLS
- **Credentials**: Database connection string only
- **SSL**: Valid CA certificate
- **User**: Non-root user (nodejs:nodejs)
- **Data**: Persistent with backups

## Scaling Considerations

### Development

- **Horizontal**: Each developer runs their own stack
- **Isolation**: Ephemeral branches prevent conflicts
- **Resources**: Local machine resources
- **Cost**: Minimal (ephemeral branches are cheap)

### Production

- **Horizontal**: Multiple app containers, single DB
- **Scaling**: Neon handles DB autoscaling
- **Resources**: Defined limits (CPU/memory)
- **Cost**: Pay-as-you-go for compute time

## Troubleshooting Decision Tree

```
Container won't start?
    │
    ├──▶ Development?
    │    │
    │    ├──▶ Check Neon Local logs
    │    ├──▶ Verify API credentials
    │    └──▶ Check parent branch exists
    │
    └──▶ Production?
         │
         ├──▶ Check DATABASE_URL
         ├──▶ Verify network connectivity
         └──▶ Check Neon project status

Can't connect to database?
    │
    ├──▶ Development?
    │    │
    │    ├──▶ neon-local healthy?
    │    ├──▶ Using service name (not localhost)?
    │    └──▶ Port 5432 available?
    │
    └──▶ Production?
         │
         ├──▶ DATABASE_URL correct?
         ├──▶ SSL enabled?
         └──▶ Firewall blocking?
```

## Summary

| Aspect | Development | Production |
|--------|-------------|------------|
| **Database** | Neon Local Proxy | Direct to Neon Cloud |
| **Branch Type** | Ephemeral | Persistent |
| **Data Lifecycle** | Temporary | Permanent |
| **Hot Reload** | ✅ Enabled | ❌ Disabled |
| **Volumes** | Mounted | Copied |
| **User** | root | nodejs (non-root) |
| **SSL Cert** | Self-signed | CA-signed |
| **Container Count** | 2 (app + proxy) | 1 (app only) |
| **Startup Time** | ~10s | ~5s |
| **Network** | Docker bridge | Internet |
