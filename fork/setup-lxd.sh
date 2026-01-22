#!/bin/bash
set -e

CONTAINER_NAME="${1:-kan}"
AUTH_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)

echo "Creating LXD container: $CONTAINER_NAME"
lxc launch ubuntu:24.04 "$CONTAINER_NAME"

echo "Configuring container for Docker support..."
lxc stop "$CONTAINER_NAME"
lxc config set "$CONTAINER_NAME" security.nesting=true
lxc config set "$CONTAINER_NAME" security.syscalls.intercept.mknod=true
lxc config set "$CONTAINER_NAME" security.syscalls.intercept.setxattr=true
lxc start "$CONTAINER_NAME"

echo "Waiting for container to be ready..."
sleep 5

echo "Installing Docker..."
lxc exec "$CONTAINER_NAME" -- apt-get update -qq
lxc exec "$CONTAINER_NAME" -- apt-get install -y -qq docker.io docker-compose-v2 git

echo "Cloning Kan..."
lxc exec "$CONTAINER_NAME" -- git clone https://github.com/kanbn/kan.git /opt/kan

echo "Creating .env file..."
lxc exec "$CONTAINER_NAME" -- bash -c "cat > /opt/kan/.env << EOF
NEXT_PUBLIC_BASE_URL=http://localhost:3000
BETTER_AUTH_SECRET=$AUTH_SECRET
POSTGRES_URL=postgresql://kan:localpassword123@postgres:5432/kan_db
POSTGRES_PASSWORD=localpassword123
NEXT_PUBLIC_ALLOW_CREDENTIALS=true
NEXT_PUBLIC_DISABLE_EMAIL=true
EOF"

echo "Creating Docker network..."
lxc exec "$CONTAINER_NAME" -- docker network create dokploy-network 2>/dev/null || true

echo "Starting Kan..."
lxc exec "$CONTAINER_NAME" -- bash -c "cd /opt/kan && docker compose up -d"

echo "Waiting for containers to start..."
sleep 10

IP=$(lxc list "$CONTAINER_NAME" -c 4 --format csv | grep eth0 | cut -d' ' -f1)

echo ""
echo "Kan is running at: http://$IP:3000"
echo ""
echo "Commands:"
echo "  Logs:   lxc exec $CONTAINER_NAME -- docker compose -f /opt/kan/docker-compose.yml logs -f"
echo "  Stop:   lxc stop $CONTAINER_NAME"
echo "  Start:  lxc start $CONTAINER_NAME && lxc exec $CONTAINER_NAME -- docker compose -f /opt/kan/docker-compose.yml up -d"
echo "  Delete: lxc delete $CONTAINER_NAME --force"
