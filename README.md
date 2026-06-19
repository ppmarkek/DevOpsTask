# DevOps Task — WordPress on Kubernetes

Тестовое задание: отказоустойчивый WordPress на K8s (local / dev / prod).

## Environments

| Env | Script | URL |
|---|---|---|
| Local | `.\scripts\local-up.ps1` | http://wordpress.local |
| Dev | `.\scripts\dev-up.ps1` | http://dev.wordpress.local:8081 |
| Prod | `.\scripts\prod-up.ps1` | http://prod.wordpress.local:8082 |

Hosts (Administrator): `.\scripts\add-hosts.ps1`

## CI/CD (GitHub Actions)

### Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| `ci.yml` | PR / push | Helm lint + Docker build (+ push to GHCR on push) |
| `cd-dev.yml` | push `develop` | Build → push image → deploy dev (self-hosted) |
| `cd-prod.yml` | push `main` | Build → push image → deploy prod (self-hosted) |

### Deploy manually (no self-hosted runner)

```powershell
.\scripts\deploy-dev.ps1 -Repo "ghcr.io/ppmarkek/devopstask/wordpress" -Tag "develop"
.\scripts\deploy-prod.ps1 -Repo "ghcr.io/ppmarkek/devopstask/wordpress" -Tag "main"
```

## GitOps (Argo CD) — Step 6

Argo CD watches Git and syncs Helm chart to the cluster.

### Bootstrap

```powershell
# Dev cluster must be running: .\scripts\dev-up.ps1
.\scripts\argocd-bootstrap-dev.ps1

# Prod cluster: .\scripts\prod-up.ps1
.\scripts\argocd-bootstrap-prod.ps1
```

### Argo CD UI

```powershell
# Dev (terminal 1)
kubectl port-forward svc/argocd-server -n argocd 9090:443 --context kind-wp-dev

# Prod (terminal 2)
kubectl port-forward svc/argocd-server -n argocd 9091:443 --context kind-wp-prod
```

Open https://localhost:9090 — login `admin` + password from bootstrap output.

### GitOps flow

```
1. Change code in wordpress/
2. git push develop (or main)
3. CI builds image → GHCR
4. Argo CD detects Git/Helm changes → syncs cluster
```

| Branch | Argo Application | Cluster |
|---|---|---|
| `develop` | `wp-dev` | kind-wp-dev |
| `main` | `wp-prod` | kind-wp-prod |

## Project structure

```
├── .github/workflows/   # CI/CD
├── docker/              # WordPress image
├── wordpress/           # PHP code + config
├── helm/wordpress/      # Helm chart
├── scripts/             # up/down/deploy scripts
├── terraform/           # DO IaC (target cloud)
└── docs/                # Architecture, runbook
```
