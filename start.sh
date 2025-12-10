#!/bin/bash

# Quick start script for code-server with VSC marketplace
# This script helps you get started quickly with code-server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Code-Server Quick Start${NC}"
echo "======================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed${NC}"

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Ask user for password
echo -e "${YELLOW}Configuration${NC}"
read -p "Enter password for code-server (default: changeme): " PASSWORD
PASSWORD=${PASSWORD:-changeme}

# Ask for port
read -p "Enter port to run code-server on (default: 8080): " PORT
PORT=${PORT:-8080}

# Create project directory
echo ""
echo -e "${YELLOW}Setting up project directory...${NC}"
mkdir -p ./project
echo -e "${GREEN}✓ Project directory created${NC}"

# Pull the image
echo ""
echo -e "${YELLOW}Pulling code-server image...${NC}"
docker pull ghcr.io/pashkadez/code-server-image:latest

# Stop and remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^code-server$"; then
    echo ""
    echo -e "${YELLOW}Removing existing code-server container...${NC}"
    docker stop code-server 2>/dev/null || true
    docker rm code-server 2>/dev/null || true
fi

# Run the container
echo ""
echo -e "${YELLOW}Starting code-server...${NC}"
docker run -d \
  --name code-server \
  -p ${PORT}:8080 \
  -e PASSWORD="${PASSWORD}" \
  -e SUDO_PASSWORD="${PASSWORD}" \
  -v "$(pwd)/project:/home/coder/project" \
  -v code-server-config:/home/coder/.local/share/code-server \
  -v code-server-data:/home/coder/.config \
  ghcr.io/pashkadez/code-server-image:latest

# Wait for container to start
echo -e "${YELLOW}Waiting for code-server to start...${NC}"
sleep 5

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^code-server$"; then
    echo ""
    echo -e "${GREEN}======================================"
    echo "✓ Code-Server is now running!"
    echo "======================================${NC}"
    echo ""
    echo -e "Access code-server at: ${GREEN}http://localhost:${PORT}${NC}"
    echo -e "Password: ${GREEN}${PASSWORD}${NC}"
    echo ""
    echo "Your project files are in: ./project"
    echo ""
    echo "Useful commands:"
    echo "  - View logs:    docker logs -f code-server"
    echo "  - Stop server:  docker stop code-server"
    echo "  - Start server: docker start code-server"
    echo "  - Remove server: docker stop code-server && docker rm code-server"
    echo ""
else
    echo -e "${RED}Error: Failed to start code-server${NC}"
    echo "Check logs with: docker logs code-server"
    exit 1
fi
