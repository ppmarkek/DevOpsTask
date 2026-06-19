# Architecture

## Cloud: DigitalOcean K8n

## Deploy: Helm

## Local (kind)

- WordPress: 2 replicas, HPA 2–5

- DB: mariadb:11 (standalone)

- Uploads: RWX hostPath (local-rwx)

- Ingress: nginx, wordpress.local

- PDB: minAvailable 1