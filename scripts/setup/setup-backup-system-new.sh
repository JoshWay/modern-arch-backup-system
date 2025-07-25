#!/bin/bash
# Modern Arch Linux Backup System Setup
# This script sets up the backup system with proper configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load configuration if running from repo
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [[ -f "${SCRIPT_DIR}/../common/load-config.sh" ]]; then
    source "${SCRIPT_DIR}/../common/load-config.sh"
else
    # Set defaults if config not available
    BACKUP_STORAGE_ROOT="${BACKUP_STORAGE_ROOT:-/mnt/backup-storage}"
    CONFIG_DIR="${CONFIG_DIR:-/etc/backup-system}"
    BACKUP_USER="${BACKUP_USER:-$USER}"
fi

echo -e "${GREEN}Modern Arch Linux Backup System Setup${NC}"
echo -e "${GREEN}=====================================\n${NC}"

# Check if running as root (needed for system setup)
if [[ $EUID -ne 0 ]]; then 
   echo -e "${YELLOW}This script needs to be run with sudo for system setup${NC}"
   echo -e "${YELLOW}Run: sudo $0${NC}"
   exit 1
fi

# Get actual username if running under sudo
ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
ACTUAL_UID=$(id -u "$ACTUAL_USER")

echo -e "${YELLOW}Setting up for user: $ACTUAL_USER${NC}"

# 1. Install required packages
echo -e "\n${YELLOW}1. Installing required packages...${NC}"
packages="btrbk restic python python-dbus libnotify"
echo "Installing: $packages"
pacman -S --needed --noconfirm $packages

# 2. Create directory structure
echo -e "\n${YELLOW}2. Creating directory structure...${NC}"

# System directories
mkdir -p /etc/backup-system
mkdir -p /usr/local/bin
mkdir -p /var/lib/backup-system

# User config directory
sudo -u "$ACTUAL_USER" mkdir -p "$ACTUAL_HOME/.config/backup-system"

# Backup storage directories (if accessible)
if [[ -d "$(dirname "$BACKUP_STORAGE_ROOT")" ]]; then
    mkdir -p "$BACKUP_STORAGE_ROOT"/{system-backups,btrbk-snapshots,restic-repo}
    mkdir -p "$BACKUP_STORAGE_ROOT"/system-backups/{configs,packages,bootloader}
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$BACKUP_STORAGE_ROOT"
    echo -e "${GREEN}Created backup directories at $BACKUP_STORAGE_ROOT${NC}"
else
    echo -e "${YELLOW}Warning: Backup storage location $BACKUP_STORAGE_ROOT not accessible${NC}"
    echo -e "${YELLOW}Please create it manually and re-run setup${NC}"
fi

# 3. Install scripts
echo -e "\n${YELLOW}3. Installing backup scripts...${NC}"

# Copy scripts to system location
if [[ "$BACKUP_DEV_MODE" == "true" ]]; then
    echo "Installing from repository..."
    
    # Install main scripts with appropriate permissions
    install -m 755 "$BACKUP_REPO_ROOT/scripts/backup/system-backup.sh" /usr/local/bin/
    install -m 755 "$BACKUP_REPO_ROOT/scripts/backup/master-backup.sh" /usr/local/bin/backup-master.sh
    install -m 755 "$BACKUP_REPO_ROOT/scripts/notifications/kde-notify-final.sh" /usr/local/bin/
    install -m 755 "$BACKUP_REPO_ROOT/scripts/notifications/kde-notify-dbus.py" /usr/local/bin/
    install -m 755 "$BACKUP_REPO_ROOT/scripts/common/load-config.sh" /usr/local/bin/backup-load-config.sh
    
    # Install secure scripts with restrictive permissions
    if [[ -f "$BACKUP_REPO_ROOT/scripts/setup/restic-env-systemd.sh" ]]; then
        install -m 700 -o root -g root "$BACKUP_REPO_ROOT/scripts/setup/restic-env-systemd.sh" /usr/local/bin/restic-env-secure.sh
    fi
    
    # Install helper scripts
    if [[ -f "$BACKUP_REPO_ROOT/scripts/backup/restore-helper.sh" ]]; then
        install -m 755 "$BACKUP_REPO_ROOT/scripts/backup/restore-helper.sh" /usr/local/bin/
    fi
    
    echo -e "${GREEN}Scripts installed to /usr/local/bin${NC}"
fi

# 4. Setup btrbk configuration
echo -e "\n${YELLOW}4. Setting up btrbk configuration...${NC}"

cat > /etc/btrbk/btrbk.conf << EOF
# btrbk configuration for system snapshots
timestamp_format        long

# Snapshot settings
snapshot_preserve_min   6h
snapshot_preserve       24h 7d 4w 6m

# Target settings  
target_preserve_min     6h
target_preserve         24h 7d 4w 6m

# System root snapshots
volume /
  snapshot_dir .snapshots
  target $BACKUP_STORAGE_ROOT/btrbk-snapshots/root
  subvolume /
  subvolume /home
EOF

echo -e "${GREEN}btrbk configuration created at /etc/btrbk/btrbk.conf${NC}"

# 5. Setup sudo permissions
echo -e "\n${YELLOW}5. Setting up sudo permissions...${NC}"

# Create sudoers file for backup operations with restricted permissions
cat > /etc/sudoers.d/backup-operations << EOF
# Backup operations sudoers configuration
# Allows $ACTUAL_USER to run specific backup commands without password

# Allow only specific btrbk operations with config file
$ACTUAL_USER ALL=(root) NOPASSWD: /usr/bin/btrbk -c /etc/btrbk/btrbk.conf run
$ACTUAL_USER ALL=(root) NOPASSWD: /usr/bin/btrbk -c /etc/btrbk/btrbk.conf list
$ACTUAL_USER ALL=(root) NOPASSWD: /usr/bin/btrbk -c /etc/btrbk/btrbk.conf stats

# Allow specific backup script execution
$ACTUAL_USER ALL=(root) NOPASSWD: /usr/local/bin/system-backup.sh

# Allow read-only filesystem operations for recovery
$ACTUAL_USER ALL=(root) NOPASSWD: /usr/bin/mount -r -o subvol=.snapshots/* /dev/* /mnt/snapshot
$ACTUAL_USER ALL=(root) NOPASSWD: /usr/bin/umount /mnt/snapshot
EOF

chmod 440 /etc/sudoers.d/backup-operations
echo -e "${GREEN}Sudo permissions configured for $ACTUAL_USER${NC}"

# 6. Setup systemd service and timer
echo -e "\n${YELLOW}6. Setting up systemd service and timer...${NC}"

# Install service files
if [[ "$BACKUP_DEV_MODE" == "true" && -f "$BACKUP_REPO_ROOT/systemd/system-backup.service" ]]; then
    install -m 644 "$BACKUP_REPO_ROOT/systemd/system-backup.service" /etc/systemd/system/
    
    # Create timer if it doesn't exist
    if [[ -f "$BACKUP_REPO_ROOT/systemd/system-backup.timer" ]]; then
        install -m 644 "$BACKUP_REPO_ROOT/systemd/system-backup.timer" /etc/systemd/system/
    else
        cat > /etc/systemd/system/system-backup.timer << EOF
[Unit]
Description=Daily System Backup Timer
Requires=system-backup.service

[Timer]
OnCalendar=daily
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
    fi
    
    systemctl daemon-reload
    echo -e "${GREEN}Systemd service and timer installed${NC}"
fi

# 7. Create user configuration template
echo -e "\n${YELLOW}7. Creating user configuration...${NC}"

USER_CONFIG="$ACTUAL_HOME/.config/backup-system/backup.conf"
if [[ ! -f "$USER_CONFIG" ]]; then
    sudo -u "$ACTUAL_USER" cat > "$USER_CONFIG" << EOF
# Backup System Configuration for $ACTUAL_USER
# Customize these settings for your system

# User settings
BACKUP_USER="$ACTUAL_USER"

# Storage locations
BACKUP_STORAGE_ROOT="$BACKUP_STORAGE_ROOT"
BTRBK_SNAPSHOTS_DIR="\$BACKUP_STORAGE_ROOT/btrbk-snapshots"
RESTIC_REPO_DIR="\$BACKUP_STORAGE_ROOT/restic-repo"
SYSTEM_BACKUPS_DIR="\$BACKUP_STORAGE_ROOT/system-backups"

# Notification settings
NOTIFICATION_USER="$ACTUAL_USER"
EOF
    
    chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_CONFIG"
    chmod 600 "$USER_CONFIG"
    echo -e "${GREEN}User configuration created at $USER_CONFIG${NC}"
else
    echo -e "${YELLOW}User configuration already exists at $USER_CONFIG${NC}"
fi

# 8. Initialize Restic repository
echo -e "\n${YELLOW}8. Setting up Restic repository...${NC}"

if [[ -d "$BACKUP_STORAGE_ROOT/restic-repo" ]] && [[ ! -f "$BACKUP_STORAGE_ROOT/restic-repo/config" ]]; then
    echo -e "${GREEN}Initializing Restic repository...${NC}"
    echo -e "${YELLOW}You will be prompted to create a repository password${NC}"
    echo -e "${YELLOW}Remember this password - you'll need it for all backup operations!${NC}"
    
    sudo -u "$ACTUAL_USER" restic init --repo "$BACKUP_STORAGE_ROOT/restic-repo"
    
    # Create restic environment file
    RESTIC_ENV="$ACTUAL_HOME/.config/backup-system/.restic-env"
    sudo -u "$ACTUAL_USER" cat > "$RESTIC_ENV" << EOF
# Restic environment configuration
export RESTIC_REPOSITORY="$BACKUP_STORAGE_ROOT/restic-repo"
# export RESTIC_PASSWORD="your-password-here"
# For better security, use the setup-restic-password.sh script instead
EOF
    
    chmod 600 "$RESTIC_ENV"
    echo -e "${GREEN}Restic repository initialized${NC}"
    echo -e "${YELLOW}Run setup-restic-password.sh to securely store your password${NC}"
else
    if [[ -f "$BACKUP_STORAGE_ROOT/restic-repo/config" ]]; then
        echo -e "${YELLOW}Restic repository already exists${NC}"
    else
        echo -e "${YELLOW}Skipping Restic setup - storage not accessible${NC}"
    fi
fi

# 9. Create system configuration
echo -e "\n${YELLOW}9. Creating system configuration...${NC}"

cat > /etc/backup-system/backup.conf << EOF
# System-wide Backup Configuration
# This file is used when running backups as root/via systemd

# Storage locations
BACKUP_STORAGE_ROOT="$BACKUP_STORAGE_ROOT"
BTRBK_SNAPSHOTS_DIR="\$BACKUP_STORAGE_ROOT/btrbk-snapshots"
RESTIC_REPO_DIR="\$BACKUP_STORAGE_ROOT/restic-repo"
SYSTEM_BACKUPS_DIR="\$BACKUP_STORAGE_ROOT/system-backups"

# System settings
BTRBK_CONFIG="/etc/btrbk/btrbk.conf"
NOTIFICATION_SCRIPT="/usr/local/bin/kde-notify-final.sh"

# Default notification user (for systemd service)
NOTIFICATION_USER="$ACTUAL_USER"
EOF

chmod 644 /etc/backup-system/backup.conf

# Summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================\n${NC}"

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Configure your Restic password:"
echo "   sudo -u $ACTUAL_USER /usr/local/bin/setup-restic-password.sh"
echo ""
echo "2. Test the backup system:"
echo "   sudo /usr/local/bin/system-backup.sh"
echo ""
echo "3. Enable automatic backups:"
echo "   sudo systemctl enable --now system-backup.timer"
echo ""
echo "4. Check timer status:"
echo "   systemctl status system-backup.timer"
echo "   systemctl list-timers"

echo -e "\n${GREEN}Configuration files:${NC}"
echo "- User config: $ACTUAL_HOME/.config/backup-system/backup.conf"
echo "- System config: /etc/backup-system/backup.conf"
echo "- btrbk config: /etc/btrbk/btrbk.conf"
echo "- Sudoers: /etc/sudoers.d/backup-operations"

echo -e "\n${GREEN}Backup storage: $BACKUP_STORAGE_ROOT${NC}"
