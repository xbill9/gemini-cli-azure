# Makefile for AI Course Creator (Multi-Agent System) - Fabric Edition

# Use the current python3 from environment
PYTHON_CMD ?= $(shell which python3)

# Set PYTHONPATH to include the project root for shared modules
export PYTHONPATH := $(shell pwd):$(PYTHONPATH)

# Environment variables for local development
export GOOGLE_GENAI_USE_VERTEXAI = False
export LOG_LEVEL = DEBUG
export GENAI_MODEL = gemini-2.5-flash

.PHONY: install start run run-local restart-local local frontend frontend-local lint test test-researcher test-judge test-content-builder test-orchestrator researcher-local judge-local content-builder-local orchestrator-local backend-local frontend-local agents-local stop-local start-local check-frontend e2e-test deploy destroy status endpoint clean help install-fabric-cli

help:
	@echo "Available commands:"
	@echo "  install               - Install all dependencies for root, agents, and app"
	@echo "  install-fabric-cli    - Install Microsoft Fabric CLI and Azure extension"
	@echo "  start                 - Start all services locally (alias for start-local)"
	@echo "  stop                  - Stop all local services (alias for stop-local)"
	@echo "  run                   - Start all services locally (alias for start-local)"
	@echo "  local                 - Show local service URLs"
	@echo "  status                - Show status of local services and Fabric deployment"
	@echo "  start-local           - Start all local services in background"
	@echo "  stop-local            - Stop all local processes"
	@echo "  test                  - Run all tests (pytest)"
	@echo "  test-researcher       - Test the Researcher agent directly"
	@echo "  test-judge            - Test the Judge agent directly"
	@echo "  test-orchestrator     - Test the Orchestrator logic"
	@echo "  lint                  - Run linting checks (ruff)"
	@echo "  deploy                - Deploy stacked agents to Azure Container Apps & Fabric"
	@echo "  destroy               - Delete Azure Resource Group and all resources"
	@echo "  endpoint              - Show public service endpoint"
	@echo "  clean                 - Remove caches and logs"

TEST_URL ?= http://localhost:8080
TEST_MESSAGE ?= "Create a short course about the history of the internet"
e2e-test:
	@echo "Running end-to-end test against $(TEST_URL)..."
	@curl -s -X POST $(TEST_URL)/api/chat_stream \
		-H "Content-Type: application/json" \
		-d '{"message": $(TEST_MESSAGE), "user_id": "e2e_test_user"}' \
		--no-buffer \
		|| (echo "E2E Test Failed: No valid response from $(TEST_URL)" && exit 1)
	@echo "\nE2E Test Completed successfully!"

install:
	@echo "Installing root dependencies..."
	pip install -e ".[dev,lint]"
	@echo "Installing agent dependencies..."
	for dir in agents/*; do (cd $$dir && pip install -e .); done
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

start-local: check-frontend stop-local
	@echo "Starting Unified App Backend in background..."
	@nohup $(PYTHON_CMD) -m unified_app.app > backend.log 2>&1 &
	@echo "Starting Frontend dev server in background..."
	@nohup /bin/bash -c "cd app/frontend && npm run dev -- --host 0.0.0.0" > frontend.log 2>&1 &
	@echo "All services started. Logs: backend.log, frontend.log"
	@echo "Frontend: http://localhost:5173"
	@echo "Backend:  http://localhost:8080"

stop-local:
	@echo "Stopping any existing server processes..."
	@pkill -9 -f "unified_app[.]app" 2>/dev/null || true
	@pkill -9 -f "[v]ite" 2>/dev/null || true

frontend:
	@echo "Building frontend..."
	@$(MAKE) -C app build-frontend

frontend-local:
	@echo "Starting Frontend (Vite) dev server..."
	@/bin/bash -c "cd app/frontend && npm run dev -- --host 0.0.0.0"

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

deploy:
	chmod +x fabric/deploy.sh
	./fabric/deploy.sh

destroy:
	chmod +x fabric/destroy.sh
	./fabric/destroy.sh

status:
	@$(MAKE) check-local
	@echo "\n--- Azure Fabric / ACA Status ---"
	@chmod +x fabric/status.sh
	@./fabric/status.sh

endpoint:
	@chmod +x fabric/endpoint.sh
	@./fabric/endpoint.sh

local:
	@echo "--- Local Service URLs ---"
	@echo "Frontend: http://localhost:5173"
	@echo "Backend:  http://localhost:8080 (unified app)"

check-local:
	@echo "Checking status of locally running servers..."
	@echo "--- Network Status ---"
	@netstat -tulnp 2>/dev/null | grep -E "8080|5173" || echo "No services listening on expected ports (8080, 5173)."
	@echo "--- Process Status ---"
	@ps aux | grep -E "unified_app[.]app|[v]ite" || echo "No matching processes found."

install-fabric-cli:
	@echo "Installing Microsoft Fabric CLI (ms-fabric-cli)..."
	pip install ms-fabric-cli
	@echo "Adding Azure CLI Fabric extension..."
	az extension add --name microsoft-fabric --yes

clean:
	@echo "Cleaning up caches and temporary files..."
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".ruff_cache" -exec rm -rf {} +
	find . -type d -name ".adk" -exec rm -rf {} +
	find . -type f -name "*.log" -delete
	rm -f fabric/WorkloadManifest.xml
	@echo "Clean completed."
