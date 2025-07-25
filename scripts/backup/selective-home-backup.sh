#!/bin/bash

# Selective Home Backup Script
# This script creates a clean snapshot of home directory excluding unnecessary data

set -e

TIMESTAMP=$(date +%Y%m%dT%H%M)
HOME_USER="b3l13v3r"
SOURCE_HOME="/home/$HOME_USER"
SNAPSHOT_DIR="/.snapshots"
TARGET_DIR="/mnt/backup-drive/btrbk-snapshots"
TEMP_DIR="/tmp/home-backup-$TIMESTAMP"

# Directories/files to exclude (high space usage, non-essential for recovery)
EXCLUDES=(
    # System caches
    ".cache"
    ".local/share/Trash"
    ".thumbnails"
    
    # Browser data (cache, profiles with large data)
    ".config/*/Cache"
    ".config/*/cache"
    ".config/*/CachedData"
    ".config/*/Code Cache"
    ".config/*/GPUCache"
    ".config/*/logs"
    ".config/*/crashpad_database"
    ".config/BraveSoftware/Brave-Browser/*/Cache"
    ".config/BraveSoftware/Brave-Browser/*/Code Cache"
    ".config/BraveSoftware/Brave-Browser/*/GPUCache"
    ".config/google-chrome/*/Cache"
    ".config/google-chrome/*/Code Cache"
    ".config/firefox/*/cache2"
    ".mozilla/firefox/*/cache2"
    
    # Application caches and temporary data
    ".local/share/Steam"
    ".local/share/lutris"
    ".local/share/bottles"
    ".local/share/containers"
    ".wine"
    ".playonlinux"
    
    # VMs and large files
    "VirtualBox VMs"
    "snapd"
    "shared/WAYLIFE_Share"
    "*.iso"
    "*.img"
    "*.qcow2"
    "*.vdi"
    "*.vmdk"
    "*.ova"
    "*.ovf"
    
    # Development caches and build artifacts
    ".docker"
    ".podman"
    ".vagrant.d"
    ".local/lib/python*/site-packages"
    ".npm"
    ".yarn"
    "node_modules"
    ".local/share/pnpm"
    ".cargo/registry"
    ".cargo/git"
    ".rustup/toolchains"
    "go/pkg"
    "go/bin"
    ".gradle/caches"
    ".m2/repository"
    ".nuget"
    
    # Large downloads
    "Downloads/iso"
    "Downloads/*iso"
    "Downloads/*img"
    "Downloads/*.zip"
    "Downloads/*.tar.*"
    
    # Backup directories (avoid recursion)
    "*.backup"
    "backup*"
)

echo "Creating selective home backup excluding unnecessary data..."
echo "Excluded patterns: ${EXCLUDES[*]}"

# Create temporary directory for selective copy
mkdir -p "$TEMP_DIR"

# Use rsync to copy home directory excluding unwanted files
RSYNC_EXCLUDES=""
for exclude in "${EXCLUDES[@]}"; do
    RSYNC_EXCLUDES="$RSYNC_EXCLUDES --exclude=$exclude"
done

echo "Copying essential files from $SOURCE_HOME to $TEMP_DIR..."
rsync -av $RSYNC_EXCLUDES "$SOURCE_HOME/" "$TEMP_DIR/"

# Create btrfs subvolume from the selective copy
echo "Creating btrfs subvolume..."
sudo btrfs subvolume create "$SNAPSHOT_DIR/home-essential.$TIMESTAMP"

# Copy the selective data to the subvolume
echo "Populating subvolume with essential data..."
sudo cp -a "$TEMP_DIR/." "$SNAPSHOT_DIR/home-essential.$TIMESTAMP/"

# Send to backup target
echo "Sending snapshot to backup target..."
sudo btrfs send "$SNAPSHOT_DIR/home-essential.$TIMESTAMP" | sudo btrfs receive "$TARGET_DIR/"

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo "Selective home backup completed: home-essential.$TIMESTAMP"
echo "Backup size:"
sudo du -sh "$SNAPSHOT_DIR/home-essential.$TIMESTAMP"
