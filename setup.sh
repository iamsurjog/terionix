#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  Terionix — local dev setup (no Docker)
# ═══════════════════════════════════════════════════════════════════════
#  This script:
#    1. Creates backend/.env from .env.example (with a random secret key)
#    2. Creates a Python virtualenv & installs backend dependencies
#    3. Runs Django migrations + seeds demo content
#    4. Installs frontend & admin npm dependencies
#    5. Makes all run.sh scripts executable
#    6. Prints the exact commands to start each service
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

# ── Banner ──────────────────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║       Terionix — Local Dev Setup                ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo ""

# ═══════════════════════════════════════════════════════════════════
#  1.  Backend .env
# ═══════════════════════════════════════════════════════════════════

ENV_SRC="$ROOT/backend/.env.example"
ENV_DST="$ROOT/backend/.env"

if [ -f "$ENV_DST" ]; then
    echo "✔  backend/.env already exists — keeping it"
else
    echo "   Creating backend/.env from .env.example …"
    # Copy and inject a random secret key so the user doesn't have to
    SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))" 2>/dev/null || \
             python  -c "import secrets; print(secrets.token_urlsafe(50))" 2>/dev/null || \
             echo "change-me-to-a-real-secret-key")
    sed "s|^DJANGO_SECRET_KEY=.*|DJANGO_SECRET_KEY=$SECRET|" "$ENV_SRC" > "$ENV_DST"
    echo "✔  backend/.env created with a random secret key"
fi

# ═══════════════════════════════════════════════════════════════════
#  2.  Python virtualenv + dependencies
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "───  Backend (Python) ────────────────────────────"

cd "$ROOT/backend"

if [ -d .venv ]; then
    echo "✔  Virtualenv already exists at backend/.venv"
else
    echo "   Creating Python virtualenv …"
    python3 -m venv .venv
    echo "✔  Virtualenv created"
fi

echo "   Installing Python dependencies …"
source .venv/bin/activate
pip install -q -r requirements.txt gunicorn
echo "✔  Python dependencies installed"

# ═══════════════════════════════════════════════════════════════════
#  3.  Django migrations + seed
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "───  Database ────────────────────────────────────"

export DJANGO_SECRET_KEY="${DJANGO_SECRET_KEY:-django-insecure-setup-key}"
export DJANGO_DEBUG=True
export FRONTEND_URLS="${FRONTEND_URLS:-http://localhost:3000,http://localhost:3001}"
export SESSION_COOKIE_SECURE=False

echo "   Running migrations …"
python manage.py migrate --noinput
echo "✔  Migrations applied"

echo "   Seeding demo content …"
python manage.py seed_content
echo "✔  Demo content seeded"

cd "$ROOT"

# ═══════════════════════════════════════════════════════════════════
#  4.  Frontend dependencies
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "───  Frontend ────────────────────────────────────"

cd "$ROOT/frontend"
if [ -d node_modules ]; then
    echo "✔  node_modules already exists"
else
    echo "   Installing frontend dependencies …"
    npm install
    echo "✔  Frontend dependencies installed"
fi

# ═══════════════════════════════════════════════════════════════════
#  5.  Admin dependencies
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "───  Admin ───────────────────────────────────────"

cd "$ROOT/admin"
if [ -d node_modules ]; then
    echo "✔  node_modules already exists"
else
    echo "   Installing admin dependencies …"
    npm install
    echo "✔  Admin dependencies installed"
fi

# ═══════════════════════════════════════════════════════════════════
#  6.  Make run scripts executable
# ═══════════════════════════════════════════════════════════════════

chmod +x "$ROOT/backend/run.sh" \
       "$ROOT/frontend/run.sh" \
       "$ROOT/admin/run.sh"

# ═══════════════════════════════════════════════════════════════════
#  7.  Done — print instructions
# ═══════════════════════════════════════════════════════════════════

cd "$ROOT"

echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   ✅  Setup complete!                           ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo ""
echo "  Open THREE separate terminals and run:"
echo ""
echo "  ────────────────────────────────────────────────────"
echo "  #1 — Backend (Django API on http://localhost:8001)"
echo "  ────────────────────────────────────────────────────"
echo "  cd $ROOT/backend"
echo "  ./run.sh"
echo ""
echo "  ────────────────────────────────────────────────────"
echo "  #2 — Frontend (TanStack Start on http://localhost:3000)"
echo "  ────────────────────────────────────────────────────"
echo "  cd $ROOT/frontend"
echo "  ./run.sh"
echo ""
echo "  ────────────────────────────────────────────────────"
echo "  #3 — Admin panel (TanStack Start on http://localhost:3001)"
echo "  ────────────────────────────────────────────────────"
echo "  cd $ROOT/admin"
echo "  ./run.sh"
echo ""
echo "  Or if you prefer running the commands directly:"
echo ""
echo "  (1) Backend:"
echo "      cd $ROOT/backend && source .venv/bin/activate && ./run.sh"
echo ""
echo "  (2) Frontend:"
echo "      cd $ROOT/frontend && npm run dev"
echo ""
echo "  (3) Admin:"
echo "      cd $ROOT/admin && npm run dev"
echo ""
echo "  ────────────────────────────────────────────────────"
echo "  Tip: Ctrl+C each server to stop it."
echo "  Run this setup again anytime to re-apply migrations or seed."
echo ""
