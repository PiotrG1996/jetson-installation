#!/bin/bash
# Install OpenVPN on Jetson Nano running Ubuntu 18.04

# Log file
LOGFILE="install_openvpn.log"

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

# Function to clean up unnecessary packages
cleanup_system() {
  echo_status "Removing unnecessary packages..."
  sudo apt-get autoremove -y
  sudo apt-get clean
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

# Install OpenVPN and Easy-RSA
echo_status "Installing OpenVPN and Easy-RSA..."
sudo apt-get install -y openvpn easy-rsa
if [ $? -ne 0 ]; then
  echo_error "Failed to install OpenVPN or Easy-RSA."
  show_last_log_lines
  exit 1
fi

# Set up the Easy-RSA directory
echo_status "Setting up Easy-RSA..."
EASYRSA_DIR=~/easy-rsa/easyrsa3
if [ ! -d "$EASYRSA_DIR" ]; then
  echo_error "$EASYRSA_DIR does not exist. Cloning Easy-RSA repository."
  git clone https://github.com/OpenVPN/easy-rsa.git ~/easy-rsa
  if [ $? -ne 0 ]; then
    echo_error "Failed to clone Easy-RSA repository."
    show_last_log_lines
    exit 1
  fi
else
  echo_status "$EASYRSA_DIR already exists. Pulling latest changes."
  cd ~/easy-rsa && git pull
  if [ $? -ne 0 ]; then
    echo_error "Failed to pull latest changes from Easy-RSA repository."
    show_last_log_lines
    exit 1
  fi
fi

# Ensure the easyrsa script is executable
EASYRSA_SCRIPT="$EASYRSA_DIR/easyrsa"
if [ ! -x "$EASYRSA_SCRIPT" ]; then
  echo_error "'$EASYRSA_SCRIPT' is not executable or not found."
  show_last_log_lines
  exit 1
fi

cd "$EASYRSA_DIR"
if [ $? -ne 0 ]; then
  echo_error "Failed to navigate to Easy-RSA directory."
  show_last_log_lines
  exit 1
fi

# Initialize the PKI and build the CA
echo_status "Initializing the PKI and building the CA..."
"$EASYRSA_SCRIPT" init-pki
if [ $? -ne 0 ]; then
  echo_error "Failed to initialize PKI."
  show_last_log_lines
  exit 1
fi

"$EASYRSA_SCRIPT" build-ca nopass
if [ $? -ne 0 ]; then
  echo_error "Failed to build CA."
  show_last_log_lines
  exit 1
fi

# Generate server certificate and key
echo_status "Generating server certificate and key..."
"$EASYRSA_SCRIPT" gen-req server nopass
if [ $? -ne 0 ]; then
  echo_error "Failed to generate server certificate and key."
  show_last_log_lines
  exit 1
fi

"$EASYRSA_SCRIPT" sign-req server server
if [ $? -ne 0 ]; then
  echo_error "Failed to sign server certificate."
  show_last_log_lines
  exit 1
fi

# Generate Diffie-Hellman parameters
echo_status "Generating Diffie-Hellman parameters..."
"$EASYRSA_SCRIPT" gen-dh
if [ $? -ne 0 ]; then
  echo_error "Failed to generate Diffie-Hellman parameters."
  show_last_log_lines
  exit 1
fi

# Generate HMAC key for added security
echo_status "Generating HMAC key..."
sudo openvpn --genkey --secret "$EASYRSA_DIR/pki/ta.key"
if [ $? -ne 0 ]; then
  echo_error "Failed to generate HMAC key."
  show_last_log_lines
  exit 1
fi

# Copy configuration files to OpenVPN directory
echo_status "Copying configuration files..."
sudo cp "$EASYRSA_DIR/pki/ca.crt" "$EASYRSA_DIR/pki/private/server.key" "$EASYRSA_DIR/pki/issued/server.crt" "$EASYRSA_DIR/pki/dh.pem" "$EASYRSA_DIR/pki/ta.key" /etc/openvpn/
if [ $? -ne 0 ]; then
  echo_error "Failed to copy configuration files."
  show_last_log_lines
  exit 1
fi

# Configure OpenVPN server
echo_status "Configuring OpenVPN server..."
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
sudo gzip -d /etc/openvpn/server.conf.gz
sudo sed -i 's/;tls-auth ta.key 0 # This file is secret/tls-auth ta.key 0 # This file is secret/' /etc/openvpn/server.conf
sudo sed -i 's/dh dh2048.pem/dh dh.pem/' /etc/openvpn/server.conf
sudo sed -i 's/ca ca.crt/ca ca.crt/' /etc/openvpn/server.conf
sudo sed -i 's/cert server.crt/cert server.crt/' /etc/openvpn/server.conf
sudo sed -i 's/key server.key/key server.key/' /etc/openvpn/server.conf
sudo sed -i 's/;user nobody/user nobody/' /etc/openvpn/server.conf
sudo sed -i 's/;group nogroup/group nogroup/' /etc/openvpn/server.conf

# Enable and start OpenVPN service
echo_status "Starting and enabling OpenVPN service..."
sudo systemctl enable openvpn@server
sudo systemctl start openvpn@server
if [ $? -ne 0 ]; then
  echo_error "Failed to start or enable OpenVPN service."
  show_last_log_lines
  exit 1
fi

# Cleanup system
cleanup_system

echo_status "OpenVPN installation and configuration completed successfully."
