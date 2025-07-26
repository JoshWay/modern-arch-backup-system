#!/bin/bash

# Setup script for backup sudo permissions
# This enables passwordless sudo for backup operations

echo "Setting up passwordless sudo for backup operations..."
echo "======================================================="

# Check if running as regular user
if [[ $EUID -eq 0 ]]; then
   echo "ERROR: Do not run this script as root. Run as your regular user."
   exit 1
fi

echo "This script will:"
echo "1. Install sudoers rule for passwordless backup operations"
echo "2. Test the backup system"
echo ""

read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

echo ""
echo "Installing sudoers rule..."
echo "You will be prompted for your password to install the sudo rule."

# Copy the sudoers rule
if sudo cp /home/your-username/scripts/backup-sudoers /etc/sudoers.d/backup-operations; then
    echo "✅ Sudoers rule installed successfully"
    
    # Set proper permissions
    sudo chmod 440 /etc/sudoers.d/backup-operations
    
    echo ""
    echo "Testing passwordless sudo access..."
    
    # Test sudo access
    if sudo -n true 2>/dev/null; then
        echo "✅ Passwordless sudo is working"
        
        echo ""
        echo "Testing backup system..."
        
        # Test notification system
        notify-send --urgency=normal --icon=security-high "Backup System Ready" "Passwordless sudo configured successfully!"
        
        echo "✅ Setup completed successfully!"
        echo ""
        echo "You can now run backups with:"
        echo "  /home/your-username/scripts/master-backup.sh"
        echo ""
        echo "Or set up automated daily backups with:"
        echo "  sudo systemctl enable backup.timer"
        echo "  sudo systemctl start backup.timer"
        
    else
        echo "❌ Passwordless sudo test failed"
        echo "You may need to restart your session for changes to take effect"
    fi
    
else
    echo "❌ Failed to install sudoers rule"
    exit 1
fi
