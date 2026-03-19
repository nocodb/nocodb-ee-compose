# Quickstart Demo — Bundled PostgreSQL + Redis, No Proxy

The simplest configuration for demo and evaluation. Everything runs locally in Docker.

- **PostgreSQL**: Bundled container
- **Redis**: Bundled container
- **Proxy**: None — NocoDB exposed on port 8080

## Usage

```bash
cp -r examples/quickstart-demo ./my-deployment
cd my-deployment
# Edit docker.env — set NC_LICENSE_KEY
# Edit nocodb/db.json — change the password
# Update POSTGRES_PASSWORD in docker-compose.yml to match
docker compose up -d
```

Access NocoDB at `http://localhost:8080`.

> **Note**: The bundled PostgreSQL container is suitable for demo/evaluation only. Use an external database for production.
