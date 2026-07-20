#!/bin/bash
set -euo pipefail

echo "=== 🛑 Stopping existing containers ==="
docker compose down

echo ""
echo "=== 🔄 Syncing Codebases from GitHub ==="
echo "-> Pulling main repository updates..."
git fetch origin
git reset --hard origin/main

echo "-> Updating and syncing all submodules..."
git submodule update --init --recursive --remote

echo ""
echo "=== 🔨 Building and Starting Containers ==="
docker compose up --build -d

echo ""
echo "=================================================="
echo "✅ DEPLOYMENT COMPLETE"
echo "=================================================="
echo ""
echo "  Frontend : http://localhost:3000"
echo "  Admin    : http://localhost:3001"
echo "  Backend  : http://localhost:8001"
echo "  Scraper  : http://localhost:8002"
echo ""
echo "  Tip: docker compose logs -f  to monitor all services"
echo "=================================================="
