#!/bin/bash
# Restic environment loader for systemd service
# This version doesn't require sudo since systemd runs as root

export RESTIC_REPOSITORY=/mnt/backup-drive/restic-repo

# Check if credential exists
if systemd-creds list | grep -q "restic-password"; then
    export RESTIC_PASSWORD=$(systemd-creds decrypt /etc/credstore/restic-password -)
else
    # Fallback to .restic-env if password not yet encrypted
    if [[ -f /home/b3l13v3r/scripts/.restic-env ]]; then
        source /home/b3l13v3r/scripts/.restic-env
    else
        echo "Error: Restic password not configured!"
        echo "Run: sudo /home/b3l13v3r/scripts/setup-restic-password.sh"
        exit 1
    fi
fi
