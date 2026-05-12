![Gatus logo](https://openalternative.co/cdn-cgi/image/width=1024,quality=75,format=avif,metadata=none/https%3A%2F%2Fassets.openalternative.co%2Ftools%2Fgatus%2Fscreenshot.webp%3Fv%3D1740262245176)

# Deploy and Host Gatus on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/gatus?referralCode=QXdhdr)

Gatus is an open-source, developer-oriented health dashboard that continuously probes your endpoints over HTTP, ICMP, TCP, DNS, gRPC, WebSocket, SSH, and more, then surfaces the results on a public-or-private status page and alerts you through Slack, Discord, PagerDuty, Telegram, email, and dozens of other providers. Unlike heavier observability stacks, Gatus is a single Go binary configured by a single YAML file — perfect for monitoring your own SaaS, APIs, databases, and internal services without standing up Prometheus + Alertmanager + Grafana.

This Railway template lets you deploy Gatus on Railway in one click. The template builds a hardened Alpine image from `twinproduction/gatus:stable`, attaches a Railway volume for the embedded SQLite database, exposes a public HTTPS domain, and ships a configurable `GATUS_CONFIG_YAML` environment variable so you can paste your full Gatus configuration into the Railway dashboard without ever touching a shell.

## Getting Started with Gatus on Railway

After your Railway deployment finishes, open the generated `*.up.railway.app` URL to see the Gatus status page running with three demo endpoints already being probed (`gatus.io`, `google.com`, `1.1.1.1`). To monitor your own services, edit/add the `GATUS_CONFIG_YAML` variable on the Gatus service in the Railway dashboard and paste your full Gatus YAML — the entrypoint rewrites `/data/config.yaml` on every restart, so the next deploy picks up your changes. To lock the page behind HTTP basic auth, set `GATUS_ADMIN_USERNAME` and `GATUS_ADMIN_PASSWORD`, then redeploy — the entrypoint will bcrypt the password and inject a `security:` block at boot. The SQLite database at `/data/gatus.db` persists across redeploys thanks to the attached volume.

![Gatus dashboard screenshot](https://res.cloudinary.com/asset-cloudinary/image/upload/v1778609267/b87c8eeb-e9cf-4fd4-b32d-14d39ee829c3.png)

## About Hosting Gatus

Gatus is a YAML-driven uptime monitor that runs as a single static binary. Each endpoint definition specifies a target URL, a probe interval, and a list of conditions (e.g. `[STATUS] == 200`, `[RESPONSE_TIME] &lt; 500`, `[BODY].status == UP`). When any condition fails, Gatus triggers alerts and updates the status page.

Key features:

- Probes over HTTP, ICMP (ping), TCP, DNS, gRPC, WebSocket, SSH, STARTTLS, TLS
- 25+ alerting providers including Slack, Discord, Teams, PagerDuty, Telegram, email, generic webhooks
- Built-in OIDC and HTTP basic auth for protecting the status page
- Endpoint groups, maintenance windows, response-body assertions, and certificate-expiry checks
- Per-endpoint history with response-time graphs and uptime percentages

This template runs a single Gatus service backed by an embedded SQLite database on a Railway volume — no external Postgres required for small-to-medium dashboards.

## Why Deploy Gatus on Railway

Railway eliminates the manual work of self-hosting Gatus:

- One-click deploy from this template — no Docker, no `docker-compose`
- Persistent Railway volume mounted at `/data` for SQLite + config
- HTTPS public domain auto-provisioned, port routing wired
- Edit `GATUS_CONFIG_YAML` in the dashboard, redeploy, done
- Built-in metrics, logs, and rollback in the Railway UI
- Scale CPU/RAM independently as your endpoint list grows

## Common Use Cases

- Public status page for your SaaS, surfacing uptime and response times to customers
- Internal monitoring of microservices, databases, and queues over Railway's private network
- Certificate-expiry and DNS-record sanity checks across multiple production domains
- SLA reporting with Slack/PagerDuty alerts when conditions break

## Dependencies for Gatus on Railway

This template deploys one Railway service built from a custom Dockerfile that combines two upstream images:

- **Gatus binary:** `twinproduction/gatus:stable` (copied via multi-stage build)
- **Runtime base:** `alpine:3.20` (provides shell, `htpasswd`, `ca-certificates`, `wget`)
- **Source repository:** [`praveen-ks-2001/gatus-railway`](https://github.com/praveen-ks-2001/gatus-railway)

### Environment Variables Reference for Gatus on Railway

| Variable | Required | Description |
|---|---|---|
| `GATUS_CONFIG_PATH` | ✅ | Path inside the container where Gatus reads `config.yaml` |
| `GATUS_CONFIG_YAML` | optional | Full YAML config — overrides baked-in default on every boot |

### Deployment Dependencies for Self-Hosting Gatus

- Upstream project: [github.com/TwiN/gatus](https://github.com/TwiN/gatus)
- Official documentation: [gatus.io](https://gatus.io/)

## Hardware Requirements for Self-Hosting Gatus on Railway

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 0.25 vCPU | 0.5 vCPU |
| RAM | 256 MB | 512 MB |
| Storage | 1 GB volume | 5 GB volume |
| Runtime | Alpine 3.20 / Go static binary | Alpine 3.20 / Go static binary |

Gatus is extremely lightweight — the binary idles around 30 MB RAM.

## Self-Hosting Gatus With a Custom Configuration

The fastest way to self-host Gatus on Railway is to click Deploy and then paste your Gatus YAML into `GATUS_CONFIG_YAML`. A minimal config that monitors two endpoints and sends a Slack alert when either fails looks like this — the YAML is what you paste into the `GATUS_CONFIG_YAML` env var:

```
storage:
  type: sqlite
  path: /data/gatus.db

alerting:
  slack:
    webhook-url: ${SLACK_WEBHOOK_URL}

endpoints:
  - name: api
    url: https://api.example.com/health
    interval: 60s
    conditions:
      - "[STATUS] == 200"
      - "[BODY].status == UP"
    alerts:
      - type: slack
        failure-threshold: 3
        send-on-resolved: true

  - name: marketing
    url: https://www.example.com
    interval: 5m
    conditions:
      - "[STATUS] == 200"
      - "[CERTIFICATE_EXPIRATION] &gt; 168h"
```

Gatus performs its own `${VAR}` substitution inside the YAML, so referencing Railway service variables like `${SLACK_WEBHOOK_URL}` or `${{SomeService.VAR}}` (Railway resolves the latter at deploy time) works without escaping. To run Gatus outside of Railway with this same image, the following is the equivalent Docker command:

```
docker run -d \
  -p 8080:8080 \
  -v gatus-data:/data \
  -e GATUS_CONFIG_PATH=/data/config.yaml \
  -e GATUS_CONFIG_YAML="$(cat config.yaml)" \
  ghcr.io/praveen-ks-2001/gatus-railway:latest
```

## How Much Does Gatus Cost to Self-Host?

Gatus is fully open-source under the Apache 2.0 license — the software itself is free forever, with no paid tier. On Railway you only pay for the underlying compute, RAM, egress, and volume storage; a typical small deployment monitoring 10–50 endpoints fits comfortably inside the Hobby plan's $5 monthly credit.

## FAQ

**What is Gatus and Why Self-Host It on Railway?**

Gatus is an open-source automated status page and health monitoring tool. Self-hosting on Railway gives you full control over the endpoints you probe (including internal services on Railway's private network) without paying per-monitor fees to a SaaS like Pingdom or Better Uptime.

**How Do I Export Monitoring Data From Gatus via the REST API?**

Gatus exposes every status check over HTTP, so you can pull data from anywhere with `curl`. The main endpoints are `/api/v1/endpoints/statuses` (full snapshot of all endpoints), `/api/v1/endpoints/{group}_{name}/statuses?page=1&pageSize=100` (paginated history for one endpoint), and `/metrics` (Prometheus format, if enabled in config). Without auth:

```
curl https://your-gatus.up.railway.app/api/v1/endpoints/statuses > snapshot.json
```

If you've set `GATUS_ADMIN_USERNAME` / `GATUS_ADMIN_PASSWORD`, pass them with `-u`:

```
curl -u admin:yourpassword https://your-gatus.up.railway.app/api/v1/endpoints/statuses > snapshot.json
```

The response is JSON containing every endpoint, every probe result, response times, and condition pass/fail — pipe it into `jq`, store it in S3, or feed it to a BI tool.


**Why is SQLite Used Instead of an External Postgres for Gatus?**

For small-to-medium dashboards (under a few hundred endpoints), Gatus's embedded SQLite storage is faster, cheaper, and zero-maintenance compared to running a separate Postgres service. You can swap to Postgres later by editing `GATUS_CONFIG_YAML`.

**How Do I Enable HTTP Basic Auth in Self-Hosted Gatus on Railway?**

Set `GATUS_ADMIN_USERNAME` and `GATUS_ADMIN_PASSWORD` on the Gatus service in Railway, then trigger a redeploy. The entrypoint script bcrypts the password and injects a `security.basic` block into `/data/config.yaml` automatically. To switch to OIDC instead, add a `security.oidc:` block directly inside `GATUS_CONFIG_YAML`.

**What Format Should I Use for the GATUS_CONFIG_YAML Variable?**

Paste a standard Gatus YAML configuration — the same format the upstream project uses, with `storage:`, `endpoints:`, and optional `alerting:` / `security:` blocks. Gatus does its own `${VAR}` substitution at load time, so secrets can stay as env-var references. A minimal working example:

```
storage:
  type: sqlite
  path: /data/gatus.db

endpoints:
  - name: my-api
    url: https://api.example.com/health
    interval: 60s
    conditions:
      - "[STATUS] == 200"
      - "[RESPONSE_TIME] < 1000"
      - "[BODY].status == UP"

  - name: marketing-site
    url: https://www.example.com
    interval: 5m
    conditions:
      - "[STATUS] == 200"
      - "[CERTIFICATE_EXPIRATION] > 168h"
```

After pasting and saving, Railway redeploys automatically. The entrypoint writes the YAML to `/data/config.yaml` on boot, so your changes take effect on the next container start. Full schema reference: [gatus.io/docs](https://gatus.io/docs).
