# Backup Strategy

This document outlines backup strategies for your homelab services.

## Backup Overview

Regular backups are essential for data protection. This guide covers backup strategies for each service.

## General Backup Principles

1. **3-2-1 Rule:** 3 copies, 2 different media, 1 offsite
2. **Automate:** Use cron jobs or scheduled tasks
3. **Test Restores:** Regularly verify backups are restorable
4. **Encrypt:** Encrypt sensitive backups
5. **Document:** Keep notes on backup procedures

## Service-Specific Backups

### PostgreSQL

#### Manual Backup

```bash
# Backup a specific database
docker exec postgres pg_dump -U postgres mydb > backup_$(date +%Y%m%d).sql

# Backup all databases
docker exec postgres pg_dumpall -U postgres > backup_all_$(date +%Y%m%d).sql
```

#### Automated Backup Script

Create `scripts/backup-postgres.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/path/to/backups/postgres"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

docker exec postgres pg_dumpall -U postgres | gzip > "$BACKUP_DIR/postgres_$DATE.sql.gz"

# Keep only last 30 days
find "$BACKUP_DIR" -name "postgres_*.sql.gz" -mtime +30 -delete
```

Schedule with cron:
```bash
# Daily at 2 AM
0 2 * * * /path/to/scripts/backup-postgres.sh
```

#### Restore

```bash
# Restore from backup
cat backup.sql | docker exec -i postgres psql -U postgres

# Or from compressed
gunzip < backup.sql.gz | docker exec -i postgres psql -U postgres
```

### MinIO

#### Backup Strategy

MinIO data is stored in Docker volumes. Backup the volume:

```bash
# Stop MinIO
./scripts/docker.sh stop minio

# Backup volume
docker run --rm \
  -v minio_minio_data:/data \
  -v /path/to/backups:/backup \
  alpine tar czf /backup/minio_$(date +%Y%m%d).tar.gz /data

# Start MinIO
./scripts/docker.sh start minio
```

#### Using MinIO Client (mc)

```bash
# Install mc
docker run --rm -it minio/mc alias set local http://localhost:9000 minioadmin changeme

# Mirror to backup location
docker run --rm -it \
  -v /path/to/backup:/backup \
  minio/mc mirror local /backup
```

### Airflow

#### Backup Components

1. **Database:**
```bash
docker exec airflow-postgres pg_dumpall -U airflow | gzip > airflow_db_$(date +%Y%m%d).sql.gz
```

2. **DAGs:**
```bash
docker cp airflow-webserver:/opt/airflow/dags /path/to/backups/airflow_dags_$(date +%Y%m%d)
```

3. **Logs (optional):**
```bash
docker cp airflow-webserver:/opt/airflow/logs /path/to/backups/airflow_logs_$(date +%Y%m%d)
```

### qBittorrent

#### Backup Configuration

```bash
# Backup config volume
docker run --rm \
  -v qbittorrent_qbittorrent_config:/data \
  -v /path/to/backups:/backup \
  alpine tar czf /backup/qbittorrent_$(date +%Y%m%d).tar.gz /data
```

**Note:** Downloads directory is typically a bind mount, backup separately if needed.

### Portainer

#### Backup Data

```bash
# Backup Portainer data
docker run --rm \
  -v portainer_portainer_data:/data \
  -v /path/to/backups:/backup \
  alpine tar czf /backup/portainer_$(date +%Y%m%d).tar.gz /data
```

## Comprehensive Backup Script

Create `scripts/backup-all.sh`:

```bash
#!/bin/bash
set -euo pipefail

BACKUP_ROOT="/path/to/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$DATE"

mkdir -p "$BACKUP_DIR"

echo "Starting backup at $(date)"

# PostgreSQL
echo "Backing up PostgreSQL..."
docker exec postgres pg_dumpall -U postgres | gzip > "$BACKUP_DIR/postgres.sql.gz"

# Airflow Database
echo "Backing up Airflow database..."
docker exec airflow-postgres pg_dumpall -U airflow | gzip > "$BACKUP_DIR/airflow_db.sql.gz"

# Airflow DAGs
echo "Backing up Airflow DAGs..."
docker cp airflow-webserver:/opt/airflow/dags "$BACKUP_DIR/airflow_dags"

# MinIO (stop service first)
echo "Backing up MinIO..."
./scripts/docker.sh stop minio
docker run --rm \
  -v minio_minio_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/minio.tar.gz /data
./scripts/docker.sh start minio

# qBittorrent config
echo "Backing up qBittorrent config..."
docker run --rm \
  -v qbittorrent_qbittorrent_config:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/qbittorrent.tar.gz /data

# Portainer
echo "Backing up Portainer..."
docker run --rm \
  -v portainer_portainer_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/portainer.tar.gz /data

# Compress entire backup
echo "Compressing backup..."
cd "$BACKUP_ROOT"
tar czf "backup_$DATE.tar.gz" "$DATE"
rm -rf "$DATE"

# Keep only last 7 days
find "$BACKUP_ROOT" -name "backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed at $(date)"
```

## Offsite Backup

### Using rsync

```bash
# Sync to remote server
rsync -avz /path/to/backups user@remote-server:/backups/homelab/
```

### Using Cloud Storage

#### AWS S3

```bash
# Install AWS CLI
aws s3 sync /path/to/backups s3://your-bucket/homelab-backups/
```

#### MinIO (to another MinIO instance)

```bash
# Configure remote alias
mc alias set remote https://backup-server.com ACCESS_KEY SECRET_KEY

# Sync
mc mirror local remote/backups
```

#### Rclone

```bash
# Configure rclone for various cloud providers
rclone sync /path/to/backups remote:homelab-backups
```

## Backup Verification

### Test Restore Procedure

Regularly test your restore procedure:

1. Create a test environment
2. Restore from backup
3. Verify data integrity
4. Document any issues

### Checksums

Generate checksums for backups:

```bash
find /path/to/backups -type f -exec sha256sum {} \; > checksums.txt
```

## Automation

### Cron Schedule

```bash
# Edit crontab
crontab -e

# Daily backup at 2 AM
0 2 * * * /path/to/scripts/backup-all.sh >> /var/log/backup.log 2>&1

# Weekly full backup on Sunday at 1 AM
0 1 * * 0 /path/to/scripts/backup-all.sh --full >> /var/log/backup.log 2>&1
```

### Systemd Timer (Linux)

Create `/etc/systemd/system/homelab-backup.service`:

```ini
[Unit]
Description=Homelab Backup
After=docker.service

[Service]
Type=oneshot
ExecStart=/path/to/scripts/backup-all.sh
```

Create `/etc/systemd/system/homelab-backup.timer`:

```ini
[Unit]
Description=Daily Homelab Backup

[Timer]
OnCalendar=daily
OnCalendar=02:00

[Install]
WantedBy=timers.target
```

Enable:
```bash
sudo systemctl enable homelab-backup.timer
sudo systemctl start homelab-backup.timer
```

## Monitoring

### Backup Success Notification

Add to backup scripts:

```bash
# Email notification
echo "Backup completed" | mail -s "Homelab Backup" admin@example.com

# Or use a monitoring service (Healthchecks.io, etc.)
curl https://hc-ping.com/your-uuid
```

### Log Monitoring

Monitor backup logs for errors:

```bash
tail -f /var/log/backup.log
```

## Disaster Recovery

### Recovery Plan

1. Document recovery procedures for each service
2. Keep recovery documentation offsite
3. Test recovery procedures quarterly
4. Maintain contact list for critical services

### Recovery Checklist

- [ ] Verify backup integrity
- [ ] Stop affected services
- [ ] Restore data volumes
- [ ] Restore databases
- [ ] Verify service functionality
- [ ] Update documentation with lessons learned

