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
├── env/                 # environment + dotfiles
│   ├── shell/           # Shell configurations (.zshrc, .bashrc)
│   ├── vim/             # Vim/Neovim configurations
│   └── git/             # Git configuration
│
├── scripts/             # bootstrap + automation
│   ├── install.sh       # Initial setup script
│   ├── docker.sh        # Docker service management
│   ├── podman.sh        # Podman service management
│   └── lazyvim.sh       # LazyVim installation
│
├── docs/                # documentation
│   ├── setup.md         # Setup instructions
│   ├── networking.md    # Network configuration
│   └── backups.md       # Backup strategies
│
├── .gitignore
└── README.md
```

## 🚀 Quick Start

### 1. Initial Setup

Run the installation script to set up your environment:

```bash
./scripts/install.sh
```

This will:
- Install Docker and Docker Compose (if needed)
- Create the homelab Docker network
- Link shell and git configurations

### 2. Configure Services

Each service has an `env.example` file. Copy and customize:

```bash
cd docker/postgres
cp env.example .env
# Edit .env with your settings (especially passwords!)
```

**⚠️ Important:** Change all default passwords before starting services!

### 3. Start Services

Start all services:

```bash
./scripts/docker.sh setup
```

Or start individual services:

```bash
./scripts/docker.sh start postgres
./scripts/docker.sh start minio
./scripts/docker.sh start portainer
./scripts/docker.sh start qbittorrent
./scripts/docker.sh start airflow
```

## 📦 Services

### PostgreSQL
- **Port:** 5432
- **Purpose:** Relational database
- **Access:** `docker exec -it postgres psql -U postgres`

### MinIO
- **API Port:** 9000
- **Console Port:** 9001
- **Purpose:** S3-compatible object storage
- **Access:** http://localhost:9001

### Portainer
- **Port:** 9000
- **Purpose:** Docker container management UI
- **Access:** http://localhost:9000

### qBittorrent
- **Web UI Port:** 8081
- **BT Port:** 6881
- **Purpose:** BitTorrent client with web interface
- **Access:** http://localhost:8081
- **Default:** admin/adminadmin (⚠️ CHANGE THIS!)

### Apache Airflow
- **Web UI Port:** 8080
- **Purpose:** Workflow orchestration platform
- **Database:** Uses main PostgreSQL instance (database: `airflow`)
- **Access:** http://localhost:8080
- **Default:** airflow/airflow (⚠️ CHANGE THIS!)
- **Note:** Start PostgreSQL before Airflow

## 🛠️ Management

### Service Management

```bash
# Start a service
./scripts/docker.sh start <service>

# Stop a service
./scripts/docker.sh stop <service>

# Restart a service
./scripts/docker.sh restart <service>

# View logs
./scripts/docker.sh logs <service>

# Check status
./scripts/docker.sh status

# Stop all services
./scripts/docker.sh stop-all
```

### Available Services

- `postgres` - PostgreSQL database
- `minio` - MinIO object storage
- `portainer` - Portainer UI
- `qbittorrent` - qBittorrent client
- `airflow` - Apache Airflow

## 📚 Documentation

- [Setup Guide](docs/setup.md) - Detailed setup instructions
- [Networking](docs/networking.md) - Network configuration and port management
- [Backups](docs/backups.md) - Backup strategies and procedures

## 🔧 Configuration

### Shell Aliases

After running `install.sh`, you'll have convenient aliases:

```bash
# Docker shortcuts
dcup          # docker compose up -d
dcdown        # docker compose down
dclogs        # docker compose logs -f

# Service shortcuts
homelab-postgres      # cd to postgres directory
homelab-minio         # cd to minio directory
homelab-airflow       # cd to airflow directory
```

### Environment Variables

Each service uses environment variables for configuration. See `env.example` files in each service directory.

## 🔒 Security Notes

1. **Change Default Passwords:** All services have default credentials that MUST be changed
2. **Firewall:** Configure your firewall to restrict access
3. **SSL/TLS:** For production use, set up reverse proxy with SSL
4. **Updates:** Keep Docker images and services updated
5. **Backups:** Regular backups are essential (see [backups.md](docs/backups.md))

## 🐛 Troubleshooting

### Docker Not Running
- **macOS:** Start Docker Desktop
- **Linux:** `sudo systemctl start docker`

### Port Conflicts
Edit the `.env` file in the service directory to change ports.

### Permission Issues (Linux)
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Network Issues
```bash
docker network create homelab
```

## 📝 License

This is a personal homelab setup. Use at your own risk.

## 🤝 Contributing

This is a personal project, but suggestions and improvements are welcome!

## 🔗 Resources

- [Docker Documentation](https://docs.docker.com/)
- [Apache Airflow](https://airflow.apache.org/)
- [MinIO Documentation](https://min.io/docs/)
- [qBittorrent](https://www.qbittorrent.org/)
- [Portainer](https://www.portainer.io/)

