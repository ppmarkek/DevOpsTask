# Architecture

## Strategy (free demo)

| Environment | Implementation | URL |
|---|---|---|
| **Local** | kind `devops-wp` | http://wordpress.local |
| **Dev** | kind `wp-dev` (simulates cloud) | http://dev.wordpress.local:8081 |
| **Prod** | kind `wp-prod` | http://prod.wordpress.local:8082 |

Terraform modules in `terraform/` target **DigitalOcean** for real cloud deployment.

## Deploy

- **Helm** — one chart, values per environment
## CI/CD

- **GitHub Actions** — build image → GHCR
- **Branches:** `develop` → dev, `main` → prod

## GitOps (Argo CD)

- **Dev:** `argocd/applications/dev.yaml` → cluster `kind-wp-dev`, branch `develop`
- **Prod:** `argocd/applications/prod.yaml` → cluster `kind-wp-prod`, branch `main`
- **Sync:** automated + selfHeal
- **Bootstrap:** `scripts/argocd-bootstrap-dev.ps1`, `argocd-bootstrap-prod.ps1`

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

## Prod (kind-wp-prod)

- 3 replicas, HPA 3–10, PDB minAvailable 2
- Image tag: `prod`
- Ingress: `prod.wordpress.local` on host port 8082
- `WP_ENV=production`, `WP_DEBUG=false`
- Higher CPU/memory limits
