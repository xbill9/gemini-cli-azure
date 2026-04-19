# Makefile for AI Course Creator (Multi-Agent System)

# Use the current python3 from environment
PYTHON_CMD ?= $(shell which python3)

# Set PYTHONPATH to include the project root for shared modules
export PYTHONPATH := $(shell pwd):$(PYTHONPATH)

# Environment variables for local development
export GOOGLE_GENAI_USE_VERTEXAI = False
export LOG_LEVEL = DEBUG
export GENAI_MODEL = gemini-2.5-flash

# Azure Configuration
AZ_LOCATION ?= westus2
HOSTNAME_ID := $(shell hostname | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-10)
AZ_ACR_NAME ?= adkacr$(HOSTNAME_ID)v2
AZ_RESOURCE_GROUP_ACI ?= adk-rg-aci

.PHONY: install start run run-local restart-local local frontend lint test test-researcher test-judge test-content-builder test-orchestrator researcher-local judge-local content-builder-local orchestrator-local backend-local frontend-local agents-local stop-local start-local check-frontend e2e-test-aci deploy deploy-aci destroy-aci status-aci status endpoint-aci endpoint az-status clean help az-destroy-aci aci-status check-local az-login acr-login acr-create

az-login:
	@echo "Logging in to Azure..."
	@az login

acr-login:
	@echo "Logging in to Azure Container Registry..."
	@az acr login --name $(AZ_ACR_NAME)

acr-create:
	@RG=$${RG:-$(AZ_RESOURCE_GROUP_ACI)}; \
	echo "Ensuring Resource Group $$RG exists..." ; \
	az group create --name "$$RG" --location $(AZ_LOCATION) -o table ; \
	echo "Checking if ACR $(AZ_ACR_NAME) exists..." ; \
	az acr show --name $(AZ_ACR_NAME) --resource-group "$$RG" > /dev/null 2>&1 || \
		(echo "Creating ACR $(AZ_ACR_NAME)..." && \
		az acr create --name $(AZ_ACR_NAME) --resource-group "$$RG" --sku Basic --admin-enabled true -o table)

help:
	@echo "Available commands:"
	@echo "  --- Local Development ---"
	@echo "  install               - Install all dependencies for root, agents, and app"
	@echo "  start                 - Start all services locally (alias for start-local)"
	@echo "  stop                  - Stop all local services (alias for stop-local)"
	@echo "  run                   - Start all services locally"
	@echo "  status                - Show status of local services"
	@echo "  local                 - Show local service URLs"
	@echo "  test                  - Run all tests (pytest)"
	@echo "  lint                  - Run linting checks (ruff)"
	@echo "  --- Azure ACI ---"
	@echo "  deploy-aci            - Deploy all services to Azure Container Instances (ACI)"
	@echo "  destroy-aci           - Delete ACI resources"
	@echo "  status-aci            - Show ACI status (alias: az-status)"
	@echo "  endpoint-aci          - Show ACI service endpoint (alias: endpoint)"
	@echo "  test-e2e-aci          - Run ACI E2E test"
	@echo "  --- Shared Azure ---"
	@echo "  az-login              - Login to Azure CLI"
	@echo "  acr-login             - Login to ACR"
	@echo "  acr-create            - Create/Verify ACR and Resource Group"
	@echo "  clean                 - Remove caches and logs"

TEST_URL ?= http://localhost:8000
TEST_MESSAGE ?= "Create a short course about the history of the internet"
e2e-test:
	@echo "Running end-to-end test against $(TEST_URL)..."
	@curl -s -X POST $(TEST_URL)/api/chat_stream \
		-H "Content-Type: application/json" \
		-d '{"message": $(TEST_MESSAGE), "user_id": "e2e_test_user"}' \
		--no-buffer \
		|| (echo "E2E Test Failed: No valid response from $(TEST_URL)" && exit 1)
	@echo "\nE2E Test Completed successfully!"

e2e-test-aci:
	@ACI_URL=$$(./aci/endpoint-aci.sh | grep "http://" | tr -d '\n'); \
	if [ -z "$$ACI_URL" ]; then \
		echo "ERROR: Could not find course-creator ACI service URL. Is it deployed?"; \
		exit 1; \
	fi; \
	$(MAKE) e2e-test TEST_URL=$$ACI_URL

install:
	@echo "Installing root dependencies..."
	pip install -e ".[dev,lint]"
	@echo "Installing agent and app dependencies..."
	for dir in agents/* app; do (cd $$dir && pip install -e .); done
	@echo "Installing frontend dependencies..."
	cd app/frontend && npm install

run: start-local

start: start-local

run-local: start-local

restart-local: start-local

stop: stop-local

check-frontend:
	@if [ ! -d "app/dist" ]; then \
		echo "Frontend build missing. Building frontend..."; \
		$(MAKE) frontend; \
	fi

researcher-local:
	@echo "Starting Researcher agent locally on port 8001..."
	@/bin/bash -c "source .env 2>/dev/null || true; \
	$(PYTHON_CMD) -m shared.adk_app --host 0.0.0.0 --port 8001 --a2a agents/researcher"

judge-local:
	@echo "Starting Judge agent locally on port 8002..."
	@/bin/bash -c "source .env 2>/dev/null || true; \
	$(PYTHON_CMD) -m shared.adk_app --host 0.0.0.0 --port 8002 --a2a agents/judge"

content-builder-local:
	@echo "Starting Content Builder agent locally on port 8003..."
	@/bin/bash -c "source .env 2>/dev/null || true; \
	$(PYTHON_CMD) -m shared.adk_app --host 0.0.0.0 --port 8003 --a2a agents/content_builder"

orchestrator-local:
	@echo "Starting Orchestrator agent locally on port 8004..."
	@/bin/bash -c "source .env 2>/dev/null || true; \
	export RESEARCHER_AGENT_CARD_URL=http://localhost:8001/a2a/researcher/.well-known/agent-card.json; \
	export JUDGE_AGENT_CARD_URL=http://localhost:8002/a2a/judge/.well-known/agent-card.json; \
	export CONTENT_BUILDER_AGENT_CARD_URL=http://localhost:8003/a2a/content_builder/.well-known/agent-card.json; \
	$(PYTHON_CMD) -m shared.adk_app --host 0.0.0.0 --port 8004 agents/orchestrator"

agents-local: stop-local
	@echo "Starting all agents in background..."
	@nohup $(MAKE) researcher-local > researcher.log 2>&1 &
	@nohup $(MAKE) judge-local > judge.log 2>&1 &
	@nohup $(MAKE) content-builder-local > content_builder.log 2>&1 &
	@echo "Waiting for sub-agents to start..."
	@sleep 5
	@nohup $(MAKE) orchestrator-local > orchestrator.log 2>&1 &
	@echo "All agents started. Logs: researcher.log, judge.log, content_builder.log, orchestrator.log"

start-local: check-frontend agents-local
	@echo "Starting App Backend in background..."
	@nohup $(MAKE) backend-local > backend.log 2>&1 &
	@echo "Starting Frontend dev server in background..."
	@nohup $(MAKE) frontend-local > frontend.log 2>&1 &
	@echo "All services started. Logs: researcher.log, judge.log, content_builder.log, orchestrator.log, backend.log, frontend.log"
	@echo "Frontend: http://localhost:5173"
	@echo "Backend:  http://localhost:8000"

stop-local:
	@echo "Stopping any existing agent and server processes..."
	@pkill -9 -f "[s]hared[.]adk_app" 2>/dev/null || true
	@pkill -9 -f "[m]ain[.]py" 2>/dev/null || true
	@pkill -9 -f "[v]ite" 2>/dev/null || true

backend-local:
	@echo "Starting App Backend locally on port 8000..."
	@/bin/bash -c "source .env 2>/dev/null || true; \
	export AGENT_SERVER_URL=http://localhost:8004; \
	export AGENT_NAME=orchestrator; \
	export PORT=8000; \
	cd app && $(PYTHON_CMD) main.py"

frontend-local:
	@echo "Starting Frontend (Vite) dev server..."
	@/bin/bash -c "cd app/frontend && npm run dev -- --host 0.0.0.0"

frontend:
	make -C app build-frontend

lint:
	ruff check .

test:
	python -m pytest

test-researcher:
	./research_test.sh

test-judge:
	./judge_test.sh

test-orchestrator:
	python agents/orchestrator/test_orchestrator.py

test-content-builder:
	python agents/content_builder/tests/test_agent.py

deploy: deploy-aci

deploy-aci:
	./aci/deploy-aci.sh

deploy-group-aci:
	chmod +x aci/deploy-group.sh
	./aci/deploy-group.sh

destroy-aci:
	./aci/destroy-aci.sh

az-destroy-aci:
	@AZ_DEFAULTS_GROUP=$${AZ_DEFAULTS_GROUP:-"adk-rg-aci"}; \
	echo "Destroying Azure Resource Group $$AZ_DEFAULTS_GROUP..."; \
	echo "Resource Group name used: $$AZ_DEFAULTS_GROUP"; \
	az group delete --name "$$AZ_DEFAULTS_GROUP" --yes --no-wait; \
	echo "Resource Group deletion initiated."

status-aci:
	./aci/status-aci.sh

aci-status: status-aci

endpoint-aci:
	./aci/endpoint-aci.sh

status: check-local

local:
	@echo "--- Local Service URLs ---"
	@echo "Frontend: http://localhost:5173"
	@echo "Backend:  http://localhost:8000 (main app)"
	@echo "Agents:"
	@echo "  Researcher:      http://localhost:8001"
	@echo "  Judge:           http://localhost:8002"
	@echo "  Content Builder: http://localhost:8003"
	@echo "  Orchestrator:    http://localhost:8004"

check-local:
	@echo "Checking status of locally running agents and servers..."
	@echo "--- Network Status ---"
	@netstat -tulnp 2>/dev/null | grep -E "8000|8001|8002|8003|8004|5173" || echo "No services listening on expected ports (8000-8004, 5173)."
	@echo "--- Process Status ---"
	@ps aux | grep -E "[s]hared[.]adk_app|[m]ain[.]py|[v]ite" || echo "No matching processes found."

clean:
	@echo "Cleaning up caches and temporary files..."
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".ruff_cache" -exec rm -rf {} +
	find . -type d -name ".adk" -exec rm -rf {} +
	find . -type f -name "*.log" -delete
	@echo "Clean completed."

# Azure ACI Aliases
az-status: status-aci
endpoint: endpoint-aci
