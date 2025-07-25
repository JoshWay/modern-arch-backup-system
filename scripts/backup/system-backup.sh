#!/bin/bash
# Comprehensive Arch Linux Backup Script

set -euo pipefail

# Load path configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/config/paths.sh"

# Trap to handle errors and send failure notification
error_handler() {
    local exit_code=$?
    log "Backup failed with exit code: $exit_code"
    "$NOTIFICATION_SCRIPT" "System Backup Failed" "❌ Daily backup failed!\nCheck logs: $LOG_FILE\nFailed at: $(date '+%Y-%m-%d %H:%M')" "critical" "dialog-error"
    exit $exit_code
}

trap 'error_handler' ERR

# Use secure password loading if available, fallback to .restic-env
if [[ -f "$RESTIC_ENV_SECURE" ]]; then
    source "$RESTIC_ENV_SECURE"
elif [[ -f "$RESTIC_ENV_FILE" ]]; then
    source "$RESTIC_ENV_FILE"
else
    echo "Error: No Restic environment configuration found!"
    echo "Run: sudo $SETUP_SCRIPTS_DIR/setup-restic-password.sh"
    exit 1
fi

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_START_TIME=$(date +%s)
LOG_FILE="/var/log/system-backup-$BACKUP_DATE.log"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting system backup..."

# Send notification that backup is starting
"$NOTIFICATION_SCRIPT" "System Backup Started" "Daily system backup started at $(date '+%H:%M')" "normal" "drive-harddisk"

# 1. BTRFS Snapshots with btrbk
log "Creating BTRFS snapshots..."
sudo btrbk -c "$BTRBK_CONFIG" run

# 2. Package lists
log "Backing up package lists..."
pacman -Qe > /mnt/backup-drive/system-backups/packages/pkglist-$BACKUP_DATE.txt
pacman -Qm > /mnt/backup-drive/system-backups/packages/foreign-pkglist-$BACKUP_DATE.txt
pacman -Qqe | grep -Fvx "$(pacman -Qqm)" > /mnt/backup-drive/system-backups/packages/native-pkglist-$BACKUP_DATE.txt

# 3. System configurations
log "Backing up system configurations..."
sudo tar -czf /mnt/backup-drive/system-backups/configs/etc-$BACKUP_DATE.tar.gz /etc
tar -czf /mnt/backup-drive/system-backups/configs/dotfiles-$BACKUP_DATE.tar.gz \
    /home/b3l13v3r/.config \
    /home/b3l13v3r/.local \
    /home/b3l13v3r/.bashrc \
    /home/b3l13v3r/.zshrc \
    /home/b3l13v3r/.gitconfig \
    2>/dev/null || true

# 4. Bootloader and partition info
log "Backing up bootloader and partition table..."
sudo dd if=/dev/nvme0n1 of=/mnt/backup-drive/system-backups/bootloader/nvme0n1-mbr-$BACKUP_DATE.img bs=512 count=2048
sudo dd if=/dev/nvme0n1p1 of=/mnt/backup-drive/system-backups/bootloader/efi-partition-$BACKUP_DATE.img bs=1M
sudo sfdisk -d /dev/nvme0n1 > /mnt/backup-drive/system-backups/bootloader/partition-table-$BACKUP_DATE.txt
sudo efibootmgr -v > /mnt/backup-drive/system-backups/bootloader/efi-boot-entries-$BACKUP_DATE.txt

# 5. Restic backup for important directories
log "Running Restic backup..."

# Send Restic-specific start notification
"$NOTIFICATION_SCRIPT" "Restic Backup Started" "Your data backup using Restic is now in progress.\nBacking up: /home, /etc, /var/lib/docker, /opt" "low" "drive-harddisk"

# Run Restic backup with error handling
if restic backup \
    --exclude-caches \
    --exclude='/home/*/.cache' \
    --exclude='/home/*/Downloads' \
    --exclude='/home/*/.local/share/Trash' \
    --exclude='/home/*/.cache/*/trash' \
    --exclude='/home/*/.Trash*' \
    --exclude='*/trash' \
    --exclude='*/Trash' \
    --tag system-backup \
    --tag "$BACKUP_DATE" \
    /home/b3l13v3r \
    /etc \
    /var/lib/docker \
    /opt; then
    
    # Restic backup succeeded
    log "Restic backup completed successfully"
else
    # Restic backup failed
    log "Restic backup failed with exit code: $?"
    "$NOTIFICATION_SCRIPT" "Restic Backup Failed" "An error occurred during your Restic backup.\nCheck logs: $LOG_FILE\nPlease investigate immediately." "critical" "dialog-error"
    # Continue with other backup tasks even if Restic fails
fi

# 6. Clean old backups
log "Cleaning old backups..."
# Keep only last 30 days of config archives
find /mnt/backup-drive/system-backups/configs -type f -mtime +30 -delete
find /mnt/backup-drive/system-backups/packages -type f -mtime +90 -delete
find /mnt/backup-drive/system-backups/bootloader -type f -mtime +30 -delete

# Restic cleanup
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune

log "Backup completed successfully!"

# Calculate backup duration
BACKUP_END_TIME=$(date +%s)
if [[ -n "${BACKUP_START_TIME:-}" ]]; then
    BACKUP_DURATION=$((BACKUP_END_TIME - BACKUP_START_TIME))
    DURATION_FORMATTED=$(printf '%dm %02ds' $((BACKUP_DURATION/60)) $((BACKUP_DURATION%60)))
else
    DURATION_FORMATTED="unknown"
fi

# Send success notification with details
BACKUP_SIZE=$(du -sh /mnt/backup-drive/btrbk-snapshots/ 2>/dev/null | cut -f1 || echo "unknown")
"$NOTIFICATION_SCRIPT" "System Backup Complete" "✅ Daily backup finished successfully\nDuration: $DURATION_FORMATTED\nSnapshot size: $BACKUP_SIZE\nCompleted: $(date '+%Y-%m-%d %H:%M')" "low" "drive-harddisk"
