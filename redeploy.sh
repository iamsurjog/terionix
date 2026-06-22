#!/bin/bash
set -euo pipefail

echo "=== 🛑 Stopping existing servers ==="
killall node || true
killall python || true
killall python3 || true
killall lt || true # Clear out older localtunnel allocations too

sleep 2

echo "=== 🚀 Starting Deploy Pipeline ==="
cd ~/Terionix

# 1. Launch services in background subshells
echo "-> Launching Frontend..."
sh frontend/run.sh > frontend.log 2>&1 &

echo "-> Launching Admin Panel..."
sh admin/run.sh > admin.log 2>&1 &

sleep 5

echo "-> Launching Django Backend..."
sh backend/run.sh > backend.log 2>&1 &

# ==========================================
# NEW: Localtunnel Exposure Layer
# ==========================================
echo "-> Cooling down for 5 seconds before tunnel handshake..."
sleep 5

echo "=== 🌐 Initializing Public Tunnels ==="

# Launch tunnels in the background but direct their startup info into dedicated logs
lt -p 3000 -s terionix-frontend > frontend-tunnel.log 2>&1 &
lt -p 3001 -s terionix-admin > admin-tunnel.log 2>&1 &

# Give localtunnel 3 seconds to complete the network handshake
sleep 3

echo ""
echo "=================================================="
echo "🎯 DEPLOYMENT COMPLETE — TUNNEL LINKS:"
echo "=================================================="
echo "Frontend Tunnel Output:"
cat frontend-tunnel.log
echo "--------------------------------------------------"
echo "Admin Tunnel Output:"
cat admin-tunnel.log
echo "=================================================="
echo "Tip: Run 'tail -f backend.log' to monitor runtime traffic."
