#!/bin/bash

# Script to install VS Code CLI for ARM64 and run SSH Tunnel
# https://github.com/device/login -> Add here generated CODE to access SSH Tunnel

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
    
    # Run the tunnel command
    ./code tunnel --accept-server-license-terms
    
    echo "Tunnel is running. You can access it using the provided URL."
}

# Main script execution
echo "Starting the installation of VS Code CLI for ARM64..."

# Install VS Code CLI
install_vscode_cli

# Create secure tunnel
create_secure_tunnel





# # Function to get the default IP address
# get_default_ip() {
#   ip route get 1 | awk '{print $7; exit}'
# }

# # Function to get the current username
# get_current_user() {
#   whoami
# }

# # Get default IP address and current username
# default_ip=$(get_default_ip)
# current_user=$(get_current_user)

# # Display default values to the user
# echo "Default IP Address: $default_ip"
# echo "Default Username: $current_user"

# # Prompt for SSH server details
# read -p "Enter SSH server hostname or IP address (default: $default_ip): " remote_host
# remote_host=${remote_host:-$default_ip}

# read -p "Enter SSH server username (default: $current_user): " username
# username=${username:-$current_user}

# # Prompt for local and remote port numbers
# read -p "Enter local port to use for tunnel (e.g., 8080): " local_port
# read -p "Enter remote port on SSH server (e.g., 80): " remote_port

# # Establish SSH tunnel
# echo "Establishing SSH tunnel to $remote_host as user $username..."
# ssh -N -L "$local_port:localhost:$remote_port" "$username@$remote_host" &
# echo "SSH tunnel established. You can now access remote service at localhost:$local_port."

# # Instructions for creating a systemd service for the SSH tunnel
# echo "To create a systemd service for this tunnel, follow these steps:"

# # Generate SSH key (if needed)
# echo "Generating SSH key (if needed)..."
# ssh-keygen -t rsa -b 4096

# # Create systemd service file
# echo "Creating systemd service file..."
# cat <<EOF | sudo tee /etc/systemd/system/ssh-tunnel.service
# [Unit]
# Description=SSH Tunnel Service
# After=network.target

# [Service]
# User=$username
# Environment="LOCAL_PORT=$local_port"
# Environment="REMOTE_HOST=$remote_host"
# Environment="REMOTE_PORT=$remote_port"
# ExecStart=/usr/bin/ssh -N -L \$LOCAL_PORT:localhost:\$REMOTE_PORT \$USER@\$REMOTE_HOST
# Restart=always
# RestartSec=3

# [Install]
# WantedBy=multi-user.target
# EOF

# # Reload systemd and enable the service
# echo "Reloading systemd and enabling the SSH tunnel service..."
# sudo systemctl daemon-reload
# sudo systemctl enable ssh-tunnel.service
# sudo systemctl start ssh-tunnel.service

# # Check the status of the service
# echo "Checking the status of the SSH tunnel service..."
# sudo systemctl status ssh-tunnel.service
