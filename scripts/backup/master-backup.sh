#!/bin/bash

# Master Backup Script with KDE Notifications
# Runs system backup via btrbk and essential home backup

set -e

# Function to send KDE notifications
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="$3"  # low, normal, critical
    local icon="$4"
    
    # Send notification via notify-send (works with KDE Plasma)
    notify-send --urgency="$urgency" --icon="$icon" "$title" "$message"
}

# Function to log with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Trap to handle errors and send failure notification
trap 'send_notification "Backup Failed" "Backup process encountered an error. Check logs for details." "critical" "dialog-error"; exit 1' ERR

log_message "Starting Master Backup Process"
send_notification "Backup Started" "System and home backup process has begun" "normal" "system-software-update"

echo "========================================"
echo "Starting Master Backup Process"
echo "========================================"

# Check if backup drive is mounted
if ! mountpoint -q /mnt/sdb-btrfs; then
    echo "ERROR: Backup drive not mounted at /mnt/sdb-btrfs"
    send_notification "Backup Failed" "Backup drive not mounted at /mnt/sdb-btrfs" "critical" "dialog-error"
    exit 1
fi

# Check if we have sudo access for backup commands
if ! sudo -n true 2>/dev/null; then
    echo "ERROR: This script requires passwordless sudo access for backup operations"
    echo "Please run the following command to enable it:"
    echo "sudo cp /home/b3l13v3r/scripts/backup-sudoers /etc/sudoers.d/backup-operations"
    send_notification "Backup Failed" "Passwordless sudo required. Check terminal for setup instructions." "critical" "dialog-error"
    exit 1
fi

# Check available space
echo "Checking backup drive space..."
df -h /mnt/sdb-btrfs

echo ""
echo "========================================"
echo "Running System Backup (btrbk)"
echo "========================================"

# Run system backup
sudo btrbk -c /home/b3l13v3r/scripts/btrbk.conf run

echo ""
echo "========================================"
echo "Running Essential Home Backup"
echo "========================================"

# Run essential home backup
CALLED_FROM_MASTER=true /home/b3l13v3r/scripts/essential-home-backup.sh

echo ""
echo "========================================"
echo "Backup Summary"
echo "========================================"

echo "Current backups on target drive:"
ls -lah /mnt/backup-drive/btrbk-snapshots/ | grep -E "(ROOT|home-essential)" | tail -10

echo ""
echo "Disk usage after backup:"
df -h /mnt/sdb-btrfs

echo ""
echo "========================================"
echo "Master Backup Completed Successfully"
echo "========================================"

# Move ISO file back if it was moved
if [ -f /tmp/backup-exclude/Win11_23H2_English_x64v2.iso ]; then
    echo "Moving ISO file back to original location..."
    mv /tmp/backup-exclude/Win11_23H2_English_x64v2.iso /home/b3l13v3r/shared/WAYLIFE_Share/ 2>/dev/null || {
        echo "Warning: Could not move ISO file back"
    }
fi

# Get backup statistics for notification
CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
DISK_USAGE=$(df -h /mnt/sdb-btrfs | tail -1 | awk '{print $3 " used of " $2 " (" $5 ")"}')
ROOT_COUNT=$(ls -1 /mnt/backup-drive/btrbk-snapshots/ROOT* 2>/dev/null | wc -l)
HOME_COUNT=$(ls -1 /mnt/backup-drive/btrbk-snapshots/home-essential* 2>/dev/null | wc -l)

log_message "Backup process completed successfully"
send_notification "Backup Completed Successfully" "✅ System: $ROOT_COUNT snapshots\n🏠 Home: $HOME_COUNT snapshots\n💾 Storage: $DISK_USAGE" "normal" "security-high"

echo "Backup process completed at $(date)"
