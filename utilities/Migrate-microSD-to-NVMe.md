# Jetson Orin NVMe SSD Migration Guide

**Author:** Piotr Gapski  
**Organization:** RoboticsGap Systems  
**Version:** 1.0  
**Date:** September 2025  

## Overview

This guide provides complete step-by-step instructions for migrating your NVIDIA Jetson Orin system from a microSD card to an NVMe M.2 SSD for significantly improved performance and reliability.

## Prerequisites

- NVIDIA Jetson Orin (AGX or NX)
- NVMe M.2 SSD installed in the M.2 slot
- microSD card with working JetPack installation
- SSH or direct access to the Jetson
- Basic Linux command line knowledge

## Performance Benefits

Migrating to NVMe SSD provides:
- **10-20x faster read/write speeds** compared to microSD
- **Reduced system lag** and faster application loading
- **Better reliability** and longer lifespan
- **More storage capacity** (typically 256GB-2TB vs 32-128GB SD cards)

## Step-by-Step Migration Process

### Phase 1: System Assessment

#### 1.1 Verify Current System Status

```bash
# Check current root filesystem
df -h /

# Verify NVMe detection
lsblk -f

# Check NVMe drive details
sudo fdisk -l /dev/nvme0n1

# Verify current boot parameters
cat /proc/cmdline
```

**Expected output should show:**
- Root filesystem mounted from `/dev/mmcblk0p1` (microSD)
- NVMe drive detected as `/dev/nvme0n1`

#### 1.2 Install Required Tools

```bash
# Update package list
sudo apt update

# Install necessary tools
sudo apt install rsync gparted parted -y
```

### Phase 2: Prepare NVMe Drive

#### 2.1 Backup Important Data (Recommended)

```bash
# Create backup directory
mkdir -p ~/backup

# Backup critical configuration files
sudo cp -r /etc ~/backup/
sudo cp -r /boot ~/backup/
sudo cp /home/$USER/.* ~/backup/ 2>/dev/null || true
```

#### 2.2 Partition the NVMe Drive

⚠️ **WARNING: This will erase all data on the NVMe drive!**

```bash
# Check current NVMe partitions
sudo parted /dev/nvme0n1 print

# Create new GPT partition table
sudo parted /dev/nvme0n1 mklabel gpt

# Create primary partition for root filesystem
sudo parted /dev/nvme0n1 mkpart primary ext4 1MiB 100%

# Format the partition
sudo mkfs.ext4 /dev/nvme0n1p1

# Verify partition creation
lsblk /dev/nvme0n1
```

### Phase 3: Clone System to NVMe

#### 3.1 Mount NVMe Drive

```bash
# Create mount point
sudo mkdir -p /mnt/nvme

# Mount the NVMe partition
sudo mount /dev/nvme0n1p1 /mnt/nvme

# Verify mount
df -h /mnt/nvme
```

#### 3.2 Clone Root Filesystem

This process takes 15-30 minutes depending on your system size:

```bash
# Clone entire root filesystem to NVMe
sudo rsync -aHAXxv --numeric-ids --progress / /mnt/nvme/ \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"}
```

**Progress indicators:**
- The command shows real-time progress
- Look for file count and transfer rate
- Total size should match your current system usage

#### 3.3 Verify Clone Completion

```bash
# Compare directory structures
ls -la /
ls -la /mnt/nvme/

# Check copied data size
du -sh /
du -sh /mnt/nvme/
```

### Phase 4: Update System Configuration

#### 4.1 Get NVMe Partition UUID

```bash
# Get the UUID of NVMe partition
sudo blkid /dev/nvme0n1p1

# Note the UUID value (example: e29adb36-c68f-40fa-875c-33a5b7d6b442)
```

#### 4.2 Update fstab on NVMe System

```bash
# Edit fstab on the cloned system
sudo nano /mnt/nvme/etc/fstab
```

**Replace the root filesystem line:**

**Before:**
```
/dev/root            /                     ext4           defaults                                     0 1
```

**After:**
```
UUID=YOUR_NVME_UUID_HERE /                     ext4           defaults                                     0 1
```

**Example fstab content:**
```bash
# /etc/fstab: static file system information.
#
# <file system> <mount point>             <type>          <options>                               <dump> <pass>
UUID=e29adb36-c68f-40fa-875c-33a5b7d6b442 /                     ext4           defaults                                     0 1
UUID=3FFC-5543 /boot/efi vfat defaults 0 1
```

### Phase 5: Update Bootloader Configuration

#### 5.1 Backup Current Bootloader Config

```bash
# Create backup of bootloader configuration
sudo cp /boot/extlinux/extlinux.conf /boot/extlinux/extlinux.conf.backup
```

#### 5.2 Update Boot Parameters

```bash
# Edit bootloader configuration
sudo nano /boot/extlinux/extlinux.conf
```

**Find the APPEND line and change:**

**Before:**
```
APPEND ${cbootargs} root=/dev/mmcblk0p1 rw rootwait rootfstype=ext4 ...
```

**After:**
```
APPEND ${cbootargs} root=/dev/nvme0n1p1 rw rootwait rootfstype=ext4 ...
```

**Complete example configuration:**
```bash
TIMEOUT 30
DEFAULT primary

MENU TITLE L4T boot options

LABEL primary
      MENU LABEL primary kernel
      LINUX /boot/Image
      INITRD /boot/initrd
      APPEND ${cbootargs} root=/dev/nvme0n1p1 rw rootwait rootfstype=ext4 mminit_loglevel=4 console=ttyTCU0,115200 firmware_class.path=/etc/firmware fbcon=map:0 nospectre_bhb video=efifb:off console=tty0
```

### Phase 6: Finalize and Test

#### 6.1 Sync and Prepare for Reboot

```bash
# Ensure all data is written to disk
sync

# Unmount NVMe (optional but recommended)
sudo umount /mnt/nvme
```

#### 6.2 Reboot to NVMe System

```bash
# Reboot the system
sudo reboot
```

#### 6.3 Verify Successful Migration

After reboot, run these verification commands:

```bash
# Check root filesystem source
df -h /
# Should show: /dev/nvme0n1p1

# Verify boot parameters
cat /proc/cmdline
# Should show: root=/dev/nvme0n1p1

# Check overall system
lsblk
# Should show nvme0n1p1 mounted at /

# Verify fstab
cat /etc/fstab
# Should show UUID of nvme0n1p1 for root
```

### Phase 7: Performance Testing

#### 7.1 Test Read Performance

```bash
# Test sequential read speed
sudo hdparm -Tt /dev/nvme0n1

# Test random read performance
sudo fio --name=random-read --ioengine=posixaio --rw=randread --bs=4k --size=1g --numjobs=1 --iodepth=1 --runtime=60 --time_based --end_fsync=1
```

#### 7.2 Test Write Performance

```bash
# Test write speed (creates 1GB test file)
time dd if=/dev/zero of=/tmp/speedtest bs=1M count=1000 oflag=direct

# Clean up test file
rm /tmp/speedtest
```

**Expected NVMe performance:**
- **Read speed**: 2000-7000 MB/s
- **Write speed**: 1000-6000 MB/s
- **Random IOPS**: 100,000-500,000+ IOPS

Compare with microSD performance (typically 50-100 MB/s).

## Troubleshooting

### Issue: System Won't Boot from NVMe

**Solution 1: Check Boot Configuration**
```bash
# Boot from microSD (if still available)
# Check extlinux.conf
sudo nano /boot/extlinux/extlinux.conf

# Ensure root parameter points to nvme0n1p1
```

**Solution 2: Verify NVMe Partition**
```bash
# Check if NVMe partition exists and is formatted
sudo fsck /dev/nvme0n1p1

# Check fstab on NVMe system
sudo mount /dev/nvme0n1p1 /mnt/nvme
cat /mnt/nvme/etc/fstab
```

**Solution 3: Fallback to microSD**
```bash
# Edit extlinux.conf to boot from microSD temporarily
sudo nano /boot/extlinux/extlinux.conf

# Change root=/dev/nvme0n1p1 back to root=/dev/mmcblk0p1
```

### Issue: Permission Errors After Migration

**Solution:**
```bash
# Fix ownership and permissions
sudo chown -R $USER:$USER /home/$USER
sudo chmod -R 755 /home/$USER
```

### Issue: Missing Files or Applications

**Solution:**
```bash
# Re-run rsync to catch any missed files
sudo mount /dev/nvme0n1p1 /mnt/nvme
sudo rsync -aHAXxv --numeric-ids / /mnt/nvme/ \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"}
```

## Post-Migration Optimization

### Enable NVMe Power Management

```bash
# Add to /etc/rc.local for better power efficiency
echo 'auto' | sudo tee /sys/block/nvme0n1/queue/scheduler

# Enable NVMe power saving
echo 'med_power_with_dipm' | sudo tee /sys/class/scsi_host/host*/link_power_management_policy
```

### Update Swap Configuration

```bash
# Disable zram swap if using large NVMe
sudo systemctl disable zram-config

# Create swap file on NVMe (optional)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Add to fstab
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Enable TRIM Support

```bash
# Enable TRIM for SSD longevity
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer
```

## Maintenance and Best Practices

### Regular Health Checks

```bash
# Check NVMe health status
sudo nvme smart-log /dev/nvme0n1

# Monitor SSD temperature
sudo nvme get-feature -f 0x02 -H /dev/nvme0n1

# Check filesystem
sudo fsck -f /dev/nvme0n1p1
```

### Backup Strategy

```bash
# Create system backup script
cat > ~/backup_nvme.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/media/external_drive/jetson_backup_$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"
sudo rsync -aHAXxv --numeric-ids / "$BACKUP_DIR/" \
    --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"}
EOF

chmod +x ~/backup_nvme.sh
```

## Additional Resources

- [NVIDIA Jetson Documentation](https://docs.nvidia.com/jetson/)
- [JetPack SDK Documentation](https://developer.nvidia.com/embedded/jetpack)
- [L4T (Linux for Tegra) Documentation](https://docs.nvidia.com/jetson/l4t/)

## FAQ

**Q: Can I keep both microSD and NVMe?**
A: Yes, you can use the microSD for additional storage or as a backup boot option.

**Q: Will this void my warranty?**
A: No, installing an NVMe SSD in the provided M.2 slot does not void the warranty.

**Q: Can I migrate back to microSD?**
A: Yes, simply change the extlinux.conf boot parameters back to `/dev/mmcblk0p1`.

**Q: How much faster is NVMe compared to microSD?**
A: Typically 10-20x faster for sequential operations and 50-100x faster for random operations.

**Q: What if my NVMe drive fails?**
A: Keep your original microSD card as a backup. You can boot from it by changing the bootloader configuration.

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all commands were executed correctly
3. Ensure your NVMe drive is compatible with Jetson Orin
4. Consult NVIDIA Developer Forums for additional support

---

**Migration completed successfully!** Your Jetson Orin should now be running much faster with the NVMe SSD as the primary storage device.

---

## About the Author

**Piotr Gapski**  
RoboticsGap Systems  
Specializing in embedded systems optimization and robotics development  

For questions or support regarding this guide, please refer to the troubleshooting section or consult the NVIDIA Developer Forums.

---

**Last updated:** September 2025  
**Author:** Piotr Gapski - RoboticsGap Systems  
**Compatible with:** JetPack 5.x and 6.x  
**Tested on:** Jetson Orin AGX, Jetson Orin NX
