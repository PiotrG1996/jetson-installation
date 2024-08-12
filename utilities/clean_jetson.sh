#!/bin/bash

echo "=============================="
echo "Jetson Nano Minimalist Image Creation Script"
echo "=============================="
echo ""
echo "WARNING: This script will remove various packages and files to reduce the size of the system."
echo "Proceed with caution and ensure you have a backup before continuing."
echo "=============================="
echo ""

# Step 1: Safe Cleaning
read -p "Step 1: Perform safe cleaning (apt update, autoremove, clean, remove LibreOffice & Thunderbird)? [y/N]: " choice1
if [[ "$choice1" == "y" || "$choice1" == "Y" ]]; then
    echo "Performing safe cleaning..."
    sudo apt update
    sudo apt autoremove -y
    sudo apt clean
    sudo apt remove -y libreoffice* thunderbird* gnome-software* \
                       gnome-calendar* gnome-contacts* gnome-maps* \
                       gnome-weather* rhythmbox* totem* \
                       cheese* simple-scan* \
                       remmina* transmission* \
                       aisleriot* gnome-mahjongg* gnome-mines* \
                       gnome-sudoku*
    echo "Safe cleaning completed."
else
    echo "Skipping safe cleaning."
fi
echo ""

# Step 2: Deeper Cleaning (Not Recommended for Development Use)
echo "WARNING: The next step will remove development samples, repos, and headers."
read -p "Step 2: Perform deeper cleaning (remove samples, repos, headers)? [y/N]: " choice2
if [[ "$choice2" == "y" || "$choice2" == "Y" ]]; then
    echo "Performing deeper cleaning..."
    sudo rm -rf /usr/local/cuda/samples \
        /usr/src/cudnn_samples_* \
        /usr/src/tensorrt/data \
        /usr/src/tensorrt/samples \
        /usr/share/visionworks* ~/VisionWorks-SFM*Samples \
        /opt/nvidia/deepstream/deepstream*/samples	
    
    sudo apt purge -y cuda-repo-l4t-*local* libvisionworks-*repo
    sudo rm /etc/apt/sources.list.d/cuda*local* /etc/apt/sources.list.d/visionworks*repo*
    sudo rm -rf /usr/src/linux-headers-*
    echo "Deeper cleaning completed."
else
    echo "Skipping deeper cleaning."
fi
echo ""

# Step 3: Advanced Cleaning (WARNING! Removes GUI and Important Packages)
echo "WARNING: The next step will remove the GUI and other important packages."
echo "This is only recommended if you want a headless setup."
read -p "Step 3: Perform advanced cleaning (remove GUI and related packages)? [y/N]: " choice3
if [[ "$choice3" == "y" || "$choice3" == "Y" ]]; then
    echo "Performing advanced cleaning..."
    sudo apt-get purge -y gnome-shell ubuntu-wallpapers-bionic light-themes chromium-browser* \
                           gnome-terminal* gnome-session* gdm3* \
                           nautilus* gnome-control-center* network-manager* \
                           pulseaudio* gnome-software* \
                           libvisionworks libvisionworks-sfm-dev
    sudo apt-get autoremove -y
    sudo apt clean -y
    echo "Advanced cleaning completed."
else
    echo "Skipping advanced cleaning."
fi
echo ""

# Step 4: Remove Static Libraries (Optional)
echo "Step 4: You can remove static libraries related to CUDA, cuDNN, and TensorRT."
read -p "Remove static libraries? [y/N]: " choice4
if [[ "$choice4" == "y" || "$choice4" == "Y" ]]; then
    echo "Removing static libraries..."
    sudo rm -rf /usr/local/cuda/targets/aarch64-linux/lib/*.a \
        /usr/lib/aarch64-linux-gnu/libcudnn*.a \
        /usr/lib/aarch64-linux-gnu/libnvcaffe_parser*.a \
        /usr/lib/aarch64-linux-gnu/libnvinfer*.a \
        /usr/lib/aarch64-linux-gnu/libnvonnxparser*.a \
        /usr/lib/aarch64-linux-gnu/libnvparsers*.a
    echo "Static libraries removed."
else
    echo "Skipping removal of static libraries."
fi
echo ""

# Display Disk Size Information
echo "=============================="
echo "Disk Usage Summary:"
df -h /
echo "=============================="

# Step 5: Install and Run jtop
echo "Step 5: Installing and running jtop."
if ! command -v jtop &> /dev/null; then
    echo "jtop is not installed. Installing jtop..."
    sudo apt install -y python3-pip
    sudo pip3 install jetson-stats
    echo "jtop installed successfully."
else
    echo "jtop is already installed."
fi

# Run jtop
echo "Launching jtop..."
jtop

echo "=============================="
echo "Script execution completed."
echo "Please review the changes made to your system."
echo "=============================="
