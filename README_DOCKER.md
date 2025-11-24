# Docker Deployment

This project supports Docker-based deployment with different configurations for development and production environments.

## Quick Start

### Development with Neon Local

```bash
# 1. Configure your Neon credentials
cp .env.example .env.development
# Edit .env.development with your Neon API Key and Project ID

# 2. Start the application
docker-compose -f docker-compose.dev.yml --env-file .env.development up

# 3. Access the application
# App: http://localhost:3000
# Database: localhost:5432
```

### Production with Neon Cloud

```bash
# 1. Configure production database
# Edit .env.production with your Neon Cloud connection string

# 2. Build and start
docker-compose -f docker-compose.prod.yml --env-file .env.production up -d

# 3. Run migrations
docker-compose -f docker-compose.prod.yml exec app npm run db:migrate
```

## Using Make Commands

For convenience, use the provided Makefile:

```bash
# Development
make dev-up          # Start development environment
make dev-logs        # View logs
make dev-migrate     # Run migrations
make dev-down        # Stop environment

# Production
make prod-build      # Build production image
make prod-up         # Start production environment
make prod-logs       # View logs
make prod-migrate    # Run migrations
make prod-down       # Stop environment

# See all commands
make help
```

## Architecture

### Development Environment
- **Neon Local**: Proxy that creates ephemeral database branches
- **App Container**: Node.js app with hot-reload enabled
- **Automatic Branching**: Fresh database branch on every start

### Production Environment
- **App Container**: Production-optimized Node.js app
- **Neon Cloud**: Direct connection to serverless Postgres
- **No Proxy**: Connects directly to neon.tech

## Environment Variables

### Development (.env.development)
```env
NEON_API_KEY=your_neon_api_key
NEON_PROJECT_ID=your_neon_project_id
PARENT_BRANCH_ID=main
DATABASE_URL=postgres://neon:npg@localhost:5432/neondb?sslmode=require
```

### Production (.env.production)
```env
DATABASE_URL=postgres://user:password@your-project.neon.tech/neondb?sslmode=require
NODE_ENV=production
LOG_LEVEL=warn
```

## Files Overview

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage build for dev and prod |
| `docker-compose.dev.yml` | Development with Neon Local |
| `docker-compose.prod.yml` | Production with Neon Cloud |
| `.env.development` | Development environment config |
| `.env.production` | Production environment config |
| `.dockerignore` | Excludes files from Docker build |
| `Makefile` | Convenient command shortcuts |

## Documentation

- **Quick Start**: [DOCKER_QUICKSTART.md](./DOCKER_QUICKSTART.md) - Fast setup guide
- **Complete Guide**: [DOCKER_DEPLOYMENT.md](./DOCKER_DEPLOYMENT.md) - Detailed documentation
- **Neon Local Docs**: https://neon.com/docs/local/neon-local

## Key Features

✅ **Ephemeral Branches**: Fresh database for each development session  
✅ **Hot Reload**: Code changes reflected instantly in development  
✅ **Multi-stage Builds**: Optimized images for each environment  
✅ **Health Checks**: Automatic container health monitoring  
✅ **Resource Limits**: Production containers have defined limits  
✅ **Security**: Non-root user in production, secrets via env vars

## Next Steps

1. Get your Neon credentials from https://console.neon.tech
2. Follow the [Quick Start Guide](./DOCKER_QUICKSTART.md)
3. Read the [Complete Deployment Guide](./DOCKER_DEPLOYMENT.md)
4. Start developing with `make dev-up`
