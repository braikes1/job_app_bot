# ---- Build stage ----
FROM python:3.12-slim AS base

# Install system dependencies for Playwright + PostgreSQL
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright browsers
RUN playwright install chromium --with-deps

# Copy source
COPY . .

# Create necessary directories
RUN mkdir -p data/resumes logs

EXPOSE 8000

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
