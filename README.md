# DevOps Task — WordPress on Kubernetes

Тестовое задание: отказоустойчивый WordPress на K8s (local / dev / prod).

## Local

```powershell
.\scripts\local-up.ps1
```

Браузер: http://wordpress.local

Остановить: `.\scripts\local-down.ps1`

## Dev (kind cluster `wp-dev`)

```powershell
.\scripts\dev-up.ps1
```

Браузер: http://dev.wordpress.local:8081

Остановить: `.\scripts\dev-down.ps1`

> Dev использует порт **8081**, чтобы работать параллельно с local (порт 80).

## Hosts (от администратора)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\add-hosts.ps1
```

## Prod (kind cluster `wp-prod`)

```powershell
.\scripts\prod-up.ps1
```

Браузер: http://prod.wordpress.local:8082

Остановить: `.\scripts\prod-down.ps1`

## Переключение кластеров

```powershell
kubectl config use-context kind-devops-wp   # local
kubectl config use-context kind-wp-dev      # dev
kubectl config use-context kind-wp-prod     # prod
```

## Структура проекта

```
├── .github/workflows/     # CI/CD
├── docker/                # Custom WordPress image
├── wordpress/             # PHP code, themes, plugins, config
├── helm/wordpress/        # Helm chart
├── terraform/             # IaC (DigitalOcean target)
├── argocd/                # GitOps applications
├── scripts/               # local-up, dev-up, prod-up
└── docs/                  # Документация
```
