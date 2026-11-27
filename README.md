# gcp-hardened-web-infra

Infrastructure and operations setup for running a containerised Python service on GCP Compute Engine (Rocky Linux 9) using Terraform, Nginx, and Cloud Monitoring.

## Overview

- Custom VPC (`10.10.0.0/24`) with Private Google Access; no public SSH (port 22 restricted to IAP range `35.235.240.0/20`).
- Shielded `e2-micro` VM on Rocky Linux 9 with a least-privilege service account (`logging.logWriter`, `monitoring.metricWriter`, `storage.objectUser` on the backup bucket only).
- Non-root multi-stage Python container bound to `127.0.0.1:8000` behind Nginx, with SELinux kept in `Enforcing` mode (`httpd_can_network_connect=1`).
- GCP Ops Agent ships Nginx access/error logs to Cloud Logging. Terraform defines a `/health` uptime check, a log-based `nginx_http_5xx_count` metric, and an email alert policy (>3 5xx responses in 60s).
- Daily `systemd` timer archives SQLite data and Nginx config to a versioned GCS bucket (30-day lifecycle). `deploy-with-rollback.sh` tags the running image as `:previous` and reverts automatically if `/health` fails after rebuild.
- GitHub Actions runs `terraform fmt -check` and `terraform validate` on changes under `terraform/`.

## Structure

```text
.
├── .github/workflows/terraform-ci.yml
├── app/
│   ├── Dockerfile
│   ├── app.py
│   ├── docker-compose.yml
│   └── requirements.txt
├── ops/
│   ├── nginx/site.conf
│   ├── ops-agent/config.yaml
│   ├── scripts/
│   │   ├── backup.sh
│   │   └── deploy-with-rollback.sh
│   └── systemd/
│       ├── web-backup.service
│       └── web-backup.timer
└── terraform/
    ├── backend.tf
    ├── compute.tf
    ├── main.tf
    ├── monitoring.tf
    ├── network.tf
    ├── outputs.tf
    ├── terraform.tfvars.example
    └── variables.tf
```

## Requirements

- GCP project with billing enabled and APIs active (`compute`, `iap`, `logging`, `monitoring`, `storage`)
- GCS bucket for Terraform remote state
- `gcloud` CLI (ADC configured) and Terraform `>= 1.6.0`

## Setup

### 1. Provision infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# fill in project_id, region, zone, and alert_email

terraform init -backend-config="bucket=<STATE_BUCKET>"
terraform plan
terraform apply
```

### 2. Connect to the VM

```bash
gcloud compute ssh rocky-web-01 --zone=<ZONE> --tunnel-through-iap
```

### 3. Deploy application and host config

Copy `app/`, `ops/nginx/site.conf`, `ops/ops-agent/config.yaml`, `ops/scripts/`, and `ops/systemd/` to the VM using `gcloud compute scp --tunnel-through-iap`, then:

1. Start the app from `/opt/web-app` with `docker compose up -d --build`.
2. Copy `site.conf` to `/etc/nginx/conf.d/app.conf`, run `setsebool -P httpd_can_network_connect 1`, and enable `nginx`.
3. Install `google-cloud-ops-agent` using `ops/ops-agent/config.yaml`.
4. Install `backup.sh` and `deploy-with-rollback.sh` to `/usr/local/bin/`, set `BACKUP_BUCKET` in `/etc/default/web-backup`, and enable `web-backup.timer`.

## Verification

```bash
# Health check and SQLite persistence
curl -i http://<EXTERNAL_IP>/health
curl -X POST http://<EXTERNAL_IP>/data \
  -H "Content-Type: application/json" \
  -d '{"note":"test"}'
curl http://<EXTERNAL_IP>/data

# Trigger 5xx alert
for i in {1..6}; do curl -s -o /dev/null -w "%{http_code}\n" http://<EXTERNAL_IP>/trigger-500; done

# Run manual backup on VM and check GCS
sudo systemctl start web-backup.service
gcloud storage ls gs://<BACKUP_BUCKET>/snapshots/
```

## Teardown

```bash
cd terraform
terraform destroy
```
