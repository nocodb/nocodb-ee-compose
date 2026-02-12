# Installing NocoDB Enterprise with Docker Compose

Docker Compose allows you to define and run multi-container Docker applications. It's a great way to set up NocoDB along with all resources in a single configuration file.

## Prerequisites

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Network Requirements

NocoDB Enterprise requires outbound network access to the NocoDB license server for license validation and periodic license checks. Ensure the following endpoint is whitelisted in your firewall, proxy, or network security policies:

| Endpoint | Protocol | Purpose |
|---|---|---|
| `https://app.nocodb.com/api/v1/on-premise/agent` | HTTPS (TCP 443) | License activation, validation, and periodic renewal |

> [!IMPORTANT]
> If this endpoint is not reachable from your NocoDB instance, license operations will fail and the application may not start or may lose access to enterprise features.

If your environment routes outbound traffic through a proxy, ensure the proxy allows HTTPS traffic to `app.nocodb.com` as well.

## Installation Steps

1. Clone the NocoDB repository from GitHub or get the template files from the links below [Template Files](#template-files).

    ```bash
    git clone https://github.com/nocodb/nocodb-ee-compose
    ```

> [!TIP]
> If you are using the template files, download them to a directory on your host machine. \
> Structure the directory as following: \
> ├── docker-compose.yml \
> ├── docker.env \
> ├── nocodb \
> ........└── db.json

2. Navigate to the cloned directory:

    ```bash
    cd nocodb-ee-compose
    ```

3. Replace & configure the placeholder values in the `docker-compose.yml`, `docker.env` and `nocodb/db.json` files.

> [!TIP]
> You can use a text editor to search and replace the placeholder values in the files. \
> List of placeholder values to replace:
>
> - {{PLACEHOLDER_NC_LICENSE_KEY}}
> - {{PLACEHOLDER_NOCODB_DOMAIN}}
> - {{PLACEHOLDER_PG_USER}}
> - {{PLACEHOLDER_PG_PASSWORD}}

4. Start the services using Docker Compose:

    ```bash
    docker-compose up -d
    ```

    This will start NocoDB along with a PostgreSQL database, and Redis.

5. Access NocoDB in your browser by visiting `https://your-domain.tld`.

## Template Files

- `docker-compose.yml` - The main Docker Compose configuration file ([get](https://raw.githubusercontent.com/nocodb/nocodb-ee-compose/refs/heads/main/docker-compose.yml)).
- `docker.env` - Environment variables for the NocoDB service ([get](https://raw.githubusercontent.com/nocodb/nocodb-ee-compose/refs/heads/main/docker.env)).
- `db.json` - Database configuration file for NocoDB ([get](https://raw.githubusercontent.com/nocodb/nocodb-ee-compose/refs/heads/main/nocodb/db.json)).

## Troubleshooting

- If you encounter any issues, check the logs using the following command:

    ```bash
    docker-compose logs
    ```
  
- If you need to stop the services, use the following command:

    ```bash
    docker-compose down
    ```
  
- Ensure all required ports are available on your host machine (80, 443)
- If you encounter license-related errors, verify that your server can reach `https://app.nocodb.com/api/v1/on-premise/agent` (see [Network Requirements](#network-requirements))
