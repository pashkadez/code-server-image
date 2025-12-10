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

# Run code-server
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

1. Create a `docker-compose.yml` file:

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

| Path | Purpose |
|------|---------|
| `/home/coder/project` | Your workspace/project files |
| `/home/coder/.local/share/code-server` | Extensions and code-server configuration |
| `/home/coder/.config` | User configuration data |

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