# Stage 1: Browser and build tools installation
FROM python:3.11.4-slim-bullseye AS install-browser

# Install browser dependencies in separate steps to improve build resilience
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Chromium and Firefox from Debian repositories (works on both amd64 and arm64)
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    chromium-driver \
    firefox-esr \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Selenium
RUN pip install --no-cache-dir selenium==4.15.2 webdriver-manager==4.0.1

# Install geckodriver based on architecture
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then \
       wget -q https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz && \
       tar -xzf geckodriver-v0.33.0-linux64.tar.gz && \
       chmod +x geckodriver && \
       mv geckodriver /usr/local/bin/ && \
       rm geckodriver-v0.33.0-linux64.tar.gz; \
    elif [ "$ARCH" = "arm64" ]; then \
       wget -q https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux-aarch64.tar.gz && \
       tar -xzf geckodriver-v0.33.0-linux-aarch64.tar.gz && \
       chmod +x geckodriver && \
       mv geckodriver /usr/local/bin/ && \
       rm geckodriver-v0.33.0-linux-aarch64.tar.gz; \
    fi

# Stage 2: Python dependencies installation
FROM install-browser AS gpt-researcher-install

ENV PIP_ROOT_USER_ACTION=ignore
WORKDIR /usr/src/app

# Copy and install Python dependencies in a single layer to optimize cache usage
COPY ./requirements.txt ./requirements.txt
COPY ./multi_agents/requirements.txt ./multi_agents/requirements.txt

RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -r multi_agents/requirements.txt

# Stage 3: Final stage with non-root user and app
FROM gpt-researcher-install AS gpt-researcher

# Create a non-root user for security
RUN useradd -ms /bin/bash gpt-researcher && \
    chown -R gpt-researcher:gpt-researcher /usr/src/app && \
    # Add these lines to create and set permissions for outputs directory
    mkdir -p /usr/src/app/outputs && \
    chown -R gpt-researcher:gpt-researcher /usr/src/app/outputs && \
    chmod 777 /usr/src/app/outputs
    
USER gpt-researcher
WORKDIR /usr/src/app

# Copy the rest of the application files with proper ownership
COPY --chown=gpt-researcher:gpt-researcher ./ ./

# Expose the application's port
EXPOSE 8000

# Define the default command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
