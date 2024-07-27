#! /bin/bash

echo "Installing VNC"
sudo apt install vino

echo "Creating VNC user"
mkdir -p ~/.config/autostart
cp /usr/share/applications/vino-server.desktop ~/.config/autostart

echo "Creating VNC password"
gsettings set org.gnome.Vino prompt-enabled false
gsettings set org.gnome.Vino require-encryption false
gsettings set org.gnome.Vino authentication-methods "['vnc']"
gsettings set org.gnome.Vino vnc-password $(echo -n 'jetson'|base64)

echo "VNC server is now installed and configured. Please reboot the system."
sudo reboot
