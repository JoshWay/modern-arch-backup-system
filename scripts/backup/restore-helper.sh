#!/bin/bash
# Arch Linux System Restore Helper

set -euo pipefail

echo "Arch Linux System Restore Helper"
echo "================================"
echo ""
echo "1. List available BTRFS snapshots:"
echo "   sudo btrbk -c /home/b3l13v3r/scripts/btrbk.conf list"
echo ""
echo "2. Restore from BTRFS snapshot:"
echo "   sudo btrbk -c /home/b3l13v3r/scripts/btrbk.conf restore <snapshot> <target>"
echo ""
echo "3. List Restic snapshots:"
echo "   source /home/b3l13v3r/scripts/.restic-env"
echo "   restic snapshots"
echo ""
echo "4. Mount Restic snapshot:"
echo "   restic mount <snapshot-id> /mnt/restic-restore"
echo ""
echo "5. Restore packages:"
echo "   sudo pacman -S --needed - < /mnt/backup-drive/system-backups/packages/native-pkglist-<date>.txt"
echo "   yay -S --needed - < /mnt/backup-drive/system-backups/packages/foreign-pkglist-<date>.txt"
echo ""
echo "6. Restore partition table:"
echo "   sudo sfdisk /dev/nvme0n1 < /mnt/backup-drive/system-backups/bootloader/partition-table-<date>.txt"
echo ""
echo "7. Restore EFI partition:"
echo "   sudo dd if=/mnt/backup-drive/system-backups/bootloader/efi-partition-<date>.img of=/dev/nvme0n1p1"
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
                sudo btrbk -c /home/b3l13v3r/scripts/btrbk.conf list
                ;;
            "List Restic snapshots")
                source /home/b3l13v3r/scripts/.restic-env
                restic snapshots
                ;;
            "List package backups")
                ls -la /mnt/backup-drive/system-backups/packages/
                ;;
            "List config backups")
                ls -la /mnt/backup-drive/system-backups/configs/
                ;;
            "Exit")
                break
                ;;
            *) echo "Invalid option";;
        esac
    done
fi
