# NocoDB Enterprise Edition — Docker Compose

Deploy NocoDB Enterprise with Docker Compose. The interactive setup wizard configures your stack based on your infrastructure.

## Prerequisites

- Docker Engine 24+ with Compose V2
- NocoDB Enterprise license key
- A domain with DNS pointing to your server (if using built-in Traefik)

## Quick Start

```bash
git clone https://github.com/nocodb/nocodb-ee-compose.git
cd nocodb-ee-compose
./setup.sh
docker compose up -d
```

The setup wizard asks you to configure:

| Component | Options |
|-----------|---------|
| **PostgreSQL** | Bundled (demo only) or External with SSL support (RDS, Azure, Cloud SQL, custom CA) |
| **Redis** | Bundled or External |
| **Reverse Proxy** | Bundled Traefik with automatic HTTPS (Let's Encrypt), or BYO (exposes port 8080) |

## Updating

```bash
./update.sh
```

Pulls the latest images and restarts services.

## Network Requirements

NocoDB Enterprise requires outbound HTTPS to the license server:

| Endpoint | Protocol | Purpose |
|----------|----------|---------|
| `https://app.nocodb.com/api/v1/on-premise/agent` | HTTPS (TCP 443) | License activation, validation, and renewal |

> **Important:** If this endpoint is not reachable, license operations will fail and enterprise features become unavailable. If your environment routes outbound traffic through a proxy, ensure it allows HTTPS traffic to `app.nocodb.com`.

## Generated Files

`setup.sh` creates these files (gitignored — they contain credentials):

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Service orchestration |
| `docker.env` | Environment variables (license key, Redis URL) |
| `nocodb/db.json` | Database connection config (host, credentials, SSL) |

## Reconfiguration

Run `./setup.sh` again to regenerate all configuration files:

```bash
docker compose down
./setup.sh
docker compose up -d
```

## Troubleshooting

```bash
# View logs
docker compose logs -f nocodb

# Check service status
docker compose ps

# Stop all services
docker compose down
```
