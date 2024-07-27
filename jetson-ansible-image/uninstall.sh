#!/bin/bash
echo "Stop display manager gdm3..."
sudo systemctl stop gdm3
echo "Block from starting on boot..."
sudo systemctl disable gdm3
sudo systemctl set-default multi-user.target
echo "Uninstall Ubuntu-desktop..."
sudo apt remove --purage ubuntu-desktop gdm3
echo "rebooting..."
sudo reboot
