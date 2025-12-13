#!/bin/bash
set -euo pipefail

CONF="/etc/upload_scan.conf"
LOCK="/var/run/upload_scan.lock"
JOURNAL="/var/log/upload_scan.journal.log"

exec 9>"$LOCK"
flock -n 9 || exit 0

[ ! -f "$CONF" ] && exit 0

while IFS= read -r LOG || [ -n "$LOG" ]; do
    [ -z "$LOG" ] && continue
    [ ! -f "$LOG" ] && continue

    while IFS= read -r FILE || [ -n "$FILE" ]; do
        [ -z "$FILE" ] && continue

        TS="$(date '+%Y-%m-%d %H:%M:%S')"

        if [ ! -f "$FILE" ]; then
            echo "$TS | $FILE | MISSING" >> "$JOURNAL"
            sed -i '1d' "$LOG"
            continue
        fi

        OUT="$(/usr/sbin/maldet -f "$FILE" --quarantine --clean --quiet 2>&1 || true)"

        if echo "$OUT" | grep -qi "malware hits"; then
            echo "$TS | $FILE | INFECTED" >> "$JOURNAL"
        else
            echo "$TS | $FILE | OK" >> "$JOURNAL"
        fi

        sed -i '1d' "$LOG"

    done < "$LOG"

done < "$CONF"