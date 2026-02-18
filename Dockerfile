# Multi-stage build for {{PROJECT_NAME}}
# Supports multi-arch: linux/amd64, linux/arm64

# --- Build stage ---
FROM python:3.14-slim AS builder

WORKDIR /app

# Install dependencies first for better caching
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy source
COPY . .

# --- Runtime stage ---
FROM python:3.14-slim

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app .

USER 65532:65532

ENTRYPOINT ["python", "-m", "src"]
