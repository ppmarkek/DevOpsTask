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
      (CI/CD → GHCR)   (GitOps)      (DO modules)
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
| **CI/CD** | GitHub Actions builds and publishes images to GHCR |
| **Immutable artifacts** | PHP code shipped via Docker images, not live edits on pods |
| **Configuration separation** | `values-local.yaml`, `values-dev.yaml`, `values-prod.yaml` |
| **Secrets not in Git** | DB passwords in Kubernetes Secrets; `terraform.tfvars` gitignored |
| **High availability** | Multiple replicas, HPA, PDB, health probes |
| **Shared state** | RWX volume for `wp-content/uploads` across replicas |

## Kubernetes components

### WordPress (Deployment)

- Custom image built from `docker/Dockerfile`
- Copies themes, plugins, mu-plugins, and `wp-config-extra.php`
- Environment variables from ConfigMap and Secret
- Liveness and readiness HTTP probes on `/`
- Resource requests/limits (stricter in prod)

### MariaDB (standalone Deployment)

- Official `mariadb:11` image, single replica
- Data persisted on a PersistentVolumeClaim mounted at `/var/lib/mysql`, so it survives pod restarts
- Used in local, dev, and prod kind clusters
- **Target cloud:** DigitalOcean Managed MySQL via `terraform/modules/database`

### Ingress

- nginx-ingress controller (kind-specific manifest)
- Host-based routing: `wordpress.local`, `dev.wordpress.local`, `prod.wordpress.local`

### Storage

| Layer | Local kind | Target cloud |
|---|---|---|
| Uploads | RWX hostPath (`local-rwx`) | DO Volume / S3-compatible object storage |
| Database | In-cluster MariaDB | Managed MySQL (Multi-AZ in prod) |

### Autoscaling (HPA)

| Environment | Min replicas | Max replicas | CPU target |
|---|---|---|---|
| Local | 2 | 5 | 70% |
| Dev | 2 | 5 | 70% |
| Prod | 3 | 10 | 70% |

### Resilience (PDB)

| Environment | minAvailable |
|---|---|
| Local / Dev | 1 |
| Prod | 2 |

## CI/CD pipeline

```
Developer push
      │
      ▼
┌─────────────┐     ┌──────────────┐
│  ci.yml     │────▶│ GHCR image   │
│  lint+build │     │ lowercase tag│
└─────────────┘     └──────┬───────┘
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
        cd-dev.yml                 cd-prod.yml
        (develop)                  (main)
              │                         │
              ▼                         ▼
        kind-wp-dev               kind-wp-prod
```

Image registry: `ghcr.io/ppmarkek/devopstask/wordpress` (must be lowercase).

## GitOps (Argo CD)

| Application | Branch | Values file | Cluster |
|---|---|---|---|
| `wp-dev` | `develop` | `values-dev.yaml` | `kind-wp-dev` |
| `wp-prod` | `main` | `values-prod.yaml` | `kind-wp-prod` |

Sync policy: automated prune + selfHeal.

## Terraform (target cloud)

Modules in `terraform/` provision DigitalOcean resources:

| Module | Resource |
|---|---|
| `modules/doks` | Kubernetes cluster (DOKS) |
| `modules/database` | Managed MySQL |
| `modules/registry` | Container Registry |

Environment entry points: `terraform/envs/dev/`, `terraform/envs/prod/`.

> **Note:** Terraform is included as IaC reference. kind clusters are used for the free demo; run `terraform apply` when cloud budget is available.

## Security notes

- Secrets stored in Kubernetes Secrets, not in Git
- GHCR packages should be public for kind pull, or configure `imagePullSecrets`
- Argo CD admin password in `argocd-initial-admin-secret` (rotate after first login)
- Prod has `WP_DEBUG=false`

## Future improvements

- [ ] cert-manager + Let's Encrypt for TLS in cloud
- [ ] External Secrets Operator for DB credentials
- [ ] Velero backups for PVC and manifests
- [ ] Prometheus/Grafana monitoring
- [ ] S3/Spaces for media uploads in prod (true shared object storage)
