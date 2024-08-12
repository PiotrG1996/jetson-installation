#!/bin/bash

# Function to find all installed VS Code versions
find_installed_versions() {
  echo "Checking installed VS Code versions..."
  dpkg -l | grep 'code ' || echo "No VS Code installations found."
}

# Function to install the latest VS Code (GUI)
install_latest_vs_code() {
  echo "Installing VS Code from the official repository..."

  # Install dependencies
  sudo apt-get install -y software-properties-common apt-transport-https wget

  # Import the Microsoft GPG key
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

  # Add the VS Code repository
  sudo add-apt-repository "deb [arch=arm64] https://packages.microsoft.com/repos/vscode stable main"

  # Update package lists
  sudo apt-get update

  # Install VS Code
  sudo apt-get install -y code

  # Verify the installation
  if command -v code &> /dev/null; then
    echo "VS Code installed successfully."
  else
    echo "Failed to verify the VS Code installation."
    exit 1
  fi
}

# Function to remove old versions of VS Code
remove_old_versions() {
  echo "Removing old VS Code versions..."
  sudo apt-get remove --purge code || echo "No old versions found to remove."
  sudo apt-get autoremove
}

# Function to fix broken dependencies
fix_broken_dependencies() {
  echo "Fixing broken dependencies..."
  sudo apt-get install -f
}

# Function to install VS Code CLI
install_vs_code_cli() {
  echo "Installing VS Code CLI..."

  # Download and unpack the CLI
  curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz
  tar -xf vscode_cli.tar.gz
  rm vscode_cli.tar.gz

  # Check if the code CLI executable is present
  if [ ! -f ./code/bin/code ]; then
    echo "VS Code CLI installation failed. Please check the downloaded archive."
    exit 1
  fi

  echo "VS Code CLI installed successfully."

  # Move the CLI to a proper location
  sudo mv ./code /usr/local/bin/vscode-cli

  # Create a systemd service file
  create_service_file
}

# Function to create a systemd service for VS Code CLI
create_service_file() {
  echo "Creating a systemd service for VS Code CLI..."

  sudo tee /etc/systemd/system/vscode.service <<EOF
[Unit]
Description=VS Code Server
After=network.target

[Service]
ExecStart=/usr/local/bin/vscode-cli/bin/code tunnel --accept-server-license-terms
WorkingDirectory=/home/$(whoami)
Restart=always
User=$(whoami)
Environment=DISPLAY=:0

[Install]
WantedBy=multi-user.target
EOF

  # Reload systemd and start the service
  sudo systemctl daemon-reload
  sudo systemctl enable vscode
  sudo systemctl start vscode

  echo "VS Code server service created and started."
}

# Function to log in to GitHub (manual process)
github_login_instructions() {
  echo "To complete the setup, you need to authenticate with GitHub."
  echo "Open the following URL in your browser and follow the instructions to authenticate:"
  echo "https://github.com/login/oauth/authorize"
  echo "After authenticating, you can access VS Code using the URL provided by the VS Code CLI."
}

# Prompt user for installation choice
echo "Do you want to install the GUI version (1) or CLI version (2) of VS Code?"
read -r choice

case $choice in
  1)
    # Find installed versions
    find_installed_versions

    # Remove old versions
    remove_old_versions

    # Fix broken dependencies
    fix_broken_dependencies

    # Install the latest version of VS Code (GUI)
    install_latest_vs_code
    ;;
  2)
    # Install VS Code CLI
    install_vs_code_cli

    # Provide GitHub login instructions
    github_login_instructions
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
