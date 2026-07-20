# Terionix

> **E-Waste Management Platform** — End-to-end website, admin panel, and government tender scraper for Terionix, a TNPCB-authorized e-waste recycling company based in Tamil Nadu, India.

**Tagline:** _"Where Circuits Bloom"_

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Services](#services)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Local Development (No Docker)](#local-development-no-docker)
  - [Docker Deployment](#docker-deployment)
  - [Production Redeployment](#production-redeployment)
- [API Reference](#api-reference)
- [Content Management System](#content-management-system)
- [Authentication](#authentication)
- [Scraper System](#scraper-system)
- [Frontend Pages & Components](#frontend-pages--components)
- [Styling & Theming](#styling--theming)
- [Environment Variables](#environment-variables)
- [Database](#database)

---

## Overview

Terionix is a multi-service platform for an e-waste management company. It provides:

- A **public-facing website** with pages for solutions, innovation, impact reporting, careers, contact forms, an interactive recycling game with leaderboard, and an e-waste impact calculator.
- An **admin panel** for managing website content, viewing/contacting form submissions, exporting data, and configuring email digest settings.
- A **government tender scraper** that automatically fetches active e-waste tenders from India's eProcure portal (`eprocure.gov.in`) using headless Chromium (Playwright).
- A **Django REST API backend** that serves content, handles submissions, manages authentication, and stores scraped tender data.

The platform is TNPCB/CPCB authorized and is designed for corporate clients, researchers, and individual users who need responsible e-waste disposal.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Docker Compose                            │
│                                                                  │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────────┐  │
│  │   Frontend   │   │    Admin     │   │     Scraper API      │  │
│  │  :3000       │   │  :3001       │   │     :8002            │  │
│  │  TanStack    │   │  TanStack    │   │     FastAPI +        │  │
│  │  Start (SSR) │   │  Start (SSR) │   │     Playwright       │  │
│  └──────┬───────┘   └──────┬───────┘   └──────────┬───────────┘  │
│         │                  │                       │              │
│         │    /api/**       │      /api/**          │  callback    │
│         └─────────┐        └───────┐               │              │
│                   ▼                ▼                │              │
│              ┌──────────────────────────┐          │              │
│              │      Backend (Django)    │◄─────────┘              │
│              │      :8001               │                         │
│              │      REST API + SQLite    │                         │
│              └──────────────────────────┘                         │
└──────────────────────────────────────────────────────────────────┘
```

**Data flow:**
1. **Frontend** and **Admin** both proxy `/api/**` requests to the **Backend**.
2. **Backend** serves content, handles auth, stores submissions, and manages tender data.
3. **Admin** can trigger a **Scraper** run via the backend, which calls the scraper API asynchronously.
4. **Scraper** scrapes government tenders and POSTs results back to the backend's `/api/scraper/callback`.
5. Content is stored as JSON blobs in the `ContentSection` model — the admin panel edits these directly.

---

## Services

| Service | Port | Framework | Purpose |
|---------|------|-----------|---------|
| **Backend** | 8001 | Django 6.0 + DRF | REST API, auth, content storage, submissions, email |
| **Frontend** | 3000 | TanStack Start (React 19) | Public website with SSR |
| **Admin** | 3001 | TanStack Start (React 19) | Content management, submission viewer |
| **Scraper** | 8002 | FastAPI + Playwright | Government tender scraping |

---

## Tech Stack

### Backend
- **Python 3.12** / **Django 6.0.6**
- **Django REST Framework 3.17** — API viewsets, serializers, pagination
- **django-cors-headers** — CORS configuration for frontend/admin origins
- **django-filter** — Query parameter filtering on submission endpoints
- **httpx** — HTTP client for calling the scraper API
- **SQLite** — Database (stored at `backend/data/db.sqlite3`)
- **Gunicorn** — Production WSGI server (4 workers)

### Frontend & Admin
- **React 19** with **TypeScript 6**
- **TanStack Start** — Full-stack React framework with SSR (Nitro server adapter)
- **TanStack Router** — File-based routing (`src/routes/`)
- **Vite 8** — Build tool
- **Tailwind CSS 4** — Styling with `@tailwindcss/vite` plugin
- **tailwindcss-motion** — Animation utilities (slide-up, pop, fade, bounce, etc.)
- **GSAP** — Advanced animations (hero text stagger reveal)
- **Lucide React** — Icon library

### Scraper
- **Python 3.12** / **FastAPI** — Lightweight API server
- **Playwright** — Headless Chromium browser automation
- **BeautifulSoup 4** — HTML parsing of scraped tender tables
- **httpx** — HTTP client for callback to backend

### DevOps
- **Docker** / **Docker Compose** — Containerized deployment
- **Localtunnel** — Public tunnel exposure (in `redeploy.sh`) for testing purposes
- **Git Submodules** — Each service is a separate repository

---

## Project Structure

```
Terionix/
├── backend/                  # Django REST API (git submodule)
│   ├── api/                  # Main Django app
│   │   ├── models.py         # ContentSection, ContactSubmission, LeaderboardEntry, GameItem, EmailConfig, Tender
│   │   ├── views.py          # API viewsets, auth views, health check
│   │   ├── tender_views.py   # Tender CRUD, scraper refresh/status/callback
│   │   ├── serializers.py    # DRF serializers
│   │   ├── urls.py           # API route definitions
│   │   ├── auth.py           # Custom session authentication
│   │   └── migrations/       # Database migrations
│   ├── config/               # Django project settings
│   │   ├── settings.py       # Main settings (CORS, auth, DB, email)
│   │   └── urls.py           # Root URL config (/api/ → api.urls)
│   ├── content.json          # Seed data for content sections
│   ├── manage.py             # Django management CLI
│   ├── requirements.txt      # Python dependencies
│   ├── run.sh                # Dev server launcher
│   └── Dockerfile            # Production container
│
├── frontend/                 # Public website (git submodule)
│   ├── src/
│   │   ├── routes/           # File-based routes (TanStack Router)
│   │   │   ├── __root.tsx    # Root layout (HTML shell, SEO, particle field, cursor glow)
│   │   │   ├── index.tsx     # Homepage (hero, trust stats, game, impact calculator)
│   │   │   ├── solutions.tsx # Service offerings page
│   │   │   ├── innovation.tsx# R&D and circular economy
│   │   │   ├── impact-insights.tsx # Sustainability metrics, e-waste facts
│   │   │   ├── learn/        # Educational course modules
│   │   │   ├── about.tsx     # Company info
│   │   │   ├── history.tsx   # Company timeline
│   │   │   ├── careers.tsx   # Job listings
│   │   │   └── contact.tsx   # Contact/quote/career forms
│   │   ├── components/       # Reusable UI components
│   │   │   ├── Navbar.tsx
│   │   │   ├── RecyclingGame.tsx  # Gamified recycling challenge + leaderboard
│   │   │   ├── ImpactCalculator.tsx # CO₂ impact calculator
│   │   │   ├── ProcessVisualizer.tsx # Animated recycling process
│   │   │   ├── ParticleField.tsx    # Background particle animation
│   │   │   ├── CursorGlow.tsx       # Custom cursor effect
│   │   │   ├── CourseLayout.tsx     # Learn module layout
│   │   │   ├── AdminSection.tsx     # Admin content editor
│   │   │   └── AdminNavbar.tsx      # Admin navigation
│   │   ├── lib/
│   │   │   ├── content.ts    # API client for content CRUD + auth helpers
│   │   │   ├── auth.ts       # Login/logout/session management
│   │   │   └── browser.ts    # Browser detection (Safari, reduced motion)
│   │   └── styles.css        # Global styles, theme variables, animations
│   ├── vite.config.ts        # Vite + TanStack Start + Tailwind + Nitro config
│   ├── package.json          # Dependencies
│   └── Dockerfile            # Multi-stage production build
│
├── admin/                    # Admin panel (git submodule)
│   ├── src/                  # Admin routes & components
│   ├── server/               # Server-side routes (health check, proxy)
│   └── Dockerfile
│
├── scraper/                  # Tender scraper (git submodule)
│   ├── main.py               # FastAPI app (POST /scrape, GET /status)
│   ├── scraper.py            # Playwright scraping logic for eprocure.gov.in
│   ├── requirements.txt      # beautifulsoup4, playwright
│   ├── requirements-fastapi.txt # fastapi, uvicorn, httpx
│   ├── .env.example          # BACKEND_CALLBACK_URL config
│   ├── run.sh                # Dev server launcher
│   └── Dockerfile            # Production container with Chromium deps
│
├── docker-compose.yml        # Full stack orchestration
├── setup.sh                  # Local dev setup (venvs, deps, migrations, seed)
├── redeploy.sh               # Production redeploy (git pull, restart, localtunnel)
├── redeploy_docker.sh        # Docker-based redeploy (down, build, up)
├── .gitmodules               # Submodule definitions
└── README.md                 # This file
```

---

## Getting Started

### Prerequisites

- **Python 3.12+**
- **Node.js 22+**
- **Git** (with submodule support)

### Local Development (No Docker)

Run the one-command setup script:

```bash
./setup.sh
```

This will:
1. Create `backend/.env` with a random Django secret key
2. Set up Python virtual environments for backend and scraper
3. Install all dependencies (pip, npm)
4. Run Django migrations and seed demo content
5. Install Playwright Chromium browser
6. Make all `run.sh` scripts executable

Then start all 4 services in separate terminals:

```bash
# Terminal 1 — Backend (Django API on http://localhost:8001)
cd backend && ./run.sh

# Terminal 2 — Frontend (TanStack Start on http://localhost:3000)
cd frontend && ./run.sh

# Terminal 3 — Admin panel (TanStack Start on http://localhost:3001)
cd admin && ./run.sh

# Terminal 4 — Scraper API (FastAPI on http://localhost:8002)
cd scraper && ./run.sh
```

### Docker Deployment

```bash
docker compose up --build
```

This starts all 4 services with proper networking. The frontend proxies `/api/**` to the backend automatically.

**Docker build notes:**
- Backend runs `migrate` + `seed_content` on container start, then launches Gunicorn with 4 workers.
- Frontend/Admin do a multi-stage build (npm install → build → run `.output/server/index.mjs`).
- Scraper installs Playwright Chromium with all required system libraries.

### Production Redeployment

**Option A — Local (no Docker):**

```bash
./redeploy.sh
```

This script:
1. Stops all running servers (node, python, localtunnel)
2. Pulls latest code from GitHub (including all submodules)
3. Restarts all 4 services in the background
4. Exposes Frontend and Admin via Localtunnel (`terionix-frontend`, `terionix-admin`)

**Option B — Docker:**

```bash
./redeploy_docker.sh
```

This script:
1. Runs `docker compose down` to stop all containers
2. Pulls latest code from GitHub (including all submodules)
3. Runs `docker compose up --build -d` to rebuild images and start everything detached

Use this when running the stack via Docker Compose instead of bare metal.

---

## API Reference

All endpoints are prefixed with `/api/`.

### Content

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/content` | No | Returns all content sections as a JSON tree |
| `GET` | `/api/content/{section_key}` | No | Returns a single content section |
| `PATCH` | `/api/content/{section_key}` | Yes | Updates a content section's `data` field |

### Authentication

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/auth/login` | No | Login with username/password (returns CSRF token) |
| `POST` | `/api/auth/logout` | Yes | Destroy session |
| `GET` | `/api/auth/session` | No | Check current session status |
| `POST` | `/api/auth/change-password` | Yes | Change password (min 4 chars) |

### Contact Forms

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/api/contact/{type}` | No | Submit a contact form (`general`, `career`, or `quote`) |
| `GET` | `/api/submissions` | Yes | List all submissions (paginated, filterable) |
| `GET` | `/api/submissions/export/csv` | Yes | Export submissions as CSV |
| `GET` | `/api/submissions/export/json` | Yes | Export submissions as JSON |
| `POST` | `/api/submissions/send-email` | Yes | Email submissions as HTML digest |

### Leaderboard & Game

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/leaderboard` | No | Get leaderboard scores (sorted by time) |
| `POST` | `/api/leaderboard` | No | Submit a score (name + time) |
| `GET` | `/api/game-items` | No | Get recyclable/non-recyclable items for the game |

### Tenders

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/tenders` | Yes | List scraped tenders (searchable via `?q=`) |
| `POST` | `/api/tenders/refresh` | Yes | Trigger a new scrape job |
| `GET` | `/api/tenders/scrape-status?job_id=` | Yes | Check scrape job status |
| `POST` | `/api/scraper/callback` | No | Scraper posts results here (internal) |

### Email Config

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/email-config` | Yes | Get email SMTP configuration |
| `POST` | `/api/email-config` | Yes | Update email configuration (upsert singleton) |

### Health

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `GET` | `/api/checkhealth` | No | Returns `{"status": "ok", "service": "backend"}` |

---

## Content Management System

The website is **content-driven** — all page text, navigation, stats, and configuration are stored as JSON in the `ContentSection` database model. The admin panel provides a UI to edit these sections.

**How it works:**
1. On first run, `manage.py seed_content` loads `backend/content.json` into the database as `ContentSection` records, each keyed by `section_key` (e.g., `home`, `solutions`, `innovation`, `about`, `careers`, `contact`, `game`, `learn`, etc.).
2. The frontend fetches all content via `GET /api/content` (returns `{section_key: data}` for all sections).
3. Each route's `loader` calls `readContent()` from `src/lib/content.ts` and passes the data to its component.
4. The admin panel allows authenticated users to edit any section's JSON data via `PATCH /api/content/{section_key}`.

**Content sections include:** `site`, `navbar`, `home`, `solutions`, `innovation`, `impactInsights`, `about`, `history`, `careers`, `contact`, `game`, `leaderboard`, `social`, `learn` (with sub-keys for each course module).

---

## Authentication

- **Session-based** authentication using Django's built-in session framework.
- Login sends `POST /api/auth/login` with `{username, password}` — on success, Django sets a session cookie.
- Admin panel checks `GET /api/auth/session` to verify authentication status.
- Auth state is also cached in `localStorage` (`terionix_admin` key) for UX purposes.
- CSRF protection is active — all non-GET requests include `X-CSRFToken` header.
- Default admin credentials are set during Django's `createsuperuser` or via the seed data.
- Password change requires current password verification and minimum 4-character new password.

---

## Scraper System

The scraper fetches active government e-waste tenders from **India's eProcure portal** (`eprocure.gov.in`).

**Flow:**
1. Admin triggers refresh → `POST /api/tenders/refresh` → backend calls `POST http://scraper:8002/scrape` with a job ID.
2. Scraper launches a headless Chromium browser via Playwright, navigates to the eProcure tender listing page.
3. It iterates over all organization links, opens each in a new tab, extracts tender rows from the HTML table using BeautifulSoup.
4. On completion, scraper POSTs the collected tenders to `BACKEND_CALLBACK_URL` (`/api/scraper/callback`).
5. Backend replaces all existing tenders with the new data (full refresh, not incremental).
6. Admin can check status via `GET /api/tenders/scrape-status?job_id=...`.

**Scrape timeout:** 30 minutes (hardcoded in `main.py`). Jobs that exceed this are marked as failed.

**Scraper state machine:** `idle → running → completed|failed`

---

## Frontend Pages & Components

### Routes

| Route | Page | Description |
|-------|------|-------------|
| `/` | Homepage | Hero section, trust stats, corporate features, why Terionix, impact calculator, recycling game |
| `/solutions` | Solutions | Service offerings (collection, data destruction, EPR, material recovery, compliance) |
| `/innovation` | Innovation | R&D labs, future technologies, circular economy models |
| `/impact-insights` | Impact & Insights | Sustainability metrics, e-waste facts, resources/reports |
| `/learn` | Learn Dashboard | E-Waste Recycling 101 course overview |
| `/learn/$moduleId` | Learn Module | Individual course module (6 modules, ~40 min total) |
| `/about` | About Us | Company info, mission, certifications (TNPCB, CPCB, ISO 14001) |
| `/history` | History | Company timeline |
| `/careers` | Careers | Job categories and listings (8 categories, 30+ roles) |
| `/contact` | Contact | Tabbed form: General Inquiry, Career Application, Request a Quote |

### Key Components

| Component | File | Purpose |
|-----------|------|---------|
| `RecyclingGame` | `RecyclingGame.tsx` | Gamified recycling challenge — sort 10 items, beat the clock, submit score to leaderboard |
| `Leaderboard` | `RecyclingGame.tsx` | Top 10 fastest times with medal icons |
| `ImpactCalculator` | `ImpactCalculator.tsx` | Select devices/quantities → calculate CO₂ prevented |
| `ProcessVisualizer` | `ProcessVisualizer.tsx` | Animated step-by-step recycling process visualization |
| `Navbar` | `Navbar.tsx` | Responsive navigation with dropdown menus |
| `ParticleField` | `ParticleField.tsx` | Ambient background particle animation |
| `CursorGlow` | `CursorGlow.tsx` | Custom cursor with glow effect (hidden on Safari/touch devices) |
| `CourseLayout` | `CourseLayout.tsx` | Layout for learn modules with progress tracking |
| `AdminSection` | `AdminSection.tsx` | JSON editor for content management |
| `AdminNavbar` | `AdminNavbar.tsx` | Admin panel navigation |

---

## Styling & Theming

The project uses **Tailwind CSS 4** with a custom theme defined in `src/styles.css`:

**Color palette — "Morning Emerald":**
- **Primary:** Emerald Green (`#059669`) — main brand color
- **Secondary:** Teal (`#0d9488`) — accent for badges, gradients
- **Accent:** Amber (`#d97706`) — CTAs, highlights
- **Background:** Light slate (`#f8fafc`)
- **Text:** Dark slate (`#0f172a`)

**Typography:**
- **Headings:** Exo 2 (via `font-title`)
- **Body:** Montserrat (via `font-sans`)
- **Poetry/Learn:** Cormorant Garamond (via `font-poem`)

**Animation system:**
- `tailwindcss-motion` plugin provides preset animations: `motion-preset-slide-up`, `motion-preset-pop`, `motion-preset-fade`, `motion-preset-bounce`, `motion-preset-float`, `motion-preset-pulse`, `motion-preset-wobble`
- Custom CSS animations: aurora waves, fireflies, glitch text, circuit trace, shimmer, data streams
- GSAP used for hero heading word-by-word stagger reveal
- **Accessibility:** All animations disabled when `prefers-reduced-motion: reduce` is active
- **Safari:** Extensive performance overrides (reduced blur, disabled expensive animations, native cursor)

**Custom utilities:**
- `text-gradient` — Tri-color gradient text (primary → secondary → accent)
- `text-gradient-green` — Green gradient text
- `card-hover` — Lift + shadow on hover
- `section-divider` — Gradient horizontal rule

---

## Environment Variables

### Backend (`backend/.env`)

| Variable | Default | Description |
|----------|---------|-------------|
| `DJANGO_SECRET_KEY` | (generated) | Django secret key |
| `DJANGO_DEBUG` | `True` | Debug mode |
| `FRONTEND_URLS` | `http://localhost:3000,http://localhost:3001` | Allowed CORS origins |
| `SESSION_COOKIE_SECURE` | `True` | Secure cookies (set `False` for local HTTP) |
| `EMAIL_HOST` | `smtp.gmail.com` | SMTP server |
| `EMAIL_PORT` | `587` | SMTP port |
| `EMAIL_USE_TLS` | `True` | Enable TLS |
| `DEFAULT_FROM_EMAIL` | `noreply@terionix.com` | Sender address |
| `SCRAPER_API_URL` | `http://localhost:8002` | Scraper service URL |

### Scraper (`scraper/.env`)

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKEND_CALLBACK_URL` | `http://localhost:8001/api/scraper/callback` | Where scraper posts results |

### Frontend (build-time)

| Variable | Default | Description |
|----------|---------|-------------|
| `API_URL` | `http://localhost:8001/api` | Backend API base URL (SSR) |
| `API_PROXY_TARGET` | `http://localhost:8001` | Vite/Nitro proxy target for `/api/**` |

---

## Database

**Engine:** SQLite (stored at `backend/data/db.sqlite3`)

### Models

| Model | Purpose |
|-------|---------|
| `ContentSection` | Key-value store for all website content (JSON blobs keyed by section name) |
| `ContactSubmission` | Form submissions (general, career, quote) with flexible JSON `form_data` |
| `LeaderboardEntry` | Recycling game scores (name + time in seconds) |
| `GameItem` | Items used in the recycling game (name + recyclable boolean) |
| `EmailConfig` | Singleton SMTP configuration for email digests |
| `Tender` | Scraped government e-waste tenders (serial no, dates, title, refs, org chain) |

### Migrations

The project uses standard Django migrations. On Docker startup or `setup.sh`, `python manage.py migrate --noinput` is run automatically.

Seed data is loaded via a custom `seed_content` management command that reads `backend/content.json` and populates the `ContentSection` table.

---

## Development Notes

- **Git Submodules:** Each service (`frontend`, `backend`, `admin`, `scraper`) is a separate GitHub repository linked as a submodule. Changes to individual services should be committed in their respective repos.
- **API Proxy:** In development, the frontend Vite dev server proxies `/api/**` to `http://localhost:8001`. In production (Docker), Nitro's `routeRules` handles the proxy to the backend container.
- **CSRF:** The backend uses Django's CSRF protection. The frontend reads the `csrftoken` cookie and sends it as `X-CSRFToken` header on non-GET requests.
- **Admin Access:** The admin panel requires login. Auth state is stored in both `localStorage` and Django's session cookie.
- **Safari Handling:** The frontend detects Safari and applies a `.safari` class to `<html>`, which disables expensive CSS effects (backdrop blur, custom cursor, particle animations) for better performance.
- **Reduced Motion:** Users with `prefers-reduced-motion: reduce` get all animations disabled for accessibility.

---

## License

Proprietary — Terionix. All rights reserved.
