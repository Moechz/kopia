#!/bin/sh
# ===========================================================================
# Kopia entrypoint for a non-root container (TOS 7 requirement).
#
# Two problems are solved here:
#
# 1. Credentials. Kopia's web UI is protected by HTTP Basic auth and the
#    server refuses to run without an account, so the first start generates a
#    random UI password, stores it in the config volume (mode 600) and hands it
#    to the server through KOPIA_SERVER_PASSWORD - never on the command line
#    (visible in `docker inspect`) and never in the container log. Earlier
#    versions echoed the password into the log; that is the F10 finding.
#
# 2. The landing page. Everything Kopia serves - including "/" - answers 401
#    until the browser sends Basic credentials, so the App Center open check
#    saw "HTTP 401" and reported the app as not openable. The companion
#    kopiadocker-web container serves a public landing page on the published
#    port and proxies everything else to this server, so "/" answers 200 while
#    the UI itself stays behind Basic auth.
#
# Notes:
#  * --disable-file-logging keeps the container log (docker logs) as the only
#    log sink: nothing is written below /config or /data by the logger, and no
#    request bodies or credentials end up in a file.
#  * --persist-credentials stores the *repository* password in
#    /config/kopia.config.kopia-password (mode 600) so that a repository
#    created in the UI reconnects automatically after a restart and scheduled
#    snapshots keep running. Delete that file to be asked again.
# ===========================================================================
set -e
set -u

CFG=/config
mkdir -p "$CFG" /data 2>/dev/null || true

PW_FILE="$CFG/.server-password"
if [ -s "$PW_FILE" ]; then
  PW=$(cat "$PW_FILE")
else
  PW=$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 20)
  printf '%s' "$PW" > "$PW_FILE"
  chmod 600 "$PW_FILE" 2>/dev/null || true
fi

echo "==============================================================="
echo " Kopia server starting on container port 51515"
echo " Web UI: open the published port, then the landing page entry."
echo " UI user: kopia"
echo " UI password file: $PW_FILE"
echo "   -> DockerAppData/kopiadocker/config/.server-password"
echo " The password is deliberately NOT printed here (it would end up in"
echo " docker logs and in any log collector). Read the file instead."
echo "==============================================================="

# Pass the UI password as an environment variable so that it does not show up
# in `docker inspect` (compose environment) or in the process arguments.
KOPIA_SERVER_PASSWORD="$PW"
export KOPIA_SERVER_PASSWORD

# No update check, no telemetry: the only outbound traffic is the repository
# traffic to the storage backend the user configures.
KOPIA_CHECK_FOR_UPDATES=false
export KOPIA_CHECK_FOR_UPDATES

# Keep the repository password so the server reconnects after a restart.
KOPIA_PERSIST_CREDENTIALS_ON_CONNECT=true
export KOPIA_PERSIST_CREDENTIALS_ON_CONNECT

exec /bin/kopia server start \
  --address=0.0.0.0:51515 \
  --config-file="$CFG/kopia.config" \
  --server-username=kopia \
  --cache-directory="$CFG/cache" \
  --disable-file-logging \
  --disable-content-log \
  --persist-credentials \
  --no-check-for-updates \
  --ui \
  --insecure
