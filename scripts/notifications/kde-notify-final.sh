#!/bin/bash

# Final KDE Notification Script using proper D-Bus interface
# Usage: kde-notify-final.sh "title" "message" [urgency] [icon]

TITLE="${1:-System Notification}"
MESSAGE="${2:-No message provided}"
URGENCY="${3:-normal}"  # low, normal, critical
ICON="${4:-drive-harddisk}"

# Map urgency to timeout (-1 = persistent for all)
TIMEOUT=-1

# Send notification using Python D-Bus script
if python3 /home/b3l13v3r/scripts/kde-notify-dbus.py "System Backup" "$TITLE" "$MESSAGE" "$ICON" "$TIMEOUT"; then
    # Log to systemd journal
    echo "KDE Notification sent: $TITLE - $MESSAGE" | systemd-cat -t kde-notify
else
    # Fallback to notify-send if Python script fails
    echo "Python notification failed, falling back to notify-send" >&2
    if [[ $EUID -eq 0 ]]; then
        sudo -u b3l13v3r DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" \
            notify-send --app-name="System Backup" --urgency="$URGENCY" --icon="$ICON" --expire-time=0 "$TITLE" "$MESSAGE"
    else
        notify-send --app-name="System Backup" --urgency="$URGENCY" --icon="$ICON" --expire-time=0 "$TITLE" "$MESSAGE"
    fi
fi
