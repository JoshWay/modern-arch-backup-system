#!/bin/bash
# Secure Restic environment loader
# This script should be installed with restrictive permissions (700)

set -euo pipefail

# Load configuration
if [[ -f "/etc/backup-system/backup.conf" ]]; then
    source "/etc/backup-system/backup.conf"
elif [[ -f "$HOME/.config/backup-system/backup.conf" ]]; then
    source "$HOME/.config/backup-system/backup.conf"
else
    echo "Error: No backup configuration found!" >&2
    exit 1
fi

# Set repository path
export RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-${RESTIC_REPO_DIR:-/mnt/backup-storage/restic-repo}}"

# Load password securely
if command -v systemd-creds &> /dev/null && systemd-creds list 2>/dev/null | grep -q "restic-password"; then
    # Use systemd-creds if available
    export RESTIC_PASSWORD=$(systemd-creds cat restic-password 2>/dev/null)
elif [[ -f "$HOME/.config/backup-system/.restic-env" ]]; then
    # Load from user config
    set +x  # Ensure passwords aren't printed
    source "$HOME/.config/backup-system/.restic-env"
    set -x
else
    echo "Error: Restic password not configured!" >&2
    echo "Run setup-restic-password.sh to configure" >&2
    exit 1
fi

# Verify configuration
if [[ -z "${RESTIC_PASSWORD:-}" ]]; then
    echo "Error: RESTIC_PASSWORD not set!" >&2
    exit 1
fi
