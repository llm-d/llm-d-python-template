# Project configuration
# TODO: Replace {{PROJECT_NAME}} with your project name
PROJECT_NAME ?= {{PROJECT_NAME}}
REGISTRY ?= ghcr.io/llm-d
IMAGE ?= $(REGISTRY)/$(PROJECT_NAME)
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
PLATFORMS ?= linux/amd64,linux/arm64
PYTHON ?= python3

.DEFAULT_GOAL := help

##@ General

.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: install
install: ## Install project and dev dependencies
	pip install -e ".[dev]"

.PHONY: test
test: ## Run tests with pytest
	pytest

.PHONY: test-coverage
test-coverage: ## Run tests with coverage report
	pytest --cov=src --cov-report=html --cov-report=term

.PHONY: lint
lint: ## Run linters (ruff check + format check)
	ruff check .
	ruff format --check .

.PHONY: fmt
fmt: ## Format code with ruff
	ruff check --fix .
	ruff format .

.PHONY: pre-commit
pre-commit: ## Run pre-commit hooks on all files
	pre-commit run --all-files

##@ Container

.PHONY: image-build
image-build: ## Build multi-arch container image (local only)
	docker buildx build \
		--platform $(PLATFORMS) \
		--tag $(IMAGE):$(VERSION) \
		--tag $(IMAGE):latest \
		.

.PHONY: image-push
image-push: ## Build and push multi-arch container image
	docker buildx build \
		--platform $(PLATFORMS) \
		--push \
		--annotation "index:org.opencontainers.image.source=https://github.com/llm-d/$(PROJECT_NAME)" \
		--annotation "index:org.opencontainers.image.licenses=Apache-2.0" \
		--tag $(IMAGE):$(VERSION) \
		--tag $(IMAGE):latest \
		.

##@ CI Helpers

.PHONY: ci-lint
ci-lint: ## CI: install ruff and run linters
	pip install ruff
	ruff check .
	ruff format --check .

.PHONY: clean
clean: ## Remove build artifacts
	rm -rf dist/ build/ *.egg-info/ .pytest_cache/ htmlcov/ .coverage coverage.xml
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
