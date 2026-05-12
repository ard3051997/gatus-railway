#!/bin/sh
set -e

mkdir -p /data

# Source the Gatus config from env var if provided; otherwise seed the volume
# with the baked-in default the first time the container boots.
if [ -n "$GATUS_CONFIG_YAML" ]; then
  printf '%s\n' "$GATUS_CONFIG_YAML" > /data/config.yaml
elif [ ! -f /data/config.yaml ]; then
  cp /etc/gatus/config.default.yaml /data/config.yaml
fi

# Optional basic auth — Gatus expects a base64-encoded bcrypt hash.
# We compute it at startup so the user only has to supply the plaintext password.
if [ -n "$GATUS_ADMIN_USERNAME" ] && [ -n "$GATUS_ADMIN_PASSWORD" ]; then
  if ! grep -q '^security:' /data/config.yaml; then
    BCRYPT_HASH=$(htpasswd -B -n -b "$GATUS_ADMIN_USERNAME" "$GATUS_ADMIN_PASSWORD" | cut -d: -f2)
    BCRYPT_B64=$(printf '%s' "$BCRYPT_HASH" | base64 -w0)
    {
      echo "security:"
      echo "  basic:"
      echo "    username: \"$GATUS_ADMIN_USERNAME\""
      echo "    password-bcrypt-base64: \"$BCRYPT_B64\""
      echo ""
      cat /data/config.yaml
    } > /data/config.yaml.tmp
    mv /data/config.yaml.tmp /data/config.yaml
  fi
fi

exec /usr/local/bin/gatus
