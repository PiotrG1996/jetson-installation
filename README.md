# Nvidia Jetson with ROS for Computer Vision

## Nvidia Jetson Boards - motivation

The development of minimalist images for Nvidia Jetson boards addresses the challenge posed by the large size and excessive pre-installed packages of official Jetson images. These packages often consume significant disk space and memory, which can be detrimental to performance in resource-constrained environments. These minimalist images aim to provide a streamlined alternative, optimizing both space and resource utilization.

## Supported boards

- ✅ Jetson Nano / Jetson Nano 2GB
- ✅ Jetson Orin Nano
- ✅ Jetson AGX Xavier
- ✅ Jetson Xavier NX

## Specification

**Supported Ubuntu releases**: 20.04, 22.04, 24.04

**L4T versions**: 32.x, 35.x, 36.x

> [!IMPORTANT]
> For jetson orin nano, you might need to update the firmware before being able to use an image based on l4t 36.x
>
> check this [link](https://www.jetson-ai-lab.com/initial_setup_jon.html) for more information.



## Build the jetson image yourself

> [!NOTE]
> Building the jetson image has been tested on Linux machines.

Building the jetson image is fairly easy. All you need to have is the following tools installed on your machine.

- [podman](https://github.com/containers/podman)
- [just](https://github.com/casey/just)
- [jq](https://github.com/stedolan/jq)
- [qemu-user-static]()

Start by cloning the repository from github

```bash
git clone https://github.com/PiotrG1996/jetson-installation
cd jetson-image/jetson-standard-images
```



Then create a new rootfs with the desired ubuntu version.

> [!NOTE]
> Only the orin family boards can use ubuntu 24.04

For ubuntu 22.04

```
just build-jetson-rootfs 20.04
```

This will create the rootfs in the `rootfs` directory.

> [!TIP]
> You can modify the `Containerfile.rootfs.*` files to add any tool or configuration that you will need in the final image.

Next, use the following command to build the Jetson image:

```
$ just build-jetson-image -b <board> -r <revision> -d <device> -l <l4t version>
```

> [!TIP]
> If you wish to add some specific nvidia packages that are present in the `common` section from [this link](https://repo.download.nvidia.com/jetson/)
> such as `libcudnn8` for instance, then edit the file`l4t_packages.txt` in the root directory, add list each package name on separate line.

For example, to build an image for `jetson-orin-nano` board:

```bash
$ just build-jetson-image -b jetson-orin-nano -d SD -l 36
```

Run with `-h` for more information

```bash
just build-jetson-image -h
```

> [!NOTE]
> Not every jetson board can be updated to the latest l4t version.
>
> Check this [link](https://developer.nvidia.com/embedded/jetson-linux-archive) for more information.

The Jetson image will be built and saved in the current directory in a file named `jetson.img`

## Flashing the image into your board

To flash the jetson image, just run the following command:

```
$ sudo just flash-jetson-image <jetson image file> <device>
```

Where `device` is the name of the sdcard/usb identified by your system.
For instance, if your sdard is recognized as `/dev/sda`, then replace `device` by `/dev/sda`

> [!NOTE]
> There are numerous tools out there to flash images to sd card that you can use. I stick with `dd` as it's simple and does the job.

## Nvidia Libraries

Once you boot the board with the new image, then you can install Nvidia libraries using `apt`

```bash
$ sudo apt install -y libcudnn8 libcudnn8-dev ...
```


# Jetson Nano Docker

This repository contains docker containers that are built on top of an modified [nvcr.io/nvidia/l4t-base:r32.7.1](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/l4t-base/tags) container. The container has been modified by upgrading core Ubuntu 18.04 to Ubuntu 20.04. 

[dusty-nv/jetson-containers](https://github.com/dusty-nv/jetson-containers) allows building containers for Jetson nano but they are based on offical [nvcr.io/nvidia/l4t-base:r32.7.1](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/l4t-base/tags) which is based on Ubuntu 18.04 and is limited by Python 3.6.9. 

Due to this, being inspired from [Qengineering/Jetson-Nano-Ubuntu-20-image](https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image) and based on [gpshead/Dockerfile](https://gist.github.com/gpshead/0c3a9e0a7b3e180d108b6f4aef59bc19), this container provides an Ubuntu 20.04 version of [nvcr.io/nvidia/l4t-base:r32.7.1](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/l4t-base/tags)

> Ubuntu 22.04 was also attempted, but later abandoned due to lack of support for gcc-8, g++8 and clang-8 required by CUDA 10.2 in r32.7.1

## Docker buildx for ARM64 platform (for AMD64 systems)

Run the following command on a AMD64 computer to setup buildx to build arm64 docker containers.
```bash
docker buildx create --use --driver-opt network=host --name MultiPlatform --platform linux/arm64
```

## Docker container list

<details> 
<summary> <h3> Jetson Ubuntu Foxy Base Image </h3> </summary>

- Size is about 822 MB
- Contains,
    * Python 3.8.10

### Pull or Build

Pull the docker container
```bash
docker pull ghcr.io/kalanaratnayake/foxy-base:r32.7.1
```

Build the docker container
```bash
docker buildx build --load --platform linux/arm64 -f base-images/foxy.Dockerfile -t foxy-base:r32.7.1 .
```

### Start

Start the docker container
```bash
docker run --rm -it --runtime nvidia --network host --gpus all -e DISPLAY ghcr.io/kalanaratnayake/foxy-base:r32.7.1 bash
```
<br>

</details>

<details> 
<summary> <h3> Jetson Ubuntu Foxy Minimal Image </h3> </summary>

- Size is about 1.11GB
- Contains,
    * Python 3.8.10
    * GCC-8, G++-8 (for building CUDA 10.2 related applications)
    * build-essential package (g++-9, gcc-9, make, dpkg-dev, libc6-dev)

### Pull or Build

Pull the docker container
```bash
docker pull ghcr.io/kalanaratnayake/foxy-minimal:r32.7.1
```

Build the docker container
```bash
docker buildx build --load --platform linux/arm64 -f test-images/foxy_test.Dockerfile -t foxy-minimal:r32.7.1 .
```

### Start

Start the docker container
```bash
docker run --rm -it --runtime nvidia --network host --gpus all -e DISPLAY ghcr.io/kalanaratnayake/foxy-minimal:r32.7.1 bash
```

### Test

Run the following commands inside the docker container to test the nvcc and other jetson nano specific functionality
```bash
/usr/local/cuda-10.2/bin/cuda-install-samples-10.2.sh .
cd /NVIDIA_CUDA-10.2_Samples/1_Utilities/deviceQuery
make clean
make HOST_COMPILER=/usr/bin/g++-8
./deviceQuery
```
<br>
</details>

<details> 
<summary> <h3> Jetson ROS Humble Core Image </h3> </summary>
  
- Size is about 1.71GB
- Contains,
    * Python 3.8.10
    * build-essential package (g++-9, gcc-9, make, dpkg-dev, libc6-dev)
    * ROS Humble [Core packages](https://www.ros.org/reps/rep-2001.html#id23)
  
### Pull or Build

Pull the docker container
```bash
docker pull ghcr.io/kalanaratnayake/foxy-ros:humble-core-r32.7.1
```

Build the docker container
```bash
docker buildx build --load --platform linux/arm64 -f ros-images/humble_core.Dockerfile -t foxy-ros:humble-core-r32.7.1 .
```

or build with cache locally and push when image compilation can be slow on github actions and exceeds 6rs

```bash
docker buildx build --push \
                    --platform linux/arm64 \
                    --cache-from=type=registry,ref=ghcr.io/kalanaratnayake/foxy-ros:humble-ros-core-buildcache \
                    --cache-to=type=registry,ref=ghcr.io/kalanaratnayake/foxy-ros:humble-ros-core-buildcache,mode=max  \
                    -f ros-images/humble_core.Dockerfile  \
                    -t ghcr.io/kalanaratnayake/foxy-ros:humble-core-r32.7.1 .
```

### Start

Start the docker container

```bash
docker run --rm -it --runtime nvidia --network host --gpus all -e DISPLAY ghcr.io/kalanaratnayake/foxy-ros:humble-core-r32.7.1 bash
```

### Test

Run the following commands inside the docker container to confirm that the container is working properly
```bash
ros2 run demo_nodes_cpp talker
```

Run the following commands on another instance of ros container or another Computer/Jetson device installed with ROS humble to check 
connectivity over host network and discoverability (while the above command is running).
```bash
ros2 run demo_nodes_py listener
```

<br>

</details>

<details> 
<summary> <h3> Jetson ROS Humble Base Image </h3> </summary>

- Size is about 1.76GB
- Contains,
    * Python 3.8.10
    * build-essential package (g++-9, gcc-9, make, dpkg-dev, libc6-dev)
    * ROS Humble [Base packages](https://www.ros.org/reps/rep-2001.html#id24)
  
### Pull or Build

Pull the docker container
```bash
docker pull ghcr.io/kalanaratnayake/foxy-ros:humble-base-r32.7.1
```

Build the docker container
```bash
docker buildx build --load --platform linux/arm64 -f ros-images/humble_base.Dockerfile -t foxy-ros:humble-base-r32.7.1 .
```

or build with cache locally and push when image compilation can be slow on github actions and exceeds 6rs

```bash
docker buildx build --push \
                    --platform linux/arm64 \
                    --cache-from=type=registry,ref=ghcr.io/kalanaratnayake/foxy-ros:humble-ros-base-buildcache \
                    --cache-to=type=registry,ref=ghcr.io/kalanaratnayake/foxy-ros:humble-ros-base-buildcache,mode=max  \
                    -f ros-images/humble_base.Dockerfile  \
                    -t ghcr.io/kalanaratnayake/foxy-ros:humble-base-r32.7.1 .
```

### Start

Start the docker container
```bash
docker run --rm -it --runtime nvidia --network host --gpus all -e DISPLAY ghcr.io/kalanaratnayake/foxy-ros:humble-base-r32.7.1 bash
```

### Test

Run the following commands inside the docker container to confirm that the container is working properly.
```bash
ros2 run demo_nodes_cpp talker
```

Run the following commands on another instance of ros container or another Computer/Jetson device installed with ROS humble to check 
connectivity over host network and discoverability (while the above command is running).
```bash
ros2 run demo_nodes_py listener
```

<br>
</details>

<details> 
<summary> <h3> Jetson Ubuntu Foxy Pytorch 1.13 Image </h3> </summary>
  
- Size is about 1.83GB
- Contains,
    * Python 3.8.10
    * PyTorch 1.13.0
    * TorchVision 0.14.0
  
### Pull or Build

Pull the docker container
```bash
docker pull ghcr.io/kalanaratnayake/foxy-pytorch:1-13-r32.7.1
```

Build the docker container
```bash
docker buildx build --load --platform linux/arm64 -f pytorch-images/foxy_pytorch_1_13.Dockerfile -t foxy-pytorch:1-13-r32.7.1 .
```

### Start

Start the docker container

```bash
docker run --rm -it --runtime nvidia --network host --gpus all -e DISPLAY ghcr.io/kalanaratnayake/foxy-pytorch:1-13-r32.7.1 bash
```

### Test

Run the following commands inside the docker container to confirm that the container is working properly.
```bash
python3 -c "import torch; print(torch.__version__)"
python3 -c "import torchvision; print(torchvision.__version__)"
```

<br>

</details>

<details> 
<summary> <h3> Jetson Ubuntu Foxy Pytorch 1.13 with TensorRT Image </h3> </summary>
  
- Size is about 1.83GB
- Contains,
    * Python 3.8.10
    * PyTorch 1.13.0
    * TorchVision 0.14.0
  
### Pull or Build

Pull the docker container
```bash
docker pull ghcr.io/kalanaratnayake/foxy-pytorch:1-13-tensorrt-j-nano
```

Build the docker container
```bash
docker buildx build --load --platform linux/arm64 -f pytorch-images/foxy_pytorch_1_13.Dockerfile -t foxy-pytorch:1-13-tensorrt-j-nano .
```

### Start

Start the docker container

```bash
docker run --rm -it --runtime nvidia --network host --gpus all -e DISPLAY ghcr.io/kalanaratnayake/foxy-pytorch:1-13-tensorrt-j-nano bash
```

### Test

Run the following commands inside the docker container to confirm that the container is working properly.
```bash
python3 -c "import torch; print(torch.__version__)"
python3 -c "import torchvision; print(torchvision.__version__)"
python3 -c "import tensorrt as trt; print(trt.__version__)"
dpkg -l | grep TensorRT
```

<br>

</details>

<details> 
<summary> <h3> Jetson Ubuntu Foxy Humble Core Pytorch 1.13 Image </h3> </summary>
  
- Size is about 3.05GB
- Contains,
    * Python 3.8
    * PyTorch 1.13.0
    * TorchVision 0.14.0
    * ROS Humble [Core packages](https://www.ros.org/reps/rep-2001.html#id23)
  
### Pull or Build

Pull the docker container
```bash
docker pull ghcr.io/kalanaratnayake/foxy-ros-pytorch:1-13-humble-core-r32.7.1
```

Build the docker container
```bash
docker buildx build --load --platform linux/arm64 -f ros-pytorch-images/humble_core_pytorch_1_13.Dockerfile -t foxy-ros-pytorch:1-13-humble-core-r32.7.1 .
```

### Start

Start the docker container

```bash
docker run --rm -it --runtime nvidia --network host --gpus all -e DISPLAY ghcr.io/kalanaratnayake/foxy-ros-pytorch:1-13-humble-core-r32.7.1 bash
```

### Test

Run the following commands inside the docker container to confirm that the container is working properly.
```bash
python3 -c "import torch; print(torch.__version__)"
python3 -c "import torchvision; print(torchvision.__version__)"
```

Run the following commands inside the docker container to confirm that the container is working properly.
```bash
ros2 run demo_nodes_cpp talker
```

Run the following commands on another instance of ros container or another Computer/Jetson device installed with ROS humble to check 
connectivity over host network and discoverability (while the above command is running).
```bash
ros2 run demo_nodes_py listener
```

<br>

</details>


# Jetson Nano with ROS2

## Setup

- **Power Supply:** 🔌 The Jetson Nano can be powered via a micro USB power supply (5V, 2A, 10W max), sufficient for operating a keyboard, mouse, and a small camera. For scenarios involving Neural Networks and depth cameras, it is recommended to use the DC barrel jack (5V, 4A, 20W max) for enhanced stability.
  
- **System Setup Comparison:** 🔍 This section outlines various combinations of Ubuntu and ROS2 tested with and without GUI, as well as with and without Docker. The goal was to identify a stable configuration that supports the latest ROS version and maximizes the performance of the Jetson Nano.

## System Setup Comparison

- 🖥️  **GUI Availability**  the "GUI" column indicates whether a graphical user interface (GUI) is present. Configurations without a GUI were achieved by removing all GUI-related components. For guidance on removing the GUI, please refer to relevant tutorials.

- 📊 **Idle RAM** measurements are provided to assess the maximum size of Neural Network models that can be loaded onto the device.

- 🐳 **Docker Configurations** in Docker-enabled setups, Idle RAM was measured while the base ROS Docker image was running.

- ⚙️ **Overclocking Settings**  only the default overclocking settings were applied in the tests. For further customization, refer to the [overclocking guide](https://qengineering.eu/overclocking-the-jetson-nano.html).


- Docker ROS-Humble-ROS-Base can be installed with the following command:

    ```bash
    docker pull dustynv/ros:humble-ros-base-l4t-r32.7.1
    ```

<br>

| Ubuntu | Jetpack | CUDA | ROS | GUI | Docker | CPU / GPU Frequency | Idle RAM (GB) | Tutorial |
|---	|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| [20.04](https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image?tab=readme-ov-file#bare-image) | 4.6.2 | 10.2 |[Humble](https://hub.docker.com/layers/dustynv/ros/humble-ros-base-l4t-r32.7.1/images/sha256-833447d4c81735c71cd61587b9cd61275cf7158f44bec074a135e6f3e662187a?context=explore) | Yes	| Yes | 1900Mz / 998Mz | 1.3 / 3.9 | [Image](/images/u20-humble-Docker-Desktop.png) [Tutorial](/docs/u20-humble-Docker-Desktop.md)  |
| [20.04](https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image?tab=readme-ov-file#bare-image) | 4.6.2 | 10.2  |[Humble](https://hub.docker.com/layers/dustynv/ros/humble-ros-base-l4t-r32.7.1/images/sha256-833447d4c81735c71cd61587b9cd61275cf7158f44bec074a135e6f3e662187a?context=explore)	| No | Yes | 1900Mz / 998Mz | 0.44 / 3.9 | [Image](/images/u20-humble-Docker-noDesktop.png) [Tutorial](/docs/u20-humble-Docker-noDesktop.md)  |
| [20.04](https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image?tab=readme-ov-file#bare-image) | 4.6.2 | 10.2  |Foxy | Yes | No | 1900Mz / 998Mz | 1.2 / 3.9 | [Image](/images/u20-foxy-noDocker-Desktop.png) [Tutorial](/docs/u20-foxy-noDocker-Desktop.md) |
| [20.04](https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image?tab=readme-ov-file#bare-image) | 4.6.2 | 10.2  |Foxy | No	| No 	| 1900Mz / 998Mz | 0.40 / 3.9 | [Image](/images/u20-foxy-noDocker-noDesktop.png) [Tutorial](/docs/u20-foxy-noDocker-noDesktop.md) |
| [18.04](https://developer.nvidia.com/embedded/learn/get-started-jetson-nano-devkit#write)| 4.6.4 | 10.2  | [Humble](https://hub.docker.com/layers/dustynv/ros/humble-ros-base-l4t-r32.7.1/images/sha256-833447d4c81735c71cd61587b9cd61275cf7158f44bec074a135e6f3e662187a?context=explore) | Yes | Yes | 1479Mz / 920Mz | Really Slow | Not Successful | [Image](/images/u18-humble-Docker-Desktop.png) [Tutorial](/docs/u18-humble-Docker-Desktop.md) |
| [18.04](https://developer.nvidia.com/embedded/learn/get-started-jetson-nano-devkit#write)| 4.6.4 | 10.2  | [Humble](https://hub.docker.com/layers/dustynv/ros/humble-ros-base-l4t-r32.7.1/images/sha256-833447d4c81735c71cd61587b9cd61275cf7158f44bec074a135e6f3e662187a?context=explore)	| No | Yes | 1479Mz / 920Mz | Really slow | Not Successful |


# Jetson ROS2 with YOLO 

## Docker Usage by adding to compose.yml file

To use GPU with docker while on AMD64 systems, install [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) with given instructions.

### Supported platforms

| System      | ROS Version | Value for `image`                               | Value for `device`  | Size    | file  |
| :---        | :---        | :---                                            |  :---               | :---:   | :---: |
| AMD64       | Humble      | ghcr.io/kalanaratnayake/yolo-ros:humble         | `cpu`, `0`, `0,1,2` | 5.64 GB | docker/compose.amd64.yaml |
| Jetson Nano | Humble      | ghcr.io/kalanaratnayake/yolo-ros:humble-j-nano  | `cpu`, `0`          | 3.29GB  | docker/compose.jnano.yaml |

## Docker Usage with this repository

Clone this reposiotory

```bash
mkdir -p yolo_ws/src && cd yolo_ws/src
git clone https://github.com/PiotrG1996/jetson-installation.git && cd jetson-ROS-YOLO
cd ..
```

<details> 
<summary> <h3> on AMD64 </h3> </summary>

Pull the Docker image and start compose (No need to run `docker compose build`)
```bash
cd src/yolo_ros/docker
docker compose -f compose.amd64.yaml pull
docker compose -f compose.amd64.yaml up
```

To clean the system,
```bash
cd src/yolo_ros/docker
docker compose -f compose.amd64.yaml down
docker volume rm docker_yolo
```
</details>

<details> 
<summary> <h3> on JetsonNano </h3> </summary>

Pull the Docker image and start compose (No need to run `docker compose build`)
```bash
cd src/yolo_ros/docker
docker compose -f compose.jnano.yaml pull
docker compose -f compose.jnano.yaml up
```

To clean the system,
```bash
cd src/yolo_ros/docker
docker compose -f compose.jnano.yaml down
docker volume rm docker_yolo
```
</details>

<br>

## Native Usage

Clone this repository with and install dependencies.

```bash
git clone https://github.com/KalanaRatnayake/yolo_ros.git
git clone https://github.com/KalanaRatnayake/detection_msgs.git
cd yolo_ros
pip3 install -r requirements.txt
```

### Build the package

If required, edit the parameters at `config/yolo_ros_params.yaml' and then at the workspace root run,
```bash
colcon build
```
### Start the system

To use the launch file, run,

```bash
source ./install/setup.bash
ros2 launch yolo_ros yolo.launch.py
```

<br>
<br>

## Parameter decription

| ROS Parameter           | Docker ENV parameter    | Default Value               | Description |
| :---                    | :---                    | :---:                       | :---        |
| yolo_model              | YOLO_MODEL              | `yolov9t.pt`                | Model to be used. see [1] for default models and [2] for custom models |
| subscribe_depth         | SUBSCRIBE_DEPTH         | `True`                      | Whether to subscribe to depth image or not. Use if having a depth camera. A ApproximateTimeSynchronizer is used to sync RGB and Depth images |
| input_rgb_topic         | INPUT_RGB_TOPIC         | `/camera/color/image_raw`   | Topic to subscribe for RGB image. Accepts `sensor_msgs/Image` |
| input_depth_topic       | INPUT_DEPTH_TOPIC       | `/camera/depth/points`      | Topic to subscribe for Depth image. Accepts `sensor_msgs/Image` |
| publish_detection_image | PUBLISH_ANNOTATED_IMAGE | `False`                     | Whether to publish annotated image, increases callback execution time when set to `True` |
| annotated_topic         | ANNOTATED_TOPIC         | `/yolo_ros/annotated_image` | Topic for publishing annotated images uses `sensor_msgs/Image` |
| detailed_topic          | DETAILED_TOPIC          | `/yolo_ros/detection_result`| Topic for publishing detailed results uses `yolo_ros_msgs/YoloResult` |
| threshold               | THRESHOLD               | `0.25`                      | Confidence threshold for predictions |
| device                  | DEVICE                  | `'0'`                       | `cpu` for CPU, `0` for gpu, `0,1,2,3` if there are multiple GPUs |

[1] If the model is available at [ultralytics models](https://docs.ultralytics.com/models/), It will be downloaded from the cloud at the startup. We are using docker volumes to maintain downloaded weights so that weights are not downloaded at each startup.

[2] Uncomment the commented out `YOLO_MODEL` parameter line and give the custom model weight file's name as `YOLO_MODEL` parameter. Uncomment the docker bind entry that to direct to the `weights` folder and comment the docker volume entry for yolo. Copy the custom weights to the `weights` folder.

## Latency description

Here is a summary of whether latest models work with yolo_ros node (in docker) on various platforms and the time it takes to execute a single interation of `YoloROS.image_callback` function. Values are measured as an average of 100 executions of the function and Input is a 640x480 RGB image at 30 fps.

### Performance Metrics

| Model        |  Jetson Nano (ms)  | Jetson Nano (FPS) |
| :----------- | ----------------: | -----------------: |
| `yolov10x.pt` | 975 ms           | 1.03 FPS          |
| `yolov10l.pt` | 800 ms           | 1.25 FPS          |
| `yolov10b.pt` | 750 ms           | 1.33 FPS          |
| `yolov10m.pt` | 650 ms           | 1.54 FPS          |
| `yolov10s.pt` | 210 ms           | 4.76 FPS          |
| `yolov10n.pt` | 140 ms           | 7.14 FPS          |
| `yolov9e.pt`  | 1600 ms          | 0.62 FPS          |
| `yolov9c.pt`  | 700 ms           | 1.43 FPS          |
| `yolov9m.pt`  | 500 ms           | 2.00 FPS          |
| `yolov9s.pt`  | 300 ms           | 3.33 FPS          |
| `yolov9t.pt`  | 180 ms           | 5.56 FPS          |
| `yolov8x.pt`  | 2000 ms          | 0.50 FPS          |
| `yolov8l.pt`  | 1200 ms          | 0.83 FPS          |
| `yolov8m.pt`  | 700 ms           | 1.43 FPS          |
| `yolov8s.pt`  | 300 ms           | 3.33 FPS          |
| `yolov8n.pt`  | 140 ms           | 7.14 FPS          |

### Conversion Formula

To convert milliseconds *(ms)* to frames per second *(FPS)*, use the following formula:

\[ \text{FPS} = \frac{1000}{\text{ms}} \]



# Jetson Copilot Offline Setup Guide


## 🏃 Getting Started

### First Time Setup

To set up Jetson Copilot for the first time, follow these steps to ensure that all necessary software is installed and the environment is properly configured.

1. **Clone the Jetson Copilot repository:**
    ```bash
    git clone https://github.com/NVIDIA-AI-IOT/jetson-copilot/
    ```

2. **Navigate to the cloned directory:**
    ```bash
    cd jetson-copilot
    ```

3. **Run the setup script:**
    ```bash
    ./setup_environment.sh
    ```

This script will install the following components if they are not already present on your system:
- Chromium web browser
- Docker

### How to Start Jetson Copilot

1. **Navigate to the Jetson Copilot directory:**
    ```bash
    cd jetson-copilot
    ```

2. **Launch Jetson Copilot:**
    ```bash
    ./launch_jetson_copilot.sh
    ```

This command will start a Docker container, which will then start an Ollama server and a Streamlit app inside the container. The console will display a URL for accessing the web app hosted on your Jetson device.

3. **Open the web app:**
    - On your Jetson device: Open [Local URL](http://localhost:8501) in your web browser.
    - On a PC connected to the same network as your Jetson: Access the [Network URL](http://10.110.50.252:8501).

#### Note
- An internet connection is required on the Jetson device during the first launch to pull the container image and download the default LLM and embedding model.
- The first time you access the web UI, it will download the default LLM (Llama3) and the embedding model (mxbai-embed-large).

#### Tips
- On Ubuntu Desktop, a frameless Chromium window will pop up to access the web app, making it look like an independent application. Ensure to close this window manually if you stop the container from the console, as it won’t automatically close Chromium.

## 📖 How to Use Jetson Copilot

### 0. Interact with the Plain Llama3 (8b)

By default, Jetson Copilot uses the Llama3 (8b) model as the default LLM. You can interact with this model without enabling the RAG (Retrieve and Generate) feature.

### 1. Ask Jetson-Related Questions Using Pre-Built Index

1. On the side panel, toggle "Use RAG" to enable the RAG pipeline.
2. Select a custom knowledge/index from the "Index" dropdown.

A pre-built index "_L4T_README" is available and includes all README text files from the "L4T-README" folder on your Jetson device.

To access the L4T-README folder:
    ```bash
    udisksctl mount -b /dev/disk/by-label/L4T-README
    ```

You can ask questions related to Jetson specifics, such as:
- What IP address does Jetson get assigned when connected to a PC via a USB cable in USB Device Mode?

### 2. Build Your Own Index Based on Your Documents

1. Create a directory under `Documents` to store your documents:
    ```bash
    cd jetson-copilot
    mkdir Documents/Jetson-Orin-Nano
    cd Documents/Jetson-Orin-Nano
    wget https://developer.nvidia.com/downloads/assets/embedded/secure/jetson/orin_nano/docs/jetson_orin_nano_devkit_carrier_board_specification_sp.pdf
    ```

2. In the web UI, open the side bar, toggle "Use RAG," and click "➕ Build a new index" to open the "Build Index" page.

3. Name your index (e.g., "JON Carrier Board") and specify the path for the index directory.

4. Select the directory you created (e.g., `/opt/jetson_copilot/Documents/Jetson-Orin-Nano`) or enter URLs for online documents if needed.

5. Ensure that `mxbai-embed-large` is selected for the embedding model. Note that OpenAI embedding models are not well-supported and may require additional testing.

6. Click "Build Index" and monitor the progress in the status container. Once completed, you can select your newly built index from the home screen.

### 3. Test Different LLM or Embedding Models

*This section is TODO and will be updated with instructions for testing different LLMs and embedding models.*

## 🏗️ Development

Developing your Streamlit-based web app is straightforward:

1. Enable automatic updates of the app every time you change the source code by selecting "Always rerun" in the web UI.

2. For more fundamental changes, manually run the Streamlit app inside the container:
    ```bash
    cd jetson-copilot
    ./launch_dev.sh
    ```

    Once inside the container:
    ```bash
    streamlit run app.py
    ```

## 🧱 Directory Structure

Here's an overview of the directory structure:


```bash
└── jetson-copilot
    ├── launch_jetson_copilot.sh
    ├── setup_environment.sh
    ├── Documents 
    │   └── your_abc_docs
    ├── Indexes
    │   ├── _L4T_README
    │   └── your_abc_index
    ├── logs
    │   ├── container.log
    │   └── ollama.log
    ├── ollama_models
    └── Streamlit_app
        ├── app.py
        ├── build_index.py
        └── download_model.py
```