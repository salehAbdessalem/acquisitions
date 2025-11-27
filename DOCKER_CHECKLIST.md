# Docker Setup Checklist

Use this checklist to ensure you have everything configured correctly.

## Prerequisites ✓

- [ ] Docker Desktop installed (or Docker Engine on Linux)
- [ ] Docker Compose v2.0+ available
- [ ] Neon account created at https://console.neon.tech
- [ ] Project cloned and in the correct directory

## Neon Setup ✓

### Get Your Credentials

- [ ] Log in to https://console.neon.tech
- [ ] Navigate to **Account Settings → API Keys**
- [ ] Create a new API key (or copy existing)
- [ ] Copy your **NEON_API_KEY**
- [ ] Go to your project dashboard
- [ ] Copy your **NEON_PROJECT_ID** from project settings
- [ ] Note your default branch name (usually `main`)

## Development Setup ✓

### Configure Environment

- [ ] Copy `.env.example` to `.env.development`

  ```bash
  cp .env.example .env.development
  ```

- [ ] Edit `.env.development` and fill in:
  - [ ] `NEON_API_KEY=your_actual_api_key`
  - [ ] `NEON_PROJECT_ID=your_actual_project_id`
  - [ ] `PARENT_BRANCH_ID=main` (or your default branch)

### Verify Configuration

- [ ] Open `.env.development` and confirm all values are set
- [ ] No placeholder values like `your_neon_api_key_here` remain
- [ ] File is in `.gitignore` (it is by default)

### First Start

- [ ] Open terminal in project directory
- [ ] Run: `docker-compose -f docker-compose.dev.yml --env-file .env.development up`
- [ ] Wait for both containers to start
- [ ] See "Listening on http://localhost:3000" message
- [ ] Open http://localhost:3000 in browser
- [ ] See "Hello from Acquisitions" message

### Run Database Migrations

- [ ] In a new terminal, run migrations:
  ```bash
  docker-compose -f docker-compose.dev.yml exec app npm run db:migrate
  ```
- [ ] Verify migrations completed successfully

### Test Development Workflow

- [ ] Make a change to `src/app.js` (e.g., edit the hello message)
- [ ] Refresh browser and see change immediately
- [ ] Hot reload is working! ✓

## Production Setup ✓

### Get Production Database URL

- [ ] Log in to Neon Console
- [ ] Go to your project dashboard
- [ ] Select your **production branch** (or create one)
- [ ] Click **Connection Details**
- [ ] Copy the connection string (starts with `postgres://`)

### Configure Production Environment

- [ ] Create `.env.production`:

  ```bash
  # Don't copy from example, create fresh
  touch .env.production
  ```

- [ ] Edit `.env.production` and add:
  - [ ] `DATABASE_URL=postgres://...your-neon-url...`
  - [ ] `NODE_ENV=production`
  - [ ] `PORT=3000`
  - [ ] `LOG_LEVEL=warn`

### Build and Test Production

- [ ] Build production image:

  ```bash
  docker-compose -f docker-compose.prod.yml build
  ```

- [ ] Start production container:

  ```bash
  docker-compose -f docker-compose.prod.yml --env-file .env.production up -d
  ```

- [ ] Run production migrations:

  ```bash
  docker-compose -f docker-compose.prod.yml exec app npm run db:migrate
  ```

- [ ] Check logs for errors:

  ```bash
  docker-compose -f docker-compose.prod.yml logs -f app
  ```

- [ ] Test production endpoint: http://localhost:3000

## Security Checklist ✓

- [ ] `.env.development` is NOT committed to git
- [ ] `.env.production` is NOT committed to git
- [ ] `.gitignore` contains `.env.*` pattern
- [ ] Different Neon API keys for dev/prod (recommended)
- [ ] Different Neon projects for dev/prod (recommended)
- [ ] Production DATABASE_URL uses SSL (`?sslmode=require`)

## Documentation Review ✓

- [ ] Read [DOCKER_QUICKSTART.md](./DOCKER_QUICKSTART.md) for quick commands
- [ ] Bookmark [DOCKER_DEPLOYMENT.md](./DOCKER_DEPLOYMENT.md) for reference
- [ ] Review [ARCHITECTURE.md](./ARCHITECTURE.md) to understand the system
- [ ] Check `make help` for command shortcuts

## Daily Development Checklist ✓

### Starting Your Day

- [ ] Start containers: `make dev-up` or full command
- [ ] Wait for healthy status
- [ ] Run any new migrations if needed
- [ ] Start coding!

### During Development

- [ ] Code changes auto-reload
- [ ] Check logs if issues: `make dev-logs`
- [ ] Run migrations after schema changes
- [ ] Each container restart creates fresh DB branch

### End of Day

- [ ] Stop containers: `make dev-down`
- [ ] Ephemeral branch is automatically deleted
- [ ] Commit your code changes (not .env files!)

## Troubleshooting Checklist ✓

### Container Won't Start

- [ ] Check Docker is running
- [ ] Check port 3000 is available: `netstat -ano | findstr :3000`
- [ ] Check port 5432 is available: `netstat -ano | findstr :5432`
- [ ] View container logs: `docker-compose -f docker-compose.dev.yml logs`

### Neon Local Issues

- [ ] Verify NEON_API_KEY is correct
- [ ] Verify NEON_PROJECT_ID is correct
- [ ] Check PARENT_BRANCH_ID exists in Neon Console
- [ ] Check Neon Local logs: `docker-compose -f docker-compose.dev.yml logs neon-local`

### Database Connection Issues

- [ ] Verify DATABASE_URL format
- [ ] Check neon-local container is healthy: `docker-compose -f docker-compose.dev.yml ps`
- [ ] Verify using service name (`neon-local:5432`) not `localhost`
- [ ] Check SSL mode is set: `?sslmode=require`

### Hot Reload Not Working

- [ ] Verify volumes are mounted (check docker-compose.dev.yml)
- [ ] Check file permissions (especially on Windows)
- [ ] Restart containers: `make dev-down && make dev-up`

## Common Commands Reference ✓

### Development

```bash
make dev-up          # Start dev environment
make dev-down        # Stop dev environment
make dev-logs        # View logs
make dev-migrate     # Run migrations
make dev-shell       # Open shell in container
```

### Production

```bash
make prod-build      # Build production image
make prod-up         # Start production
make prod-down       # Stop production
make prod-logs       # View logs
make prod-migrate    # Run migrations
```

### Cleanup

```bash
make clean           # Remove containers and volumes
make clean-all       # Remove everything including images
```

## Next Steps ✓

- [ ] Join Neon Discord for support: https://discord.gg/neon
- [ ] Star the Neon GitHub repo: https://github.com/neondatabase
- [ ] Explore Neon features (branching, point-in-time restore, etc.)
- [ ] Set up CI/CD with GitHub Actions
- [ ] Configure production deployment platform

## Need Help?

- **Neon Issues**: https://neon.tech/docs
- **Docker Issues**: https://docs.docker.com/
- **App Issues**: Check project README or open an issue

---

**Last Updated**: 2025-11-21

Keep this checklist handy during setup and share with team members!
