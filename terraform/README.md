# Terraform — DigitalOcean infrastructure

This directory contains Infrastructure as Code for deploying WordPress to **DigitalOcean** (DOKS + Managed MySQL + Container Registry).

The **kind** demo in `scripts/` does not require Terraform. Use these modules when you have cloud budget and want a real dev/prod cluster.

## Active modules (used by envs)

| Module | Path | Provisions |
|---|---|---|
| DOKS | [`modules/doks`](modules/doks) | Kubernetes cluster with node pool |
| Database | [`modules/database`](modules/database) | Managed MySQL 8 cluster + DB + user |
| Registry | [`modules/registry`](modules/registry) | DigitalOcean Container Registry (dev env only) |

## Environment entry points

| Environment | Path | Notes |
|---|---|---|
| Dev | [`envs/dev`](envs/dev) | DOKS + MySQL + Registry |
| Prod | [`envs/prod`](envs/prod) | DOKS + MySQL (reuses account-wide registry from dev) |

## Legacy / reference modules (not wired)

These AWS-oriented modules are included as reference alternatives and are **not** used by `envs/dev` or `envs/prod`:

| Module | Path |
|---|---|
| EKS | [`modules/eks`](modules/eks) |
| RDS | [`modules/rds`](modules/rds) |
| Networking | [`modules/networking`](modules/networking) |

## Quick start (cloud)

```bash
cd terraform/envs/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set do_token

terraform init
terraform plan
terraform apply
```

Outputs include `database_host`, `database_password` (sensitive), and `kubernetes_cluster_name`. Use them with [`helm/wordpress/values-cloud.example.yaml`](../helm/wordpress/values-cloud.example.yaml).

## Connecting Helm to Terraform outputs

After `terraform apply`:

```bash
DB_HOST=$(terraform output -raw database_host)
kubectl create secret generic wp-prod-db-credentials \
  --from-literal=mariadb-root-password="$(openssl rand -base64 24)" \
  --from-literal=mariadb-password="$(terraform output -raw database_password)" \
  --from-literal=db-password="$(terraform output -raw database_password)"

helm upgrade --install wp-prod ../../helm/wordpress \
  -f ../../helm/wordpress/values-prod.yaml \
  -f ../../helm/wordpress/values-cloud.example.yaml \
  --set wordpress.db.host="$DB_HOST"
```

## State and secrets

- `*.tfvars` is gitignored — never commit `do_token`
- Use remote state (S3/DO Spaces + locking) for team/production use
- Terraform state contains sensitive outputs — protect accordingly
