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

###########################################

## Step 1, safe
sudo apt update
sudo apt autoremove -y
sudo apt clean
sudo apt remove thunderbird libreoffice-* -y

## Step 2, still safe but not recommended for dev use
# samples
sudo rm -rf /usr/local/cuda/samples \
    /usr/src/cudnn_samples_* \
    /usr/src/tensorrt/data \
    /usr/src/tensorrt/samples \
    /usr/share/visionworks* ~/VisionWorks-SFM*Samples \
    /opt/nvidia/deepstream/deepstream*/samples	

# Remove local repos
sudo apt purge cuda-repo-l4t-*local* libvisionworks-*repo -y
sudo rm /etc/apt/sources.list.d/cuda*local* /etc/apt/sources.list.d/visionworks*repo*
sudo rm -rf /usr/src/linux-headers-*

## Step 3, hardcore only for prod (remove GUI)
sudo apt-get purge gnome-shell ubuntu-wallpapers-bionic light-themes chromium-browser* libvisionworks libvisionworks-sfm-dev -y
sudo apt-get autoremove -y
sudo apt clean -y

# remove static libs (maybe cleaner to remove the "dev" packages instead)
sudo rm -rf /usr/local/cuda/targets/aarch64-linux/lib/*.a \
    /usr/lib/aarch64-linux-gnu/libcudnn*.a \
    /usr/lib/aarch64-linux-gnu/libnvcaffe_parser*.a \
    /usr/lib/aarch64-linux-gnu/libnvinfer*.a \
    /usr/lib/aarch64-linux-gnu/libnvonnxparser*.a \
    /usr/lib/aarch64-linux-gnu/libnvparsers*.a
