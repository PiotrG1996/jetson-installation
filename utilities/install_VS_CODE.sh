#!/bin/bash
# Copyright 2024 Piotr Gapski
# MIT License
# Install the latest version of Visual Studio Code for Ubuntu 18.04 on Jetson Nano

# Log file
LOGFILE="install_vscode_server.log"

# Function to print status messages
echo_status() {
  echo -e "\e[1;32m$1\e[0m"
}

# Function to print error messages
echo_error() {
  echo -e "\e[1;31m$1\e[0m" >&2
}

# Function to show the last 50 lines of the log file
show_last_log_lines() {
  echo_error "Installation failed. Showing the last 50 lines of the log file:"
  tail -n 50 "$LOGFILE"
}

# Redirect all output to the log file
exec > >(tee -a "$LOGFILE") 2>&1

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo_error "This script must be run as root"
   exit 1
fi

# Update package list
echo_status "Updating package list..."
sudo apt-get update
if [ $? -ne 0 ]; then
  echo_error "Failed to update package list."
  show_last_log_lines
  exit 1
fi

# Install required packages
echo_status "Installing required packages..."
sudo apt-get install -y curl wget gnupg
if [ $? -ne 0 ]; then
  echo_error "Failed to install required packages."
  show_last_log_lines
  exit 1
fi

# Install VS Code Server
echo_status "Installing VS Code Server..."
mkdir -p ~/.cache/code-server
curl -#fL -o ~/.cache/code-server/code-server_4.91.1_arm64.deb https://github.com/coder/code-server/releases/download/v4.91.1/code-server_4.91.1_arm64.deb
sudo dpkg -i ~/.cache/code-server/code-server_4.91.1_arm64.deb
if [ $? -ne 0 ]; then
  echo_error "Failed to install VS Code Server."
  show_last_log_lines
  exit 1
fi

# Enable and start the VS Code Server service
echo_status "Starting VS Code Server..."
sudo systemctl enable --now code-server@$USER
if [ $? -ne 0 ]; then
  echo_error "Failed to start or enable VS Code Server service."
  show_last_log_lines
  exit 1
fi

echo_status "VS Code Server installation and configuration completed successfully."
