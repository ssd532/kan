# Kan Deployment

Documentation and scripts for deploying Kan.

## Deployment Options

| Option | Description | Cost |
|--------|-------------|------|
| [LXD](lxd.md) | Run in local LXD container | Free |
| [Fly.io](fly.md) | Deploy to Fly.io cloud | ~$5-10/month |

## Quick Start

### LXD (local)

```bash
./setup-lxd.sh
```

### Fly.io (cloud)

```bash
fly auth login
fly deploy
```

## Documents

- **[lxd.md](lxd.md)** - LXD container setup guide
- **[fly.md](fly.md)** - Fly.io deployment guide with SOPs

## Scripts

- **[setup-lxd.sh](setup-lxd.sh)** - Automated LXD container setup
- **[teardown-lxd.sh](teardown-lxd.sh)** - LXD container cleanup

## Configuration

- **[fly.toml](fly.toml)** - Fly.io app configuration

## Current Deployments

| Environment | URL | Platform |
|-------------|-----|----------|
| Production | https://kan.remiges.tech | Fly.io |
| Local | http://10.189.248.126:3000 | LXD |
