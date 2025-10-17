# Docker environment for HeatExchangerMonitor pytest-bdd testing with mock sensors
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV USE_MOCK_SENSORS=true
ENV PYTHONPATH=/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements-test.txt* ./
COPY setup.py ./
COPY pyproject.toml* ./
COPY pytest.ini* ./

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip
RUN pip install pytest>=6.0 pytest-bdd>=6.0 pytest-mock>=3.0 pytest-cov>=4.0

# Copy source code
COPY therm/ ./therm/
COPY tests/ ./tests/
COPY features/ ./features/
COPY MANIFEST.in* ./

# Install the package in development mode
RUN pip install -e .

# Create volume mount point
VOLUME ["/app"]

# Default command to run tests
CMD ["pytest", "tests/test_temperature_collector.py", "-v", "--tb=short"]
