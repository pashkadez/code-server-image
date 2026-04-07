#!/bin/bash
set -euo pipefail

# Fix permissions for mounted volumes
# This ensures that the coder user can write to these directories
# even when they are mounted as Docker volumes

echo "Fixing permissions for code-server directories..."

# Create directories if they don't exist
mkdir -p /home/coder/.local/share/code-server
mkdir -p /home/coder/.config
mkdir -p /home/coder/project

# Fix ownership only if needed (check directory ownership)
# This avoids slow recursive chown on large directory trees
if [ "$(stat -c '%U' /home/coder/.local/share/code-server)" != "coder" ]; then
    chown -R coder:coder /home/coder/.local/share/code-server
fi
if [ "$(stat -c '%U' /home/coder/.config)" != "coder" ]; then
    chown -R coder:coder /home/coder/.config
fi
if [ "$(stat -c '%U' /home/coder/project)" != "coder" ]; then
    chown -R coder:coder /home/coder/project
fi

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

# --- Managed extension installer ---
# Installs or updates a VS Code extension from the marketplace into the
# code-server volume. Runs as coder via gosu so extensions land in the
# correct user directory. Failures are non-fatal — container always starts.

# Detect the VS Code engine version that code-server exposes, used to skip
# extensions whose engine requirement exceeds what is installed.
VSCODE_ENGINE_MINOR=$(gosu coder code-server --version 2>/dev/null \
    | grep -oE 'Code [0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+$' \
    | cut -d'.' -f2 || true)
VSCODE_ENGINE_MINOR="${VSCODE_ENGINE_MINOR:-0}"

install_or_update_extension() {
    local publisher="$1"
    local ext_name="$2"
    local prerelease="${3:-false}"
    local ext_id="${publisher}.${ext_name}"

    echo "Checking extension: ${ext_id} (prerelease=${prerelease})..."

    # flags=17 returns all versions with properties (engine req, pre-release flag).
    # We always use this so we can filter by engine compatibility and pre-release status.
    local api_payload="{\"filters\":[{\"criteria\":[{\"filterType\":7,\"value\":\"${ext_id}\"}]}],\"flags\":17}"

    # Pick the first version that:
    #   - is pre-release (when requested) or any version (stable)
    #   - has an engine requirement satisfied by the running VS Code minor version
    # Engine values look like "^1.114.0"; we extract the minor and compare numerically.
    local engine_minor="$VSCODE_ENGINE_MINOR"
    local jq_filter
    if [ "$prerelease" = "true" ]; then
        jq_filter="[.results[0].extensions[0].versions[] |
          select(.properties != null) |
          select(.properties[] | select(.key == \"Microsoft.VisualStudio.Code.PreRelease\" and .value == \"true\")) |
          select((.properties | map(select(.key == \"Microsoft.VisualStudio.Code.Engine\")) | first | .value // \"^1.0.0\") |
            ltrimstr(\"^\") | ltrimstr(\"~\") | split(\".\")[1] | tonumber <= ${engine_minor})
        ][0].version"
    else
        jq_filter="[.results[0].extensions[0].versions[] |
          select(.properties != null) |
          select((.properties | map(select(.key == \"Microsoft.VisualStudio.Code.PreRelease\" and .value == \"true\")) | length) == 0) |
          select((.properties | map(select(.key == \"Microsoft.VisualStudio.Code.Engine\")) | first | .value // \"^1.0.0\") |
            ltrimstr(\"^\") | ltrimstr(\"~\") | split(\".\")[1] | tonumber <= ${engine_minor})
        ][0].version"
    fi

    local latest_version
    latest_version=$(curl -sf --max-time 10 --retry 2 \
        -X POST \
        "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json;api-version=3.0-preview.1" \
        -d "$api_payload" \
        | jq -r "$jq_filter" 2>/dev/null || true)

    if [ -z "$latest_version" ] || [ "$latest_version" = "null" ]; then
        echo "WARNING: Could not fetch compatible version for ${ext_id} — skipping."
        return 0
    fi

    # Check what's installed in the volume
    local installed_version
    installed_version=$(gosu coder code-server --list-extensions --show-versions 2>/dev/null \
        | grep -i "^${ext_id}@" | cut -d'@' -f2 || true)

    if [ "$installed_version" = "$latest_version" ]; then
        echo "Extension ${ext_id} is up to date (${latest_version})"
        return 0
    fi

    echo "Installing ${ext_id} ${latest_version} (was: ${installed_version:-not installed})..."

    local vsix_url="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${publisher}/vsextensions/${ext_name}/${latest_version}/vspackage"
    local tmp_vsix="/tmp/${ext_id}-${latest_version}.vsix"

    # --compressed decompresses the gzip-encoded response body the marketplace sends
    if curl -sf --max-time 60 --retry 2 --compressed -L "$vsix_url" -o "$tmp_vsix"; then
        gosu coder code-server --install-extension "$tmp_vsix" 2>&1 || \
            echo "WARNING: Failed to install ${ext_id} — continuing."
        rm -f "$tmp_vsix"
    else
        echo "WARNING: Failed to download ${ext_id} VSIX — continuing."
        rm -f "$tmp_vsix"
    fi
}

install_or_update_extension "GitHub"    "copilot"      "true"
install_or_update_extension "GitHub"    "copilot-chat" "true"
install_or_update_extension "anthropic" "claude-code"  "false"

# Switch to coder user and execute code-server
exec gosu coder code-server "$@"
