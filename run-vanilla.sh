#!/bin/bash
set -euo pipefail

# Default command
CMD="./TerrariaServer -x64 -config /config/serverconfig.txt -banlist /config/banlist.txt"

# Ensure /config exists
mkdir -p /config

# Create default server config if missing
if [ ! -f "/config/serverconfig.txt" ]; then
  cp /vanilla/serverconfig-default.txt /config/serverconfig.txt
fi

# Ensure banlist exists
if [ ! -f "/config/banlist.txt" ]; then
  touch /config/banlist.txt
fi

# Ensure Worlds directory in config and link it into the server dir
mkdir -p /config/Worlds
if [ -L /vanilla/Worlds ] || [ -d /vanilla/Worlds ]; then
  rm -rf /vanilla/Worlds
fi
ln -s /config/Worlds /vanilla/Worlds

# Also link to the runtime user's Terraria Worlds location if possible
if [ -n "${HOME:-}" ]; then
  mkdir -p "$HOME/.local/share/Terraria"
  if [ -e "$HOME/.local/share/Terraria/Worlds" ]; then
    rm -rf "$HOME/.local/share/Terraria/Worlds"
  fi
  ln -s /config/Worlds "$HOME/.local/share/Terraria/Worlds" || true
fi

# Helper: set a key in serverconfig.txt if the corresponding env var is set
apply_if_set() {
  varname="$1"
  key="$2"
  value="${!varname:-}"
  if [ -n "$value" ]; then
    sed -i "s/^$key=.*/$key=$value/" /config/serverconfig.txt || true
  fi
}

# Support common env vars (both upper and lower-case where upstream used lower-case)
apply_if_set "PORT" "port"
apply_if_set "port" "port"
apply_if_set "MAX_PLAYERS" "maxplayers"
apply_if_set "MAXPLAYERS" "maxplayers"
apply_if_set "WORLD" "world"
apply_if_set "world" "world"
apply_if_set "PASSWORD" "password"
apply_if_set "MOTD" "motd"

# If a world is specified via env, ensure it exists and pass it on the command line
WORLDVAR="${WORLD:-${world:-}}"
if [ -n "$WORLDVAR" ]; then
  if [ ! -f "/config/$WORLDVAR" ]; then
    echo "World file /config/$WORLDVAR does not exist. Exiting..."
    exit 1
  fi
  CMD="$CMD -world /config/$WORLDVAR"
fi

# Start server
echo "Starting container: $CMD $@"
exec $CMD "$@"
