#!/usr/bin/env bash
set -e

DOMAIN="govnozhop.mooo.com"
PORT=8443
WORKDIR="$HOME/mtg"

echo "==> Creating directory $WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "==> Generating FakeTLS secret for domain: $DOMAIN"

SECRET=$(docker run --rm nineseconds/mtg:latest generate-secret "$DOMAIN")

echo "==> Secret generated:"
echo "$SECRET"

echo "==> Writing config.toml"

cat > config.toml <<EOF
secret = "$SECRET"
bind-to = "0.0.0.0:3128"
EOF

echo "==> Writing docker-compose.yml"

cat > docker-compose.yml <<EOF
services:
  mtg:
    image: nineseconds/mtg:latest
    container_name: mtg
    restart: unless-stopped
    command: ["run", "/config.toml"]
    ports:
      - "$PORT:3128"
    volumes:
      - ./config.toml:/config.toml:ro
EOF

echo "==> Starting container"

docker compose up -d

sleep 2

echo "==> Checking container status"
docker ps | grep mtg || (echo "ERROR: container not running" && exit 1)

echo "==> Opening firewall port $PORT (ufw if exists)"
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow "$PORT/tcp" || true
  sudo ufw reload || true
fi

echo "==> Getting Telegram link"

ACCESS=$(docker exec mtg /mtg access /config.toml)

echo ""
echo "======================================"
echo "🚀 MTG Proxy is ready!"
echo "======================================"
echo "$ACCESS"
echo "======================================"
echo ""
echo "👉 Open this link on your phone"
echo "👉 Domain: $DOMAIN"
echo "👉 Port: $PORT"
