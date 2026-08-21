# Use a maintained Python slim base image
FROM python:3.12-slim-bookworm

# Install only necessary system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r litellm && useradd -r -g litellm -d /app -s /bin/bash litellm

# Set working directory
WORKDIR /app

# Install LiteLLM proxy with pinned version
# Using 1.84.0+ to address critical CVEs (CVE-2026-49468, CVE-2026-35029, etc.)
RUN pip install --no-cache-dir "litellm[proxy]==1.84.0"

# Copy configuration file
COPY --chown=litellm:litellm config.yaml /app/config.yaml

# Switch to non-root user
USER litellm

# Expose port (Render will provide PORT env var, default to 4000)
EXPOSE 4000

# Health check uses LiteLLM's built-in liveliness endpoint (no auth required)
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness', timeout=5)" || exit 1

# Start LiteLLM proxy
# Uses $PORT from Render, defaults to 4000 for local testing
CMD ["sh", "-c", "litellm --config /app/config.yaml --host 0.0.0.0 --port ${PORT:-4000}"]