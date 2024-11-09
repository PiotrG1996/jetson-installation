#!/bin/bash

# Function to install VS Code CLI for ARM64
install_vscode_cli() {
    echo "Downloading VS Code CLI for ARM64..."
    curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-arm64' --output vscode_cli.tar.gz
    
    echo "Extracting VS Code CLI..."
    tar -xf vscode_cli.tar.gz

    echo "VS Code CLI installation complete."
}

# Function to create a secure tunnel with VS Code Server
create_secure_tunnel() {
    echo "Starting VS Code Server and creating a secure tunnel..."
    
    # Run the tunnel command (replace with actual location of the 'code' binary)
    ./code tunnel --accept-server-license-terms
    
    echo "Tunnel is running. You can access it using the provided URL."
}

# Function to create systemd service for the VS Code tunnel
create_systemd_service() {
    echo "Creating systemd service for VS Code tunnel..."

    # Create the systemd service file
    cat > /etc/systemd/system/vscode-tunnel.service <<EOF
[Unit]
Description=VS Code Secure Tunnel
After=network.target

[Service]
Type=simple
User=$(whoami)  # Use the current user
WorkingDirectory=$(pwd)  # Set working directory to the current directory
ExecStart=$(pwd)/install.sh  # Full path to the install script
Restart=always  # Restart the service if it fails
Environment=GITHUB_TOKEN=your_personal_access_token  # Replace with your actual GitHub token
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to apply the changes
    echo "Reloading systemd manager..."
    sudo systemctl daemon-reload

    # Enable and start the service
    echo "Enabling and starting the VS Code tunnel service..."
    sudo systemctl enable vscode-tunnel.service
    sudo systemctl start vscode-tunnel.service

    echo "VS Code tunnel service is now running."
}

# Main script execution
echo "Starting the installation of VS Code CLI for ARM64..."

# Install VS Code CLI
install_vscode_cli

# Create secure tunnel (for immediate use, can be skipped since service will handle it)
create_secure_tunnel

# Create the systemd service to keep the tunnel open
create_systemd_service

echo "Installation and service setup complete."
