# Homelab Setup Guide

This guide will help you set up your homelab environment from scratch.

## Prerequisites

- macOS or Linux system
- Administrator/sudo access
- Internet connection

## Initial Setup

### 1. Run the Installation Script

The installation script will install Docker, Docker Compose, and set up your environment:

```bash
./scripts/install.sh
```

This script will:
- Install Docker and Docker Compose (if not already installed)
- Create the homelab Docker network
- Link shell configuration files
- Link git configuration

### 2. Configure Environment Variables

Each service has an `env.example` file. Copy and customize these:

```bash
# For each service directory
cd docker/postgres
cp env.example .env
# Edit .env with your preferred settings
```

**Important:** Change all default passwords before starting services!

### 3. Start Services

Use the docker management script to start all services:

```bash
./scripts/docker.sh setup
```

Or start individual services:

```bash
./scripts/docker.sh start postgres
./scripts/docker.sh start minio
./scripts/docker.sh start portainer
./scripts/docker.sh start qbittorrent
# Note: Start postgres before airflow (airflow uses the main postgres instance)
./scripts/docker.sh start airflow
```

**Important:** PostgreSQL must be started before Airflow, as Airflow uses the main PostgreSQL instance with a separate database.

## Service Details

### PostgreSQL

- **Port:** 5432 (default)
- **Default User:** postgres
- **Default Password:** changeme (⚠️ CHANGE THIS!)
- **Data Volume:** `postgres_data`

Access:
```bash
docker exec -it postgres psql -U postgres
```

### MinIO

- **API Port:** 9000
- **Console Port:** 9001
- **Default User:** minioadmin
- **Default Password:** changeme (⚠️ CHANGE THIS!)

Access:
- Web UI: http://localhost:9001
- API: http://localhost:9000

### Portainer

- **Port:** 9000
- **Access:** http://localhost:9000

First-time setup will prompt you to create an admin account.

### qBittorrent

- **Web UI Port:** 8081
- **BitTorrent Port:** 6881 (TCP/UDP)
- **Default Credentials:** admin/adminadmin (⚠️ CHANGE THIS!)

Access:
- Web UI: http://localhost:8081

### Apache Airflow

- **Web UI Port:** 8080
- **Database:** Uses main PostgreSQL instance (database: `airflow`)
- **Default User:** airflow
- **Default Password:** airflow (⚠️ CHANGE THIS!)

Access:
- Web UI: http://localhost:8080

**Note:** 
- Airflow uses the main PostgreSQL instance with a separate database named `airflow`
- Make sure PostgreSQL is started before starting Airflow
- The Airflow database will be created automatically on first startup
- The first startup may take a few minutes to initialize

## Useful Commands

### Check Service Status

```bash
./scripts/docker.sh status
```

### View Logs

```bash
./scripts/docker.sh logs <service-name>
```

### Restart a Service

```bash
./scripts/docker.sh restart <service-name>
```

### Stop All Services

```bash
./scripts/docker.sh stop-all
```

## Troubleshooting

### Docker Not Running

If you see "Docker is not running" errors:
- **macOS:** Start Docker Desktop from Applications
- **Linux:** `sudo systemctl start docker`

### Port Conflicts

If a port is already in use, edit the `.env` file for that service and change the port number.

### Permission Issues (Linux)

If you get permission denied errors:
```bash
sudo usermod -aG docker $USER
# Then log out and back in
```

### Network Issues

If services can't communicate:
```bash
docker network create homelab
```

## Next Steps

- Review [networking.md](./networking.md) for network configuration
- Review [backups.md](./backups.md) for backup strategies
- Customize service configurations as needed

