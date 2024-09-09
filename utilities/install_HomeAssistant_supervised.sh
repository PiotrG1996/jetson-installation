#!/bin/bash

# Exit script on any error
set -e

# Define color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\\'
    while ps -p $pid > /dev/null 2>&1; do
        for i in `seq 0 3`; do
            echo -ne "${spinstr:$i:1}"\\r
            sleep $delay
        done
    done
    echo -ne 'Done!\\r'
}

# Function to print error messages and exit
error_exit() {
    echo -e "${RED}$1${NC}" 1>&2
    exit 1
}

# Function to print success messages
success_msg() {
    echo -e "${GREEN}$1${NC}"
}

# Function to print information messages
info_msg() {
    echo -e "${GREEN}$1${NC}"
}

# Ensure the script is run as root
if [ "$(id -u)" -ne "0" ]; then
    error_exit "This script must be run as root. Please use sudo or switch to the root user."
fi

# Check OS version
os_version=$(lsb_release -d | awk -F"\t" '{print $2}')
info_msg "Operating System Version: $os_version"

# Check network connectivity
info_msg "Checking network connectivity..."
if ! ping -c 4 google.com &> /dev/null; then
    error_exit "Network connectivity issue. Please check your internet connection."
fi

# Backup current sources list
info_msg "Backing up current sources list..."
cp /etc/apt/sources.list /etc/apt/sources.list.bak

# Update sources list with alternative mirrors
info_msg "Updating sources list with alternative mirrors..."
cat <<EOF > /etc/apt/sources.list
deb http://ports.ubuntu.com/ubuntu-ports bionic main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports bionic-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports bionic-security main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports bionic-backports main restricted universe multiverse
EOF

# Update and upgrade packages
info_msg "Updating package lists and upgrading packages..."
{
    apt update -q
    apt upgrade -y
} & spinner $!
wait $!

# Install required dependencies
info_msg "Installing required dependencies..."
{
    apt install -y \
        apparmor \
        bluez \
        cifs-utils \
        curl \
        dbus \
        jq \
        libglib2.0-bin \
        lsb-release \
        network-manager \
        nfs-common \
        systemd-journal-remote \
        udisks2 \
        wget \
        tree
} & spinner $!
wait $!
success_msg "Dependencies installed successfully."

# Install Docker CE
info_msg "Installing Docker CE..."
{
    curl -fsSL https://get.docker.com | sh
} & spinner $!
wait $!

# Check Docker installation
if ! command -v docker &> /dev/null; then
    error_exit "Docker installation failed."
else
    info_msg "Docker is already installed."
fi

# Enable and start Docker
info_msg "Enabling and starting Docker service..."
{
    systemctl enable docker && systemctl start docker
} & spinner $!
wait $!
success_msg "Docker service enabled and started."

# Check if Home Assistant container already exists and remove it if needed
info_msg "Checking for existing Home Assistant container..."
if docker ps -a --format '{{.Names}}' | grep -q '^home-assistant$'; then
    info_msg "Found existing Home Assistant container. Removing it..."
    docker rm -f home-assistant || error_exit "Failed to remove existing Home Assistant container."
fi

# Run Home Assistant in Docker
info_msg "Running Home Assistant in Docker..."
{
    docker run -d --name home-assistant --restart unless-stopped -p 8123:8123 ghcr.io/home-assistant/home-assistant:latest
} & spinner $!
wait $!
success_msg "Home Assistant is running in Docker. Access it via http://<your-ip-address>:8123"

# Download and install OS-Agent
info_msg "Downloading and installing OS-Agent version 1.6.0..."
{
    wget -O /tmp/os-agent_1.6.0_linux_arm64.tar.gz https://github.com/home-assistant/os-agent/releases/download/1.6.0/os-agent_1.6.0_linux_arm64.tar.gz
    rm -rf /tmp/os-agent  # Ensure no existing directory
    mkdir -p /tmp/os-agent
    tar -xzf /tmp/os-agent_1.6.0_linux_arm64.tar.gz -C /tmp/os-agent || error_exit "Failed to extract OS-Agent package."

    # List contents of the extracted directory
    info_msg "Listing contents of extracted OS-Agent directory:"
    ls -l /tmp/os-agent

    # Copy the os-agent binary to the appropriate location
    cp /tmp/os-agent/os-agent /usr/local/bin/os-agent
    chmod +x /usr/local/bin/os-agent

    # Create a custom service file
    SERVICE_FILE=/etc/systemd/system/io.hass.os-agent.service
    info_msg "Creating systemd service file at $SERVICE_FILE..."
    cat <<EOF > $SERVICE_FILE
[Unit]
Description=OS-Agent Service
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/os-agent
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and start the service
    systemctl daemon-reload
    systemctl enable io.hass.os-agent.service
    systemctl start io.hass.os-agent.service
} & spinner $!
wait $!

# Check for successful installation
if ! gdbus introspect --system --dest io.hass.os --object-path /io/hass/os &> /dev/null; then
    error_exit "OS-Agent installation failed or is not running. Check logs for details."
fi
success_msg "OS-Agent installed successfully."

# Check for required dependencies for Home Assistant Supervised
info_msg "Checking for required dependencies..."
{
    apt update
    # Install systemd if not already installed
    if ! dpkg -l | grep -q systemd; then
        info_msg "systemd not found. Attempting to install..."
        apt install -y systemd || error_exit "systemd installation failed."
    fi
} & spinner $!
wait $!
success_msg "Required dependencies checked and installed if necessary."

# Download Home Assistant Supervised
info_msg "Downloading Home Assistant Supervised..."
{
    wget -O homeassistant-supervised.deb https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
} & spinner $!
wait $!
success_msg "Home Assistant Supervised package downloaded successfully."

# Install Home Assistant Supervised
info_msg "Installing Home Assistant Supervised..."
{
    dpkg -i homeassistant-supervised.deb || {
        info_msg "Failed to install Home Assistant Supervised. Checking for missing dependencies..."
        apt --fix-broken install -y || error_exit "Failed to fix broken dependencies. Please check logs for details."
        dpkg -i homeassistant-supervised.deb || error_exit "Failed to install Home Assistant Supervised after fixing dependencies."
    }
} & spinner $!
wait $!
success_msg "Home Assistant Supervised installed successfully."

# Enable and start necessary services
info_msg "Enabling and starting NetworkManager service..."
{
    systemctl enable NetworkManager && systemctl start NetworkManager
} & spinner $!
wait $!
success_msg "NetworkManager service enabled and started."

info_msg "Enabling and starting systemd-journal-remote service..."
{
    systemctl enable systemd-journal-remote && systemctl start systemd-journal-remote
} & spinner $!
wait $!
success_msg "systemd-journal-remote service enabled and started."

# Verify Docker is running
if ! systemctl is-active --quiet docker; then
    error_exit "Docker service is not running. Ensure Docker is installed and configured correctly."
fi

# Verify NetworkManager is running
if ! systemctl is-active --quiet NetworkManager; then
    error_exit "NetworkManager service is not running. Ensure NetworkManager is installed and configured correctly."
fi

# Verify systemd-journal-remote is running
if ! systemctl is-active --quiet systemd-journal-remote; then
    error_exit "systemd-journal-remote service is not running. Ensure it is installed and configured correctly."
fi

success_msg "Installation of Home Assistant Supervised is complete. You can access the Home Assistant UI to continue setup."

# Clean up downloaded files
info_msg "Cleaning up downloaded files..."
rm -f /tmp/os-agent_1.6.0_linux_arm64.tar.gz
rm -rf /tmp/os-agent
rm -f homeassistant-supervised.deb
success_msg "Clean up completed successfully."

# Provide tips for common issues
info_msg "If you encounter issues, consider the following tips:"
info_msg "1. Ensure your system meets all prerequisites for Home Assistant."
info_msg "2. Check the logs for Docker and Home Assistant for detailed error messages."
info_msg "3. Consult the Home Assistant community and documentation for further assistance."

# Establish an SSH tunnel to keep the connection open
info_msg "Establishing an SSH tunnel to keep the connection open..."
{
    ssh -f -N -L 8123:localhost:8123 $(whoami)@192.168.100.3
} & spinner $!
wait $!

info_msg "To access the Home Assistant UI, open your browser and navigate to http://localhost:8123"
