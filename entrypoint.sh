#!/bin/bash
set -e

# Fix permissions for mounted volumes
# This ensures that the coder user can write to these directories
# even when they are mounted as Docker volumes

echo "Fixing permissions for code-server directories..."

# Create directories if they don't exist
mkdir -p /home/coder/.local/share/code-server
mkdir -p /home/coder/.config
mkdir -p /home/coder/project

# Fix ownership
chown -R coder:coder /home/coder/.local/share/code-server
chown -R coder:coder /home/coder/.config
chown -R coder:coder /home/coder/project

# Restore marketplace configuration if it doesn't exist
if [ ! -f "/home/coder/.local/share/code-server/coder.json" ]; then
    echo "Restoring marketplace configuration..."
    cat > /home/coder/.local/share/code-server/coder.json << 'EOF'
{
  "extensions": {
    "marketplace": {
      "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
      "itemUrl": "https://marketplace.visualstudio.com/items"
    }
  }
}
EOF
    chown coder:coder /home/coder/.local/share/code-server/coder.json
fi

echo "Permissions fixed. Starting code-server..."

# Switch to coder user and execute code-server
exec gosu coder code-server "$@"
