#!/bin/bash

BACKUP_NAME="backup_$(date +%Y-%m-%d_%H-%M).tar.gz"
BACKUP_DIR="/home/edu/archive"

# if backup dir already made
if [ ! -d "$BACKUP_DIR" ]; then
  echo "Dir $BACKUP_DIR nope! Make it."
  mkdir -p "$BACKUP_DIR"
fi

tar -czf "$BACKUP_DIR/$BACKUP_NAME" /home /etc/ssh/ /etc/vsftpd.conf /var/log 2>/dev/null

# if backup done?
if [ $? -eq 0 ]; then
  echo "BackUp done. $BACKUP_DIR/$BACKUP_NAME"
else
  echo "Error!"
  exit 1
fi

