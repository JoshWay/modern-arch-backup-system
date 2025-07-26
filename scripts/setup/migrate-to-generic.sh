#!/bin/bash
# Migration script to transition from hardcoded paths to generic configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Backup System Migration Tool${NC}"
echo -e "${GREEN}============================\n${NC}"

# Check current user
CURRENT_USER="$USER"
echo -e "${YELLOW}Migrating setup for user: $CURRENT_USER${NC}"

# 1. Ensure config directory exists
echo -e "\n${YELLOW}1. Creating configuration directory...${NC}"
mkdir -p "$HOME/.config/backup-system"

# 2. Create user configuration with current paths
echo -e "\n${YELLOW}2. Creating user configuration from existing setup...${NC}"

CONFIG_FILE="$HOME/.config/backup-system/backup.conf"

cat > "$CONFIG_FILE" << EOF
# Backup System Configuration for $CURRENT_USER
# This file was created by the migration script

# User settings
BACKUP_USER="$CURRENT_USER"

# Storage locations (from your current setup)
BACKUP_STORAGE_ROOT="/mnt/raid-storage"
BTRBK_SNAPSHOTS_DIR="\$BACKUP_STORAGE_ROOT/btrbk-snapshots"
RESTIC_REPO_DIR="\$BACKUP_STORAGE_ROOT/restic-repo"
SYSTEM_BACKUPS_DIR="\$BACKUP_STORAGE_ROOT/system-backups"

# Script locations (current paths)
BTRBK_CONFIG="/home/$CURRENT_USER/scripts/btrbk.conf"
RESTIC_ENV_FILE="/home/$CURRENT_USER/scripts/.restic-env"

# Notification settings
NOTIFICATION_USER="$CURRENT_USER"
EOF

chmod 600 "$CONFIG_FILE"
echo -e "${GREEN}Configuration created at: $CONFIG_FILE${NC}"

# 3. Check for existing Restic environment
echo -e "\n${YELLOW}3. Checking for existing Restic configuration...${NC}"

if [[ -f "/home/$CURRENT_USER/scripts/.restic-env" ]]; then
    echo "Found existing .restic-env file"
    
    # Copy to new location
    cp "/home/$CURRENT_USER/scripts/.restic-env" "$HOME/.config/backup-system/.restic-env"
    chmod 600 "$HOME/.config/backup-system/.restic-env"
    
    echo -e "${GREEN}Restic configuration copied to ~/.config/backup-system/${NC}"
else
    echo -e "${YELLOW}No existing .restic-env found${NC}"
fi

# 4. Test configuration loading
echo -e "\n${YELLOW}4. Testing configuration...${NC}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [[ -f "${SCRIPT_DIR}/../common/load-config.sh" ]]; then
    # shellcheck source=../common/load-config.sh
    source "${SCRIPT_DIR}/../common/load-config.sh"
    
    echo "Loaded configuration:"
    echo "  BACKUP_USER: $BACKUP_USER"
    echo "  BACKUP_STORAGE_ROOT: $BACKUP_STORAGE_ROOT" 
    echo "  BTRBK_CONFIG: $BTRBK_CONFIG"
    echo -e "${GREEN}Configuration loaded successfully!${NC}"
else
    echo -e "${RED}Could not find load-config.sh${NC}"
fi

# 5. Create wrapper scripts for compatibility
echo -e "\n${YELLOW}5. Creating compatibility wrapper scripts...${NC}"

# Create a wrapper for the old system-backup.sh location
if [[ ! -f "/home/$CURRENT_USER/scripts/system-backup-wrapper.sh" ]]; then
    cat > "/home/$CURRENT_USER/scripts/system-backup-wrapper.sh" << 'EOF'
#!/bin/bash
# Wrapper script for backward compatibility
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/../modern-arch-backup-system/scripts/backup/system-backup.sh" "$@"
EOF
    chmod +x "/home/$CURRENT_USER/scripts/system-backup-wrapper.sh"
    echo -e "${GREEN}Created wrapper script for system-backup.sh${NC}"
fi

# Summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Migration Summary${NC}"
echo -e "${GREEN}========================================\n${NC}"

echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Test the new configuration:"
echo "   cd $HOME/scripts/modern-arch-backup-system"
echo "   ./scripts/backup/system-backup.sh"
echo ""
echo "2. Run the full setup to install scripts system-wide:"
echo "   sudo ./scripts/setup/setup-backup-system-new.sh"
echo ""
echo "3. Update any cron jobs or scripts that reference old paths"
echo ""
echo "4. Your existing setup remains unchanged at:"
echo "   /home/$CURRENT_USER/scripts/"
echo ""
echo -e "${GREEN}Configuration file: $CONFIG_FILE${NC}"
echo -e "${GREEN}You can edit this file to adjust paths as needed${NC}"
