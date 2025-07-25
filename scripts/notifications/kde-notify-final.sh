#!/bin/bash

# Final KDE Notification Script using proper D-Bus interface
# Usage: kde-notify-final.sh "title" "message" [urgency] [icon]

TITLE="${1:-System Notification}"
MESSAGE="${2:-No message provided}"
URGENCY="${3:-normal}"  # low, normal, critical
ICON="${4:-drive-harddisk}"

# Map urgency to timeout (-1 = persistent for all)
TIMEOUT=-1

# Get notification user from environment or config
NOTIFICATION_USER="${NOTIFICATION_USER:-${SUDO_USER:-$USER}}"
NOTIFICATION_UID=$(id -u "$NOTIFICATION_USER" 2>/dev/null || echo "1000")

# Find the Python script
PYTHON_SCRIPT="kde-notify-dbus.py"
if [[ -f "/usr/local/bin/$PYTHON_SCRIPT" ]]; then
    PYTHON_SCRIPT="/usr/local/bin/$PYTHON_SCRIPT"
elif [[ -f "$(dirname "$0")/$PYTHON_SCRIPT" ]]; then
    PYTHON_SCRIPT="$(dirname "$0")/$PYTHON_SCRIPT"
fi

# Send notification using Python D-Bus script
if [[ -f "$PYTHON_SCRIPT" ]] && python3 "$PYTHON_SCRIPT" "System Backup" "$TITLE" "$MESSAGE" "$ICON" "$TIMEOUT"; then
    # Log to systemd journal
    echo "KDE Notification sent: $TITLE - $MESSAGE" | systemd-cat -t kde-notify
else
    # Fallback to notify-send if Python script fails or not found
    echo "Python notification failed, falling back to notify-send" >&2
    if [[ $EUID -eq 0 ]]; then
        sudo -u "$NOTIFICATION_USER" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$NOTIFICATION_UID/bus" \
            notify-send --app-name="System Backup" --urgency="$URGENCY" --icon="$ICON" --expire-time=0 "$TITLE" "$MESSAGE"
    else
        notify-send --app-name="System Backup" --urgency="$URGENCY" --icon="$ICON" --expire-time=0 "$TITLE" "$MESSAGE"
    fi
fi
