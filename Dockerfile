# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install Poetry
RUN pip install poetry

# Configure poetry to create the virtual environment in the project directory
RUN poetry config virtualenvs.in-project true

# Install dependencies
RUN poetry install

# Make port 8501 available for Streamlit
EXPOSE 8501

# Run the Streamlit server using poetry run
CMD ["poetry", "run", "streamlit", "run", "./src/ant_ai/Get_Started.py"]
