# Networking Guide

This document describes the networking setup for your homelab services.

## Docker Network

All services run on a shared Docker network called `homelab`. This network is created automatically by the installation script or can be created manually:

```bash
docker network create homelab
```

## Service Ports

### Default Port Mappings

| Service | Internal Port | External Port | Protocol |
|---------|--------------|---------------|----------|
| PostgreSQL | 5432 | 5432 | TCP |
| MinIO API | 9000 | 9000 | TCP |
| MinIO Console | 9001 | 9001 | TCP |
| Portainer | 9000 | 9000 | TCP |
| qBittorrent WebUI | 8080 | 8081 | TCP |
| qBittorrent BT | 6881 | 6881 | TCP/UDP |
| Airflow WebUI | 8080 | 8080 | TCP |
| Airflow PostgreSQL | 5432 | 5433 | TCP |

### Changing Ports

To change any port, edit the `.env` file in the respective service directory:

```bash
cd docker/postgres
# Edit .env and change POSTGRES_PORT=5432 to your desired port
```

Then restart the service:

```bash
./scripts/docker.sh restart postgres
```

## Firewall Configuration

### macOS

If using macOS firewall, you may need to allow connections:

1. System Preferences → Security & Privacy → Firewall
2. Click "Firewall Options"
3. Allow incoming connections for Docker

### Linux (UFW)

If using UFW firewall:

```bash
# Allow specific ports
sudo ufw allow 5432/tcp  # PostgreSQL
sudo ufw allow 9000/tcp  # MinIO/Portainer
sudo ufw allow 9001/tcp  # MinIO Console
sudo ufw allow 8080/tcp  # Airflow
sudo ufw allow 8081/tcp  # qBittorrent
sudo ufw allow 6881/tcp  # qBittorrent BT
sudo ufw allow 6881/udp  # qBittorrent BT
```

### Linux (firewalld)

```bash
sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --permanent --add-port=9001/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8081/tcp
sudo firewall-cmd --permanent --add-port=6881/tcp
sudo firewall-cmd --permanent --add-port=6881/udp
sudo firewall-cmd --reload
```

## Reverse Proxy (Optional)

For production use, consider setting up a reverse proxy (nginx, Traefik, Caddy) to:
- Use standard ports (80/443)
- Add SSL/TLS encryption
- Use subdomains instead of ports

### Example with nginx

```nginx
server {
    listen 80;
    server_name airflow.example.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Service Communication

Services on the `homelab` network can communicate using container names:

- PostgreSQL: `postgres:5432`
- MinIO: `minio:9000`
- Airflow PostgreSQL: `airflow-postgres:5432`

Example connection string from another container:
```
postgresql://postgres:password@postgres:5432/mydb
```

## External Access

### Local Network Access

By default, services are accessible from:
- `localhost` (127.0.0.1)
- Your machine's IP address

To access from other devices on your network:
- Find your machine's IP: `ip addr` (Linux) or `ifconfig` (macOS)
- Access via `http://<your-ip>:<port>`

### Internet Access (Not Recommended)

⚠️ **Security Warning:** Exposing services directly to the internet without proper security (firewall, authentication, SSL) is dangerous.

If you must expose services:
1. Use a VPN (recommended)
2. Set up a reverse proxy with SSL
3. Use strong passwords
4. Keep services updated
5. Monitor access logs

## Network Troubleshooting

### Check Network Status

```bash
docker network inspect homelab
```

### Test Connectivity

```bash
# From host
curl http://localhost:8080  # Airflow

# From container
docker exec -it postgres ping minio
```

### View Network Traffic

```bash
# Install tcpdump in a container
docker run --rm -it --net homelab nicolaka/netshoot tcpdump -i eth0
```

## DNS Resolution

Container names resolve automatically within the Docker network. For custom DNS:

1. Create a custom network with DNS options
2. Use `extra_hosts` in docker-compose.yml
3. Configure `/etc/hosts` in containers

