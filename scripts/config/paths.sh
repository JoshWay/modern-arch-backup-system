#!/bin/bash
# Path configuration for Modern Arch Linux Backup System

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Base directory of the backup system
BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Script directories
BACKUP_SCRIPTS_DIR="$BASE_DIR/scripts/backup"
SETUP_SCRIPTS_DIR="$BASE_DIR/scripts/setup"
NOTIFICATIONS_DIR="$BASE_DIR/scripts/notifications"

# Configuration directories
CONFIGS_DIR="$BASE_DIR/configs"
SYSTEMD_DIR="$BASE_DIR/systemd"
DOCS_DIR="$BASE_DIR/docs"

# Individual script paths
SYSTEM_BACKUP_SCRIPT="$BACKUP_SCRIPTS_DIR/system-backup.sh"
NOTIFICATION_SCRIPT="$NOTIFICATIONS_DIR/kde-notify-final.sh"
BTRBK_CONFIG="$CONFIGS_DIR/btrbk.conf"

# Restic environment files (these should be in a secure location)
RESTIC_ENV_SECURE="$SETUP_SCRIPTS_DIR/restic-env-secure.sh"
RESTIC_ENV_FILE="$BASE_DIR/.restic-env"

# Export paths for use in other scripts
export BASE_DIR BACKUP_SCRIPTS_DIR SETUP_SCRIPTS_DIR NOTIFICATIONS_DIR
export CONFIGS_DIR SYSTEMD_DIR DOCS_DIR
export SYSTEM_BACKUP_SCRIPT NOTIFICATION_SCRIPT BTRBK_CONFIG
export RESTIC_ENV_SECURE RESTIC_ENV_FILE
