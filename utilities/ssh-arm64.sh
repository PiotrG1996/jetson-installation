#!/bin/bash

set -e

# ============================================================
# Configuration
# ============================================================

INSTALL_DIR="/opt/vscode-tunnel"
SERVICE_NAME="vscode-tunnel"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# The user who will run the VS Code tunnel.
# By default, use the user who launched this script.
VSCODE_USER="${SUDO_USER:-$(whoami)}"

# ============================================================
# Helper functions
# ============================================================

log() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

error_exit() {
    echo
    echo "ERROR: $1"
    exit 1
}

# ============================================================
# Check requirements
# ============================================================

check_requirements() {
    log "Checking system requirements"

    if [ "$(uname -m)" != "aarch64" ]; then
        echo "Warning: This script is intended for ARM64/aarch64."
        echo "Detected architecture: $(uname -m)"
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        error_exit "sudo is required."
    fi

    if ! command -v systemctl >/dev/null 2>&1; then
        error_exit "systemd/systemctl is required."
    fi

    if ! id "$VSCODE_USER" >/dev/null 2>&1; then
        error_exit "User '$VSCODE_USER' does not exist."
    fi

    echo "Using user: $VSCODE_USER"
    echo "Architecture: $(uname -m)"
}

# ============================================================
# Install dependencies
# ============================================================

install_dependencies() {
    log "Installing dependencies"

    sudo apt-get update
    sudo apt-get install -y curl tar ca-certificates

    echo "Dependencies installed."
}

# ============================================================
# Install VS Code CLI
# ============================================================

install_vscode_cli() {
    log "Installing VS Code CLI"

    sudo mkdir -p "$INSTALL_DIR"

    sudo chown "$VSCODE_USER:$VSCODE_USER" "$INSTALL_DIR"

    TEMP_DIR=$(mktemp -d)

    echo "Downloading VS Code CLI for ARM64..."

    curl -fL \
        'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-arm64' \
        -o "$TEMP_DIR/vscode_cli.tar.gz"

    if [ ! -s "$TEMP_DIR/vscode_cli.tar.gz" ]; then
        rm -rf "$TEMP_DIR"
        error_exit "Failed to download VS Code CLI."
    fi

    echo "Extracting VS Code CLI..."

    tar -xzf "$TEMP_DIR/vscode_cli.tar.gz" \
        -C "$TEMP_DIR"

    if [ ! -f "$TEMP_DIR/code" ]; then
        rm -rf "$TEMP_DIR"
        error_exit "The VS Code CLI binary was not found after extraction."
    fi

    sudo install -m 0755 \
        "$TEMP_DIR/code" \
        "$INSTALL_DIR/code"

    rm -rf "$TEMP_DIR"

    sudo chown "$VSCODE_USER:$VSCODE_USER" "$INSTALL_DIR/code"

    echo "VS Code CLI installed at:"
    echo "$INSTALL_DIR/code"

    echo
    echo "VS Code CLI version:"
    sudo -u "$VSCODE_USER" "$INSTALL_DIR/code" --version || true
}

# ============================================================
# Create systemd service
# ============================================================

create_systemd_service() {
    log "Creating systemd service"

    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=VS Code Remote Tunnel
Documentation=https://code.visualstudio.com/docs/remote/tunnels
After=network-online.target
Wants=network-online.target

[Service]
Type=simple

User=$VSCODE_USER
WorkingDirectory=$INSTALL_DIR

ExecStart=$INSTALL_DIR/code tunnel --accept-server-license-terms

Restart=always
RestartSec=10

# Give the tunnel enough time to start/stop cleanly
TimeoutStartSec=300
TimeoutStopSec=30

# Do not kill the process because of an idle timeout
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

    echo "Service file created:"
    echo "$SERVICE_FILE"
}

# ============================================================
# Enable systemd service
# ============================================================

enable_systemd_service() {
    log "Enabling VS Code tunnel service"

    sudo systemctl daemon-reload

    sudo systemctl enable "$SERVICE_NAME.service"

    echo "Systemd service enabled."
}

# ============================================================
# Authentication reminder
# ============================================================

show_authentication_instructions() {
    log "VS Code Tunnel authentication"

    echo "The systemd service has been created, but VS Code tunnel"
    echo "authentication may need to be completed for user:"
    echo
    echo "    $VSCODE_USER"
    echo
    echo "Before starting the service for the first time, run:"
    echo
    echo "    sudo -u $VSCODE_USER $INSTALL_DIR/code tunnel"
    echo
    echo "Follow the authentication instructions shown by VS Code."
    echo
    echo "After authentication is complete, stop the foreground"
    echo "tunnel with Ctrl+C and start the systemd service using:"
    echo
    echo "    sudo systemctl start $SERVICE_NAME"
}

# ============================================================
# Start service
# ============================================================

start_systemd_service() {
    log "Starting VS Code tunnel service"

    sudo systemctl start "$SERVICE_NAME.service"

    sleep 3

    if sudo systemctl is-active --quiet "$SERVICE_NAME.service"; then
        echo
        echo "VS Code tunnel service is RUNNING."
    else
        echo
        echo "WARNING: VS Code tunnel service did not remain running."
        echo
        echo "Service status:"
        sudo systemctl status "$SERVICE_NAME.service" --no-pager || true

        echo
        echo "Recent logs:"
        sudo journalctl -u "$SERVICE_NAME.service" -n 50 --no-pager || true

        exit 1
    fi
}

# ============================================================
# Verify service
# ============================================================

verify_systemd_service() {
    log "Verifying systemd service"

    echo "Enabled status:"
    sudo systemctl is-enabled "$SERVICE_NAME.service"

    echo
    echo "Active status:"
    sudo systemctl is-active "$SERVICE_NAME.service"

    echo
    echo "Service status:"
    sudo systemctl status "$SERVICE_NAME.service" --no-pager
}

# ============================================================
# Main
# ============================================================

log "Starting VS Code ARM64 Tunnel Installation"

check_requirements

install_dependencies

install_vscode_cli

create_systemd_service

enable_systemd_service

show_authentication_instructions

echo
echo "============================================================"
echo "Installation complete."
echo "============================================================"
echo
echo "IMPORTANT:"
echo
echo "The tunnel should be authenticated before relying on the"
echo "systemd service."
echo
echo "To authenticate:"
echo
echo "  sudo -u $VSCODE_USER $INSTALL_DIR/code tunnel"
echo
echo "After authentication, press Ctrl+C and run:"
echo
echo "  sudo systemctl start $SERVICE_NAME"
echo
echo "Check status:"
echo
echo "  sudo systemctl status $SERVICE_NAME"
echo
echo "View logs:"
echo
echo "  sudo journalctl -u $SERVICE_NAME -f"
echo
echo "Check whether it starts on boot:"
echo
echo "  systemctl is-enabled $SERVICE_NAME"
echo
echo "============================================================"
