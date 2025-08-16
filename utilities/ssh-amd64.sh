#!/bin/bash

# Function to install dependencies
install_dependencies() {
    echo "Installing required dependencies..."
    sudo apt-get update
    sudo apt-get install -y curl tar
}

# Function to install VS Code CLI for amd64
install_vscode_cli() {
    echo "Downloading VS Code CLI for amd64..."
    curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz

    if [ ! -f vscode_cli.tar.gz ]; then
        echo "Error: Failed to download VS Code CLI."
        exit 1
    fi

    echo "Extracting VS Code CLI..."
    tar -xf vscode_cli.tar.gz

    if [ ! -f code ]; then
        echo "Error: Failed to extract VS Code CLI."
        exit 1
    fi

    echo "VS Code CLI installation complete."
}

# Function to create a secure tunnel with VS Code Server
create_secure_tunnel() {
    echo "Starting VS Code Server and creating a secure tunnel..."
    ./code tunnel --accept-server-license-terms

    if [ $? -ne 0 ]; then
        echo "Error: Failed to start VS Code tunnel."
        exit 1
    fi

    echo "Tunnel is running. You can access it using the provided URL."
}

# Function to create systemd service for the VS Code tunnel
create_systemd_service() {
    echo "Creating systemd service for VS Code tunnel..."
    
    # Get the current user and directory
    local SERVICE_USER=$(whoami)
    local WORKING_DIR=$(pwd)
    
    # Create the systemd service file
    sudo bash -c "cat > /etc/systemd/system/vscode-tunnel.service <<EOF
[Unit]
Description=VS Code Secure Tunnel
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$WORKING_DIR
ExecStart=$WORKING_DIR/code tunnel --accept-server-license-terms
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=vscode-tunnel

# Give the service reasonable time to start/shutdown
TimeoutStartSec=300
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF"

    # Reload systemd to apply the changes
    echo "Reloading systemd manager..."
    sudo systemctl daemon-reload

    # Enable and start the service
    echo "Enabling and starting the VS Code tunnel service..."
    sudo systemctl enable vscode-tunnel.service
    sudo systemctl start vscode-tunnel.service

    if [ $? -ne 0 ]; then
        echo "Error: Failed to start VS Code tunnel service."
        exit 1
    fi

    echo "VS Code tunnel service is now running."
    echo "You can check its status with: systemctl status vscode-tunnel"
}

# Main script execution
echo "Starting the installation of VS Code CLI for amd64..."

# Install dependencies
install_dependencies

# Install VS Code CLI
install_vscode_cli

# Create the systemd service to keep the tunnel open
create_systemd_service

echo "Installation and service setup complete."
echo "The VS Code tunnel will automatically start on system boot."
