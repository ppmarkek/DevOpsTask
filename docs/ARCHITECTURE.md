# Architecture

## Overview

This project implements a **fault-tolerant WordPress** stack on Kubernetes with three isolated environments. For the demo, all environments run on **kind** (Kubernetes in Docker) at **$0 cost**. Terraform modules in `terraform/` describe the **target production infrastructure** on DigitalOcean.

## High-level diagram

```
                    ┌─────────────────┐
                    │   GitHub Repo   │
                    │  develop / main │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
      GitHub Actions    Argo CD       Terraform
      (CI → GHCR)    + Image Updater  (DO modules)
              │              │
              ▼              ▼
     ┌────────────────────────────────────┐
     │         kind clusters (local)       │
     ├──────────┬───────────┬─────────────┤
     │  local   │   dev     │    prod     │
     │devops-wp │  wp-dev    │  wp-prod    │
     └──────────┴───────────┴─────────────┘
              │              │              │
         WordPress       WordPress       WordPress
         2 rep + HPA     2 rep + HPA     3 rep + HPA
         MariaDB         MariaDB         MariaDB
         RWX uploads     RWX uploads     RWX uploads
```

## CD pipeline (Image Updater)

```
Developer push (develop/main)
        │
        ▼
  cd-dev.yml / cd-prod.yml
        │
        ▼
   GHCR image (develop/main + sha tag)
        │
        ▼
 Argo CD Image Updater (watch GHCR)
        │
        ├── git write-back → values-dev.yaml / values-prod.yaml
        │
        ▼
   Argo CD sync → kind cluster
```

No GitHub Actions job touches the cluster directly. This removes the previous conflict between push-deploy (`helm upgrade`) and Argo CD `selfHeal`.

## Environments

| Environment | Cluster | Purpose | URL |
|---|---|---|---|
| **Local** | `kind-devops-wp` | Developer workstation | http://wordpress.local |
| **Dev** | `kind-wp-dev` | Cloud dev simulation | http://dev.wordpress.local:8081 |
| **Prod** | `kind-wp-prod` | Production simulation | http://prod.wordpress.local:8082 |

Each environment uses a **separate kind cluster** with its own ingress port mapping to avoid conflicts on localhost.

## Design principles (DevOps)

| Principle | Implementation |
|---|---|
| **Infrastructure as Code** | Helm chart, Terraform modules, Argo CD manifests |
| **GitOps** | Argo CD syncs cluster state from Git |
| **Continuous Delivery** | Image Updater watches GHCR, writes tag to Git |
| **CI/CD separation** | GitHub Actions builds/pushes only; cluster pull-based deploy |
| **Immutable artifacts** | PHP code shipped via Docker images, not live edits on pods |
| **Configuration separation** | `values-local.yaml`, `values-dev.yaml`, `values-prod.yaml` |
| **Secrets not in Git** | DB credentials in cluster Secrets via `bootstrap-secrets.ps1` |
| **High availability** | Multiple replicas, HPA, PDB, differentiated health probes |
| **Shared state** | RWX volume for `wp-content/uploads` across replicas |

## Kubernetes components

### WordPress (Deployment)

- Custom image built from `docker/Dockerfile`
- Copies themes, plugins, mu-plugins, and `wp-config-extra.php`
- Environment variables from ConfigMap and Secret
- **startupProbe** on `/` — allows slow WordPress boot
- **readinessProbe** on `/` — full app + DB check; removes pod from Service
- **livenessProbe** on `/wp-includes/images/blank.gif` — Apache only; avoids restart loops when DB is down
- Resource requests/limits (stricter in prod)
- Optional `imagePullSecrets` for private GHCR

### MariaDB (standalone Deployment)

- Official `mariadb:11` image, single replica
- Data persisted on PVC at `/var/lib/mysql`
- Credentials from pre-created Secret (`existingSecret`) in dev/prod
- startupProbe + readiness/liveness via `mariadb-admin ping`
- **Target cloud:** DigitalOcean Managed MySQL via `terraform/modules/database`

### Ingress

- nginx-ingress controller (kind-specific manifest)
- Host-based routing: `wordpress.local`, `dev.wordpress.local`, `prod.wordpress.local`

### Storage

| Layer | Local kind | Target cloud |
|---|---|---|
| Uploads | RWX hostPath (`local-rwx`) | DO Spaces / NFS / object storage |
| Database | In-cluster MariaDB | Managed MySQL (Multi-AZ in prod) |

### Autoscaling (HPA)

| Environment | Min replicas | Max replicas | CPU target |
|---|---|---|---|
| Local | 2 | 5 | 70% |
| Dev | 2 | 5 | 70% |
| Prod | 3 | 10 | 70% |

When HPA is enabled, Deployment initial replicas = `minReplicas` (HPA owns scaling).

### Resilience (PDB)

| Environment | minAvailable |
|---|---|
| Local / Dev | 1 |
| Prod | 2 |

## GitOps (Argo CD + Image Updater)

| Application | Branch | Values file | Cluster | Tag filter |
|---|---|---|---|---|
| `wp-dev` | `develop` | `values-dev.yaml` | `kind-wp-dev` | `develop`, `dev-*` |
| `wp-prod` | `main` | `values-prod.yaml` | `kind-wp-prod` | `main`, `prod-*` |

Sync policy: automated prune + selfHeal.

Image Updater annotations on Application manifests configure GHCR watch + helm values git write-back.

## Terraform (target cloud)

Modules in `terraform/` provision DigitalOcean resources:

| Module | Resource | Status |
|---|---|---|
| `modules/doks` | Kubernetes cluster (DOKS) | Active |
| `modules/database` | Managed MySQL | Active |
| `modules/registry` | Container Registry | Active (dev env) |
| `modules/eks` | AWS EKS | Legacy reference |
| `modules/rds` | AWS RDS | Legacy reference |
| `modules/networking` | AWS VPC | Legacy reference |

Environment entry points: `terraform/envs/dev/`, `terraform/envs/prod/`.

See [`helm/wordpress/values-cloud.example.yaml`](../helm/wordpress/values-cloud.example.yaml) for cloud Helm overrides (external DB, no in-cluster MariaDB).

> **Note:** Terraform is included as IaC reference. kind clusters are used for the free demo; run `terraform apply` when cloud budget is available.

## Security notes

- DB passwords created by `bootstrap-secrets.ps1`, stored in Kubernetes Secrets
- Dev/prod values reference `existingSecret`; no credentials in Git
- GHCR packages should be public for kind pull, or configure `imagePullSecrets` + `GHCR_TOKEN` in bootstrap
- Argo CD admin password in `argocd-initial-admin-secret` (rotate after first login)
- Image Updater git write-back requires GitHub PAT with repo write scope
- Prod has `WP_DEBUG=false`

## Future improvements

- [ ] cert-manager + Let's Encrypt for TLS in cloud
- [ ] External Secrets Operator for DB credentials in cloud
- [ ] Velero backups for PVC and manifests
- [ ] Prometheus/Grafana monitoring
- [ ] S3/Spaces for media uploads in prod (true shared object storage)
