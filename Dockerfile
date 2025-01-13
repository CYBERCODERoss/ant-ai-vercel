# Use the latest version of the official Python image with a slim variant
FROM python:3.11-slim

# Set an environment variable to prevent Python from writing .pyc files to disk and to buffer stdout and stderr
ENV PYTHONDONTWRITEBYTECODE=1 
ENV PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Install system dependencies for running the application
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

# Add Poetry to PATH
ENV PATH="/root/.local/bin:$PATH"

# Copy the entire project to the working directory
COPY . /app

# Install Python dependencies using Poetry
RUN poetry config virtualenvs.create false \
    && poetry install --without dev

# Create necessary directories
RUN mkdir -p logs notebooks

# Configure Streamlit
RUN mkdir -p /root/.streamlit
RUN echo "\
[server]\n\
enableCORS = false\n\
enableXsrfProtection = false\n\
" > /root/.streamlit/config.toml

# Default port for Heroku
ENV PORT=8501
ENV STREAMLIT_SERVER_PORT=$PORT
ENV STREAMLIT_SERVER_ADDRESS="0.0.0.0"

# Run the Streamlit application
CMD streamlit run src/ant_ai/Get_Started.py