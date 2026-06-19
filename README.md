# DevOps Task — WordPress on Kubernetes

Тестовое задание: отказоустойчивый WordPress на K8s (local / dev / prod).

## Local — быстрый старт

### 1. Поднять кластер (Git Bash или WSL)

```bash
bash scripts/local-up.sh
```

### 2. Hosts (Windows, от администратора)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\add-hosts.ps1
```

Или вручную добавь в `C:\Windows\System32\drivers\etc\hosts`:

```
127.0.0.1 wordpress.local
```

### 3. Браузер

http://wordpress.local

### Остановить

```bash
bash scripts/local-down.sh
```

## Структура проекта

```
├── .github/workflows/     # CI/CD
├── docker/                # Custom WordPress image
├── wordpress/             # PHP code, themes, plugins, config
├── helm/wordpress/        # Helm chart
├── k8s/                   # Kustomize (альтернатива Helm)
├── terraform/             # Облачная инфраструктура
├── argocd/                # GitOps applications
├── scripts/               # Локальный запуск
└── docs/                  # Документация
```
