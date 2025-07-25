#!/bin/bash
# Test script to verify backup system installation

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Backup System Installation Test${NC}"
echo -e "${GREEN}================================${NC}\n"

ERRORS=0

# Function to check and report
check() {
    local description="$1"
    local command="$2"
    echo -n "Checking $description... "
    
    if eval "$command" &>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        ((ERRORS++))
    fi
}

# 1. Check required commands
echo -e "${YELLOW}1. Checking required commands:${NC}"
check "btrbk installation" "command -v btrbk"
check "restic installation" "command -v restic"
check "python3 installation" "command -v python3"
check "systemd-creds availability" "command -v systemd-creds"

# 2. Check configuration files
echo -e "\n${YELLOW}2. Checking configuration:${NC}"
check "user config directory" "[[ -d ~/.config/backup-system ]]"
check "user config file" "[[ -f ~/.config/backup-system/backup.conf ]]"

# 3. Check permissions (if running as user)
if [[ $EUID -ne 0 ]]; then
    echo -e "\n${YELLOW}3. Checking file permissions:${NC}"
    
    if [[ -f ~/.config/backup-system/backup.conf ]]; then
        PERM=$(stat -c %a ~/.config/backup-system/backup.conf)
        if [[ "$PERM" == "600" ]]; then
            echo -e "Config file permissions... ${GREEN}OK${NC} (600)"
        else
            echo -e "Config file permissions... ${YELLOW}WARNING${NC} (is $PERM, should be 600)"
        fi
    fi
fi

# 4. Check if running from repo or installed
echo -e "\n${YELLOW}4. Checking installation mode:${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [[ -f "${SCRIPT_DIR}/common/load-config.sh" ]]; then
    echo "Running from repository (development mode)"
    source "${SCRIPT_DIR}/common/load-config.sh"
elif [[ -f "/usr/local/bin/backup-load-config.sh" ]]; then
    echo "Running from installed location"
    source "/usr/local/bin/backup-load-config.sh"
else
    echo -e "${RED}Configuration loader not found!${NC}"
    ((ERRORS++))
fi

# 5. Check backup storage
echo -e "\n${YELLOW}5. Checking backup storage:${NC}"
if [[ -n "${BACKUP_STORAGE_ROOT:-}" ]]; then
    echo "Backup storage root: $BACKUP_STORAGE_ROOT"
    check "storage directory exists" "[[ -d $BACKUP_STORAGE_ROOT ]]"
    check "storage is writable" "[[ -w $BACKUP_STORAGE_ROOT ]]"
else
    echo -e "${RED}BACKUP_STORAGE_ROOT not configured!${NC}"
    ((ERRORS++))
fi

# 6. Test notifications (if not root)
if [[ $EUID -ne 0 ]]; then
    echo -e "\n${YELLOW}6. Testing notifications:${NC}"
    echo "Sending test notification..."
    
    if command -v notify-send &>/dev/null; then
        notify-send "Backup System Test" "This is a test notification" && \
            echo -e "${GREEN}Notification sent${NC}" || \
            echo -e "${YELLOW}Notification may have failed${NC}"
    else
        echo -e "${YELLOW}notify-send not available${NC}"
    fi
fi

# 7. Check sudo permissions
echo -e "\n${YELLOW}7. Checking sudo permissions:${NC}"
if [[ -f /etc/sudoers.d/backup-operations ]]; then
    echo -e "Sudoers file exists... ${GREEN}OK${NC}"
    
    # Test if we can run btrbk without password
    if sudo -n btrbk -c /etc/btrbk/btrbk.conf list &>/dev/null; then
        echo -e "Sudo btrbk access... ${GREEN}OK${NC}"
    else
        echo -e "Sudo btrbk access... ${YELLOW}May require configuration${NC}"
    fi
else
    echo -e "Sudoers file... ${YELLOW}Not installed${NC}"
    echo "Run: sudo ./scripts/setup/setup-backup-system-new.sh"
fi

# Summary
echo -e "\n${YELLOW}Summary:${NC}"
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}All checks passed! The backup system appears to be properly configured.${NC}"
    echo -e "\nNext steps:"
    echo "1. Configure your Restic password if not done"
    echo "2. Run a test backup"
    echo "3. Enable the systemd timer for automatic backups"
else
    echo -e "${RED}Found $ERRORS errors. Please review the output above.${NC}"
    echo -e "\nCommon fixes:"
    echo "1. Run the setup script: sudo ./scripts/setup/setup-backup-system-new.sh"
    echo "2. Check your configuration: ~/.config/backup-system/backup.conf"
    echo "3. Ensure backup storage is mounted and writable"
fi
