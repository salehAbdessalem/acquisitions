.PHONY: help dev-up dev-down dev-logs dev-migrate dev-studio prod-up prod-down prod-logs prod-migrate clean

help: ## Show this help message
	@echo "Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development commands
dev-up: ## Start development environment with Neon Local
	docker-compose -f docker-compose.dev.yml --env-file .env.development up

dev-up-d: ## Start development environment in detached mode
	docker-compose -f docker-compose.dev.yml --env-file .env.development up -d

dev-down: ## Stop development environment
	docker-compose -f docker-compose.dev.yml down

dev-logs: ## View development logs
	docker-compose -f docker-compose.dev.yml logs -f app

dev-migrate: ## Run database migrations in development
	docker-compose -f docker-compose.dev.yml exec app npm run db:migrate

dev-generate: ## Generate database migrations in development
	docker-compose -f docker-compose.dev.yml exec app npm run db:generate

dev-studio: ## Open Drizzle Studio in development
	docker-compose -f docker-compose.dev.yml exec app npm run db:studio

dev-shell: ## Open shell in development app container
	docker-compose -f docker-compose.dev.yml exec app sh

# Production commands
prod-build: ## Build production image
	docker-compose -f docker-compose.prod.yml build

prod-up: ## Start production environment
	docker-compose -f docker-compose.prod.yml --env-file .env.production up -d

prod-down: ## Stop production environment
	docker-compose -f docker-compose.prod.yml down

prod-logs: ## View production logs
	docker-compose -f docker-compose.prod.yml logs -f app

prod-migrate: ## Run database migrations in production
	docker-compose -f docker-compose.prod.yml exec app npm run db:migrate

prod-restart: ## Restart production service
	docker-compose -f docker-compose.prod.yml restart app

prod-ps: ## Check production service status
	docker-compose -f docker-compose.prod.yml ps

prod-shell: ## Open shell in production app container
	docker-compose -f docker-compose.prod.yml exec app sh

# Cleanup commands
clean: ## Remove all containers, images, and volumes
	docker-compose -f docker-compose.dev.yml down -v
	docker-compose -f docker-compose.prod.yml down -v
	docker system prune -f

clean-all: ## Remove everything including unused images
	docker-compose -f docker-compose.dev.yml down -v --rmi all
	docker-compose -f docker-compose.prod.yml down -v --rmi all
	docker system prune -af
