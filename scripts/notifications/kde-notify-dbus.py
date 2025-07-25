#!/usr/bin/env python3

import dbus
import sys
import os

def send_kde_notification(app_name, title, message, icon="drive-harddisk", timeout=-1):
    """
    Send a notification using the proper D-Bus interface
    """
    try:
        # Set up D-Bus session
        if os.geteuid() == 0:
            # Running as root - need to connect to user's session
            bus_address = "unix:path=/run/user/1000/bus"
            bus = dbus.bus.BusConnection(bus_address)
        else:
            # Running as regular user
            bus = dbus.SessionBus()
        
        # Get the notification service
        notifications = bus.get_object('org.freedesktop.Notifications', 
                                     '/org/freedesktop/Notifications')
        
        # Create the notification interface
        notify_interface = dbus.Interface(notifications, 
                                        'org.freedesktop.Notifications')
        
        # Set up notification parameters
        app_name = str(app_name)
        replaces_id = dbus.UInt32(0)
        app_icon = str(icon)
        summary = str(title)
        body = str(message)
        actions = dbus.Array([], signature='s')
        
        # Create hints dict with proper D-Bus types
        hints = dbus.Dictionary({
            'desktop-entry': dbus.String('system-backup'),
            'category': dbus.String('transfer'),
            'urgency': dbus.Byte(1)  # 0=low, 1=normal, 2=critical
        }, signature='sv')
        
        expire_timeout = dbus.Int32(timeout)
        
        # Send the notification
        notification_id = notify_interface.Notify(
            app_name,
            replaces_id,
            app_icon,
            summary,
            body,
            actions,
            hints,
            expire_timeout
        )
        
        print(f"Notification sent successfully with ID: {notification_id}")
        return notification_id
        
    except Exception as e:
        print(f"Error sending notification: {e}")
        return None

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: kde-notify-dbus.py <app_name> <title> <message> [icon] [timeout]")
        print("Example: kde-notify-dbus.py 'System Backup' 'Backup Started' 'Backup in progress'")
        sys.exit(1)
    
    app_name = sys.argv[1]
    title = sys.argv[2]
    message = sys.argv[3]
    icon = sys.argv[4] if len(sys.argv) > 4 else "drive-harddisk"
    timeout = int(sys.argv[5]) if len(sys.argv) > 5 else -1
    
    send_kde_notification(app_name, title, message, icon, timeout)
