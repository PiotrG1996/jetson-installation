#!/bin/bash

set -e  # Exit on any error

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
echo "Installing dependencies..."
sudo apt-get install -y \
    python3 \
    python3-venv \
    python3-pip \
    libffi-dev \
    libyaml-dev \
    python3-dev \
    build-essential \
    libssl-dev \
    libjpeg-dev \
    zlib1g-dev \
    libsqlite3-dev \
    liblzma-dev \
    libreadline-dev \
    libbz2-dev \
    libncurses5-dev \
    libncursesw5-dev \
    tk-dev \
    lsb-release

# Ensure lsb-release is working
echo "Checking lsb-release functionality..."
if ! command -v lsb_release &> /dev/null; then
    echo "lsb-release command is not available. Reinstalling..."
    sudo apt-get install --reinstall lsb-release
else
    echo "lsb-release is functional"
fi

# Create a Home Assistant user if it doesn't exist
echo "Creating Home Assistant user..."
if ! id -u jetson &> /dev/null; then
    sudo useradd -rm -G dialout,gpio,i2c jetson
else
    echo "User 'jetson' already exists"
fi

# Clean up any previous installation
echo "Cleaning up previous installations..."
if sudo rm -rf /srv/homeassistant; then
    echo "Previous installation removed successfully"
else
    echo "Failed to remove /srv/homeassistant. Check permissions."
    exit 1
fi

# Create and activate virtual environment
echo "Setting up virtual environment..."
sudo mkdir -p /srv/homeassistant
sudo chown jetson:jetson /srv/homeassistant
sudo -u jetson -H bash -c 'cd /srv/homeassistant && python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip wheel'

# Install Home Assistant Core
echo "Installing Home Assistant Core..."
sudo -u jetson -H bash -c 'source /srv/homeassistant/venv/bin/activate && pip install --upgrade homeassistant'

# Create a systemd service file for Home Assistant Core
echo "Creating systemd service file..."
sudo tee /etc/systemd/system/home-assistant@jetson.service > /dev/null << EOF
[Unit]
Description=Home Assistant
After=network.target

[Service]
Type=simple
User=jetson
ExecStart=/srv/homeassistant/venv/bin/hass -c "/srv/homeassistant/.homeassistant"
Restart=always
RestartSec=3
Environment="PATH=/srv/homeassistant/venv/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize the new service
echo "Reloading systemd and starting Home Assistant service..."
sudo systemctl daemon-reload
sudo systemctl enable home-assistant@jetson
sudo systemctl start home-assistant@jetson

# Check the status of the service
echo "Checking the status of Home Assistant service..."
if ! sudo systemctl status home-assistant@jetson; then
    echo "Home Assistant service failed to start. Check the logs."
    exit 1
fi

# Output access URL
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "Home Assistant Core installed and running. Access it via http://$IP_ADDRESS:8123"

# Check Home Assistant logs for errors
# echo "Checking Home Assistant logs..."
# sudo journalctl -u home-assistant@jetson --since "10 minutes ago"
