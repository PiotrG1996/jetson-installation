#!/bin/bash

# Define colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define spinner function
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp="${spinstr#?}${spinstr%???}"
        printf "\r${temp:0:1}"
        sleep $delay
    done
    printf "\r"
}

# Print start message
echo -e "${GREEN}Starting Python 3.8 installation on Jetson Nano...${NC}"

# Update and upgrade system packages
echo -e "${GREEN}Updating system packages...${NC}"
sudo apt update -y
sudo apt upgrade -y

# Install build dependencies
echo -e "${GREEN}Installing build dependencies...${NC}"
sudo apt install -y build-essential libssl-dev zlib1g-dev libncurses5-dev libncursesw5-dev \
libreadline-dev libsqlite3-dev libgdbm-dev libdb5.3-dev libbz2-dev libexpat1-dev \
liblzma-dev libffi-dev libc6-dev

# Download Python source code for ARM architecture
PYTHON_VERSION="3.8.12"
PYTHON_TAR="Python-${PYTHON_VERSION}.tar.xz"
PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTHON_TAR}"

echo -e "${GREEN}Downloading Python ${PYTHON_VERSION} source code...${NC}"
wget -q ${PYTHON_URL} || { echo -e "${RED}Failed to download Python source code.${NC}"; exit 1; }

# Extract the downloaded archive
echo -e "${GREEN}Extracting Python ${PYTHON_VERSION} source code...${NC}"
tar -xf ${PYTHON_TAR} || { echo -e "${RED}Failed to extract Python source code.${NC}"; exit 1; }

# Change to the source directory
cd Python-${PYTHON_VERSION} || { echo -e "${RED}Failed to enter Python source directory.${NC}"; exit 1; }

# Configure the build process
echo -e "${GREEN}Configuring build process...${NC}"
./configure --enable-optimizations || { echo -e "${RED}Configuration failed.${NC}"; exit 1; }

# Build Python
echo -e "${GREEN}Building Python ${PYTHON_VERSION}...${NC}"
make -j4 &
spinner $!

# Install Python
echo -e "${GREEN}Installing Python ${PYTHON_VERSION}...${NC}"
sudo make altinstall || { echo -e "${RED}Installation failed.${NC}"; exit 1; }

# Verify installation
echo -e "${GREEN}Verifying Python ${PYTHON_VERSION} installation...${NC}"
python3.8 --version || { echo -e "${RED}Python installation verification failed.${NC}"; exit 1; }

# Return to the previous directory
cd .. || { echo -e "${RED}Failed to return to the previous directory.${NC}"; exit 1; }

# Create and activate a virtual environment
echo -e "${GREEN}Creating and activating a virtual environment...${NC}"
python3.8 -m venv myenv || { echo -e "${RED}Failed to create virtual environment.${NC}"; exit 1; }
source myenv/bin/activate || { echo -e "${RED}Failed to activate virtual environment.${NC}"; exit 1; }

# Completion message
echo -e "${GREEN}Python ${PYTHON_VERSION} installation and environment setup complete!${NC}"
