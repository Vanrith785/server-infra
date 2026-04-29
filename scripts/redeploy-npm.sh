#!/bin/bash
# Redeploy Nginx Proxy Manager (snap Docker requires /root/ volume paths)
docker rm -f nginx-proxy-manager-app-1 2>/dev/null
docker run -d \
  --name nginx-proxy-manager-app-1 \
  --restart always \
  -p 80:80 -p 81:81 -p 443:443 \
  -e TZ="Australia/Brisbane" \
  -v /root/npm-data:/data \
  -v /root/npm-letsencrypt:/etc/letsencrypt \
  --network nginx-proxy-manager_default \
  jc21/nginx-proxy-manager:latest
for net in sjb-attendant_default vanta_api_default production root_default; do
  docker network connect $net nginx-proxy-manager-app-1 2>/dev/null
done
echo "NPM redeployed and connected to all networks."
