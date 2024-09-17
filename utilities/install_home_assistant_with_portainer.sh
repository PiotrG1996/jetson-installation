
#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check the exit status of the last command
check_status() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERROR] $1 failed. Exiting...${NC}"
        exit 1
    else
        echo -e "${GREEN}[SUCCESS] $1${NC}"
    fi
}

# Print info in blue
info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Print warning in yellow
warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run as root or use sudo.${NC}"
    exit 1
fi

# Get the device's current IP address
DEVICE_IP=$(hostname -I | awk '{print $1}')
if [ -z "$DEVICE_IP" ]; then
    warn "Unable to detect IP address. Using <your-device-ip> as placeholder."
    DEVICE_IP="<your-device-ip>"
fi

# Update the package list
info "Updating package list..."
apt-get update -y
check_status "Package list update"

# Install dependencies
info "Installing necessary dependencies..."
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
check_status "Installing dependencies"

# Install Docker if not already installed
if ! [ -x "$(command -v docker)" ]; then
    info "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    check_status "Download Docker script"
    sh get-docker.sh
    check_status "Docker installation"
    rm get-docker.sh
else
    info "Docker is already installed."
fi

# Start and enable Docker service
info "Starting and enabling Docker service..."
systemctl start docker
check_status "Docker service start"
systemctl enable docker
check_status "Docker service enable"

# Install Portainer if not already installed
if ! docker ps -a --format '{{.Names}}' | grep -q '^portainer$'; then
    info "Installing Portainer..."
    docker volume create portainer_data
    docker run -d \
        -p 9000:9000 \
        -p 8000:8000 \
        --name=portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest
    check_status "Portainer installation"
else
    info "Portainer is already installed."
fi

# Pull and Run Home Assistant for ARM64
if ! docker ps -a --format '{{.Names}}' | grep -q '^home-assistant$'; then
    info "Installing Home Assistant (ARM64)..."
    docker run -d \
        --name home-assistant \
        --restart unless-stopped \
        -v /home/$(whoami)/homeassistant:/config \
        --network host \
        ghcr.io/home-assistant/home-assistant:stable
    check_status "Home Assistant installation"
else
    info "Home Assistant is already installed."
fi

# Check if everything is running
info "Checking running containers..."
docker ps

# Print success message with access info
echo -e "${GREEN}[SUCCESS] Installation completed.${NC}"
echo -e "${GREEN}You can access Portainer at: http://$DEVICE_IP:9000${NC}"
echo -e "${GREEN}You can access Home Assistant at: http://$DEVICE_IP:8123${NC}"
