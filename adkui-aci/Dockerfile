FROM python:3.13-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PORT=8080
# Disable local storage for read-only container environments like Cloud Run or ACI
ENV ADK_DISABLE_LOCAL_STORAGE=1

# Set the working directory
WORKDIR /app

# Install system dependencies (e.g., libatomic1 is needed for some LLM/GenAI operations)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libatomic1 \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast package management
RUN pip install --no-cache-dir uv

# Copy requirements and install
COPY requirements.txt .
RUN uv pip install --no-cache-dir --system -r requirements.txt

# Copy the entire project into the container
COPY . .

# Expose the port used by the ADK web server
EXPOSE 8080

# Start the ADK Web UI, serving all agents in the current directory
CMD ["adk", "web", ".", "--host", "0.0.0.0", "--port", "8080"]
