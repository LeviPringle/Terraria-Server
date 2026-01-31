#!/bin/sh
set -euo pipefail

# Ensure /config exists
mkdir -p /config

# If running as root, ensure /config is owned by the terraria user
if [ "$(id -u)" = "0" ]; then
  # If terraria user exists, chown; otherwise skip
  if id terraria >/dev/null 2>&1; then
    chown -R terraria:terraria /config || true
  fi
  # Drop privileges to the terraria user and run the server script
  exec runuser -u terraria -- /vanilla/run.sh "$@"
else
  # Already non-root — just run the server script
  exec /vanilla/run.sh "$@"
fi
