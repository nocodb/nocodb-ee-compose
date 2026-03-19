# Example Configurations

Pre-built Docker Compose configurations for common deployment scenarios. Copy an example as your starting point instead of running the setup wizard.

> **Important**: Replace all placeholder values (`YOUR_LICENSE_KEY`, `CHANGE_ME_generated_password`, etc.) before starting.

| Example | PostgreSQL | Redis | Proxy | Best for |
|---------|-----------|-------|-------|----------|
| [quickstart-demo](quickstart-demo/) | Bundled | Bundled | None (port 8080) | Quick demo / evaluation |
| [managed-postgres](managed-postgres/) | External (managed SSL) | External | None (port 8080) | Production with managed DB |
| [external-postgres-and-redis](external-postgres-and-redis/) | External (managed SSL) | External | None (port 8080) | Production, minimal footprint |
| [traefik-custom-ssl](traefik-custom-ssl/) | External (managed SSL) | External | Traefik + custom SSL | Production with own TLS cert |
| [postgres-private-ca](postgres-private-ca/) | External (private CA) | External | Traefik + Let's Encrypt | On-prem / private cloud DB |

## Quick start

```bash
cp -r examples/quickstart-demo ./my-deployment
cd my-deployment
# Edit placeholder values in docker.env and nocodb/db.json
docker compose up -d
```

Alternatively, run `./setup.sh` in the repo root for an interactive guided setup.
