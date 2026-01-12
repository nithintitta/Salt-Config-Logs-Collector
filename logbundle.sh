########################################################################################################
######################## Written by Nithin Titta ######################################################
#######################################################################################################


#!/bin/bash

BUNDLE_NAME="salt_diagnostic_$(hostname)_$(date +%Y%m%d_%H%M%S)"
DEST_DIR="/tmp/$BUNDLE_NAME"
LOG_ARCHIVE="/tmp/$BUNDLE_NAME.tar.gz"

if [ "$EUID" -ne 0 ]; then 
  echo "Error: Please run as root (sudo)."
  exit 1
fi

echo "--- Initializing SaltStack & RAAS Diagnostic Collection ---"
mkdir -p "$DEST_DIR/reports"
mkdir -p "$DEST_DIR/systemd"

[ -x "$(command -v salt)" ] && salt --versions-report > "$DEST_DIR/reports/salt_versions.txt" 2>&1
[ -x "$(command -v salt-master)" ] && salt-master --versions-report > "$DEST_DIR/reports/master_versions.txt" 2>&1
[ -x "$(command -v salt-minion)" ] && salt-minion --versions-report > "$DEST_DIR/reports/minion_versions.txt" 2>&1
[ -x "$(command -v salt-cloud)" ] && salt-cloud --version > "$DEST_DIR/reports/cloud_version.txt" 2>&1

if [ -x "$(command -v raas)" ]; then
    echo "      -> Collecting RAAS versions report"
    su - raas -c "raas --versions-report" > "$DEST_DIR/reports/raas_versions_report.txt" 2>&1
fi

for svc in salt-master salt-minion salt-api salt-syndic raas; do
    if systemctl list-unit-files | grep -q "^$svc.service"; then
        echo "      -> Collecting $svc info"
        systemctl status "$svc" > "$DEST_DIR/systemd/${svc}_status.txt" 2>&1
        journalctl -u "$svc" --no-pager -n 1000 > "$DEST_DIR/systemd/${svc}_journal.log" 2>&1
    fi
done

ps aux | grep -E 'salt|raas' > "$DEST_DIR/reports/process_list.txt"
if [ -x "$(command -v ss)" ]; then
    ss -tulpn | grep -E '4505|4506|8237' > "$DEST_DIR/reports/network_ports.txt"
fi

echo "      -> Mirroring Configuration structures (/etc/salt, /etc/raas)"
[ -d /etc/salt ] && cp -Rp --parents /etc/salt "$DEST_DIR/"
[ -d /etc/raas ] && cp -Rp --parents /etc/raas "$DEST_DIR/"

echo "      -> Mirroring Log structures (/var/log/salt, /var/log/raas)"
[ -d /var/log/salt ] && cp -Rp --parents /var/log/salt "$DEST_DIR/"
[ -d /var/log/raas ] && cp -Rp --parents /var/log/raas "$DEST_DIR/"

if [ -x "$(command -v salt-call)" ]; then
    salt-call --local grains.items > "$DEST_DIR/reports/minion_grains.txt" 2>&1
fi
if [ -x "$(command -v salt-key)" ]; then
    salt-key -L > "$DEST_DIR/reports/master_keys_list.txt" 2>&1
fi

echo "--- Finalizing: Compressing bundle ---"
tar -czf "$LOG_ARCHIVE" -C "$DEST_DIR" .
rm -rf "$DEST_DIR"

echo "------------------------------------------------"
echo "Bundle Ready: $LOG_ARCHIVE"
echo "------------------------------------------------"
