# svsnlosgistics.shop — Server Infrastructure

**Server:** 194.163.155.11 (Ubuntu, 146GB disk, 7.8GB RAM)
**Docker:** Snap v29.3.1
**Last updated:** 2026-04-29

---

## Quick Reference

| Service | URL | Credentials |
|---------|-----|-------------|
| Nginx Proxy Manager | https://nginx.svsnlosgistics.shop | pichvanrith785@gmail.com / (set by admin) |
| Portainer | https://port.svsnlosgistics.shop | admin / (set by admin) |
| Direct NPM UI | http://194.163.155.11:81 | same as above |
| Direct Portainer | http://194.163.155.11:9000 | same as above |

---

## Architecture

```
Internet → Cloudflare CDN → 194.163.155.11
                                  │
                    Nginx Proxy Manager (ports 80/443)
                                  │
              ┌───────────────────┼───────────────────┐
         production          sjb-attendant_default  vanta_api_default
        (172.28.0.0)          (192.168.192.0)       (192.168.176.0)
              │                      │                     │
    15 backend containers       sjb-frontend          vanta_api-app
                                sjb-backend           vanta_api-mongo
```

All domains use Cloudflare proxy. SSL terminates at NPM.

---

## Running Services (19 containers)

| Container | Image | Compose File |
|-----------|-------|-------------|
| nginx-proxy-manager-app-1 | jc21/nginx-proxy-manager:latest | /srv/nginx-proxy-manager/docker-compose.yml |
| portainer | portainer/portainer-ce:lts | docker run (no compose) |
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

| Domain | Backend | SSL |
|--------|---------|-----|
| svsnlosgistics.shop | svsn_frontend:80 | cert#39 |
| sjb.svsnlosgistics.shop | sjb-attendant-frontend-1:5173 | cert#31 |
| sjb-api.svsnlosgistics.shop | sjb-attendant-backend-1:3030 | cert#31 |
| sv-front.svsnlosgistics.shop | svsn_frontend:80 | cert#31 |
| sv-back.svsnlosgistics.shop | svsn_backend:7005 | cert#31 |
| sv-db.svsnlosgistics.shop | svsn_mongodb:27017 | cert#31 |
| rentroom.svsnlosgistics.shop | rentroom-frontend:82 | cert#31 |
| rentroom-back.svsnlosgistics.shop | rentroom-backend:3001 | cert#31 |
| rentroom-db.svsnlosgistics.shop | rentroom-mongodb:27017 | cert#31 |
| aea-api.svsnlosgistics.shop | attendance_backend:80 | cert#31 |
| aea-db.svsnlosgistics.shop | attendance_mongodb:27017 | cert#31 |
| diabetes.svsnlosgistics.shop | diabetes-frontend:80 | cert#31 |
| diabetes-api.svsnlosgistics.shop | diabetes-api:5000 | cert#31 |
| diabetes-db.svsnlosgistics.shop | diabetes-mongodb:27017 | cert#31 |
| diabetes-db-express.svsnlosgistics.shop | diabetes-mongo-express:8081 | cert#31 |
| tavan-api.svsnlosgistics.shop | vanta_api-app-1:5051 | cert#31 |
| tavan-db.svsnlosgistics.shop | vanta_api-mongo-1:27017 | cert#31 |
| vantapolicy.svsnLosgistics.shop | policy-policy-1:5175 | cert#31 |
| port.svsnlosgistics.shop | portainer:9000 | cert#31 |
| nginx.svsnlosgistics.shop | localhost:81 | cert#31 |
| attendant.example.com | 127.0.0.1:5173 | none (dev) |
| attendant-api.example.com | 127.0.0.1:3030 | none (dev) |
| vanta-api.example.com | 127.0.0.1:5051 | none (dev) |

---

## SSL Certificates

| ID | Domain | Type | Expires | Renewal |
|----|--------|------|---------|---------|
| cert#31 | *.svsnlosgistics.shop | Wildcard | 2026-06-17 | DNS-01 via Cloudflare API |
| cert#39 | svsnlosgistics.shop | Root | 2026-06-17 | HTTP-01 via webroot |

**Important:** cert#31 renewal requires a valid Cloudflare API token at:
`/root/npm-letsencrypt/credentials/credentials-31`

NPM auto-renews within 30 days of expiry. Next renewal window: ~2026-05-18.

After any renewal, sync certs to snap-accessible path:
```bash
cp -rp /data/compose/1/letsencrypt/* /root/npm-letsencrypt/
docker exec nginx-proxy-manager-app-1 nginx -s reload
```

---

## NPM Data Paths

Docker is installed via **snap**, which restricts bind mount access.
NPM data must live under /root/ — not /data/.

| Purpose | Host Path | Container Path |
|---------|-----------|----------------|
| NPM config, DB, nginx configs | /root/npm-data | /data |
| SSL certs and keys | /root/npm-letsencrypt | /etc/letsencrypt |
| Original source (read-only ref) | /data/compose/1/data | — |
| Original certs (read-only ref) | /data/compose/1/letsencrypt | — |

---

## Docker Networks

| Network | Subnet | Members |
|---------|--------|---------|
| production | 172.28.0.0/16 | NPM + all backends except SJB and Vanta |
| nginx-proxy-manager_default | 172.27.0.0/16 | NPM only |
| sjb-attendant_default | 192.168.192.0/20 | NPM, sjb-frontend, sjb-backend |
| vanta_api_default | 192.168.176.0/20 | NPM, vanta_api-app-1, vanta_api-mongo-1 |
| svlosgistics_svsn_network | 192.168.224.0/20 | svsn_frontend, svsn_backend, svsn_mongodb |
| rentroom_default | 192.168.240.0/20 | rentroom-frontend, rentroom-backend, rentroom-mongodb |

NPM is connected to: production, nginx-proxy-manager_default,
sjb-attendant_default, vanta_api_default, root_default.

---

## Backup

**Script:** /root/backup.sh
**Schedule:** Daily 02:00 via cron (0 2 * * *)
**Log:** /var/log/backup.log
**Output:** /root/backups/YYYY-MM-DD/ (7-day rolling retention)

Each backup contains:
- npm-data/        — NPM proxy config, database, nginx patches
- npm-letsencrypt/ — SSL certs, private keys, Cloudflare credentials
- *.archive        — mongodump of all 5 MongoDB databases (gzip)
- compose/         — all docker-compose files
- portainer-redeploy.sh — exact docker run command for Portainer

GitHub repos (all up to date, 0 unpushed commits):
- https://github.com/Vanrith785/SJB-Attendant
- https://github.com/Vanrith785/Vanta_api
- https://github.com/Vanrith785/backend-aea
- https://github.com/Vanrith785/Diabetes-Patient
- https://github.com/Vanrith785/policy
- https://github.com/Vanrith785/svlosgistics
- https://github.com/Vanrith785/rentroom

---

## Common Operations

### Restart a service
```bash
docker compose -f /path/to/docker-compose.yml restart
docker restart nginx-proxy-manager-app-1   # NPM
docker restart portainer
```

### Check logs
```bash
docker logs --tail 50 <container_name>
docker logs --tail 50 nginx-proxy-manager-app-1
```

### Health check
```bash
docker ps --format "{{.Names}}: {{.Status}}" | sort
tail -3 /var/log/backup.log
```

### Add a new backend to NPM routing
```bash
# Backend must be on the production network
docker network connect production <container_name>
# Then add proxy host in NPM UI at https://nginx.svsnlosgistics.shop
# Assign cert#31 for *.svsnlosgistics.shop subdomains
```

### Redeploy Portainer
```bash
docker rm -f portainer
docker run -d --name portainer --restart always \
  -p 9000:9000 -p 8000:8000 -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  --network production \
  portainer/portainer-ce:lts
```

### Redeploy NPM
```bash
docker rm -f nginx-proxy-manager-app-1
docker run -d --name nginx-proxy-manager-app-1 --restart always \
  -p 80:80 -p 81:81 -p 443:443 \
  -e TZ="Australia/Brisbane" \
  -v /root/npm-data:/data \
  -v /root/npm-letsencrypt:/etc/letsencrypt \
  --network nginx-proxy-manager_default \
  jc21/nginx-proxy-manager:latest
for net in sjb-attendant_default vanta_api_default production root_default; do
  docker network connect $net nginx-proxy-manager-app-1
done
```

### Full restore from backup
```bash
BACKUP=/root/backups/YYYY-MM-DD
cp -rp $BACKUP/npm-data /root/npm-data
cp -rp $BACKUP/npm-letsencrypt /root/npm-letsencrypt
# Redeploy NPM (above), then restore MongoDB:
docker cp $BACKUP/<db>.archive <container>:/tmp/
docker exec <container> mongorestore --archive=/tmp/<db>.archive --gzip --drop
```

---

## Known Issues & Quirks

### 1. Snap Docker bind mount restriction
Docker (snap) can only bind-mount from /root/ or /home/.
NPM data at /data/compose/1/ is inaccessible — copies live at /root/npm-data/
and /root/npm-letsencrypt/. Never move these unless updating the compose file.

### 2. Ghost container detection
If a service is responding but missing from `docker ps`, run:
```bash
ctr -n moby tasks ls | wc -l   # should match docker ps -a count
```
Fix: remove stale state from /var/lib/docker/containers/<id>/ and redeploy.

### 3. Stale iptables DNAT rules
After container redeployments, duplicate DNAT rules can block ports 80/81/443.
Check with:
```bash
iptables -t nat -L DOCKER -n --line-numbers | grep "dpt:443"
```
Delete stale rules: `iptables -t nat -D DOCKER <line_number>`

### 4. vantapolicy nginx config
The nginx config at /root/npm-data/nginx/proxy_host/46.conf was manually
patched to add SSL. cert#31 is now registered in the NPM database (id=31).
If NPM regenerates configs, this is now handled correctly.

### 5. MongoDB exposed publicly
sv-db, rentroom-db, aea-db, diabetes-db, tavan-db are proxied via NPM
without authentication at the proxy level. Access relies solely on MongoDB's
own auth. Consider adding NPM Access Lists to these routes.

---

## Security Recommendations

### CRITICAL — Do immediately

1. **Change default passwords**
   - NPM: https://nginx.svsnlosgistics.shop → Account Settings
   - Portainer: https://port.svsnlosgistics.shop → Account Settings
   - Default credentials set during recovery are in this README — rotate now.

2. **Restrict MongoDB proxy routes**
   In NPM, add an Access List with IP whitelist or HTTP basic auth to:
   sv-db, rentroom-db, aea-db, diabetes-db, tavan-db, tavan-db
   These databases should not be publicly accessible.

3. **Verify Cloudflare API token validity**
   Check /root/npm-letsencrypt/credentials/credentials-31 is not expired.
   SSL wildcard renewal will silently fail without a valid token.

### HIGH — Do within 1 week

4. **SSH hardening**
   - Disable password authentication: set PasswordAuthentication no in /etc/ssh/sshd_config
   - Ensure only authorized public keys are in /root/.ssh/authorized_keys
   - Change SSH port from 22 to a non-standard port

5. **Set up UFW firewall**
   ```bash
   ufw allow 22/tcp       # SSH
   ufw allow 80/tcp       # HTTP (Cloudflare)
   ufw allow 443/tcp      # HTTPS (Cloudflare)
   ufw allow 81/tcp       # NPM admin (restrict to your IP)
   ufw allow 9000/tcp     # Portainer (restrict to your IP)
   ufw enable
   ```
   Better: restrict ports 81 and 9000 to specific admin IPs only.

6. **Restrict dev endpoints**
   The three example.com proxy hosts (attendant, attendant-api, vanta-api)
   have no SSL and use 127.0.0.1 as backend. Disable or delete if not needed.

7. **Rotate MongoDB default passwords**
   - svsn_mongodb: uses credentials from .env — verify they are non-default
   - rentroom-mongodb: admin/password123 — change immediately
   - diabetes-mongo-express: admin/admin123 — change immediately

### MEDIUM — Do within 1 month

8. **Move backups off-server**
   Current backups are stored locally at /root/backups/. A disk failure loses
   both data and backups. Sync to S3, Backblaze B2, or another server:
   ```bash
   # Example: rclone sync /root/backups remote:bucket/server-backups
   ```

9. **Enable Cloudflare "Under Attack" mode** for any service under abuse.
   Set SSL/TLS mode to "Full (strict)" in Cloudflare if not already set.

10. **Add container resource limits** to docker-compose files to prevent
    any single container from consuming all RAM/CPU:
    ```yaml
    deploy:
      resources:
        limits:
          memory: 512m
          cpus: '0.5'
    ```

11. **Pin Docker image versions** — several services use :latest tags.
    Replace with specific version tags to ensure reproducible deployments.
