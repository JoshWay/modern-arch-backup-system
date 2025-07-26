#!/bin/bash
# Modern Arch Linux Backup System Setup
# Supports BTRFS snapshots, Restic, and traditional backups

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_ROOT="/mnt/raid-storage/system-backups"
RESTIC_REPO="/mnt/raid-storage/restic-repo"
BTRBK_ROOT="/mnt/raid-storage/btrbk-snapshots"
SCRIPTS_DIR="$HOME/scripts"

echo -e "${GREEN}Setting up Modern Arch Linux Backup System${NC}"

# Create directory structure
echo -e "${YELLOW}Creating backup directories...${NC}"
sudo mkdir -p "$BACKUP_ROOT"/{configs,packages,bootloader}
sudo mkdir -p "$RESTIC_REPO"
sudo mkdir -p "$BTRBK_ROOT"
sudo mkdir -p "$SCRIPTS_DIR"
sudo chown -R "$USER:$USER" "$BACKUP_ROOT" "$RESTIC_REPO" "$BTRBK_ROOT" "$SCRIPTS_DIR"

# 1. Setup BTRFS snapshot configuration with btrbk
echo -e "${YELLOW}Setting up btrbk for BTRFS snapshots...${NC}"
cat > "$SCRIPTS_DIR/btrbk.conf" << 'EOF'
# btrbk configuration for system snapshots
timestamp_format        long

# Snapshot settings
snapshot_preserve_min   6h
snapshot_preserve       24h 7d 4w 6m

# Target settings
target_preserve_min     6h
target_preserve         24h 7d 4w 6m

# System root
volume /
  snapshot_dir .snapshots
  target /mnt/raid-storage/btrbk-snapshots/root
  subvolume /
  subvolume /home
EOF

# 2. Initialize Restic repository
echo -e "${YELLOW}Initializing Restic repository...${NC}"
if [ ! -f "$RESTIC_REPO/config" ]; then
    echo -e "${GREEN}Enter a password for Restic repository:${NC}"
    restic init --repo "$RESTIC_REPO"
    echo "RESTIC_REPOSITORY=$RESTIC_REPO" > "$SCRIPTS_DIR/.restic-env"
    echo "# Add your password: export RESTIC_PASSWORD='your-password'" >> "$SCRIPTS_DIR/.restic-env"
    chmod 600 "$SCRIPTS_DIR/.restic-env"
fi

# 3. Create backup scripts
echo -e "${YELLOW}Creating backup scripts...${NC}"

# Main backup script
cat > "$SCRIPTS_DIR/system-backup.sh" << 'EOF'
#!/bin/bash
# Comprehensive Arch Linux Backup Script

set -euo pipefail
source "$HOME/scripts/.restic-env"

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/system-backup-$BACKUP_DATE.log"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting system backup..."

# 1. BTRFS Snapshots with btrbk
log "Creating BTRFS snapshots..."
sudo btrbk -c "$HOME/scripts/btrbk.conf" run

# 2. Package lists
log "Backing up package lists..."
pacman -Qe > /mnt/raid-storage/system-backups/packages/pkglist-$BACKUP_DATE.txt
pacman -Qm > /mnt/raid-storage/system-backups/packages/foreign-pkglist-$BACKUP_DATE.txt
pacman -Qqe | grep -Fvx "$(pacman -Qqm)" > /mnt/raid-storage/system-backups/packages/native-pkglist-$BACKUP_DATE.txt

# 3. System configurations
log "Backing up system configurations..."
sudo tar -czf /mnt/raid-storage/system-backups/configs/etc-$BACKUP_DATE.tar.gz /etc
tar -czf /mnt/raid-storage/system-backups/configs/dotfiles-$BACKUP_DATE.tar.gz \
    "$HOME/.config" \
    "$HOME/.local" \
    "$HOME/.bashrc" \
    "$HOME/.zshrc" \
    "$HOME/.gitconfig" \
    2>/dev/null || true

# 4. Bootloader and partition info
log "Backing up bootloader and partition table..."
sudo dd if=/dev/nvme0n1 of=/mnt/raid-storage/system-backups/bootloader/nvme0n1-mbr-$BACKUP_DATE.img bs=512 count=2048
sudo dd if=/dev/nvme0n1p1 of=/mnt/raid-storage/system-backups/bootloader/efi-partition-$BACKUP_DATE.img bs=1M
sudo sfdisk -d /dev/nvme0n1 > /mnt/raid-storage/system-backups/bootloader/partition-table-$BACKUP_DATE.txt
sudo efibootmgr -v > /mnt/raid-storage/system-backups/bootloader/efi-boot-entries-$BACKUP_DATE.txt

# 5. Restic backup for important directories
log "Running Restic backup..."
restic backup \
    --exclude-caches \
    --exclude='/home/*/.cache' \
    --exclude='/home/*/Downloads' \
    --exclude='/home/*/.local/share/Trash' \
    --tag system-backup \
    --tag "$BACKUP_DATE" \
    "$HOME" \
    /etc \
    /var/lib/docker \
    /opt

# 6. Clean old backups
log "Cleaning old backups..."
# Keep only last 30 days of config archives
find /mnt/raid-storage/system-backups/configs -type f -mtime +30 -delete
find /mnt/raid-storage/system-backups/packages -type f -mtime +90 -delete
find /mnt/raid-storage/system-backups/bootloader -type f -mtime +30 -delete

# Restic cleanup
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune

log "Backup completed successfully!"
EOF

# Quick restore helper script
cat > "$SCRIPTS_DIR/restore-helper.sh" << 'EOF'
#!/bin/bash
# Arch Linux System Restore Helper

set -euo pipefail

echo "Arch Linux System Restore Helper"
echo "================================"
echo ""
echo "1. List available BTRFS snapshots:"
echo "   sudo btrbk -c $HOME/scripts/btrbk.conf list"
echo ""
echo "2. Restore from BTRFS snapshot:"
echo "   sudo btrbk -c $HOME/scripts/btrbk.conf restore <snapshot> <target>"
echo ""
echo "3. List Restic snapshots:"
echo "   source $HOME/scripts/.restic-env"
echo "   restic snapshots"
echo ""
echo "4. Mount Restic snapshot:"
echo "   restic mount <snapshot-id> /mnt/restic-restore"
echo ""
echo "5. Restore packages:"
echo "   sudo pacman -S --needed - < /mnt/raid-storage/system-backups/packages/native-pkglist-<date>.txt"
echo "   yay -S --needed - < /mnt/raid-storage/system-backups/packages/foreign-pkglist-<date>.txt"
echo ""
echo "6. Restore partition table:"
echo "   sudo sfdisk /dev/nvme0n1 < /mnt/raid-storage/system-backups/bootloader/partition-table-<date>.txt"
echo ""
echo "7. Restore EFI partition:"
echo "   sudo dd if=/mnt/raid-storage/system-backups/bootloader/efi-partition-<date>.img of=/dev/nvme0n1p1"
echo ""

# Interactive restore menu
read -p "Would you like to start the interactive restore process? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    PS3='Please select restore option: '
    options=("List BTRFS snapshots" "List Restic snapshots" "List package backups" "List config backups" "Exit")
    select opt in "${options[@]}"
    do
        case $opt in
            "List BTRFS snapshots")
                sudo btrbk -c "$HOME/scripts/btrbk.conf" list
                ;;
            "List Restic snapshots")
                source "$HOME/scripts/.restic-env"
                restic snapshots
                ;;
            "List package backups")
                ls -la /mnt/raid-storage/system-backups/packages/
                ;;
            "List config backups")
                ls -la /mnt/raid-storage/system-backups/configs/
                ;;
            "Exit")
                break
                ;;
            *) echo "Invalid option";;
        esac
    done
fi
EOF

# Make scripts executable
chmod +x "$SCRIPTS_DIR/system-backup.sh"
chmod +x "$SCRIPTS_DIR/restore-helper.sh"

# 4. Setup systemd timer for automated backups
echo -e "${YELLOW}Setting up systemd timer for automated backups...${NC}"

# Create systemd service
sudo tee /etc/systemd/system/system-backup.service > /dev/null << EOF
[Unit]
Description=System Backup Service
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$HOME/scripts/system-backup.sh
StandardOutput=journal
StandardError=journal
SyslogIdentifier=system-backup
User=$USER
Group=$USER

[Install]
WantedBy=multi-user.target
EOF

# Create systemd timer
sudo tee /etc/systemd/system/system-backup.timer > /dev/null << EOF
[Unit]
Description=Weekly System Backup
Persistent=true

[Timer]
OnCalendar=weekly
OnCalendar=Sun 02:00
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
EOF

# Enable timer
sudo systemctl daemon-reload
sudo systemctl enable system-backup.timer

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Edit $SCRIPTS_DIR/.restic-env and add your Restic password"
echo "2. Test the backup: $SCRIPTS_DIR/system-backup.sh"
echo "3. Check timer status: systemctl status system-backup.timer"
echo "4. For recovery help: $SCRIPTS_DIR/restore-helper.sh"
