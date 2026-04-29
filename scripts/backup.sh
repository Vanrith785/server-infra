#!/bin/bash
# =============================================================
# Server Backup Script — svsnlosgistics.shop
# Run daily via cron: 0 2 * * * /root/backup.sh >> /var/log/backup.log 2>&1
# =============================================================

BACKUP_DIR="/root/backups/$(date +%Y-%m-%d)"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"
RETAIN_DAYS=7

mkdir -p "$BACKUP_DIR"
echo "$LOG_PREFIX Starting backup to $BACKUP_DIR"

# --- NPM config, proxy rules, nginx patches ---
echo "$LOG_PREFIX Backing up NPM data..."
cp -rp /root/npm-data "$BACKUP_DIR/npm-data"

# --- SSL certs (including wildcard private keys) ---
echo "$LOG_PREFIX Backing up SSL certs..."
cp -rp /root/npm-letsencrypt "$BACKUP_DIR/npm-letsencrypt"

# --- MongoDB dumps ---
echo "$LOG_PREFIX Dumping MongoDB databases..."
for entry in \
  "svsn_mongodb:svsn_logistics:$(docker exec svsn_mongodb printenv MONGO_INITDB_ROOT_USERNAME):$(docker exec svsn_mongodb printenv MONGO_INITDB_ROOT_PASSWORD)" \
  "rentroom-mongodb:rentroom:admin:password123" \
  "attendance_mongodb:attendance_db::" \
  "diabetes-mongodb:diabetes-tracker::" \
  "vanta_api-mongo-1:vantapass::"
do
  container=$(echo $entry | cut -d: -f1)
  db=$(echo $entry | cut -d: -f2)
  user=$(echo $entry | cut -d: -f3)
  pass=$(echo $entry | cut -d: -f4)

  if [ -n "$user" ]; then
    auth="--username $user --password $pass --authenticationDatabase admin"
  else
    auth=""
  fi

  docker exec "$container" mongodump $auth \
    --db "$db" --archive="/tmp/${db}.archive" --gzip 2>/dev/null \
    && docker cp "$container:/tmp/${db}.archive" "$BACKUP_DIR/${db}.archive" \
    && docker exec "$container" rm -f "/tmp/${db}.archive" \
    && echo "$LOG_PREFIX   $db: OK" \
    || echo "$LOG_PREFIX   $db: FAILED"
done

# --- Compose files and run commands ---
echo "$LOG_PREFIX Backing up compose files..."
mkdir -p "$BACKUP_DIR/compose"
cp /srv/nginx-proxy-manager/docker-compose.yml "$BACKUP_DIR/compose/"
for f in \
  /root/SJB-Attendant/docker-compose.yml \
  /root/aea/backend-aea/docker-compose.yml \
  /root/diabetes/Diabetes-Patient/docker-compose.yml \
  /root/policy/docker-compose.yml \
  /root/Vanta_api/docker-compose.yml \
  /home/project1/svlosgistics/docker-compose.yml \
  /home/project2/rentroom/docker-compose.yml
do
  cp "$f" "$BACKUP_DIR/compose/$(basename $(dirname $f))_$(basename $f)" 2>/dev/null
done

# --- Portainer run command snapshot ---
docker inspect portainer --format \
  'docker run -d --name portainer --restart always -p 9000:9000 -p 8000:8000 -p 9443:9443 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data --network production portainer/portainer-ce:lts' \
  > "$BACKUP_DIR/portainer-redeploy.sh" 2>/dev/null

# --- Cleanup old backups ---
echo "$LOG_PREFIX Cleaning up backups older than ${RETAIN_DAYS} days..."
find /root/backups -maxdepth 1 -mindepth 1 -type d -mtime +$RETAIN_DAYS -exec rm -rf {} +

# --- Summary ---
SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
echo "$LOG_PREFIX Backup complete. Size: $SIZE | Location: $BACKUP_DIR"
