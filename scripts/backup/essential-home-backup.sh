#!/bin/bash

# Essential Home Backup Script - Minimal approach
# Only backs up configuration files and critical data

set -e

# Function to send KDE notifications (only if called independently)
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="$3"  # low, normal, critical
    local icon="$4"
    
    # Only send if not called from master script
    if [[ "$CALLED_FROM_MASTER" != "true" ]]; then
        notify-send --urgency="$urgency" --icon="$icon" "$title" "$message"
    fi
}

TIMESTAMP=$(date +%Y%m%dT%H%M)
HOME_USER="b3l13v3r"
SOURCE_HOME="/home/$HOME_USER"
SNAPSHOT_DIR="/.snapshots"
TARGET_DIR="/mnt/backup-drive/btrbk-snapshots"

echo "Creating minimal essential home backup..."

# Create the snapshot directly from select directories only
echo "Creating btrfs subvolume..."
sudo btrfs subvolume create "$SNAPSHOT_DIR/home-essential.$TIMESTAMP"

# Copy only the most essential directories/files
ESSENTIAL_PATHS=(
    ".bash_history"
    ".bash_profile"
    ".bashrc"
    ".zsh_history" 
    ".zshrc"
    ".gitconfig"
    ".ssh"
    "scripts/"
    "dotfiles/"
    "Projects/"
    ".config/nvim"
    ".config/kitty"  
    ".config/rofi"
    ".config/waybar"
    ".local/bin"
    "Documents/"
)

echo "Copying essential files and directories..."
for path in "${ESSENTIAL_PATHS[@]}"; do
    if [ -e "$SOURCE_HOME/$path" ]; then
        echo "  Copying: $path"
        # Create parent directory structure
        parent_dir=$(dirname "$SNAPSHOT_DIR/home-essential.$TIMESTAMP/$path")
        sudo mkdir -p "$parent_dir"
        # Copy the file/directory
        sudo cp -a "$SOURCE_HOME/$path" "$SNAPSHOT_DIR/home-essential.$TIMESTAMP/$path" 2>/dev/null || {
            echo "    Warning: Could not copy $path"
        }
    else
        echo "  Skipping (not found): $path"
    fi
done

echo "Setting ownership..."
sudo chown -R "$HOME_USER:$(id -gn $HOME_USER)" "$SNAPSHOT_DIR/home-essential.$TIMESTAMP/" 2>/dev/null || true

# Make subvolume read-only
echo "Making subvolume read-only..."
sudo btrfs property set -ts "$SNAPSHOT_DIR/home-essential.$TIMESTAMP" ro true

# Send to backup target
echo "Sending snapshot to backup target..."
sudo btrfs send "$SNAPSHOT_DIR/home-essential.$TIMESTAMP" | sudo btrfs receive "$TARGET_DIR/"

echo "Essential home backup completed: home-essential.$TIMESTAMP"
echo "Backup size:"
sudo du -sh "$SNAPSHOT_DIR/home-essential.$TIMESTAMP"

echo ""
echo "Backup contents:"
ls -la "$TARGET_DIR/home-essential.$TIMESTAMP" || echo "Could not list target contents"
