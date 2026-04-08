# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Docker image wrapping [code-server](https://github.com/coder/code-server) (VS Code in the browser) with the official Visual Studio Code Marketplace configured. This enables extensions like GitHub Copilot that are normally blocked on code-server due to its open-source marketplace restriction.

The key trick: `product.json` at `/usr/lib/code-server/lib/vscode/product.json` and `coder.json` at `/home/coder/.local/share/code-server/coder.json` both point to `marketplace.visualstudio.com` instead of the default open-vsx.

## Key Architecture Decisions

- **Base image**: pinned to a specific tag (e.g. `codercom/code-server:4.114.1`). Renovate opens PRs when a new version is released — never manually edit the `FROM` line.
- **User model**: Runs as root in `entrypoint.sh`, uses `gosu coder` to drop privileges before exec-ing code-server. This is intentional — it allows the entrypoint to fix volume ownership at startup without slow recursive `chown` (it checks `stat -c '%U'` first).
- **Sudo**: optional. Set `SUDO_PASSWORD` to enable password-protected sudo for the `coder` user inside the container. If `SUDO_PASSWORD` is unset, no sudoers entry is created and sudo is unavailable.
- **Extension auto-install**: `entrypoint.sh` queries the VSC marketplace API on every start and installs/updates GitHub Copilot (pre-release), GitHub Copilot Chat (pre-release), and Claude Code (stable) into the extensions volume. First boot downloads ~50 MB; subsequent starts are a no-op if versions match.
- **Marketplace config survives volume mounts**: `entrypoint.sh` restores `coder.json` if a mounted volume overwrites it, ensuring the VSC marketplace config persists even after fresh volume mounts.
- **Multi-arch**: CI builds `linux/amd64` and `linux/arm64` via QEMU.

## Commands

```bash
# Build locally
docker build -t code-server-vsc .

# Run with local build (docker-compose.local.yml forces build:)
docker compose -f docker-compose.local.yml up -d

# Run with pre-built image from ghcr.io
docker compose up -d

# Quick interactive start (prompts for password/port)
./start.sh

# View logs
docker compose logs -f code-server

# Verify marketplace config is in place
docker exec code-server cat /usr/lib/code-server/lib/vscode/product.json
```

## CI/CD

`.github/workflows/docker-build.yml` pushes to `ghcr.io/pashkadez/code-server-image` on every push to `main`. Tags: `latest` (default branch), semver (`v*` tags), and branch name. PRs build but do not push.

## Deployment

- **Docker Compose** (`docker-compose.yml`): uses pre-built image; two named volumes for extensions (`code-server-config`) and user config (`code-server-data`), plus `./project` bind-mount for workspace.
- **Kubernetes** (`kubernetes/deployment.yml`): raw manifests — Namespace, Secret, two PVCs, Deployment, ClusterIP Service, Ingress. Change the Ingress host and Secret passwords before applying. No Helm chart exists.

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `PASSWORD` | required | code-server web UI password |
| `SUDO_PASSWORD` | unset | sudo password inside container; sudo is disabled when unset |
| `TZ` | `UTC` | Timezone |
