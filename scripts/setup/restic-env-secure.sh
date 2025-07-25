#!/bin/bash
# Secure Restic environment loader
export RESTIC_REPOSITORY=/mnt/backup-drive/restic-repo
export RESTIC_PASSWORD=$(sudo systemd-creds decrypt /etc/credstore/restic-password -)
