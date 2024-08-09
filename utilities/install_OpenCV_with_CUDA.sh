#!/bin/bash

# Script to install OpenCV with CUDA support on Jetson Nano

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt-get update && sudo apt-get upgrade -y

# Install dependencies
echo "Installing dependencies..."
sudo apt-get install -y build-essential cmake git libgtk2.0-dev pkg-config \
libavcodec-dev libavformat-dev libswscale-dev python3-dev python3-numpy \
libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev \
libv4l-dev v4l-utils qv4l2 v4l2ucp libgstreamer1.0-dev \
libgstreamer-plugins-base1.0-dev libavresample-dev x264 libx264-dev \
libopenblas-dev libatlas-base-dev gfortran libhdf5-dev \
libprotobuf-dev protobuf-compiler libgoogle-glog-dev \
libgflags-dev libgphoto2-dev libeigen3-dev libhdf5-serial-dev \
hdf5-tools libqt4-dev mesa-utils libglew-dev python3-testresources \
qt5-default

# Download OpenCV and OpenCV Contrib
echo "Downloading OpenCV and OpenCV Contrib..."
cd ~
git clone https://github.com/opencv/opencv.git
git clone https://github.com/opencv/opencv_contrib.git

# Checkout a specific version (Optional)
echo "Checking out OpenCV version 4.5.0..."
cd ~/opencv
git checkout 4.5.0

cd ~/opencv_contrib
git checkout 4.5.0

# Create a build directory and configure the build with CMake
echo "Configuring the build with CMake..."
cd ~/opencv
mkdir build
cd build

cmake -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
      -D WITH_CUDA=ON \
      -D CUDA_ARCH_BIN=5.3 \
      -D CUDA_ARCH_PTX= \
      -D WITH_CUDNN=ON \
      -D OPENCV_DNN_CUDA=ON \
      -D ENABLE_FAST_MATH=ON \
      -D CUDA_FAST_MATH=ON \
      -D WITH_CUBLAS=ON \
      -D WITH_LIBV4L=ON \
      -D BUILD_opencv_python3=ON \
      -D BUILD_opencv_python2=OFF \
      -D BUILD_TESTS=OFF \
      -D BUILD_PERF_TESTS=OFF \
      -D WITH_QT=ON \
      -D WITH_OPENGL=ON \
      -D OPENCV_ENABLE_NONFREE=ON \
      -D EIGEN_INCLUDE_PATH=/usr/include/eigen3 \
      ..

# Compile OpenCV
echo "Compiling OpenCV (this may take a while)..."
make -j4

# Install OpenCV
echo "Installing OpenCV..."
sudo make install
sudo ldconfig

# Verify installation
echo "Verifying OpenCV installation..."
python3 -c "import cv2; print('OpenCV version:', cv2.__version__); print('CUDA enabled devices:', cv2.cuda.getCudaEnabledDeviceCount())"

echo "OpenCV installation with CUDA support is complete!"
