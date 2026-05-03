# --- Stage 1: Build Frontend ---
FROM node:25-slim AS frontend-builder
WORKDIR /app/frontend
COPY app/frontend/package*.json ./
RUN npm install
COPY app/frontend/ ./
RUN npm run build

# --- Stage 2: Final Unified Image ---
FROM python:3.13-slim
WORKDIR /app

# Install root dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all source code (shared, agents, app, unified_app)
COPY . .

# Copy built frontend from Stage 1 into the expected directory
COPY --from=frontend-builder /app/dist /app/app/dist

# Set working directory to project root
WORKDIR /app

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV HOST 0.0.0.0

# Port for Cloud Run / ACA (default is 8080)
EXPOSE 8080

# Start the unified app
CMD ["python3", "-m", "unified_app.app"]
