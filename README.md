# Code-Server with VSC Marketplace Access

A Docker image for [code-server](https://github.com/coder/code-server) (VS Code in the browser) configured to access the official Visual Studio Code Marketplace, enabling you to install extensions like GitHub Copilot, Pylance, and other VSC-exclusive extensions.

## Features

- ✅ **Official VSC Marketplace Access**: Install any extension from the Visual Studio Code marketplace, including GitHub Copilot
- 🐳 **Docker Ready**: Pre-built Docker image available on GitHub Container Registry
- 🚀 **Multi-Platform Support**: Built for both `amd64` and `arm64` architectures
- 🔒 **Secure**: Password-protected access with configurable authentication
- 💾 **Persistent Storage**: Data and extensions persist across container restarts
- ⚙️ **Flexible Deployment**: Support for Docker, Docker Compose, and Kubernetes

## Quick Start

### One-Command Setup (Recommended)

For the fastest way to get started, use our quick start script:

```bash
# Clone the repository
git clone https://github.com/pashkadez/code-server-image.git
cd code-server-image

# Run the quick start script
./start.sh
```

The script will:
- ✅ Check Docker installation
- ✅ Pull the latest image
- ✅ Set up your project directory
- ✅ Start code-server with your chosen password and port
- ✅ Provide you with the access URL

### Prerequisites

- Docker installed on your system
- (Optional) Docker Compose for easier management
- (Optional) Kubernetes cluster for production deployments

## Installation Methods

### 1. Docker

#### Using Pre-built Image

```bash
# Create a project directory
mkdir -p ~/code-server-project

# Run code-server with proper volume mounts for extension persistence
docker run -d \
  --name code-server \
  -p 8080:8080 \
  -e PASSWORD="your-password" \
  -e SUDO_PASSWORD="your-sudo-password" \
  -v ~/code-server-project:/home/coder/project \
  -v code-server-config:/home/coder/.local/share/code-server \
  -v code-server-data:/home/coder/.config \
  ghcr.io/pashkadez/code-server-image:latest
```

> **⚠️ Important**: The volume mounts `-v code-server-config:/home/coder/.local/share/code-server` and `-v code-server-data:/home/coder/.config` are **required** to persist your installed extensions and settings across container restarts.

#### Building Locally

```bash
# Clone the repository
git clone https://github.com/pashkadez/code-server-image.git
cd code-server-image

# Build the image
docker build -t code-server-vsc .

# Run the container
docker run -d \
  --name code-server \
  -p 8080:8080 \
  -e PASSWORD="your-password" \
  -e SUDO_PASSWORD="your-sudo-password" \
  -v ~/code-server-project:/home/coder/project \
  -v code-server-config:/home/coder/.local/share/code-server \
  -v code-server-data:/home/coder/.config \
  code-server-vsc
```

Access code-server at `http://localhost:8080` and login with your configured password.

### 2. Docker Compose

#### Using Pre-built Image

1. Use the example configuration file (recommended):

```bash
# Copy the example configuration
cp docker-compose.example.yml docker-compose.yml

# Edit the configuration to set your password and preferences
nano docker-compose.yml  # or use your preferred editor
```

Or create a `docker-compose.yml` file manually:

```yaml
version: '3.8'

services:
  code-server:
    image: ghcr.io/pashkadez/code-server-image:latest
    container_name: code-server
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - PASSWORD=changeme
      - SUDO_PASSWORD=changeme
      - TZ=UTC
    volumes:
      # CRITICAL: These paths are required for extension persistence
      - code-server-config:/home/coder/.local/share/code-server
      - code-server-data:/home/coder/.config
      - ./project:/home/coder/project

volumes:
  code-server-config:
  code-server-data:
```

2. Start the service:

```bash
docker-compose up -d
```

> **💡 Tip**: See `docker-compose.example.yml` for a fully documented configuration with all available options and detailed explanations.

#### Using Local Build

1. Clone this repository:

```bash
git clone https://github.com/pashkadez/code-server-image.git
cd code-server-image
```

2. Create a project directory:

```bash
mkdir -p project
```

3. Edit the `docker-compose.yml` to uncomment the build section:

```yaml
services:
  code-server:
    build:
      context: .
      dockerfile: Dockerfile
    # Comment out or remove the image line
    # image: ghcr.io/pashkadez/code-server-image:latest
```

4. Start the service:

```bash
docker-compose up -d
```

5. View logs:

```bash
docker-compose logs -f code-server
```

6. Stop the service:

```bash
docker-compose down
```

Access code-server at `http://localhost:8080`.

### 3. Kubernetes

#### Prerequisites

- A running Kubernetes cluster
- `kubectl` configured to access your cluster
- (Optional) An Ingress controller for external access
- (Optional) cert-manager for TLS certificates

#### Deployment Steps

1. Download the Kubernetes manifests:

```bash
curl -O https://raw.githubusercontent.com/pashkadez/code-server-image/main/kubernetes/deployment.yml
```

Or clone the repository:

```bash
git clone https://github.com/pashkadez/code-server-image.git
cd code-server-image/kubernetes
```

2. **Important**: Edit `deployment.yml` to customize:
   - Change the passwords in the Secret
   - Update the Ingress host to your domain
   - Configure TLS if needed
   - Adjust storage sizes based on your needs
   - Configure resource limits based on your cluster

3. Apply the manifests:

```bash
kubectl apply -f kubernetes/deployment.yml
```

4. Verify the deployment:

```bash
# Check if pods are running
kubectl get pods -n code-server

# Check service status
kubectl get svc -n code-server

# Check ingress
kubectl get ingress -n code-server
```

5. Access code-server:

- **With Ingress**: Access via your configured domain (e.g., `https://code-server.example.com`)
- **Port Forward** (for testing):

```bash
kubectl port-forward -n code-server svc/code-server 8080:8080
```

Then access at `http://localhost:8080`

6. View logs:

```bash
kubectl logs -n code-server -l app=code-server -f
```

7. Clean up:

```bash
kubectl delete -f kubernetes/deployment.yml
```

#### Kubernetes Configuration Details

The Kubernetes deployment includes:

- **Namespace**: Isolated `code-server` namespace
- **Secret**: Stores passwords securely
- **PersistentVolumeClaims**: 
  - `code-server-data` (10Gi) - Project files
  - `code-server-config` (5Gi) - Extensions and configuration
- **Deployment**: Single replica with resource limits
- **Service**: ClusterIP service on port 8080
- **Ingress**: External access configuration (needs customization)

#### Advanced Kubernetes Options

**Using a Different Storage Class:**

```yaml
spec:
  storageClassName: your-storage-class
  accessModes:
    - ReadWriteOnce
```

**Enabling TLS with cert-manager:**

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - code-server.example.com
    secretName: code-server-tls
```

**Scaling** (Note: code-server is designed for single-user, so replicas > 1 requires session affinity):

```yaml
spec:
  replicas: 1  # Keep at 1 for single user
```

**Resource Tuning:**

```yaml
resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "4000m"
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PASSWORD` | Password for code-server web interface | `changeme` |
| `SUDO_PASSWORD` | Password for sudo commands inside container | `changeme` |
| `TZ` | Timezone setting | `UTC` |

### Volume Mounts

⚠️ **IMPORTANT**: To persist extensions and settings across container restarts, you **must** mount these specific paths:

| Path | Purpose | Required for Extensions |
|------|---------|------------------------|
| `/home/coder/project` | Your workspace/project files | No |
| `/home/coder/.local/share/code-server` | **Extensions and code-server configuration** | **YES** ✓ |
| `/home/coder/.config` | User configuration data | **YES** ✓ |

**Example volume configuration:**
```yaml
volumes:
  # Named volumes (recommended for extensions persistence)
  - code-server-config:/home/coder/.local/share/code-server
  - code-server-data:/home/coder/.config
  # Bind mount for your project files
  - ./project:/home/coder/project
```

**Or using bind mounts:**
```yaml
volumes:
  # Bind mounts (use absolute paths)
  - /home/user/code-server/config:/home/coder/.local/share/code-server
  - /home/user/code-server/data:/home/coder/.config
  - /home/user/code-server/project:/home/coder/project
```

❌ **Common Mistake**: Mounting to `/config` instead of `/home/coder/.local/share/code-server` will NOT persist extensions!

## Installing Extensions

### GitHub Copilot

1. Access your code-server instance
2. Open the Extensions panel (Ctrl+Shift+X)
3. Search for "GitHub Copilot"
4. Click Install
5. Sign in with your GitHub account
6. Authorize the extension

### Other Extensions

Thanks to the VSC marketplace configuration, you can install any extension available in the Visual Studio Code marketplace, including:

- Python (Pylance)
- ESLint
- Prettier
- Docker
- GitLens
- Remote Development extensions
- And thousands more...

## Security Considerations

⚠️ **Important Security Notes:**

1. **Change Default Passwords**: Always change the default passwords in production
2. **Use HTTPS**: Configure TLS/SSL for production deployments
3. **Network Security**: Restrict access using firewalls or network policies
4. **Keep Updated**: Regularly update the image to get security patches
5. **Secrets Management**: Use Kubernetes secrets or Docker secrets for sensitive data

## Troubleshooting

### Extensions Not Persisting After Restart

If your installed extensions disappear after restarting the container, this is almost always due to incorrect volume mounts.

**Problem**: Extensions are stored in `/home/coder/.local/share/code-server/extensions` but your volume is mounted to the wrong path.

**Solution**: Ensure you have the correct volume mounts:

```yaml
volumes:
  # CORRECT - This will persist extensions
  - code-server-config:/home/coder/.local/share/code-server
  - code-server-data:/home/coder/.config
  - ./project:/home/coder/project
```

**Common mistakes to avoid:**
```yaml
# ❌ WRONG - Mounting to /config instead of /home/coder/.local/share/code-server
- /home/user/config:/config

# ❌ WRONG - Only mounting workspace without config directories
- /home/user/workspace:/home/coder/project

# ✓ CORRECT - Using named Docker volumes (recommended)
- code-server-config:/home/coder/.local/share/code-server
- code-server-data:/home/coder/.config

# ✓ CORRECT - Using bind mounts with correct paths
- /home/user/code-server-config:/home/coder/.local/share/code-server
- /home/user/code-server-data:/home/coder/.config
```

**To verify your extensions are being persisted:**

1. Install an extension in code-server
2. Check if the extension files are in the mounted volume:
   ```bash
   # For named volumes
   docker volume inspect code-server-config
   
   # For bind mounts
   ls -la /home/user/code-server-config/extensions
   ```
3. Restart the container:
   ```bash
   docker restart code-server
   ```
4. The extension should still be installed after restart

**To migrate from incorrect configuration:**

If you've been using incorrect volume mounts and want to keep your extensions:

1. Install your extensions with the OLD configuration
2. Copy the extensions from the container:
   ```bash
   docker cp code-server:/home/coder/.local/share/code-server /home/user/code-server-backup
   ```
3. Stop and remove the container:
   ```bash
   docker stop code-server
   docker rm code-server
   ```
4. Update your docker-compose.yml with correct volume mounts
5. Restore the extensions:
   ```bash
   # If using bind mounts
   cp -r /home/user/code-server-backup/* /home/user/code-server-config/
   
   # If using named volumes, start the container first, then:
   docker cp /home/user/code-server-backup/. code-server:/home/coder/.local/share/code-server/
   docker exec -u root code-server chown -R coder:coder /home/coder/.local/share/code-server
   ```
6. Restart the container

### Cannot Install Extensions

If you can't install extensions from the VSC marketplace:

1. Check that the container started successfully:
   ```bash
   docker logs code-server
   ```

2. Verify the product.json configuration is in place:
   ```bash
   docker exec code-server cat /usr/lib/code-server/lib/vscode/product.json
   ```

### Permission Issues

If you encounter permission errors:

```bash
# Fix ownership of mounted volumes
docker exec -u root code-server chown -R coder:coder /home/coder
```

### Container Won't Start

1. Check Docker logs:
   ```bash
   docker logs code-server
   ```

2. Verify port 8080 is not already in use:
   ```bash
   netstat -tulpn | grep 8080
   ```

### Kubernetes Pod Issues

```bash
# Describe the pod to see events
kubectl describe pod -n code-server -l app=code-server

# Check pod logs
kubectl logs -n code-server -l app=code-server

# Check PVC status
kubectl get pvc -n code-server
```

## Frequently Asked Questions (FAQ)

### Q: Will my installed extensions persist after container restart?

**A: Yes**, but **only if** you have the correct volume mounts configured. You need these two volume mounts:

```yaml
volumes:
  - code-server-config:/home/coder/.local/share/code-server  # ← Stores extensions
  - code-server-data:/home/coder/.config                      # ← Stores settings
```

Without these mounts, extensions will be lost when the container is restarted or recreated.

### Q: I'm using `/config` as a mount point - will my extensions persist?

**A: No**. Mounting to `/config` will **not** work. You must mount to `/home/coder/.local/share/code-server` for extensions to persist. See the [Extensions Not Persisting](#extensions-not-persisting-after-restart) troubleshooting section for the correct configuration.

### Q: What's the difference between named volumes and bind mounts?

**Named volumes** (recommended):
```yaml
volumes:
  - code-server-config:/home/coder/.local/share/code-server
```
- Managed by Docker
- Easier to use
- Better for portability
- Good for extension storage

**Bind mounts**:
```yaml
volumes:
  - /home/user/code-server-config:/home/coder/.local/share/code-server
```
- Maps to a specific host directory
- Requires absolute paths
- Good for project files you want to access from the host
- Requires manual directory creation

### Q: How do I check if my extensions are being persisted?

1. Install an extension in code-server
2. Restart the container: `docker restart code-server`
3. Check if the extension is still there

If extensions disappear, your volume mounts are incorrect.

### Q: Can I use the same project directory from my host machine?

**A: Yes!** That's exactly what the project mount is for:

```yaml
volumes:
  - ./project:/home/coder/project           # Use relative path
  # OR
  - /home/user/my-code:/home/coder/project  # Use absolute path
```

The two config volumes should still use named volumes for best results.

### Q: Do I need all three volume mounts?

- `/home/coder/.local/share/code-server` - **Required** for extensions ✓
- `/home/coder/.config` - **Required** for settings ✓  
- `/home/coder/project` - Optional, but recommended for project files

### Q: What happens if I don't mount the config directories?

Your extensions and settings will be lost every time you:
- Restart the container
- Update the container
- Recreate the container with `docker-compose up -d`

### Q: Can I access the host's Docker daemon from within code-server?

**A: Yes!** You can mount the Docker socket to run Docker commands from code-server's terminal.

**⚠️ Security Warning**: Mounting the Docker socket gives the container full access to your Docker daemon, which is equivalent to root access on the host. Only do this if you trust the code you'll be running.

**Configuration:**

```yaml
services:
  code-server:
    image: ghcr.io/pashkadez/code-server-image:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # Mount Docker socket
      - code-server-config:/home/coder/.local/share/code-server
      - code-server-data:/home/coder/.config
      - ./project:/home/coder/project
```

**Additional setup required:**

A complete example Dockerfile is provided in the repository as `Dockerfile.docker-cli`. You can use it directly:

```bash
# Build the image with Docker CLI support
docker build -f Dockerfile.docker-cli -t code-server-with-docker .

# Or match your host's docker group GID (recommended for better permissions):
docker build -f Dockerfile.docker-cli \
  --build-arg DOCKER_GID=$(getent group docker | cut -d: -f3) \
  -t code-server-with-docker .

# Run with Docker socket mounted
docker run -d \
  --name code-server \
  -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v code-server-config:/home/coder/.local/share/code-server \
  -v code-server-data:/home/coder/.config \
  -v ./project:/home/coder/project \
  code-server-with-docker
```

Or with Docker Compose - update your `docker-compose.yml`:

```yaml
services:
  code-server:
    build:
      context: .
      dockerfile: Dockerfile.docker-cli
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - code-server-config:/home/coder/.local/share/code-server
      - code-server-data:/home/coder/.config
      - ./project:/home/coder/project
```

**Customization:**

If you need to customize the Docker group GID to match your host system, see the `Dockerfile.docker-cli` file which includes detailed comments about adjusting the GID. You can determine your host's docker group GID with:

```bash
getent group docker | cut -d: -f3
```

Then update the Dockerfile accordingly before building.

After this setup, you can run Docker commands from code-server's integrated terminal (e.g., `docker ps`, `docker build`, `docker-compose up`, etc.).

**Alternative - SSH into host:**

If you want full host terminal access via SSH:

1. Configure SSH access to your host machine
2. Use the "Remote - SSH" extension in code-server to connect to localhost or your host's IP
3. This provides complete host terminal access without security risks of Docker socket mounting

## Building Custom Images

To build a custom image with additional tools:

1. Create a custom Dockerfile:

```dockerfile
FROM ghcr.io/pashkadez/code-server-image:latest

USER root

# Install additional tools
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

USER coder
```

2. Build and run:

```bash
docker build -t my-custom-code-server .
docker run -d -p 8080:8080 my-custom-code-server
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is provided as-is. Please refer to code-server's license for the underlying software.

## Acknowledgments

- [code-server](https://github.com/coder/code-server) - VS Code in the browser
- [Visual Studio Code](https://code.visualstudio.com/) - The editor this is based on

## Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review existing [GitHub Issues](https://github.com/pashkadez/code-server-image/issues)
3. Open a new issue with:
   - Your deployment method (Docker/Docker Compose/Kubernetes)
   - Steps to reproduce the problem
   - Relevant logs
   - Your environment details