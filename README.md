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
| `cd-dev.yml` | push `develop` | Build → push `ghcr.io/.../wordpress:develop` → deploy dev |
| `cd-prod.yml` | push `main` | Build → push `ghcr.io/.../wordpress:main` → deploy prod (approval) |

### What gets deployed automatically

| Change | Path | How |
|---|---|---|
| PHP (themes, plugins) | `wordpress/wp-content/` | New Docker image |
| WordPress config | `wordpress/config/wp-config-extra.php` | New Docker image |
| Helm settings | `helm/wordpress/values-*.yaml` | `helm upgrade` |
| Media uploads | `wp-content/uploads/` | PVC (not in image) |

### Setup GitHub

1. Push repo to GitHub
2. Settings → Actions → General → **Read and write permissions** for `GITHUB_TOKEN`
3. Settings → Actions → General → Workflow permissions: allow package publish
4. Make package public: Profile → Packages → wordpress → Package settings → Public
5. (Optional) Settings → Environments → create `production` with **Required reviewers**

### Branch strategy

```
feature/* → PR → ci.yml
develop   → cd-dev.yml (deploy dev)
main      → cd-prod.yml (deploy prod)
```

### Deploy without self-hosted runner (local fallback)

CI builds image on GitHub. Deploy manually:

```powershell
# After CI pushed image to GHCR:
.\scripts\deploy-dev.ps1 -Repo "ghcr.io/YOUR_USER/DevOpsTask/wordpress" -Tag "develop"
.\scripts\deploy-prod.ps1 -Repo "ghcr.io/YOUR_USER/DevOpsTask/wordpress" -Tag "main"
```

### Full auto-deploy (self-hosted runner)

GitHub-hosted runners cannot reach local kind. For automatic deploy:

1. GitHub → Settings → Actions → Runners → New self-hosted runner (Windows)
2. Install runner on your PC (same machine as kind)
3. `cd-dev.yml` / `cd-prod.yml` deploy jobs will run on it

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
