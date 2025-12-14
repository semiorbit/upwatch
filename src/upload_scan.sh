#!/bin/bash
set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CONF="/etc/upload_scan.conf"
LOCK="/var/run/upload_scan.lock"
JOURNAL="/var/log/upload_scan.journal.log"

CLAMSCAN="/usr/bin/clamscan"
CLAM_OPTS="--no-summary --infected"

exec 9>"$LOCK"
flock -n 9 || exit 0

[ ! -f "$CONF" ] && exit 0

while IFS= read -r LOG || [ -n "$LOG" ]; do
    [ -z "$LOG" ] && continue
    [ ! -f "$LOG" ] && continue

    while IFS= read -r FILE || [ -n "$FILE" ]; do
        [ -z "$FILE" ] && continue

        TS="$(date '+%Y-%m-%d %H:%M:%S')"

        # Allow only /home paths
        case "$FILE" in
            /home/*) ;;
            *)
                echo "$TS | $FILE | SKIPPED (OUTSIDE HOME)" >> "$JOURNAL"
                sed -i '1d' "$LOG"
                continue
            ;;
        esac

        # Skip symlinks
        if [ -L "$FILE" ]; then
            echo "$TS | $FILE | SKIPPED (SYMLINK)" >> "$JOURNAL"
            sed -i '1d' "$LOG"
            continue
        fi

        if [ ! -f "$FILE" ]; then
            echo "$TS | $FILE | MISSING" >> "$JOURNAL"
            sed -i '1d' "$LOG"
            continue
        fi

        if "$CLAMSCAN" $CLAM_OPTS "$FILE" >/dev/null 2>&1; then
            echo "$TS | $FILE | OK" >> "$JOURNAL"
        else
            RC=$?
            if [ "$RC" -eq 1 ]; then
                rm -f -- "$FILE"
                echo "$TS | $FILE | INFECTED (DELETED)" >> "$JOURNAL"
            else
                echo "$TS | $FILE | ERROR($RC)" >> "$JOURNAL"
            fi
        fi

        sed -i '1d' "$LOG"

    done < "$LOG"

done < "$CONF"
