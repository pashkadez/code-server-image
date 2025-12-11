FROM codercom/code-server:latest

# Switch to root to install dependencies and configure
USER root

# Install additional tools and dependencies including gosu for proper user switching
RUN apt-get update && apt-get install -y \
    curl \
    git \
    sudo \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Create coder user with sudo privileges if it doesn't exist
RUN if ! id -u coder > /dev/null 2>&1; then \
    useradd -m -s /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
    fi

# Create necessary directories
RUN mkdir -p /home/coder/.local/share/code-server && \
    mkdir -p /home/coder/project && \
    chown -R coder:coder /home/coder

# Configure code-server to use official VSC marketplace
# This is the key configuration to enable GitHub Copilot and other VSC extensions
RUN echo '{\n\
  "extensions": {\n\
    "marketplace": {\n\
      "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",\n\
      "itemUrl": "https://marketplace.visualstudio.com/items"\n\
    }\n\
  }\n\
}' > /home/coder/.local/share/code-server/coder.json && \
    chown -R coder:coder /home/coder/.local

# Create product.json to enable VSC marketplace
RUN mkdir -p /usr/lib/code-server/lib/vscode && \
    echo '{\n\
  "extensionsGallery": {\n\
    "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",\n\
    "itemUrl": "https://marketplace.visualstudio.com/items",\n\
    "cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",\n\
    "controlUrl": "",\n\
    "recommendationsUrl": ""\n\
  }\n\
}' > /usr/lib/code-server/lib/vscode/product.json

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set environment variables
ENV PASSWORD="changeme" \
    SUDO_PASSWORD="changeme"

# Set working directory
WORKDIR /home/coder/project

# Expose code-server port
EXPOSE 8080

# Use entrypoint script to fix permissions and start code-server
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--bind-addr", "0.0.0.0:8080", "--auth", "password", "."]
