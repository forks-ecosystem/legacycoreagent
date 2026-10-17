#!/bin/sh
set -e

cd "$(dirname "$0")"

GO="${GO:-/usr/local/go/bin/go}"
BIN=/usr/local/bin/legacycoreagent
SERVICE=legacycoreagent
SRC=/app/legacycore

echo "==> Building legacycoreagent binary from $SRC..."
cd "$SRC"
"$GO" build -o "$BIN" ./cmd/legacycoreagent/

echo '==> Restarting systemd service...'
systemctl restart "$SERVICE"

echo '==> Status:'
systemctl status "$SERVICE" --no-pager | head -8

echo '==> Done, legacycoreagent rebuilt and running.'
