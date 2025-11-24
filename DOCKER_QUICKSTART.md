# Docker Quick Start Guide

## 🚀 Development (Neon Local)

### First-time Setup

1. **Get Neon Credentials** from https://console.neon.tech:
   - API Key (Account Settings → API Keys)
   - Project ID (Project Settings)

2. **Configure Environment**:
   ```bash
   # Copy and edit .env.development
   cp .env.example .env.development
   
   # Add your credentials:
   NEON_API_KEY=your_actual_api_key
   NEON_PROJECT_ID=your_actual_project_id
   PARENT_BRANCH_ID=main
   ```

3. **Start Development**:
   ```bash
   docker-compose -f docker-compose.dev.yml --env-file .env.development up
   ```

4. **Access**:
   - App: http://localhost:3000
   - Database: localhost:5432

### Daily Development Commands

```bash
# Start (creates fresh ephemeral branch)
docker-compose -f docker-compose.dev.yml --env-file .env.development up -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f app

# Run migrations
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate

# Stop (deletes ephemeral branch)
docker-compose -f docker-compose.dev.yml down
```

## 🏭 Production (Neon Cloud)

### First-time Setup

1. **Get Production Database URL** from Neon Console:
   - Format: `postgres://user:password@ep-xxx.neon.tech/neondb?sslmode=require`

2. **Configure Environment**:
   ```bash
   # Create .env.production
   DATABASE_URL=postgres://user:password@your-project.neon.tech/neondb?sslmode=require
   NODE_ENV=production
   PORT=3000
   LOG_LEVEL=warn
   ```

3. **Deploy**:
   ```bash
   # Build and start
   docker-compose -f docker-compose.prod.yml --env-file .env.production up -d
   
   # Run migrations
   docker-compose -f docker-compose.prod.yml exec app npm run db:migrate
   ```

### Production Commands

```bash
# View logs
docker-compose -f docker-compose.prod.yml logs -f app

# Check health
docker-compose -f docker-compose.prod.yml ps

# Restart
docker-compose -f docker-compose.prod.yml restart app

# Stop
docker-compose -f docker-compose.prod.yml down
```

## 📝 Key Differences

| Feature | Development | Production |
|---------|-------------|------------|
| Database | Neon Local (ephemeral branches) | Neon Cloud |
| Connection | `neon-local:5432` | `*.neon.tech` |
| Branch Lifecycle | Auto-created/deleted | Persistent |
| SSL Certificate | Self-signed | Valid CA |
| Hot Reload | ✅ Enabled | ❌ Disabled |
| Build Target | `development` | `production` |

## ⚠️ Important Notes

1. **Never commit** `.env.development` or `.env.production` with real credentials
2. Ephemeral branches are **deleted** when you run `docker-compose down`
3. Test migrations on a staging branch before production
4. Use different Neon projects for dev/prod

## 🆘 Troubleshooting

**Can't connect to database?**
```bash
# Check Neon Local is healthy
docker-compose -f docker-compose.dev.yml ps

# View Neon Local logs
docker-compose -f docker-compose.dev.yml logs neon-local
```

**Port already in use?**
```powershell
# Windows: Find process using port 3000
netstat -ano | findstr :3000

# Stop all Docker services
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.prod.yml down
```

For detailed documentation, see [DOCKER_DEPLOYMENT.md](./DOCKER_DEPLOYMENT.md)
