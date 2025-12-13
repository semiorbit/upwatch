#!/bin/bash
set -e

install -m 750 src/upwatch /usr/local/bin/upwatch
install -m 750 src/upload_scan.sh /usr/local/bin/upload_scan.sh

touch /etc/upload_scan.conf
chmod 640 /etc/upload_scan.conf
chown root:root /etc/upload_scan.conf

touch /var/log/upload_scan.journal.log
chmod 600 /var/log/upload_scan.journal.log
chown root:root /var/log/upload_scan.journal.log

echo "UpWatch installed."
