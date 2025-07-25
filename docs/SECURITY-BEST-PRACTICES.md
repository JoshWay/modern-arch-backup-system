# Security Best Practices for Arch Linux Backup System

## Overview

This document outlines the security measures implemented in the backup system and best practices for secure deployment.

## Security Features

### 1. **Restricted Sudo Permissions**

The sudoers configuration (`configs/backup-sudoers`) has been carefully crafted to provide minimal necessary privileges:

```sudoers
# Only allows specific btrbk commands with the system config file
USERNAME ALL=(root) NOPASSWD: /usr/bin/btrbk -c /etc/btrbk/btrbk.conf run
USERNAME ALL=(root) NOPASSWD: /usr/bin/btrbk -c /etc/btrbk/btrbk.conf list
USERNAME ALL=(root) NOPASSWD: /usr/bin/btrbk -c /etc/btrbk/btrbk.conf stats

# Only allows the specific backup script
USERNAME ALL=(root) NOPASSWD: /usr/local/bin/system-backup.sh

# Read-only mount operations for recovery
USERNAME ALL=(root) NOPASSWD: /usr/bin/mount -r -o subvol=.snapshots/* /dev/* /mnt/snapshot
USERNAME ALL=(root) NOPASSWD: /usr/bin/umount /mnt/snapshot
```

**Security benefits:**
- No unrestricted access to `btrbk` or `btrfs` commands
- Mount operations are read-only
- Specific paths prevent arbitrary filesystem access

### 2. **Secure Temporary Directories**

All scripts use `mktemp` for temporary directories:

```bash
TEMP_DIR=$(mktemp -d -t "backup-XXXXXX")
trap 'rm -rf "$TEMP_DIR"' EXIT
```

**Security benefits:**
- Unpredictable directory names prevent race conditions
- Automatic cleanup on script exit
- Proper permissions set by mktemp

### 3. **Secure Password Storage**

Multiple layers of password security:

1. **systemd-creds encryption** (preferred):
   ```bash
   echo -n "your-password" | sudo systemd-creds encrypt - restic-password
   ```

2. **File permissions**:
   - Configuration files: mode 600
   - Secure scripts: mode 700
   - Password files: mode 600

### 4. **Proper Quoting and Array Usage**

All scripts use proper quoting to prevent injection:

```bash
# Good - using arrays
RSYNC_ARGS=()
for exclude in "${EXCLUDES[@]}"; do
    RSYNC_ARGS+=("--exclude=$exclude")
done
rsync -av "${RSYNC_ARGS[@]}" "$SOURCE" "$DEST"
```

### 5. **Dynamic User Detection**

No hardcoded UIDs or usernames:

```python
# Detects user dynamically
target_user = os.environ.get('NOTIFICATION_USER', os.environ.get('SUDO_USER', None))
uid = pwd.getpwnam(target_user).pw_uid
```

### 6. **Systemd Service Hardening**

The systemd service includes security features:

```ini
[Service]
# Security hardening
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=/mnt /var/log
NoNewPrivileges=true
```

## Installation Security Checklist

### 1. **File Permissions**

After installation, verify:

```bash
# Check script permissions
ls -la /usr/local/bin/system-backup.sh         # Should be 755
ls -la /usr/local/bin/restic-env-secure.sh     # Should be 700

# Check config permissions
ls -la ~/.config/backup-system/backup.conf     # Should be 600
ls -la ~/.config/backup-system/.restic-env     # Should be 600

# Check sudoers
ls -la /etc/sudoers.d/backup-operations        # Should be 440
```

### 2. **Sudo Configuration**

Verify sudoers syntax before use:

```bash
sudo visudo -c -f /etc/sudoers.d/backup-operations
```

### 3. **Password Security**

Never store passwords in:
- Scripts
- Version control
- World-readable files
- Environment variables in scripts

Instead use:
- systemd-creds (recommended)
- Secure password managers
- Encrypted configuration files

## Usage Security Guidelines

### 1. **Running Backups**

- Always run backup scripts through their installed paths
- Don't modify scripts in `/usr/local/bin` directly
- Monitor logs for unusual activity

### 2. **Restore Operations**

- Always verify backup integrity before restore
- Test restores in isolated environments first
- Use read-only mounts when browsing backups

### 3. **Configuration Management**

- Keep configuration files in secure locations
- Use different passwords for different backup repositories
- Rotate passwords periodically
- Don't share configuration files

## Monitoring and Auditing

### 1. **Log Monitoring**

Monitor backup logs for:

```bash
# Check backup logs
journalctl -u system-backup.service -f

# Check sudo usage
journalctl _COMM=sudo | grep backup

# Check notification logs
journalctl -t kde-notify
```

### 2. **Backup Verification**

Regularly verify:

```bash
# Check Restic repository
restic check --read-data-subset=10%

# Verify btrbk snapshots
sudo btrbk -c /etc/btrbk/btrbk.conf list

# Test restore procedures
restic mount /mnt/test-restore
```

## Security Updates

Keep the system secure by:

1. **Regular Updates**:
   ```bash
   sudo pacman -Syu
   ```

2. **Monitor Security Advisories**:
   - Arch Linux security tracker
   - Restic security updates
   - btrbk release notes

3. **Review Permissions Periodically**:
   ```bash
   # Find world-writable files
   find /usr/local/bin -perm -002 -type f
   
   # Check for SUID/SGID files
   find /usr/local/bin -perm /6000 -type f
   ```

## Incident Response

If you suspect a security breach:

1. **Immediate Actions**:
   - Disable backup timer: `sudo systemctl stop system-backup.timer`
   - Change all passwords
   - Review sudo logs

2. **Investigation**:
   - Check for unauthorized sudo usage
   - Review backup logs for anomalies
   - Verify backup integrity

3. **Recovery**:
   - Reinstall backup system
   - Create new encryption keys
   - Verify all backups before restoring

## Conclusion

Security is a continuous process. Regular monitoring, updates, and adherence to these practices will help maintain a secure backup system. Always prioritize security over convenience when configuring the system.
