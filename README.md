# Homelab

A self-hosted homelab setup with Docker containers for various services.

## 🏗️ Structure

```
homelab/
├── docker/              # ALL containers live here
│   ├── airflow/         # Apache Airflow - Workflow orchestration
│   ├── minio/           # MinIO - S3-compatible object storage
│   ├── postgres/        # PostgreSQL - Database
│   ├── qbittorrent/     # qBittorrent - BitTorrent client
│   └── portainer/       # Portainer - Docker management UI
│
├── scripts/             # bootstrap + automation
│   ├── docker.sh        # Docker service management
├── .gitignore
└── README.md
```
