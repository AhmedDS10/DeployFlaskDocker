# Use official Ubuntu as base image
FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install basic packages
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    git \
    vim \
    sudo \
    python3 \
    python3-pip \
    python3-venv \
    build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy local files to container
COPY . /app

# Create Python virtual environment
RUN python3 -m venv venv

# Activate virtual environment, upgrade pip, and install requirements
RUN /bin/bash -c "source venv/bin/activate && \
    pip install --upgrade pip && \
    pip install -r requirements.txt"

# Set environment variable to automatically activate venv
ENV VIRTUAL_ENV=/app/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Copy entrypoint script
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Run Flask server by default
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
