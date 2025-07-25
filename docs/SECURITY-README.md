# Restic Password Security

## Overview
The Restic backup password is now stored securely using systemd-creds encryption instead of plaintext.

## Initial Setup
1. Run the setup script to encrypt your password:
   ```bash
   sudo /home/b3l13v3r/scripts/setup-restic-password.sh
   ```

2. Enter your Restic password when prompted (the same one you used during repository initialization)

## How It Works
- Password is encrypted using systemd-creds and stored in `/etc/credstore/restic-password`
- Only root and systemd services can decrypt the password
- The backup script automatically uses the encrypted password

## Manual Backup Usage
To run backups manually with the encrypted password:
```bash
source /home/b3l13v3r/scripts/restic-env-secure.sh
# Now you can use restic commands
restic snapshots
```

## Security Notes
- The old `.restic-env` file with plaintext password should be deleted after setting up encryption
- The encrypted credential is tied to your system's TPM/machine-id
- If you migrate the system, you'll need to re-encrypt the password

## Troubleshooting
If you get password errors:
1. Check if the credential exists: `sudo systemd-creds list`
2. Re-run the setup script if needed
3. For systemd service issues, check: `sudo journalctl -u system-backup.service`
