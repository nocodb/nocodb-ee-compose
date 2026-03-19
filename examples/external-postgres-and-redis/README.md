# External Postgres and Redis — No Proxy

Minimal Docker footprint — only NocoDB containers. All backing services are managed externally.

- **PostgreSQL**: External managed database with SSL
- **Redis**: External (e.g., ElastiCache, Memorystore, Azure Cache)
- **Proxy**: None — NocoDB exposed on port 8080 (put behind your own LB/proxy)

## Usage

```bash
cp -r examples/external-postgres-and-redis ./my-deployment
cd my-deployment
# Edit docker.env — set NC_LICENSE_KEY and NC_REDIS_URL
# Edit nocodb/db.json — set your database host, credentials, and port
docker compose up -d
```

## Redis URL format

```
redis://host:port
redis://:password@host:port
rediss://:password@host:port   # TLS
```

## Scaling

With external databases, you can scale NocoDB horizontally by increasing the replica count:

```yaml
deploy:
  mode: replicated
  replicas: 3
```

Ensure your load balancer distributes traffic across all replicas.
