#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/web-app"
IMAGE="gcp-hardened-web"
HEALTH_URL="http://127.0.0.1:8000/health"

cd "$APP_DIR"

if docker image inspect "${IMAGE}:latest" >/dev/null 2>&1; then
  docker tag "${IMAGE}:latest" "${IMAGE}:previous"
fi

echo "Building and deploying new container..."
docker compose up -d --build

for i in $(seq 1 10); do
  if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
    echo "Health check passed."
    exit 0
  fi
  sleep 2
done

echo "Health check failed — rolling back to ${IMAGE}:previous..."
docker tag "${IMAGE}:previous" "${IMAGE}:latest"
docker compose up -d --no-build

if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
  echo "Rollback succeeded; service is healthy."
  exit 1
else
  echo "CRITICAL: Rollback health check also failed." >&2
  exit 2
fi
