# single-container/Dockerfile - All-in-one container for Azure Functions
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies if needed
RUN apt-get update && apt-get install -y \
    curl \
    make \
    && rm -rf /var/lib/apt/lists/*

# Copy root requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy everything
COPY . .

# Install all components
RUN pip install --no-cache-dir --upgrade --force-reinstall google-adk a2a-sdk
RUN pip install --no-cache-dir ./shared
RUN pip install --no-cache-dir ./agents/researcher
RUN pip install --no-cache-dir ./agents/judge
RUN pip install --no-cache-dir ./agents/content_builder
RUN pip install --no-cache-dir ./agents/orchestrator
RUN pip install --no-cache-dir ./app

# Ensure frontend is built (or use existing dist if copied)
# RUN cd app && make build-frontend

# Make entrypoint executable
RUN chmod +x single-container/entrypoint.sh

# Expose the main port for Azure Functions
EXPOSE 8080

ENTRYPOINT ["/bin/bash", "single-container/entrypoint.sh"]
