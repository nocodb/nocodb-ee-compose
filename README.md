# nocodb-ee-compose (deprecated)

> **This repository is deprecated.** NocoDB now ships a single Docker image (`nocodb/nocodb:latest`) containing both Community and Enterprise code; a license key activates Enterprise features at runtime. All Docker Compose installation content has moved to the main [`nocodb/nocodb`](https://github.com/nocodb/nocodb) repository and the [self-hosting documentation](https://nocodb.com/docs/self-hosting).

## Where everything moved

| Used to live here | Now lives at |
|---|---|
| The `setup.sh` install wizard | [Quickstart](https://nocodb.com/docs/self-hosting/installation/quickstart) and [Single-server install](https://nocodb.com/docs/self-hosting/installation/single-server) (installer hosted at `https://install.nocodb.com/noco.sh`) |
| The `examples/` directory (managed Postgres, Traefik custom SSL, etc.) | [Custom infrastructure](https://nocodb.com/docs/self-hosting/installation/custom-infrastructure) and [`docker-compose/examples/`](https://github.com/nocodb/nocodb/tree/develop/docker-compose/examples) |
| Upgrading and backups | [Self-hosting docs](https://nocodb.com/docs/self-hosting) |
| License purchase, activation (standard, airgapped, offline), and egress requirements | [Purchasing a license](https://nocodb.com/docs/self-hosting/purchase-license) and [Activating a license](https://nocodb.com/docs/self-hosting/license-activation) |

## Existing installations

Your current stack keeps working unchanged. To pick up future releases, follow [Upgrading](https://nocodb.com/docs/self-hosting/maintenance/upgrading). For migration help, contact [cs@nocodb.com](mailto:cs@nocodb.com).
