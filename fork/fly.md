# Running Kan on Fly.io

## Prerequisites

- Fly CLI installed: `curl -L https://fly.io/install.sh | sh`
- Add to PATH: `export PATH="$HOME/.fly/bin:$PATH"`
- Log in: `fly auth login`

## Deploy

### 1. Create the app

```bash
fly apps create kan-app --org personal
```

### 2. Create Postgres database

```bash
fly postgres create --name kan-db --region sin --vm-size shared-cpu-1x --volume-size 1 --initial-cluster-size 1
```

### 3. Attach database to app

```bash
fly postgres attach kan-db --app kan-app
```

This creates a database and sets `DATABASE_URL` secret automatically.

### 4. Set secrets

```bash
AUTH_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)

fly secrets set --app kan-app \
  POSTGRES_URL="<connection-string-from-attach-output>" \
  BETTER_AUTH_SECRET="$AUTH_SECRET"
```

### 5. Deploy

From this directory:

```bash
fly deploy
```

---

## Standard Operating Procedures

### Machine Operations

#### List machines

```bash
fly machines list --app kan-app
```

Output shows machine ID, state, region, and last updated time.

#### Start a machine

```bash
fly machines start <machine-id> --app kan-app
```

#### Stop a machine

```bash
fly machines stop <machine-id> --app kan-app
```

#### Stop all machines

```bash
fly machines list --app kan-app --json | jq -r '.[].id' | xargs -I {} fly machines stop {} --app kan-app
```

#### Start all machines

```bash
fly machines list --app kan-app --json | jq -r '.[].id' | xargs -I {} fly machines start {} --app kan-app
```

#### Restart a machine

```bash
fly machines restart <machine-id> --app kan-app
```

#### Scale number of machines

```bash
# Run 1 machine (cheaper)
fly scale count 1 --app kan-app

# Run 2 machines (high availability)
fly scale count 2 --app kan-app
```

### Logs

#### Stream live logs

```bash
fly logs --app kan-app
```

#### Stream logs from specific machine

```bash
fly logs --app kan-app --instance <machine-id>
```

#### Filter logs by region

```bash
fly logs --app kan-app --region sin
```

### Debugging

#### SSH into running machine

```bash
fly ssh console --app kan-app
```

#### SSH into specific machine

```bash
fly ssh console --app kan-app --instance <machine-id>
```

#### Run a command in container

```bash
fly ssh console --app kan-app -C "ps aux"
fly ssh console --app kan-app -C "cat /app/.env"
fly ssh console --app kan-app -C "printenv | grep POSTGRES"
```

#### Check app status

```bash
fly status --app kan-app
```

#### Check machine details

```bash
fly machines status <machine-id> --app kan-app
```

#### View app info

```bash
fly info --app kan-app
```

### Secrets Management

#### List secrets (names only)

```bash
fly secrets list --app kan-app
```

#### Set a secret

```bash
fly secrets set MY_SECRET="value" --app kan-app
```

#### Set multiple secrets

```bash
fly secrets set KEY1="val1" KEY2="val2" --app kan-app
```

#### Remove a secret

```bash
fly secrets unset MY_SECRET --app kan-app
```

### Database Operations

#### Connect to Postgres

```bash
fly postgres connect --app kan-db
```

#### Run SQL query

```bash
fly postgres connect --app kan-db -c "SELECT count(*) FROM users;"
```

#### Proxy database to localhost

```bash
fly proxy 5432 --app kan-db
```

Then connect locally: `psql postgres://postgres:password@localhost:5432`

#### Check database status

```bash
fly status --app kan-db
```

#### Database logs

```bash
fly logs --app kan-db
```

### Deployment

#### Deploy latest image

```bash
fly deploy --app kan-app
```

#### Deploy specific image tag

```bash
fly deploy --app kan-app --image ghcr.io/kanbn/kan:v1.0.0
```

#### Rollback to previous deployment

```bash
fly releases --app kan-app              # List releases
fly deploy --app kan-app --image <previous-image>
```

#### View release history

```bash
fly releases --app kan-app
```

### Monitoring

#### Check machine health

```bash
fly checks list --app kan-app
```

#### View metrics dashboard

```bash
fly dashboard --app kan-app
```

Opens the Fly.io dashboard in browser.

#### View resource usage

```bash
fly scale show --app kan-app
```

### Troubleshooting

#### App not starting

1. Check logs for errors:
   ```bash
   fly logs --app kan-app
   ```

2. Verify secrets are set:
   ```bash
   fly secrets list --app kan-app
   ```

3. SSH in and check environment:
   ```bash
   fly ssh console --app kan-app -C "printenv"
   ```

#### Database connection issues

1. Check database is running:
   ```bash
   fly status --app kan-db
   ```

2. Verify POSTGRES_URL secret:
   ```bash
   fly ssh console --app kan-app -C "printenv | grep POSTGRES"
   ```

3. Test connection from app machine:
   ```bash
   fly ssh console --app kan-app
   # Inside container:
   nc -zv kan-db.flycast 5432
   ```

#### Machine keeps stopping

Check if auto_stop is enabled in fly.toml. With `auto_stop_machines = "stop"`, machines stop after idle period. First request will wake them (cold start ~5-10s).

To disable auto-stop:
```toml
[http_service]
  auto_stop_machines = "off"
```

Then redeploy: `fly deploy`

#### Out of memory

Increase machine memory:
```bash
fly scale memory 2048 --app kan-app
```

---

## Configuration

The `fly.toml` in this directory configures:

- **Region**: Singapore (`sin`)
- **Image**: `ghcr.io/kanbn/kan:latest`
- **Memory**: 1GB shared CPU
- **Auto-stop**: Machines stop when idle, start on request

To change region, edit `primary_region` in `fly.toml` and redeploy.

## Cost

With auto-stop enabled and minimal usage:
- ~$0 when idle (machines stopped)
- ~$5-10/month with light usage
- Postgres: ~$2/month minimum

Check current usage:
```bash
fly billing view
```

## Cleanup

#### Delete app only

```bash
fly apps destroy kan-app
```

#### Delete database

```bash
fly apps destroy kan-db
```

#### Delete everything

```bash
fly apps destroy kan-app -y
fly apps destroy kan-db -y
```

---

## Custom Domain

### Add domain to Fly

```bash
fly certs create kan.remiges.tech --app kan-app
```

### Configure DNS

Add one of these record sets to your DNS provider:

**Option 1 - A/AAAA records (recommended)**
```
A     kan    66.241.125.247
AAAA  kan    2a09:8280:1::c8:2067:0
```

**Option 2 - CNAME record**
```
CNAME kan    zjp8y5m.kan-app.fly.dev
```

### Update base URL

```bash
fly secrets set NEXT_PUBLIC_BASE_URL="https://kan.remiges.tech" --app kan-app
```

### Verify certificate

```bash
fly certs check kan.remiges.tech --app kan-app
```

### List certificates

```bash
fly certs list --app kan-app
```

### Remove a domain

```bash
fly certs delete kan.remiges.tech --app kan-app
```

---

## Current Deployment

- **URL**: https://kan.remiges.tech (custom domain)
- **Fly URL**: https://kan-app.fly.dev
- **Region**: Singapore (sin)
- **Postgres**: kan-db.flycast:5432
- **App name**: kan-app
- **DB name**: kan-db
