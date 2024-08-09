#!/bin/bash
# Copyright 2024 Piotr Gapski
# MIT License
# Install the latest version of Visual Studio Code for Ubuntu 18.04 on Jetson Nano

# Log file
LOGFILE="install_vscode.log"

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

# Add the Microsoft repository
echo_status "Adding Microsoft repository..."
sudo apt-get update
sudo apt-get install -y wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo sh -c 'echo "deb [arch=arm64] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
if [ $? -ne 0 ]; then
  echo_error "Failed to add Microsoft repository."
  show_last_log_lines
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

# Install Visual Studio Code
echo_status "Installing Visual Studio Code..."
sudo apt-get install -y code
if [ $? -ne 0 ]; then
  echo_error "Failed to install Visual Studio Code."
  show_last_log_lines
  exit 1
fi

# Check if VS Code was installed successfully
if ! command -v code &> /dev/null; then
  echo_error "Visual Studio Code installation failed. 'code' command not found."
  show_last_log_lines
  exit 1
else
  echo_status "Visual Studio Code installed successfully."
fi

# Install Python3 and pip3
echo_status "Installing Python3 and pip3..."
sudo apt-get install -y python3-pip
if [ $? -ne 0 ]; then
  echo_error "Failed to install Python3 or pip3."
  show_last_log_lines
  exit 1
fi

# Install Python linter (pylint)
echo_status "Installing pylint..."
pip3 install pylint
if [ $? -ne 0 ]; then
  echo_error "Failed to install pylint."
  show_last_log_lines
  exit 1
fi

# Install Python formatter (black)
echo_status "Installing black..."
pip3 install black
if [ $? -ne 0 ]; then
  echo_error "Failed to install black."
  show_last_log_lines
  exit 1
fi

# Install the Python extension for Visual Studio Code
echo_status "Installing Python extension for Visual Studio Code..."
code --install-extension ms-python.python --force
if [ $? -ne 0 ]; then
  echo_error "Failed to install the Python extension for Visual Studio Code."
  show_last_log_lines
  exit 1
fi

echo_status "Visual Studio Code and Python tools installation completed successfully."
