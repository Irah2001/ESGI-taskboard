#!/bin/bash
set -e

PROD_DB_PASSWORD=$1
PROD_JWT_SECRET=$2

echo "1. Pull de la nouvelle image..."
docker pull ghcr.io/irah2001/esgi-taskboard/taskboard:latest

echo "2. Nettoyage de l'ancien conteneur..."
docker stop taskboard-app || true
docker rm taskboard-app || true

docker stop taskboard-db || true
docker rm taskboard-db || true

echo "3. Lancement de la base de données..."
docker run -d \
  --name taskboard-db \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD="${PROD_DB_PASSWORD}" \
  -e POSTGRES_DB=taskboard \
  postgres:14 || true

echo "4. Lancement du nouveau conteneur app..."
docker run -d \
  --name taskboard-app \
  --link taskboard-db:db \
  -p 3000:3000 \
  -e DATABASE_URL="postgres://admin:${PROD_DB_PASSWORD}@db:5432/taskboard" \
  -e JWT_SECRET="${PROD_JWT_SECRET}" \
  ghcr.io/irah2001/esgi-taskboard/taskboard:latest

echo "5. Pause pour laisser le serveur démarrer..."
sleep 5

echo "5. Healthcheck..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)

if [ "$STATUS" -eq 200 ]; then
  echo "✅ Déploiement réussi ! Healthcheck OK (200)."
  exit 0
else
  echo "❌ Échec du Healthcheck (Status: $STATUS). Annulation."
  exit 1
fi