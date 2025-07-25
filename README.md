# Modern Arch Linux Backup System
```
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
```

# 

A comprehensive, multi-layered backup solution optimized for BTRFS on Arch Linux with real-time KDE notifications.

## Features

- **BTRFS Snapshots** - Instant, space-efficient filesystem snapshots using `btrbk`
- **Restic Backups** - Deduplicating, encrypted, incremental backups
- **Traditional Archives** - Package lists, configs, and bootloader backups
- **KDE Notifications** - Real-time desktop notifications for backup status
- **Automated Scheduling** - Systemd timer-based automation
- **Comprehensive Recovery** - From quick file recovery to bare metal restore

## Why This System?

### Advantages Over Traditional Methods

1. **BTRFS Native Snapshots**
   - Instant creation (seconds vs hours)
   - Space-efficient (only changed blocks)
   - Can be mounted and browsed easily
   - Atomic operations (no partial backups)

2. **Restic Benefits**
   - Deduplication saves 60-80% storage
   - Built-in encryption
   - Incremental forever (only first backup is full)
   - Can backup to cloud storage directly

3. **Smart Notifications**
   - KDE desktop notifications for all backup events
   - Persistent notifications for critical errors
   - Fallback to standard notify-send if needed

## Repository Structure

```
modern-arch-backup-system/
├── scripts/
│   ├── backup/          # Main backup scripts
│   ├── setup/           # Installation and configuration scripts
│   └── notifications/   # KDE notification system
├── configs/             # Configuration files
├── systemd/             # Systemd service and timer files
├── docs/                # Documentation
└── README.md           # This file
```

## Quick Start

### Prerequisites

- Arch Linux with BTRFS root filesystem
- KDE Plasma (for notifications)
- sudo access
- External storage for backups

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/modern-arch-backup-system
   cd modern-arch-backup-system
   ```

2. Run the setup script:
   ```bash
   sudo ./scripts/setup/setup-backup-system.sh
   ```

3. Configure your Restic password:
   ```bash
   sudo ./scripts/setup/setup-restic-password.sh
   ```

4. Test the backup system:
   ```bash
   sudo ./scripts/backup/system-backup.sh
   ```

## Documentation

- **[Complete Setup Guide](docs/BACKUP_GUIDE.md)** - Comprehensive installation and usage guide
- **[Security Documentation](docs/SECURITY-README.md)** - Security considerations and best practices

## Configuration

Key configuration files:
- `configs/btrbk.conf` - BTRFS snapshot configuration
- `configs/backup-sudoers` - Sudo permissions for backup scripts
- `systemd/backup.timer` - Backup schedule configuration

## Recovery Options

The system supports multiple recovery scenarios:

1. **Quick File Recovery** - Restore individual files from BTRFS snapshots
2. **Directory Restore** - Restore entire directories from Restic backups
3. **Full System Restore** - Complete system restoration from snapshots
4. **Bare Metal Recovery** - Full disaster recovery including bootloader

## Monitoring

Monitor your backups through:
- KDE desktop notifications
- Systemd journal logs
- Backup status commands
- Restic repository health checks

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Requirements

- Arch Linux
- BTRFS filesystem
- KDE Plasma Desktop
- Python 3 (for notifications)
- btrbk
- restic
- systemd

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This backup system is provided as-is. Always test your backups and recovery procedures before relying on them for important data. The authors are not responsible for any data loss.

## Acknowledgments

- Built for the Arch Linux community
- Inspired by the need for modern, efficient backup solutions
- Thanks to the developers of btrbk, restic, and BTRFS

---

**Remember: The best backup is one that's automated, tested, and stored in multiple locations!**
