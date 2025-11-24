# Docker Deployment Guide

This guide explains how to run the acquisitions application using Docker with Neon Database for both development and production environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Development Setup](#development-setup)
- [Production Setup](#production-setup)
- [Database Migrations](#database-migrations)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Docker Compose v2.0+
- Neon Account (sign up at https://console.neon.tech)

### Neon Credentials

You'll need the following from your Neon Console:

1. **NEON_API_KEY**: Found in Account Settings → API Keys
2. **NEON_PROJECT_ID**: Found in your project settings
3. **PARENT_BRANCH_ID**: Usually `main` or your default branch name
4. **DATABASE_URL** (production only): Your Neon Cloud connection string

## Architecture Overview

### Development Environment

- **Neon Local Proxy**: Creates ephemeral database branches automatically
- **App Container**: Runs the Node.js application with hot-reload
- **Network**: Both containers communicate via Docker network
- **Database**: Fresh branch created on `docker-compose up`, deleted on `docker-compose down`

### Production Environment

- **App Container**: Production-optimized Node.js application
- **Database**: Direct connection to Neon Cloud (serverless Postgres)
- **No Neon Local**: Production connects directly to neon.tech

```
Development:                    Production:
┌─────────────┐                ┌─────────────┐
│     App     │                │     App     │
│  Container  │                │  Container  │
└──────┬──────┘                └──────┬──────┘
       │                              │
       ↓                              ↓
┌─────────────┐                ┌─────────────┐
│ Neon Local  │                │   Neon DB   │
│    Proxy    │────────────────│    Cloud    │
└─────────────┘                └─────────────┘
  (Ephemeral                    (Production
   Branches)                     Database)
```

## Development Setup

### Step 1: Configure Environment Variables

Create or update `.env.development` with your Neon credentials:

```bash
# Server Configuration
PORT=3000
NODE_ENV=development
LOG_LEVEL=info

# Neon API Credentials
NEON_API_KEY=your_neon_api_key_here
NEON_PROJECT_ID=your_neon_project_id_here
PARENT_BRANCH_ID=main

# Database URL (connects to Neon Local)
DATABASE_URL=postgres://neon:npg@localhost:5432/neondb?sslmode=require
```

### Step 2: Start Development Environment

```bash
# Start all services (Neon Local + App)
docker-compose -f docker-compose.dev.yml --env-file .env.development up

# Or run in detached mode
docker-compose -f docker-compose.dev.yml --env-file .env.development up -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f app
```

### Step 3: Access Your Application

- **Application**: http://localhost:3000
- **Database**: localhost:5432 (via Neon Local proxy)

### Step 4: Working with the Development Environment

```bash
# Run database migrations inside the app container
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate

# Generate new migrations
docker-compose -f docker-compose.dev.yml exec app npm run db:generate

# Access Drizzle Studio
docker-compose -f docker-compose.dev.yml exec app npm run db:studio

# Stop all services (deletes ephemeral branch)
docker-compose -f docker-compose.dev.yml down
```

### Hot Reloading

Source code is mounted as a volume, so changes to files in `src/` will automatically reload the application.

## Production Setup

### Step 1: Configure Production Environment

Create or update `.env.production` with your production credentials:

```bash
# Server Configuration
PORT=3000
NODE_ENV=production
LOG_LEVEL=warn

# Neon Cloud Database URL (get from Neon Console)
DATABASE_URL=postgres://user:password@your-project.neon.tech/neondb?sslmode=require
```

**Important**: Never commit `.env.production` with real credentials to version control!

### Step 2: Build and Start Production Container

```bash
# Build the production image
docker-compose -f docker-compose.prod.yml build

# Start production service
docker-compose -f docker-compose.prod.yml --env-file .env.production up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f app
```

### Step 3: Production Operations

```bash
# Check container health
docker-compose -f docker-compose.prod.yml ps

# Run migrations in production
docker-compose -f docker-compose.prod.yml exec app node -e "import('./node_modules/drizzle-kit/bin.cjs').then(m => m.migrate())"

# Restart the application
docker-compose -f docker-compose.prod.yml restart app

# Stop production service
docker-compose -f docker-compose.prod.yml down
```

### Deploying to Cloud Platforms

#### Using Environment Variables (Recommended)

Instead of using `.env.production`, inject environment variables directly:

**Docker Compose Override:**
```bash
docker-compose -f docker-compose.prod.yml up -d \
  -e DATABASE_URL="postgres://..." \
  -e NODE_ENV="production"
```

**Docker Run:**
```bash
docker build --target production -t acquisitions:latest .

docker run -d \
  -p 3000:3000 \
  -e DATABASE_URL="postgres://..." \
  -e NODE_ENV="production" \
  acquisitions:latest
```

## Database Migrations

### Development

Migrations run automatically on container start, or manually:

```bash
# Generate migration from schema changes
docker-compose -f docker-compose.dev.yml exec app npm run db:generate

# Apply migrations
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate
```

### Production

**Important**: Always test migrations on a staging branch first!

```bash
# Run migrations in production
docker-compose -f docker-compose.prod.yml exec app npm run db:migrate

# Or create a one-off container
docker-compose -f docker-compose.prod.yml run --rm app npm run db:migrate
```

## Environment Variables Reference

### Development (Neon Local)

| Variable | Description | Example |
|----------|-------------|---------|
| `NEON_API_KEY` | Neon API key from console | `neon_api_xxx...` |
| `NEON_PROJECT_ID` | Your Neon project ID | `proud-rain-12345` |
| `PARENT_BRANCH_ID` | Parent branch for ephemeral branches | `main` |
| `DATABASE_URL` | Connection to Neon Local | `postgres://neon:npg@localhost:5432/neondb?sslmode=require` |

### Production (Neon Cloud)

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | Neon Cloud connection string | `postgres://user:pass@ep-xxx.neon.tech/neondb?sslmode=require` |
| `NODE_ENV` | Node environment | `production` |
| `LOG_LEVEL` | Logging level | `warn` or `error` |

## Troubleshooting

### Issue: Neon Local fails to start

**Symptoms**: `neon-local` container exits immediately

**Solutions**:
1. Verify your `NEON_API_KEY` and `NEON_PROJECT_ID` are correct
2. Check that `PARENT_BRANCH_ID` exists in your Neon project
3. View logs: `docker-compose -f docker-compose.dev.yml logs neon-local`

### Issue: App can't connect to database

**Symptoms**: Connection refused or timeout errors

**Solutions**:
1. Ensure `neon-local` container is healthy: `docker-compose -f docker-compose.dev.yml ps`
2. Check the `DATABASE_URL` uses the correct service name (`neon-local` in Docker network)
3. Verify SSL mode is set correctly: `?sslmode=require`

### Issue: Hot reload not working in development

**Solutions**:
1. Verify volumes are mounted correctly in `docker-compose.dev.yml`
2. Check that your `--watch` flag is working: `npm run dev` should use Node's watch mode
3. On Windows, ensure Docker Desktop has proper file sharing permissions

### Issue: Self-signed certificate errors (JavaScript apps)

If using `pg` or `postgres` libraries, add to your database client config:

```javascript
import { neon } from '@neondatabase/serverless';

const sql = neon(process.env.DATABASE_URL, {
  ssl: { rejectUnauthorized: false }
});
```

### Issue: Production container won't start

**Solutions**:
1. Check logs: `docker-compose -f docker-compose.prod.yml logs app`
2. Verify `DATABASE_URL` is set and correct
3. Test connection to Neon Cloud: `pg_isready -d "your_connection_string"`
4. Ensure migrations have been run

### Issue: Port already in use

**Symptoms**: Error binding to port 3000 or 5432

**Solutions**:
```bash
# Find process using the port (Windows PowerShell)
netstat -ano | findstr :3000

# Stop conflicting containers
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.prod.yml down
```

## Best Practices

### Security

1. **Never commit** `.env.development` or `.env.production` with real credentials
2. Use `.env.example` as a template
3. Rotate API keys regularly
4. Use different Neon projects for dev/staging/production
5. Enable Neon IP allowlisting in production

### Performance

1. Use ephemeral branches in development to keep your data fresh
2. Set appropriate connection pool sizes for production
3. Monitor Neon metrics in the console
4. Use Neon's autoscaling in production

### Development Workflow

1. Start with ephemeral branches (`PARENT_BRANCH_ID`)
2. Use specific branches (`BRANCH_ID`) when testing with specific data
3. Run migrations before starting the app
4. Clean up old branches periodically

## Additional Resources

- [Neon Local Documentation](https://neon.com/docs/local/neon-local)
- [Neon Console](https://console.neon.tech)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Drizzle ORM Documentation](https://orm.drizzle.team/)

## Support

For issues specific to:
- **Neon Database**: https://neon.tech/docs/introduction
- **Docker**: https://docs.docker.com/
- **This Application**: [Open an issue in the repository]
