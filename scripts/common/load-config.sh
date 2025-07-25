#!/bin/bash
# Common configuration loader for backup system
# This file sets up all paths and variables used by the backup scripts

# Determine if we're running from the repository or installed location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're in development mode (running from repo)
if [[ "$SCRIPT_DIR" =~ /scripts/common$ ]]; then
    # Development mode - use repo structure
    export BACKUP_DEV_MODE=true
    export BACKUP_REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    export BACKUP_CONFIG_FILE="${BACKUP_CONFIG_FILE:-$HOME/.config/backup-system/backup.conf}"
else
    # Production mode - use system paths
    export BACKUP_DEV_MODE=false
    export BACKUP_CONFIG_FILE="${BACKUP_CONFIG_FILE:-/etc/backup-system/backup.conf}"
fi

# Load user configuration if it exists
if [[ -f "$BACKUP_CONFIG_FILE" ]]; then
    source "$BACKUP_CONFIG_FILE"
fi

# Set default values if not configured
export BACKUP_USER="${BACKUP_USER:-$USER}"
export BACKUP_STORAGE_ROOT="${BACKUP_STORAGE_ROOT:-/mnt/backup-storage}"
export BTRBK_SNAPSHOTS_DIR="${BTRBK_SNAPSHOTS_DIR:-$BACKUP_STORAGE_ROOT/btrbk-snapshots}"
export RESTIC_REPO_DIR="${RESTIC_REPO_DIR:-$BACKUP_STORAGE_ROOT/restic-repo}"
export SYSTEM_BACKUPS_DIR="${SYSTEM_BACKUPS_DIR:-$BACKUP_STORAGE_ROOT/system-backups}"

# Configuration paths
if [[ "$BACKUP_DEV_MODE" == "true" ]]; then
    # Development mode paths
    export BTRBK_CONFIG="${BTRBK_CONFIG:-$BACKUP_REPO_ROOT/configs/btrbk.conf}"
    export NOTIFICATION_SCRIPT="${NOTIFICATION_SCRIPT:-$BACKUP_REPO_ROOT/scripts/notifications/kde-notify-final.sh}"
    export BACKUP_SCRIPTS_DIR="$BACKUP_REPO_ROOT/scripts/backup"
    export CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/backup-system}"
else
    # Production mode paths
    export BTRBK_CONFIG="${BTRBK_CONFIG:-/etc/btrbk/btrbk.conf}"
    export NOTIFICATION_SCRIPT="${NOTIFICATION_SCRIPT:-/usr/local/bin/kde-notify-final.sh}"
    export BACKUP_SCRIPTS_DIR="/usr/local/bin"
    export CONFIG_DIR="${CONFIG_DIR:-/etc/backup-system}"
fi

# Restic configuration
export RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-$RESTIC_REPO_DIR}"
export RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-$CONFIG_DIR/restic-password}"
export RESTIC_ENV_FILE="${RESTIC_ENV_FILE:-$CONFIG_DIR/.restic-env}"

# Logging configuration
export LOG_TAG="${LOG_TAG:-backup-system}"

# Export the notify function
notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    local icon="${4:-drive-harddisk}"
    
    if [[ -x "$NOTIFICATION_SCRIPT" ]]; then
        "$NOTIFICATION_SCRIPT" "$title" "$message" "$urgency" "$icon"
    else
        # Fallback to logger if notification script not available
        logger -t "$LOG_TAG" "[$urgency] $title: $message"
    fi
}
