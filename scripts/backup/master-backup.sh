#!/bin/bash

# Master Backup Script with KDE Notifications
# Runs system backup via btrbk and essential home backup

set -e

# Load common configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# shellcheck source=../common/load-config.sh
source "${SCRIPT_DIR}/../common/load-config.sh"

# Use the notify function from common config
alias send_notification=notify

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
if ! mountpoint -q "$BACKUP_STORAGE_ROOT"; then
    echo "ERROR: Backup drive not mounted at $BACKUP_STORAGE_ROOT"
    send_notification "Backup Failed" "Backup drive not mounted at $BACKUP_STORAGE_ROOT" "critical" "dialog-error"
    exit 1
fi

# Check if we have sudo access for backup commands
if ! sudo -n true 2>/dev/null; then
    echo "ERROR: This script requires passwordless sudo access for backup operations"
    echo "Please run the setup script to configure sudo access"
    send_notification "Backup Failed" "Passwordless sudo required. Check terminal for setup instructions." "critical" "dialog-error"
    exit 1
fi

# Check available space
echo "Checking backup drive space..."
df -h "$BACKUP_STORAGE_ROOT"

echo ""
echo "========================================"
echo "Running System Backup (btrbk)"
echo "========================================"

# Run system backup
sudo btrbk -c "$BTRBK_CONFIG" run

echo ""
echo "========================================"
echo "Running Essential Home Backup"
echo "========================================"

# Run essential home backup
CALLED_FROM_MASTER=true "$BACKUP_SCRIPTS_DIR/essential-home-backup.sh"

echo ""
echo "========================================"
echo "Backup Summary"
echo "========================================"

echo "Current backups on target drive:"
ls -lah "$BTRBK_SNAPSHOTS_DIR"/ROOT* "$BTRBK_SNAPSHOTS_DIR"/home-essential* 2>/dev/null | tail -10

echo ""
echo "Disk usage after backup:"
df -h "$BACKUP_STORAGE_ROOT"

echo ""
echo "========================================"
echo "Master Backup Completed Successfully"
echo "========================================"

# Move ISO file back if it was moved (if specific to user setup)
# This section can be customized in user's backup.conf if needed

# Get backup statistics for notification
CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
DISK_USAGE=$(df -h "$BACKUP_STORAGE_ROOT" | tail -1 | awk '{print $3 " used of " $2 " (" $5 ")"}')
ROOT_COUNT=$(ls -1 "$BTRBK_SNAPSHOTS_DIR"/ROOT* 2>/dev/null | wc -l)
HOME_COUNT=$(ls -1 "$BTRBK_SNAPSHOTS_DIR"/home-essential* 2>/dev/null | wc -l)

log_message "Backup process completed successfully"
send_notification "Backup Completed Successfully" "✅ System: $ROOT_COUNT snapshots\n🏠 Home: $HOME_COUNT snapshots\n💾 Storage: $DISK_USAGE" "normal" "security-high"

echo "Backup process completed at $(date)"
