# urban syrix

`urban syrix` is a Flutter web smart-city platform for:

- map-based city object monitoring
- incident reporting (`fire`, `car accident`, `other`)
- role-based access with Supabase
- AI-assisted place scoring and review impact
- safe route planning around incident zones
- multilingual UI (`EN`, `RU`, `KZ`)

This repo contains both:

- the Flutter frontend
- the local FastAPI backend used for detection and route building

## Stack

- Flutter Web
- Supabase Auth + Postgres
- Google Maps
- FastAPI
- OpenAI API
- OpenRouteService

## Features

- email/password auth
- roles: `resident`, `builder`, `admin`
- add `place` and `accident` points directly from the map
- reverse geocoding for addresses
- `fire` / `car accident` media analysis
- comments and reviews stored in Supabase
- AI-based score calculation for places and review impact
- safe routing that avoids accident zones

## Project structure

```text
lib/                    Flutter frontend
backend/                FastAPI backend for detection and routing
supabase/               SQL setup scripts
```

Important paths:

- [lib/main.dart](/Users/aliserromankul/Desktop/arsen/hackathon_net/lib/main.dart)
- [backend/main.py](/Users/aliserromankul/Desktop/arsen/hackathon_net/backend/main.py)
- [supabase/profiles.sql](/Users/aliserromankul/Desktop/arsen/hackathon_net/supabase/profiles.sql)
- [supabase/urban_places.sql](/Users/aliserromankul/Desktop/arsen/hackathon_net/supabase/urban_places.sql)
- [supabase/urban_place_reviews.sql](/Users/aliserromankul/Desktop/arsen/hackathon_net/supabase/urban_place_reviews.sql)

## Prerequisites

Install locally:

- Flutter SDK
- Python 3.10+
- Google Chrome
- a Supabase project

Optional but recommended:

- OpenAI API key
- OpenRouteService API key

## 1. Supabase setup

Create a Supabase project and enable Email auth.

You need:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

### Required SQL

Run these scripts in Supabase SQL Editor:

1. [supabase/profiles.sql](/Users/aliserromankul/Desktop/arsen/hackathon_net/supabase/profiles.sql)
2. [supabase/urban_places.sql](/Users/aliserromankul/Desktop/arsen/hackathon_net/supabase/urban_places.sql)
3. [supabase/urban_place_reviews.sql](/Users/aliserromankul/Desktop/arsen/hackathon_net/supabase/urban_place_reviews.sql)

These scripts create:

- `public.profiles`
- `public.urban_places`
- `public.urban_place_reviews`
- RLS policies and grants used by the app

### Roles

Available roles:

- `resident`
- `builder`
- `admin`

Notes:

- public sign-up allows only `resident` and `builder`
- `admin` should be assigned manually

Example:

```sql
update public.profiles
set role = 'admin'
where email = 'user@example.com';
```

## 2. Backend setup

The local backend is used for:

- `fire` detection
- `car accident` detection
- safe route building

### Backend install

```bash
cd /Users/aliserromankul/Desktop/arsen/hackathon_net/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Backend environment

Create `backend/.env`:

```env
OPENROUTESERVICE_API_KEY=your_openrouteservice_key
```

`OPENROUTESERVICE_API_KEY` is required for safe routing.

### Run backend

```bash
cd /Users/aliserromankul/Desktop/arsen/hackathon_net/backend
source .venv/bin/activate
python main.py
```

The backend runs on:

- `http://localhost:8001`

Health check:

```bash
curl http://localhost:8001/api/health
```

### Backend endpoints

Detection:

- `POST /api/fire/analyze`
- `POST /api/fire/analyze-image`
- `POST /api/accident/analyze-image`
- `POST /api/accident/analyze-video`

Routing:

- `POST /api/route/safe-route`

## 3. Flutter setup

Install frontend dependencies:

```bash
cd /Users/aliserromankul/Desktop/arsen/hackathon_net
flutter pub get
```

## 4. Run Flutter web

### Minimal run

If you only need auth + frontend:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### Full local run

For full app functionality including detection, routing, and AI scoring:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=DETECTION_API_BASE_URL=http://localhost:8001 \
  --dart-define=OPENAI_API_KEY=your-openai-key
```

### Web-server run

Useful if you want a stable local URL:

```bash
flutter run -d web-server --web-port 8080 \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=DETECTION_API_BASE_URL=http://localhost:8001 \
  --dart-define=OPENAI_API_KEY=your-openai-key
```

Then open:

- [http://localhost:8080](http://localhost:8080)

## Runtime variables

Frontend:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `DETECTION_API_BASE_URL`
- `OPENAI_API_KEY`
- `GOOGLE_MAPS_API_KEY` (optional override if you do not want to use the default one in the repo)

Backend:

- `OPENROUTESERVICE_API_KEY`

## What each variable does

`SUPABASE_URL`

- Supabase project URL
- required for auth and database access

`SUPABASE_ANON_KEY`

- public client key for Supabase
- required for auth and frontend DB access

`DETECTION_API_BASE_URL`

- base URL for local FastAPI backend
- used for fire / accident detection and safe route requests

`OPENAI_API_KEY`

- used to analyze place descriptions
- used to analyze comments and map them into score impact

`OPENROUTESERVICE_API_KEY`

- used by backend safe route logic

## Local development flow

Recommended order:

1. Start backend
2. Start Flutter app
3. Sign in with a `builder` account
4. Open the map
5. Add a `place` or `accident`
6. Test detection, comments, and routing

## Typical demo flow

1. Sign in as `builder`
2. Click `Add accident`
3. Select `fire` or `car accident`
4. Upload media
5. Run `Analyze media`
6. Add incident to the map
7. Set route start and end
8. Build safe route
9. Open a place and add a comment
10. Observe score changes

## Common issues

### Profile setup is incomplete

Reason:

- `profiles` table or policies are missing
- or Supabase request is blocked

Fix:

- run [supabase/profiles.sql](/Users/aliserromankul/Desktop/arsen/hackathon_net/supabase/profiles.sql)
- verify `grant` and RLS policies exist

### New places do not persist

Reason:

- `urban_places` table is missing

Fix:

- run [supabase/urban_places.sql](/Users/aliserromankul/Desktop/arsen/hackathon_net/supabase/urban_places.sql)

### Comments do not persist

Reason:

- `urban_place_reviews` table is missing

Fix:

- run [supabase/urban_place_reviews.sql](/Users/aliserromankul/Desktop/arsen/hackathon_net/supabase/urban_place_reviews.sql)

### Description scoring stays medium

Reason:

- app was started without `OPENAI_API_KEY`
- fallback score constants were used instead of OpenAI

Fix:

- restart Flutter with `--dart-define=OPENAI_API_KEY=...`

### Detection fails

Reason:

- backend is not running
- wrong `DETECTION_API_BASE_URL`

Fix:

- verify backend on `http://localhost:8001/api/health`

### Safe route fails

Reason:

- backend not running
- `OPENROUTESERVICE_API_KEY` missing in `backend/.env`

## Verify setup

Frontend analysis:

```bash
cd /Users/aliserromankul/Desktop/arsen/hackathon_net
flutter analyze
```

Backend health:

```bash
curl http://localhost:8001/api/health
```

## Security note

Current repo still contains a Google Maps API key in client-facing files. For production:

- move all possible keys to runtime configuration
- rotate exposed keys
- do not expose server-level secrets to Flutter web clients

For production architecture, OpenAI calls should ideally be moved out of the web client and into a backend or Supabase Edge Function.
