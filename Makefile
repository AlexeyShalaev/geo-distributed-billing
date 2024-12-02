# Variables
DOCKER_COMPOSE = docker compose
PROJECT_NAME = geo_distributed_billing

# Default target
.PHONY: all
all: restart

# Stop and remove all containers
.PHONY: down
down:
	$(DOCKER_COMPOSE) down

# Remove unused containers and volumes
.PHONY: prune
prune:
	docker container prune -f
	docker volume prune -f

# Build and start containers
.PHONY: up
up:
	$(DOCKER_COMPOSE) up --build

# Restart the entire project with cleanup
.PHONY: restart
restart: down prune up

# Start services without building
.PHONY: start
start:
	$(DOCKER_COMPOSE) up

# Stop services without cleanup
.PHONY: stop
stop:
	$(DOCKER_COMPOSE) stop
