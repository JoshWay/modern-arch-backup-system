#!/bin/bash
# Setup secure Restic password using systemd-creds

set -euo pipefail

echo "Setting up secure Restic password storage..."
echo "==========================================="
echo ""

# Check if running with proper permissions
if [[ $EUID -ne 0 ]]; then 
    echo "This script must be run with sudo to store system credentials"
    exit 1
fi

# Prompt for password
echo -n "Enter your Restic repository password: "
read -s RESTIC_PASSWORD
echo ""
echo -n "Confirm password: "
read -s RESTIC_PASSWORD_CONFIRM
echo ""

if [[ "$RESTIC_PASSWORD" != "$RESTIC_PASSWORD_CONFIRM" ]]; then
    echo "Passwords do not match!"
    exit 1
fi

# Store password securely using systemd-creds
echo -n "$RESTIC_PASSWORD" | systemd-creds encrypt --name=restic-password - /etc/credstore/restic-password

# Create a wrapper script that retrieves the password
cat > "$HOME/scripts/restic-env-secure.sh" << 'EOF'
#!/bin/bash
# Secure Restic environment loader
export RESTIC_REPOSITORY=/mnt/raid-storage/restic-repo
export RESTIC_PASSWORD=$(sudo systemd-creds decrypt /etc/credstore/restic-password -)
EOF

chmod 755 "$HOME/scripts/restic-env-secure.sh"
chown "$USER:$USER" "$HOME/scripts/restic-env-secure.sh"

echo ""
echo "✓ Password stored securely using systemd-creds"
echo "✓ Created secure environment loader script"
echo ""
echo "The password is now encrypted and stored in /etc/credstore/restic-password"
echo "Only root and systemd can decrypt it."
echo ""
echo "To use Restic with the encrypted password:"
echo "  source $HOME/scripts/restic-env-secure.sh"
echo ""
