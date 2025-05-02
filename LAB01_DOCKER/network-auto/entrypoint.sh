#!/bin/bash
set -e
echo "[INFO] Generating SSH keys..."
ssh-keygen -A

echo "[INFO] Starting SSH daemon..."
/usr/sbin/sshd

echo "[INFO] Starting Bash shell..."
exec bash
