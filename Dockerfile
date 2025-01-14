# Build stage
FROM python:3.11.7-slim AS builder

# Set build environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    POETRY_VERSION=1.7.1 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_NO_INTERACTION=1 \
    PATH="/opt/poetry/bin:$PATH" \
    PIP_DEFAULT_TIMEOUT=100 \
    PIP_RETRIES=3

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry with retry logic
RUN for i in 1 2 3; do \
    curl -sSL https://install.python-poetry.org | POETRY_HOME=/opt/poetry python3 - && break || sleep 10; \
    done && \
    chmod +x /opt/poetry/bin/poetry

# Set working directory
WORKDIR /app

# Copy only dependency files
COPY pyproject.toml poetry.lock ./

# Configure Poetry for better network handling
RUN poetry config installer.max-workers 4 && \
    poetry config installer.parallel false

# Install runtime dependencies only with retry logic
RUN for i in 1 2 3; do \
    poetry install --only main --no-interaction --no-ansi --no-root && break || sleep 10; \
    done

# Final stage
FROM python:3.11.7-slim

# Set runtime environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    STREAMLIT_SERVER_PORT=8501 \
    STREAMLIT_SERVER_ADDRESS=0.0.0.0

WORKDIR /app

# Install only required runtime system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy Python packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# Copy only necessary application files
COPY src/ant_ai ./src/ant_ai
COPY definitions ./definitions

# Create required directories and configure Streamlit
RUN mkdir -p logs notebooks /root/.streamlit && \
    echo '\
[server]\n\
enableCORS = false\n\
enableXsrfProtection = false\n\
' > /root/.streamlit/config.toml

# Expose Streamlit port
EXPOSE 8501

# Run the application
CMD ["streamlit", "run", "src/ant_ai/Get_Started.py"]
