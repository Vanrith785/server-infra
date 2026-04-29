# svsnlosgistics.shop — Server Infrastructure

**Server:** 194.163.155.11 (Ubuntu, 146GB disk, 7.8GB RAM)
**Docker:** Snap v29.3.1
**Last updated:** 2026-04-29
**Repo:** https://github.com/Vanrith785/server-infra

---

## Quick Reference

| Service | URL | Login |
|---------|-----|-------|
| Nginx Proxy Manager | https://nginx.svsnlosgistics.shop | pichvanrith785@gmail.com |
| Portainer | https://port.svsnlosgistics.shop | admin |
| NPM (direct) | http://194.163.155.11:81 | same |
| Portainer (direct) | http://194.163.155.11:9000 | same |

> Change both passwords after every recovery. See Security section.

---

## Architecture

```
Browser
  │
  ▼
Cloudflare CDN  (proxies all *.svsnlosgistics.shop)
  │  443/80
  ▼
194.163.155.11
  │
  ├─ docker-proxy ──► nginx-proxy-manager-app-1
  │                         │
  │         ┌───────────────┼──────────────────┐
  │         ▼               ▼                  ▼
  │   production      sjb-attendant_default  vanta_api_default
  │  (172.28.0.0/16)  (192.168.192.0/20)   (192.168.176.0/20)
  │         │               │                  │
  │   15 containers    sjb-frontend        vanta-api
  │                    sjb-backend         vanta-mongo
  │
  └─ 9000 ──► portainer
```

- All domains are Cloudflare-proxied. SSL terminates at NPM.
- NPM is connected to 5 Docker networks simultaneously to reach all backends.
- Docker installed via **snap** — bind mounts must be under `/root/` or `/home/`.

---

## Running Services (19 containers)

| Container | Image | Compose File |
|-----------|-------|-------------|
| nginx-proxy-manager-app-1 | jc21/nginx-proxy-manager:latest | /srv/nginx-proxy-manager/docker-compose.yml |
| portainer | portainer/portainer-ce:lts | `docker run` — see scripts/redeploy-portainer.sh |
| sjb-attendant-frontend-1 | node:20-alpine | /root/SJB-Attendant/docker-compose.yml |
| sjb-attendant-backend-1 | node:20-alpine | /root/SJB-Attendant/docker-compose.yml |
| svsn_frontend | svlosgistics-frontend | /home/project1/svlosgistics/docker-compose.yml |
| svsn_backend | svlosgistics-backend | /home/project1/svlosgistics/docker-compose.yml |
| svsn_mongodb | mongo:7 | /home/project1/svlosgistics/docker-compose.yml |
| rentroom-frontend | rentroom-frontend | /home/project2/rentroom/docker-compose.yml |
| rentroom-backend | rentroom-backend | /home/project2/rentroom/docker-compose.yml |
| rentroom-mongodb | mongo:7 | /home/project2/rentroom/docker-compose.yml |
| attendance_backend | backend-aea-backend | /root/aea/backend-aea/docker-compose.yml |
| attendance_mongodb | mongo:8.0 | /root/aea/backend-aea/docker-compose.yml |
| diabetes-frontend | diabetes-patient-frontend | /root/diabetes/Diabetes-Patient/docker-compose.yml |
| diabetes-api | diabetes-patient-api | /root/diabetes/Diabetes-Patient/docker-compose.yml |
| diabetes-mongodb | mongo:7 | /root/diabetes/Diabetes-Patient/docker-compose.yml |
| diabetes-mongo-express | mongo-express:latest | /root/diabetes/Diabetes-Patient/docker-compose.yml |
| policy-policy-1 | node:22-alpine | /root/policy/docker-compose.yml |
| vanta_api-app-1 | vanta_api-app | /root/Vanta_api/docker-compose.yml |
| vanta_api-mongo-1 | mongo:7 | /root/Vanta_api/docker-compose.yml |

---

## Proxy Routes (23 hosts)

All routes force HTTPS. 404 on API root paths is expected behaviour.

| Domain | Backend | SSL | Status |
|--------|---------|-----|--------|
| svsnlosgistics.shop | svsn_frontend:80 | cert#39 | 200 |
| sjb.svsnlosgistics.shop | sjb-attendant-frontend-1:5173 | cert#31 | 200 |
| sjb-api.svsnlosgistics.shop | sjb-attendant-backend-1:3030 | cert#31 | 200 |
| sv-front.svsnlosgistics.shop | svsn_frontend:80 | cert#31 | 200 |
| sv-back.svsnlosgistics.shop | svsn_backend:7005 | cert#31 | 200 |
| sv-db.svsnlosgistics.shop | svsn_mongodb:27017 | cert#31 | 200 |
| rentroom.svsnlosgistics.shop | rentroom-frontend:82 | cert#31 | 200 |
| rentroom-back.svsnlosgistics.shop | rentroom-backend:3001 | cert#31 | 404 |
| rentroom-db.svsnlosgistics.shop | rentroom-mongodb:27017 | cert#31 | 200 |
| aea-api.svsnlosgistics.shop | attendance_backend:80 | cert#31 | 404 |
| aea-db.svsnlosgistics.shop | attendance_mongodb:27017 | cert#31 | 200 |
| diabetes.svsnlosgistics.shop | diabetes-frontend:80 | cert#31 | 200 |
| diabetes-api.svsnlosgistics.shop | diabetes-api:5000 | cert#31 | 404 |
| diabetes-db.svsnlosgistics.shop | diabetes-mongodb:27017 | cert#31 | 200 |
| diabetes-db-express.svsnlosgistics.shop | diabetes-mongo-express:8081 | cert#31 | 401 |
| tavan-api.svsnlosgistics.shop | vanta_api-app-1:5051 | cert#31 | 404 |
| tavan-db.svsnlosgistics.shop | vanta_api-mongo-1:27017 | cert#31 | 200 |
| vantapolicy.svsnLosgistics.shop | policy-policy-1:5175 | cert#31 | 200 |
| port.svsnlosgistics.shop | portainer:9000 | cert#31 | 200 |
| nginx.svsnlosgistics.shop | localhost:81 | cert#31 | 200 |
| attendant.example.com | 127.0.0.1:5173 | none | dev only |
| attendant-api.example.com | 127.0.0.1:3030 | none | dev only |
| vanta-api.example.com | 127.0.0.1:5051 | none | dev only |

---

## SSL Certificates

| ID | Domain | Type | Expires | Renewal Method |
|----|--------|------|---------|----------------|
| cert#31 | *.svsnlosgistics.shop | Wildcard | 2026-06-17 | DNS-01 via Cloudflare API |
| cert#39 | svsnlosgistics.shop | Root | 2026-06-17 | HTTP-01 via webroot |

NPM auto-renews within 30 days of expiry. **Next renewal window: ~2026-05-18.**

cert#31 requires a Cloudflare API token:
```
/root/npm-letsencrypt/credentials/credentials-31
```
Verify the token is still valid before the renewal window or wildcard renewal
will fail silently.

After any manual renewal, sync certs to the snap-accessible path:
```bash
cp -rp /data/compose/1/letsencrypt/* /root/npm-letsencrypt/
docker exec nginx-proxy-manager-app-1 nginx -s reload
```

---

## NPM Volume Paths

Docker (snap) restricts bind mounts to `/root/` and `/home/`. NPM data
was originally at `/data/compose/1/` (Portainer-managed) and is now mirrored
to `/root/` where snap Docker has full traversal access.

| Purpose | Host Path | Container Path |
|---------|-----------|----------------|
| Config, DB, nginx | /root/npm-data | /data |
| SSL certs & keys | /root/npm-letsencrypt | /etc/letsencrypt |
| Original source | /data/compose/1/data | reference only |
| Original certs | /data/compose/1/letsencrypt | reference only |

**Never move `/root/npm-data` or `/root/npm-letsencrypt`** without updating
`/srv/nginx-proxy-manager/docker-compose.yml` and `scripts/redeploy-npm.sh`.

---

## Docker Networks

| Network | Subnet | Purpose |
|---------|--------|---------|
| production | 172.28.0.0/16 | Shared hub — NPM + 15 backends |
| nginx-proxy-manager_default | 172.27.0.0/16 | NPM internal |
| sjb-attendant_default | 192.168.192.0/20 | SJB frontend + backend |
| vanta_api_default | 192.168.176.0/20 | Vanta API + MongoDB |
| svlosgistics_svsn_network | 192.168.224.0/20 | SVSN internal |
| rentroom_default | 192.168.240.0/20 | Rentroom internal |

NPM connects to: `production`, `nginx-proxy-manager_default`,
`sjb-attendant_default`, `vanta_api_default`, `root_default`.

Any new backend container must join `production` before NPM can route to it:
```bash
docker network connect production <container_name>
```

---

## Backup

### Schedule & Location

| Setting | Value |
|---------|-------|
| Script | /root/backup.sh |
| Cron | `0 2 * * *` — daily at 02:00 server time |
| Log | /var/log/backup.log |
| Output | /root/backups/YYYY-MM-DD/ |
| Retention | 7 days rolling |
| Disk used | ~14 MB per day |

### What is backed up

| Item | Method | Verified size |
|------|--------|---------------|
| NPM config + nginx patches | cp -rp | ~6 MB |
| SSL certs + private keys | cp -rp | ~200 KB |
| svsn_logistics (MongoDB) | mongodump --gzip | ~500 B |
| rentroom (MongoDB) | mongodump --gzip | ~300 B |
| attendance_db (MongoDB) | mongodump --gzip | ~116 B |
| diabetes-tracker (MongoDB) | mongodump --gzip | ~821 B |
| vantapass (MongoDB) | mongodump --gzip | ~786 KB |
| All docker-compose files | cp | 8 files |
| Portainer redeploy command | docker inspect | 1 script |

### Verify last backup

```bash
tail -5 /var/log/backup.log
ls -lh /root/backups/$(date +%Y-%m-%d)/
```

### Expected log output (healthy)

```
[2026-04-29 02:00:00] Starting backup to /root/backups/2026-04-29
[2026-04-29 02:00:01] Backing up NPM data...
[2026-04-29 02:00:01] Backing up SSL certs...
[2026-04-29 02:00:01] Dumping MongoDB databases...
[2026-04-29 02:00:01]   svsn_logistics: OK
[2026-04-29 02:00:02]   rentroom: OK
[2026-04-29 02:00:02]   attendance_db: OK
[2026-04-29 02:00:02]   diabetes-tracker: OK
[2026-04-29 02:00:02]   vantapass: OK
[2026-04-29 02:00:03] Backing up compose files...
[2026-04-29 02:00:03] Cleaning up backups older than 7 days...
[2026-04-29 02:00:03] Backup complete. Size: 14M | Location: /root/backups/2026-04-29
```

Any line showing `FAILED` instead of `OK` means a MongoDB dump failed.
Common causes: container stopped, wrong credentials, disk full.

### Source code backup (GitHub)

All 7 project repos are pushed to GitHub under Vanrith785/:

| Repo | Path on server |
|------|----------------|
| SJB-Attendant | /root/SJB-Attendant |
| Vanta_api | /root/Vanta_api |
| backend-aea | /root/aea/backend-aea |
| Diabetes-Patient | /root/diabetes/Diabetes-Patient |
| policy | /root/policy |
| svlosgistics | /home/project1/svlosgistics |
| rentroom | /home/project2/rentroom |
| **server-infra** | /root/server-infra (this repo) |

---

## Deployment Procedures

### Start / restart a service

```bash
# Any service (uses compose file)
docker compose -f /path/to/docker-compose.yml restart

# NPM
docker restart nginx-proxy-manager-app-1

# Portainer
docker restart portainer
```

### View logs

```bash
docker logs --tail 50 -f <container_name>
docker logs --tail 50 -f nginx-proxy-manager-app-1
```

### Full health check

```bash
# All containers
docker ps --format "{{.Names}}: {{.Status}}" | sort

# Route spot-check (from server)
for d in svsnlosgistics.shop sjb.svsnlosgistics.shop port.svsnlosgistics.shop; do
  curl -skL --resolve "$d:443:194.163.155.11" https://$d/ \
    -o /dev/null -w "[$?/%{http_code}] $d\n"
done

# Last backup
tail -3 /var/log/backup.log

# Disk & RAM
df -h / | awk 'NR==2{print "Disk:", $3"/"$2, "("$5")"}'
free -h | awk 'NR==2{print "RAM: ", $3"/"$2}'
```

### Deploy a new service

```bash
# 1. Clone/create project
cd /home/project1 && git clone https://github.com/Vanrith785/<repo>.git

# 2. Add production network to docker-compose.yml:
#    networks:
#      production:
#        external: true
#        name: production
#    (add  networks: [production]  to each service)

# 3. Start it
docker compose -f /home/project1/<repo>/docker-compose.yml up -d

# 4. Add proxy host in NPM UI
#    https://nginx.svsnlosgistics.shop
#    Assign cert#31 for *.svsnlosgistics.shop subdomains
```

### Redeploy NPM

```bash
bash /root/server-infra/scripts/redeploy-npm.sh
```

### Redeploy Portainer

```bash
bash /root/server-infra/scripts/redeploy-portainer.sh
```

### Update a running service

```bash
# Pull latest code
git -C /path/to/project pull

# Rebuild and redeploy
docker compose -f /path/to/docker-compose.yml up -d --build
```

---

## Full Restore Procedure

### 1. Restore NPM (config + certs)

```bash
BACKUP=/root/backups/YYYY-MM-DD   # set date

cp -rp $BACKUP/npm-data /root/npm-data
cp -rp $BACKUP/npm-letsencrypt /root/npm-letsencrypt

bash /root/server-infra/scripts/redeploy-npm.sh
```

### 2. Restore a MongoDB database

```bash
BACKUP=/root/backups/YYYY-MM-DD

# Example: vantapass
docker cp $BACKUP/vantapass.archive vanta_api-mongo-1:/tmp/
docker exec vanta_api-mongo-1 mongorestore \
  --archive=/tmp/vantapass.archive --gzip --drop
docker exec vanta_api-mongo-1 rm /tmp/vantapass.archive

# Example: svsn_logistics (requires auth)
docker cp $BACKUP/svsn_logistics.archive svsn_mongodb:/tmp/
MONGO_USER=$(docker exec svsn_mongodb printenv MONGO_INITDB_ROOT_USERNAME)
MONGO_PASS=$(docker exec svsn_mongodb printenv MONGO_INITDB_ROOT_PASSWORD)
docker exec svsn_mongodb mongorestore \
  --username $MONGO_USER --password $MONGO_PASS \
  --authenticationDatabase admin \
  --archive=/tmp/svsn_logistics.archive --gzip --drop
docker exec svsn_mongodb rm /tmp/svsn_logistics.archive
```

### 3. Restore all services from scratch

```bash
# Clone all repos
for repo in SJB-Attendant Vanta_api backend-aea Diabetes-Patient policy; do
  git clone https://github.com/Vanrith785/$repo /root/$repo
done
git clone https://github.com/Vanrith785/svlosgistics /home/project1/svlosgistics
git clone https://github.com/Vanrith785/rentroom /home/project2/rentroom

# Start all services
docker compose -f /root/SJB-Attendant/docker-compose.yml up -d
docker compose -f /home/project1/svlosgistics/docker-compose.yml up -d
docker compose -f /home/project2/rentroom/docker-compose.yml up -d
docker compose -f /root/aea/backend-aea/docker-compose.yml up -d
docker compose -f /root/diabetes/Diabetes-Patient/docker-compose.yml up -d
docker compose -f /root/policy/docker-compose.yml up -d
docker compose -f /root/Vanta_api/docker-compose.yml up -d

# Restore NPM and Portainer
bash /root/server-infra/scripts/redeploy-portainer.sh
bash /root/server-infra/scripts/redeploy-npm.sh
```

---

## Known Issues & Quirks

### 1. Snap Docker bind mount restriction
Docker (snap) silently creates empty tmpfs mounts for paths outside `/root/`
or `/home/`. NPM data must live at `/root/npm-data` and `/root/npm-letsencrypt`.
Never store NPM volumes at `/data/` or system paths.

### 2. Ghost containers
If `docker ps` shows fewer containers than expected but services respond,
the Docker daemon has lost sync with containerd:
```bash
# Detect: containerd task count should match docker ps -a count
ctr -n moby tasks ls | wc -l
docker ps -a | wc -l

# Fix: remove stale state file and redeploy
rm -rf /var/lib/docker/containers/<CONTAINER_ID>/
docker compose -f /path/to/docker-compose.yml up -d
```
Data in named Docker volumes is NOT affected.

### 3. Stale iptables DNAT rules
After a ghost container is cleared, old DNAT rules may continue hijacking
ports 80/81/443 and routing traffic to a dead IP:
```bash
# Check for duplicate rules on the same port
iptables -t nat -L DOCKER -n --line-numbers | grep "dpt:443"

# Delete stale rule (use the line number of the one with the wrong IP)
iptables -t nat -D DOCKER <line_number>
```

### 4. Docker address pool exhaustion
The default Docker subnet pool has ~16 /20 slots. Creating many services
each with a new isolated network exhausts it:
```bash
# Free unused networks
docker network prune -f

# Or configure new services to use the existing 'production' network
# instead of creating their own
```

### 5. vantapolicy SSL config
`/root/npm-data/nginx/proxy_host/46.conf` was manually patched to add SSL.
cert#31 is now registered in the NPM database. If NPM ever regenerates
configs (e.g. after cert renewal), verify this route still has SSL enabled
in the NPM UI.

### 6. MongoDB routes are publicly accessible
sv-db, rentroom-db, aea-db, diabetes-db, tavan-db are proxied without
proxy-level authentication. Access relies solely on MongoDB's own auth.
Add NPM Access Lists (IP whitelist) to these routes.

---

## Security Recommendations

### CRITICAL — Do immediately

1. **Change NPM and Portainer passwords**
   Credentials were reset during recovery on 2026-04-29 and are stored in
   this README. Rotate them immediately via each service's account settings.

2. **Restrict MongoDB proxy routes**
   In NPM, add an Access List with your office/VPN IP to:
   `sv-db`, `rentroom-db`, `aea-db`, `diabetes-db`, `tavan-db`
   These should never be publicly accessible.

3. **Verify Cloudflare API token**
   `/root/npm-letsencrypt/credentials/credentials-31` must be valid before
   2026-05-18 or the wildcard cert will fail to auto-renew silently.

### HIGH — Within 1 week

4. **Enable UFW firewall**
   ```bash
   ufw allow 22/tcp
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw allow from <YOUR_IP> to any port 81    # NPM admin
   ufw allow from <YOUR_IP> to any port 9000  # Portainer
   ufw enable
   ```

5. **Disable SSH password authentication**
   ```bash
   sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' \
     /etc/ssh/sshd_config
   systemctl reload sshd
   ```
   Ensure your public key is in `/root/.ssh/authorized_keys` first.

6. **Rotate weak MongoDB passwords**
   - `rentroom-mongodb`: change `password123` in .env and compose
   - `diabetes-mongo-express`: change `admin123` in compose

7. **Disable or secure dev proxy routes**
   `attendant.example.com`, `attendant-api.example.com`, `vanta-api.example.com`
   have no SSL and point to 127.0.0.1. Delete if not in use.

### MEDIUM — Within 1 month

8. **Off-server backup storage**
   `/root/backups/` is on the same disk. A hardware failure loses both.
   Sync daily to S3, Backblaze B2, or a second server via rclone:
   ```bash
   # Add to crontab after backup.sh
   5 2 * * * rclone sync /root/backups remote:bucket/svsnlosgistics
   ```

9. **Set Cloudflare SSL to Full (strict)**
   In Cloudflare dashboard → SSL/TLS → set mode to "Full (strict)".
   Origin has valid Let's Encrypt certs so this is safe.

10. **Pin Docker image versions**
    Replace `:latest` tags with specific versions in compose files to
    ensure reproducible deploys and prevent unexpected breaking changes.

11. **Add container resource limits**
    Add to each service's compose to prevent runaway containers:
    ```yaml
    deploy:
      resources:
        limits:
          memory: 512m
          cpus: '0.5'
    ```
