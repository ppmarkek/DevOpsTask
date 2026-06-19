# Runbook

Operational guide for the WordPress-on-Kubernetes demo stack.

## Quick reference

| Task | Command |
|---|---|
| Start local | `.\scripts\local-up.ps1` |
| Start dev | `.\scripts\dev-up.ps1` |
| Start prod | `.\scripts\prod-up.ps1` |
| Stop local | `.\scripts\local-down.ps1` |
| Stop dev | `.\scripts\dev-down.ps1` |
| Stop prod | `.\scripts\prod-down.ps1` |
| Update hosts | `.\scripts\add-hosts.ps1` (as Administrator) |
| Bootstrap secrets | `.\scripts\bootstrap-secrets.ps1 -SecretName wp-dev-db-credentials -Context kind-wp-dev` |
| Argo CD dev UI | `kubectl port-forward svc/argocd-server -n argocd 9090:443 --context kind-wp-dev` |
| Local fallback deploy | `.\scripts\deploy-dev.ps1 -UseLocalImage` (only without Argo CD) |

---

## Starting environments

### Local

```powershell
.\scripts\local-up.ps1
# Browser: http://wordpress.local
```

### Dev

```powershell
.\scripts\dev-up.ps1
# Browser: http://dev.wordpress.local:8081
```

### Prod

```powershell
.\scripts\prod-up.ps1
# Browser: http://prod.wordpress.local:8082
```

### Hosts file

Run as **Administrator**:

```powershell
.\scripts\add-hosts.ps1
```

Adds:

```
127.0.0.1 wordpress.local
127.0.0.1 dev.wordpress.local
127.0.0.1 prod.wordpress.local
```

---

## Health checks

```powershell
# Switch context first
kubectl config use-context kind-wp-dev

kubectl get pods
kubectl get hpa
kubectl get pdb
kubectl get ingress
kubectl get pvc
```

Expected:

- All WordPress and MariaDB pods: `1/1 Running`
- HPA: shows current/target CPU and replica count
- PDB: `minAvailable` configured
- PVC `wp-dev-wordpress-uploads` (dev) or `wp-wordpress-uploads` (local): `Bound`, access mode `RWX`

Verify environment header:

```powershell
Invoke-WebRequest -Uri "http://dev.wordpress.local:8081" -UseBasicParsing | Select-Object -ExpandProperty Headers
# X-DevOps-Env: development
```

---

## Troubleshooting

### Pod stuck in `Pending`

```powershell
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

**Common causes:**

| Symptom | Cause | Fix |
|---|---|---|
| PVC Pending | Storage class missing | Run `.\scripts\install-kind-rwx.ps1` |
| PVC Terminating | Old volume still mounted | `kubectl scale deployment wp-dev-wordpress --replicas=0`, delete PVC, `helm upgrade` |
| ImagePullBackOff | Image not in kind | `kind load docker-image wordpress-devops:dev --name wp-dev` |
| ImagePullBackOff (GHCR) | Private package | Set `GHCR_TOKEN` and re-run `argocd-install.ps1`, or make GHCR package public |
| CreateContainerConfigError | DB secret missing | Run `.\scripts\bootstrap-secrets.ps1 -SecretName wp-dev-db-credentials -Context kind-wp-dev` |

### WordPress `CrashLoopBackOff`

Database not ready yet. Wait for MariaDB pod to be `Running`, then WordPress should recover.

```powershell
kubectl logs deploy/wp-dev-mariadb
kubectl logs deploy/wp-dev-wordpress
```

If MariaDB is up but WordPress readiness fails, check DB credentials Secret keys: `mariadb-root-password`, `mariadb-password`, `db-password`.

### Site not loading in browser

1. Check ingress controller:

   ```powershell
   kubectl get pods -n ingress-nginx
   ```

2. Check hosts file entries exist.

3. Use correct port:
   - Local: `:80`
   - Dev: `:8081`
   - Prod: `:8082`

4. Temporary workaround:

   ```powershell
   kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
   # http://dev.wordpress.local:8080
   ```

### Helm upgrade failed (immutable PVC)

Cannot change PVC access mode in place.

```powershell
kubectl scale deployment wp-dev-wordpress --replicas=0
kubectl delete pvc wp-dev-wordpress-uploads
helm upgrade wp-dev helm/wordpress -f helm/wordpress/values-dev.yaml
```

### HPA shows `<unknown>` CPU

Wait 1–2 minutes for metrics-server. On kind, metrics-server is included by default.

### Argo CD login fails

1. Use **HTTPS**: https://localhost:9090 (accept self-signed certificate)
2. Get password:

   ```powershell
   $p = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
   [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($p)) | Set-Clipboard
   ```

3. Enable insecure mode for HTTP access:

   ```powershell
   kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}'
   kubectl -n argocd rollout restart deployment argocd-server
   ```

### Argo CD Application `OutOfSync`

1. Open Argo CD UI → select application → **Refresh** → **Sync**
2. Check repo branch exists (`develop` / `main` pushed to GitHub)
3. Check Application logs in UI

### Image Updater not deploying new tags

1. Check Image Updater logs:

   ```powershell
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater --tail=100
   ```

2. Verify GHCR tag exists (`develop`, `dev-<sha>`, `main`, or `prod-<sha>`).

3. For private GHCR, set `GHCR_TOKEN` and re-run `argocd-install.ps1`.

4. For git write-back, configure PAT:

   ```powershell
   $env:GITHUB_TOKEN = "<pat>"
   .\scripts\argocd-configure-git-writeback.ps1 -Context kind-wp-dev
   ```

5. Check Application annotations in `argocd/applications/dev.yaml`.

### Direct helm upgrade reverted by Argo CD

Expected when Argo CD `selfHeal: true` is active. Use Git push → GHCR → Image Updater instead of `deploy-*.ps1`.

### GitHub Actions `repository name must be lowercase`

GHCR requires lowercase image paths. Image must be `ghcr.io/ppmarkek/devopstask/wordpress`, not `DevOpsTask`.

---

## Rollback

### Helm rollback (local / no Argo CD)

```powershell
kubectl config use-context kind-wp-dev
helm history wp-dev
helm rollback wp-dev <revision>
```

### Argo CD rollback

In Argo CD UI → Application → **History and Rollback** → select previous revision.

### Image rollback via Git

Revert the commit where Image Updater changed `image.tag` in `values-dev.yaml` or `values-prod.yaml`. Argo CD syncs the previous tag.

---

## Deploying a new image version

### Via CI + Image Updater (recommended)

1. Push code to `develop` or `main`
2. Wait for `cd-dev.yml` / `cd-prod.yml` to push image to GHCR
3. Image Updater detects new tag and updates Git (if write-back configured)
4. Argo CD syncs the cluster automatically

### Local image (no registry, no Argo CD)

```powershell
docker build -t wordpress-devops:dev -f docker/Dockerfile .
kind load docker-image wordpress-devops:dev --name wp-dev
.\scripts\deploy-dev.ps1 -UseLocalImage
```

---

## Verifying shared storage (RWX)

```powershell
$pods = kubectl get pods -l app.kubernetes.io/instance=wp-dev -o jsonpath='{.items[*].metadata.name}'
$p1, $p2 = $pods -split ' '
kubectl exec $p1 -- sh -c "echo test-rwx > /var/www/html/wp-content/uploads/test.txt"
kubectl exec $p2 -- cat /var/www/html/wp-content/uploads/test.txt
```

Expected output: `test-rwx`

---

## Load test (HPA demo)

```powershell
1..5000 | ForEach-Object { Invoke-WebRequest -Uri "http://dev.wordpress.local:8081" -UseBasicParsing | Out-Null }
kubectl get hpa -w
```

Watch replica count increase under CPU load.

---

## Stopping and cleanup

### Stop one environment

```powershell
.\scripts\dev-down.ps1   # deletes kind-wp-dev cluster
```

### Delete all kind clusters

```powershell
kind delete cluster --name devops-wp
kind delete cluster --name wp-dev
kind delete cluster --name wp-prod
```

### Terraform cleanup (cloud)

```powershell
cd terraform/envs/dev
terraform destroy
```

---

## Contacts and escalation

| Issue | Action |
|---|---|
| Local demo broken | Follow troubleshooting above |
| Cloud deployment | Apply `terraform/` modules on DigitalOcean |
| Security incident | Rotate DB passwords via `bootstrap-secrets.ps1 -Force`, regenerate Argo CD admin password |

---

## Backup strategy (recommended for real prod)

| Data | Method |
|---|---|
| WordPress uploads (PVC) | Velero scheduled backup |
| Database | DigitalOcean Managed Database automated backups |
| Git state | GitHub (source of truth) |
| Helm values | Versioned in Git |

> Backups are **not automated** in the kind demo. Document as future work for production.
