#!/bin/bash
set -euo pipefail

echo "=== 🛑 Stopping existing servers ==="
# Using '|| true' ensures the script keeps moving forward even if no processes were currently running
killall node || true
killall python || true
killall python3 || true

# Give the ports 2 seconds to completely clear out of memory namespaces
sleep 2

echo "=== 🚀 Starting Deploy Pipeline ==="
cd ~/Terionix

# 1. Start Frontend in the background, save logs to frontend.log
echo "-> Launching Frontend..."
sh frontend/run.sh > frontend.log 2>&1 &

# 2. Concurrently start Admin in the background, save logs to admin.log
echo "-> Launching Admin Panel..."
sh admin/run.sh > admin.log 2>&1 &

# 3. Wait 5 seconds to let node/npm compilation clear its initial heavy CPU spike 
# before starting the Python backend. This prevents phone memory choking.
sleep 5

# 4. Start Backend in the background, save logs to backend.log
echo "-> Launching Django Backend..."
sh backend/run.sh > backend.log 2>&1 &

echo "=== 🎉 Deployment script finished successfully! ==="
echo "All processes are spinning in the background."
echo "Use 'tail -f backend.log' or 'htop' to monitor them."
