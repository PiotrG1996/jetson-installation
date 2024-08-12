#!/bin/bash

set -e

# Define the BSP URL
BSP=https://developer.nvidia.com/embedded/l4t/r32_release_v6.1/t210/jetson-210_linux_r32.6.1_aarch64.tbz2

# Check if the script is running as root
if [ "$(whoami)" != "root" ]; then
    echo -e "\e[31mThis script requires root privileges. Please run as root.\e[0m"
    exit 1
fi

# Check for necessary environment variables
if [ -z "$JETSON_ROOTFS_DIR" ] || [ -z "$JETSON_BUILD_DIR" ]; then
    echo -e "\e[31mPlease set the environment variables \$JETSON_ROOTFS_DIR and \$JETSON_BUILD_DIR\e[0m"
    exit 1
fi

# Check if $JETSON_ROOTFS_DIR is non-empty
if [ ! -d "$JETSON_ROOTFS_DIR" ] || [ ! "$(ls -A "$JETSON_ROOTFS_DIR")" ]; then
    echo -e "\e[31mNo root filesystem found in $JETSON_ROOTFS_DIR\e[0m"
    exit 1
fi

# Check if the Jetson board type is specified
if [ -z "$JETSON_NANO_BOARD" ]; then
    echo -e "\e[31mJetson Nano board type must be specified (e.g., jetson-nano-2gb or jetson-nano)\e[0m"
    exit 1
fi

echo -e "\e[32mStarting to build the image...\e[0m"

# Create the build directory if it does not exist
mkdir -p "$JETSON_BUILD_DIR"

# Download L4T if the build directory is empty
if [ ! "$(ls -A "$JETSON_BUILD_DIR")" ]; then
    echo -e "\e[32mDownloading L4T...\e[0m"
    wget -qO- "$BSP" | tar -jxpf - -C "$JETSON_BUILD_DIR"
    echo -e "\e[32m[OK] L4T downloaded and extracted\e[0m"

    # Apply NVIDIA's known fixes for specific BSP versions
    case "$BSP" in
        *32.5*)
            sed -i 's/cp -f/cp -af/g' "$JETSON_BUILD_DIR/Linux_for_Tegra/tools/ota_tools/version_upgrade/ota_make_recovery_img_dtb.sh"
            ;;
        *32.6*)
            sed -i 's/rootfs_size +/rootfs_size + 128 +/g' "$JETSON_BUILD_DIR/Linux_for_Tegra/tools/jetson-disk-image-creator.sh"
            ;;
    esac
fi

# Copy the root filesystem into the build directory
echo -e "\e[32mCopying root filesystem...\e[0m"
cp -rp "$JETSON_ROOTFS_DIR/"* "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/"
echo -e "\e[32m[OK] Root filesystem copied\e[0m"

# Apply patches
if [ -f "patches/nv-apply-debs.diff" ]; then
    echo -e "\e[32mApplying patches...\e[0m"
    patch "$JETSON_BUILD_DIR/Linux_for_Tegra/nv_tegra/nv-apply-debs.sh" < patches/nv-apply-debs.diff > /dev/null
    echo -e "\e[32m[OK] Patches applied\e[0m"
else
    echo -e "\e[33mWarning: Patch file not found. Skipping patches.\e[0m"
fi

# Run NVIDIA's apply_binaries.sh script
pushd "$JETSON_BUILD_DIR/Linux_for_Tegra/" > /dev/null
echo -e "\e[32mApplying NVIDIA binaries...\e[0m"
./apply_binaries.sh &> /dev/null
popd > /dev/null
echo -e "\e[32m[OK] NVIDIA binaries applied\e[0m"

# Create the Jetson image based on the board type
pushd "$JETSON_BUILD_DIR/Linux_for_Tegra/tools" > /dev/null
case "$JETSON_NANO_BOARD" in
    jetson-nano-2gb)
        echo -e "\e[32mCreating image for Jetson Nano 2GB board...\e[0m"
        ROOTFS_DIR=$JETSON_ROOTFS_DIR ./jetson-disk-image-creator.sh -o jetson.img -b jetson-nano-2gb-devkit
        ;;
    jetson-nano)
        nano_board_revision=${JETSON_NANO_REVISION:=300}
        echo -e "\e[32mCreating image for Jetson Nano board (revision $nano_board_revision)...\e[0m"
        ROOTFS_DIR=$JETSON_ROOTFS_DIR ./jetson-disk-image-creator.sh -o jetson.img -b jetson-nano -r $nano_board_revision
        ;;
    *)
        echo -e "\e[31mUnknown Jetson Nano board type specified: $JETSON_NANO_BOARD\e[0m"
        exit 1
        ;;
esac

popd > /dev/null

# Copy the created image to the current directory
if [ -f "$JETSON_BUILD_DIR/Linux_for_Tegra/tools/jetson.img" ]; then
    cp "$JETSON_BUILD_DIR/Linux_for_Tegra/tools/jetson.img" .
    echo -e "\e[32mImage created successfully and copied to ./jetson.img\e[0m"
else
    echo -e "\e[31mImage creation failed. No image found in the build directory.\e[0m"
    exit 1
fi
