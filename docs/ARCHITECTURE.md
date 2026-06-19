# Architecture

## Strategy (free demo)

| Environment | Implementation | URL |
|---|---|---|
| **Local** | kind `devops-wp` | http://wordpress.local |
| **Dev** | kind `wp-dev` (simulates cloud) | http://dev.wordpress.local:8081 |
| **Prod** | kind `wp-prod` (planned) | http://prod.wordpress.local:8082 |

Terraform modules in `terraform/` target **DigitalOcean** for real cloud deployment.

## Deploy

- **Helm** — one chart, values per environment
- **CI/CD** — GitHub Actions (planned)
- **GitOps** — Argo CD (planned)

## Local (kind-devops-wp)

- WordPress: 2 replicas, HPA 2–5
- DB: mariadb:11 (standalone)
- Uploads: RWX hostPath (`local-rwx`)
- Ingress: nginx, `wordpress.local`
- PDB: minAvailable 1

## Dev (kind-wp-dev)

- Same stack as local, separate cluster
- Image tag: `dev`
- Ingress: `dev.wordpress.local` on host port 8081
- `WP_ENV=development`
