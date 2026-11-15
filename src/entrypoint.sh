#!/bin/sh
# ===========================================================================
# Kopia entrypoint for a non-root container (TOS 7 requirement).
#
# The image starts a server that has no user account and writes its logs under
# /app/logs, which is read-only for uid 1000. This wrapper generates a random UI
# password on the first start, stores it in the config volume and starts the
# server with that account and a writable log directory.
# ===========================================================================
set -e
set -u

CFG=/config
mkdir -p "$CFG/logs" /data 2>/dev/null || true

PW_FILE="$CFG/.server-password"
if [ -s "$PW_FILE" ]; then
  PW=$(cat "$PW_FILE")
else
  PW=$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 20)
  printf '%s' "$PW" > "$PW_FILE"
  chmod 600 "$PW_FILE" 2>/dev/null || true
fi

echo "==============================================================="
echo " Kopia UI: http://<NAS-IP>:<host-port>/"
echo " user=kopia password=$PW"
echo " (also stored in config/.server-password)"
echo "==============================================================="

exec /bin/kopia server start \
  --address=0.0.0.0:51515 \
  --config-file="$CFG/kopia.config" \
  --server-username=kopia \
  --server-password="$PW" \
  --log-dir="$CFG/logs" \
  --ui --insecure
