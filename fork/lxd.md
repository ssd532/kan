# Running Kan in LXD

Run Kan in an isolated LXD container with Docker.

## Prerequisites

- LXD installed and initialized (`lxd init`)

## Setup

### 1. Create the container

```bash
lxc launch ubuntu:24.04 kan
```

### 2. Enable Docker support

LXD containers need extra privileges to run Docker:

```bash
lxc stop kan
lxc config set kan security.nesting=true
lxc config set kan security.syscalls.intercept.mknod=true
lxc config set kan security.syscalls.intercept.setxattr=true
lxc start kan
```

### 3. Install Docker

```bash
lxc exec kan -- apt-get update
lxc exec kan -- apt-get install -y docker.io docker-compose-v2 git
```

### 4. Clone and configure Kan

```bash
lxc exec kan -- git clone https://github.com/kanbn/kan.git /opt/kan
```

Create the `.env` file:

```bash
lxc exec kan -- bash -c "cat > /opt/kan/.env << 'EOF'
NEXT_PUBLIC_BASE_URL=http://localhost:3000
BETTER_AUTH_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
POSTGRES_URL=postgresql://kan:localpassword123@postgres:5432/kan_db
POSTGRES_PASSWORD=localpassword123
NEXT_PUBLIC_ALLOW_CREDENTIALS=true
NEXT_PUBLIC_DISABLE_EMAIL=true
EOF"
```

### 5. Create the external network and start

```bash
lxc exec kan -- docker network create dokploy-network
lxc exec kan -- bash -c "cd /opt/kan && docker compose up -d"
```

### 6. Get the container IP

```bash
lxc list kan -c n4 --format csv
```

Look for the `eth0` IP address. Access Kan at `http://<IP>:3000`.

## Management

### View logs

```bash
lxc exec kan -- docker compose -f /opt/kan/docker-compose.yml logs -f
```

### Stop Kan

```bash
lxc exec kan -- docker compose -f /opt/kan/docker-compose.yml down
```

Or stop the entire container:

```bash
lxc stop kan
```

### Start Kan

```bash
lxc start kan
lxc exec kan -- docker compose -f /opt/kan/docker-compose.yml up -d
```

### Shell access

```bash
lxc exec kan -- bash
```

### Delete the container

```bash
lxc delete kan --force
```

## Port forwarding (optional)

To access Kan on `localhost:3000` from your host:

```bash
lxc config device add kan proxy3000 proxy listen=tcp:0.0.0.0:3000 connect=tcp:127.0.0.1:3000
```

Remove with:

```bash
lxc config device remove kan proxy3000
```
