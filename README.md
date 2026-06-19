# DevOps Task: WordPress on Kubernetes

Fault-tolerant WordPress infrastructure on Kubernetes with **local**, **dev**, and **prod** environments. Built with Helm, GitHub Actions, and Argo CD (GitOps). Runs on **kind** clusters locally ($0) with Terraform modules targeting DigitalOcean for real cloud deployment.

## Quick start (5 minutes)

### Prerequisites

- Docker Desktop
- [kind](https://kind.sigs.k8s.io/), [kubectl](https://kubernetes.io/docs/tasks/tools/), [Helm](https://helm.sh/)
- PowerShell (Windows) or Bash (Git Bash / WSL)

### 1. Local environment

```powershell
cd G:\DevOpsTask
.\scripts\local-up.ps1
```

### 2. Hosts file (run PowerShell as Administrator)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\add-hosts.ps1
```

### 3. Open in browser

| Environment | URL |
|---|---|
| Local | http://wordpress.local |
| Dev | http://dev.wordpress.local:8081 |
| Prod | http://prod.wordpress.local:8082 |

---

## Environments

| Env | Cluster | Script | Stop |
|---|---|---|---|
| **Local** | `kind-devops-wp` | `.\scripts\local-up.ps1` | `.\scripts\local-down.ps1` |
| **Dev** | `kind-wp-dev` | `.\scripts\dev-up.ps1` | `.\scripts\dev-down.ps1` |
| **Prod** | `kind-wp-prod` | `.\scripts\prod-up.ps1` | `.\scripts\prod-down.ps1` |

Switch kubectl context:

```powershell
kubectl config use-context kind-devops-wp   # local
kubectl config use-context kind-wp-dev      # dev
kubectl config use-context kind-wp-prod     # prod
```

---

## What gets deployed

| Component | Technology |
|---|---|
| WordPress | Custom Docker image (PHP themes/plugins) |
| Database | MariaDB 11 (standalone, persisted via PVC) |
| Ingress | nginx-ingress |
| Storage | RWX hostPath (`local-rwx`) for shared uploads |
| Scaling | HPA (Horizontal Pod Autoscaler) |
| Resilience | PDB (Pod Disruption Budget), multi-replica |
| GitOps | Argo CD |
| CI/CD | GitHub Actions → GHCR |

---

## CI/CD (GitHub Actions)

| Workflow | Trigger | Action |
|---|---|---|
| `ci.yml` | PR / push to `main` or `develop` | Helm lint + Docker build (+ push to GHCR) |
| `cd-dev.yml` | push to `develop` | Build image → deploy dev (self-hosted runner) |
| `cd-prod.yml` | push to `main` | Build image → deploy prod (self-hosted runner) |

### Manual deploy (no self-hosted runner)

After CI pushes the image to GHCR:

```powershell
.\scripts\deploy-dev.ps1 -Repo "ghcr.io/ppmarkek/devopstask/wordpress" -Tag "develop"
.\scripts\deploy-prod.ps1 -Repo "ghcr.io/ppmarkek/devopstask/wordpress" -Tag "main"
```

### Branch strategy

```
feature/*  →  PR  →  ci.yml (lint + build)
develop    →  cd-dev.yml (build + deploy dev)
main       →  cd-prod.yml (build + deploy prod)
```

### What is deployed automatically

| Change | Path | Mechanism |
|---|---|---|
| PHP (themes, plugins) | `wordpress/wp-content/` | New Docker image |
| WordPress config | `wordpress/config/wp-config-extra.php` | Baked into image |
| Helm settings | `helm/wordpress/values-*.yaml` | `helm upgrade` / Argo CD sync |
| Media uploads | `wp-content/uploads/` | PVC (not in image) |

---

## GitOps (Argo CD)

### Bootstrap

```powershell
# Dev cluster must be running first
.\scripts\dev-up.ps1
.\scripts\argocd-bootstrap-dev.ps1

# Prod
.\scripts\prod-up.ps1
.\scripts\argocd-bootstrap-prod.ps1
```

### Argo CD UI

```powershell
# Dev
kubectl port-forward svc/argocd-server -n argocd 9090:443 --context kind-wp-dev

# Prod
kubectl port-forward svc/argocd-server -n argocd 9091:443 --context kind-wp-prod
```

Open **https://localhost:9090** (accept self-signed certificate).  
Login: `admin` + password from bootstrap output or:

```powershell
$p = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($p))
```

### GitOps flow

```
1. Change code in wordpress/
2. git push to develop (or main)
3. CI builds image → GHCR
4. Argo CD syncs Helm chart → cluster
```

| Branch | Argo Application | Cluster |
|---|---|---|
| `develop` | `wp-dev` | `kind-wp-dev` |
| `main` | `wp-prod` | `kind-wp-prod` |

---

## Project structure

```
├── .github/workflows/     # CI/CD pipelines
├── argocd/applications/   # Argo CD Application manifests
├── docker/                # Custom WordPress Dockerfile
├── wordpress/             # PHP code, themes, plugins, config
├── helm/wordpress/        # Helm chart (one chart, env-specific values)
├── scripts/               # Cluster lifecycle scripts
├── terraform/             # DigitalOcean IaC (target cloud)
└── docs/                  # Architecture & runbook
```

---

## Documentation

- [Architecture](docs/ARCHITECTURE.md): design decisions and diagrams
- [Runbook](docs/RUNBOOK.md): operations, troubleshooting, recovery

---

## License

Test assignment project. Use freely for portfolio or interview demos.
