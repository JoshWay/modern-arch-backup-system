#!/bin/bash
# Installation script for Modern Arch Linux Backup System

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print ASCII banner
print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
                                  -`
                                 .o+`
                                `ooo/
                               `+oooo:
                              `+oooooo:
                              -+oooooo+:
                            `/:-:++oooo+:
                           `/++++/+++++++:
                          `/++++++++++++++:
                         `/+++ooooooooooooo/`
                        ./ooosssso++osssssso+`
                       .oossssso-````/ossssss+`
                      -osssssso.      :ssssssso.
                     :osssssss/        osssso+++.
                    /ossssssss/        +ssssooo/-
                  `/ossssso+/:-        -:/+osssso+-
                 `+sso+:-`                 `.-/+oso:
                `++:.                           `-/+/
                .`                                 `/
  ___  ______  _____  _   _ ______   ___   _____  _   __ _   _ ______
 / _ \ | ___ \/  __ \| | | || ___ \ / _ \ /  __ \| | / /| | | || ___ \
/ /_\ \| |_/ /| /  \/| |_| || |_/ // /_\ \| /  \/| |/ / | | | || |_/ /
|  _  ||    / | |    |  _  || ___ \|  _  || |    |    \ | | | ||  __/
| | | || |\ \ | \__/\| | | || |_/ /| | | || \__/\| |\  \| |_| || |
\_| |_/\_| \_| \____/\_| |_/\____/ \_| |_/ \____/\_| \_/ \___/ \_|
EOF
    echo -e "${NC}"
    echo
}

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "Please do not run this script as root. It will prompt for sudo when needed."
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Display banner
print_banner

print_status "Starting Modern Arch Linux Backup System Installation..."
echo

# Check prerequisites
print_status "Checking prerequisites..."

# Check if on Arch Linux
if ! command -v pacman &> /dev/null; then
    print_error "This script is designed for Arch Linux systems with pacman package manager."
    exit 1
fi

# Check for BTRFS root
if ! findmnt -n -o FSTYPE / | grep -q btrfs; then
    print_warning "Root filesystem is not BTRFS. Some features may not work optimally."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check required packages
REQUIRED_PACKAGES=(
    "btrbk"
    "restic"
    "python3"
)

MISSING_PACKAGES=()

for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! pacman -Qq "$package" &>/dev/null; then
        MISSING_PACKAGES+=("$package")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    print_warning "Missing required packages: ${MISSING_PACKAGES[*]}"
    print_status "Installing missing packages..."
    sudo pacman -S --needed "${MISSING_PACKAGES[@]}"
fi

# Create installation directory
INSTALL_DIR="/opt/modern-arch-backup-system"
print_status "Installing to $INSTALL_DIR..."

if [[ -d "$INSTALL_DIR" ]]; then
    print_warning "Installation directory already exists. Backing up to $INSTALL_DIR.backup"
    sudo mv "$INSTALL_DIR" "$INSTALL_DIR.backup.$(date +%Y%m%d-%H%M%S)"
fi

sudo mkdir -p "$INSTALL_DIR"
sudo cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR/"
sudo chown -R root:root "$INSTALL_DIR"
sudo chmod +x "$INSTALL_DIR"/scripts/backup/*.sh
sudo chmod +x "$INSTALL_DIR"/scripts/setup/*.sh
sudo chmod +x "$INSTALL_DIR"/scripts/notifications/*.sh
sudo chmod +x "$INSTALL_DIR"/scripts/notifications/*.py
sudo chmod +x "$INSTALL_DIR"/scripts/config/*.sh

# Create symlinks for easy access
print_status "Creating system symlinks..."
sudo ln -sf "$INSTALL_DIR/scripts/backup/system-backup.sh" /usr/local/bin/system-backup
sudo ln -sf "$INSTALL_DIR/scripts/setup/setup-backup-system.sh" /usr/local/bin/setup-backup-system

echo
print_status "Installation completed successfully!"
echo
echo -e "${GREEN}┌─────────────────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│                        Next Steps                           │${NC}"
echo -e "${GREEN}├─────────────────────────────────────────────────────────────┤${NC}"
echo -e "${GREEN}│ 1. Run: ${YELLOW}sudo setup-backup-system${GREEN}                       │${NC}"
echo -e "${GREEN}│ 2. Configure backup destinations in:                       │${NC}"
echo -e "${GREEN}│    ${BLUE}$INSTALL_DIR/configs/${GREEN}                     │${NC}"
echo -e "${GREEN}│ 3. Test the backup: ${YELLOW}sudo system-backup${GREEN}                 │${NC}"
echo -e "${GREEN}│                                                             │${NC}"
echo -e "${GREEN}│ For detailed instructions, see:                            │${NC}"
echo -e "${GREEN}│ ${BLUE}$INSTALL_DIR/docs/BACKUP_GUIDE.md${GREEN}             │${NC}"
echo -e "${GREEN}└─────────────────────────────────────────────────────────────┘${NC}"
echo
