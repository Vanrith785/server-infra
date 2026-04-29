#!/bin/bash
# Redeploy Portainer with production network
docker rm -f portainer 2>/dev/null
docker run -d \
  --name portainer \
  --restart always \
  -p 9000:9000 -p 8000:8000 -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  --network production \
  portainer/portainer-ce:lts
