# Urban Syrix

**Urban Syrix** is a smart-city operations platform that lets residents, builders, and municipal administrators monitor a city on a live map, report incidents, and get AI-assisted insight into places and reviews.

The project combines a **Flutter Web** client with a **Supabase** backend for auth/data and a **FastAPI** microservice for computer-vision detection and safe-route planning.

🔗 **Live demo:** [urbansyr-frontend.politewave-c26ab3bd.germanywestcentral.azurecontainerapps.io](https://urbansyr-frontend.politewave-c26ab3bd.germanywestcentral.azurecontainerapps.io)

Deployed as two containers on Azure Container Apps (frontend + FastAPI backend), built from the `Dockerfile`s in this repo. Both scale to zero when idle, so the first request after a period of inactivity may take 10-20s to respond (cold start).

## Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech stack](#tech-stack)
- [Features](#features)
- [Project structure](#project-structure)
- [Getting started](#getting-started)
- [Running with Docker](#running-with-docker)
- [Deployment](#deployment)
- [Environment variables](#environment-variables)
- [Backend API](#backend-api)
- [Security notes](#security-notes)

## Overview

City infrastructure incidents (fires, traffic accidents, utility works) are reported in real time on a shared map. Residents and builders can add points of interest, leave reviews, and request routes that automatically avoid active accident zones. An OpenAI-backed scoring service evaluates places and the impact of reviews, while two YOLOv8 models run fire and accident detection on uploaded images/video.

## Architecture

```
                     ┌─────────────────────────┐
                     │     Flutter Web App      │
                     │  (auth, map, dashboard)  │
                     └────────────┬─────────────┘
                                  │
             ┌────────────────────┼────────────────────┐
             │                    │                    │
   ┌─────────▼─────────┐ ┌────────▼────────┐  ┌────────▼────────┐
   │      Supabase      │ │   FastAPI       │  │   OpenAI API    │
   │ (Auth + Postgres)  │ │   backend       │  │ (place scoring, │
   │                     │ │ (YOLOv8 + ORS)  │  │  review impact) │
   └─────────────────────┘ └─────────────────┘  └─────────────────┘
```

- **Flutter Web** renders the map, dashboards, and role-based views, and talks directly to Supabase (auth + Postgres) and to the FastAPI backend for detection/routing.
- **FastAPI backend** hosts two YOLOv8 models (fire detection, traffic-accident detection) and a safe-routing endpoint backed by OpenRouteService.
- **Supabase** provides authentication, Postgres storage (`profiles`, `urban_places`, `urban_place_reviews`), and row-level security.

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | Flutter Web, Google Maps SDK |
| Auth & Database | Supabase (Postgres + Auth + RLS) |
| Detection backend | FastAPI, Ultralytics YOLOv8, OpenCV |
| AI scoring | OpenAI API |
| Routing | OpenRouteService API |
| Deployment | Docker, Docker Compose, Nginx |

## Features

- Email/password authentication with role-based access (`resident`, `builder`, `admin`)
- Map-based reporting of city objects and incidents (`fire`, `car accident`, `other`)
- Reverse geocoding for reported locations
- Fire and traffic-accident detection from images/video via on-prem YOLOv8 models
- AI-assisted scoring of places and review impact via OpenAI
- Safe-route planning that automatically routes around active accident zones
- Comments and reviews persisted in Supabase with RLS policies
- Multilingual UI (`EN`, `RU`, `KZ`)

## Project structure

```text
lib/                    Flutter frontend
  core/config/           Runtime configuration (Supabase, Maps, OpenAI, API base URL)
  features/              auth, dashboard, map, reviews, account, shell
backend/                 FastAPI backend
  fire_router.py          Fire detection (YOLOv8)
  accident_router.py      Traffic-accident detection (YOLOv8)
  route_router.py          Safe-route planning (OpenRouteService)
modules/                 YOLOv8 weights used by the backend routers
supabase/                SQL setup scripts (schema, RLS, review system)
Dockerfile               Multi-stage build: Flutter web -> Nginx
backend/Dockerfile        FastAPI + YOLOv8 backend image
docker-compose.yml        Runs frontend + backend together
```

## Getting started

### Prerequisites

- Flutter SDK
- Python 3.10+
- A Supabase project (Auth enabled)
- Optional: OpenAI API key, OpenRouteService API key, Google Maps API key

### 1. Supabase setup

Create a Supabase project and enable email auth, then run the SQL scripts in the Supabase SQL editor in this order:

1. [`supabase/profiles.sql`](supabase/profiles.sql)
2. [`supabase/urban_places.sql`](supabase/urban_places.sql)
3. [`supabase/urban_place_reviews.sql`](supabase/urban_place_reviews.sql)
4. [`supabase/swipe_review_system.sql`](supabase/swipe_review_system.sql)

Public sign-up only allows `resident` and `builder`. Promote an account to `admin` manually:

```sql
update public.profiles
set role = 'admin'
where email = 'user@example.com';
```

### 2. Backend setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Create `backend/.env`:

```env
OPENROUTESERVICE_API_KEY=your_openrouteservice_key
```

Run it:

```bash
uvicorn main:app --host 0.0.0.0 --port 8002
```

Health check:

```bash
curl http://localhost:8002/api/health
```

### 3. Frontend setup

```bash
flutter pub get
```

Minimal run (auth + frontend only):

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Full local run (detection, routing, AI scoring included):

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=DETECTION_API_BASE_URL=http://localhost:8002 \
  --dart-define=OPENAI_API_KEY=your-openai-key
```

Or run as a stable local web server:

```bash
flutter run -d web-server --web-port 8080 \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=DETECTION_API_BASE_URL=http://localhost:8002 \
  --dart-define=OPENAI_API_KEY=your-openai-key
```

Then open [http://localhost:8080](http://localhost:8080).

## Running with Docker

The repository ships with a `Dockerfile` for the Flutter web frontend, a `backend/Dockerfile` for the FastAPI service, and a `docker-compose.yml` that wires both together.

1. Copy `.env.example` to `.env` in the project root and fill in real values:

```bash
cp .env.example .env
```

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
DETECTION_API_BASE_URL=http://localhost:8002
OPENAI_API_KEY=your-openai-key
OPENROUTESERVICE_API_KEY=your-openrouteservice-key
GOOGLE_MAPS_API_KEY=your-google-maps-key
ALLOWED_ORIGINS=http://localhost:8080
```

2. Build and start both services:

```bash
docker-compose up -d --build
```

- Frontend: [http://localhost:8080](http://localhost:8080) (served by Nginx)
- Backend: [http://localhost:8002/api/health](http://localhost:8002/api/health)

Frontend build-time configuration (Supabase URL/key, detection API URL, OpenAI key) is baked into the compiled web bundle via `--dart-define`/`ARG` at image build time — rebuild the frontend image whenever these change.

## Environment variables

**Frontend** (compile-time, via `--dart-define` or Docker build args):

| Variable | Purpose |
|---|---|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase public client key |
| `DETECTION_API_BASE_URL` | Base URL of the FastAPI backend |
| `OPENAI_API_KEY` | Used for place scoring / review impact |
| `GOOGLE_MAPS_API_KEY` | Optional override of the default Maps key |

**Backend** (runtime, via `backend/.env` or container environment):

| Variable | Purpose |
|---|---|
| `OPENROUTESERVICE_API_KEY` | Required for safe-route planning |
| `ALLOWED_ORIGINS` | Comma-separated list of allowed CORS origins (defaults to `*`) |

## Backend API

Detection:

- `POST /api/fire/analyze`
- `POST /api/fire/analyze-image`
- `POST /api/accident/analyze-image`
- `POST /api/accident/analyze-video`

Routing:

- `POST /api/route/safe-route`

Health:

- `GET /api/health`

## Deployment

The live demo runs on **Azure Container Apps** (Consumption plan, `germanywestcentral`), one app per service:

- `urbansyr-frontend` — the `Dockerfile` image, built with `--build-arg` values baked in via Flutter's `--dart-define`, served by Nginx
- `urbansyr-backend` — the `backend/Dockerfile` image, exposing port 8002

Both images are built for `linux/amd64` (via `docker buildx build --platform linux/amd64`, since Azure Container Apps does not run `arm64` images) and published to Docker Hub, then deployed with:

```bash
az containerapp create \
  --name urbansyr-backend \
  --resource-group <rg> \
  --environment <env> \
  --image <dockerhub-user>/urbansyr-backend:latest \
  --target-port 8002 \
  --ingress external \
  --min-replicas 0 --max-replicas 1 \
  --cpu 2.0 --memory 4.0Gi \
  --secrets orsk=<openrouteservice-key> \
  --env-vars "OPENROUTESERVICE_API_KEY=secretref:orsk" "ALLOWED_ORIGINS=<frontend-url>"
```

```bash
az containerapp create \
  --name urbansyr-frontend \
  --resource-group <rg> \
  --environment <env> \
  --image <dockerhub-user>/urbansyr-frontend:latest \
  --target-port 80 \
  --ingress external \
  --min-replicas 0 --max-replicas 1 \
  --cpu 0.5 --memory 1.0Gi
```

Both apps scale to zero when idle (`min-replicas 0`) to stay within Azure's free monthly Container Apps grant — the trade-off is a cold start of roughly 10-20s on the first request after a period of inactivity.

## Security notes

- Frontend secrets passed via `--dart-define` are compiled into the client-side JS bundle and are visible to anyone inspecting the deployed site. Treat `SUPABASE_ANON_KEY` and `OPENAI_API_KEY` accordingly — the anon key is designed to be public and relies on Supabase RLS; the OpenAI key is not, and moving OpenAI calls behind the backend (or a Supabase Edge Function) is the recommended hardening step before a public production deploy.
- `ALLOWED_ORIGINS` defaults to `*` for convenience; set it to your real frontend origin in production.
- Rotate any API keys that were used during local development/demos before shipping to a public environment.
