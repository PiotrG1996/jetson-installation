# clean up

sudo apt purge ubuntu-desktop -y && sudo apt autoremove -y && sudo apt autoclean
sudo apt-get remove nautilus nautilus-* gnome-power-manager gnome-screensaver gnome-termina* gnome-pane* gnome-applet* gnome-bluetooth gnome-desktop* gnome-sessio* gnome-user* gnome-shell-common zeitgeist-core libzeitgeist* gnome-control-center gnome-screenshot && sudo apt-get autoremove
sudo apt-get remove --purge libreoffice*
sudo apt-get remove libreoffice-core
sudo apt-get remove snapd lightdm cups chromium*
sudo apt-get remove libcurlpp0
rm -rf Desktop
rm -rf Documents
rm -rf Downloads
rm -rf Public
rm -rf Videos
rm -rf Classes
rm -rf Music
rm -rf examples.desktop
rm -rf Templates/
rm -rf Pictures
rm -rf VisionWorks-SFM-0.90-Samples
rm -rf NVIDIA_CUDA-9.0_Samples

# remove sources

cd /usr/src/
sudo rm -rf *

sudo userdel -r ubuntu


