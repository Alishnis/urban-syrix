# Urban Syrix

A smart-city map where residents, builders and city administrators report incidents, review places, and get safe routes that avoid active accident zones. Fire and traffic-accident detection (YOLOv8) and LLM-based place scoring run in a FastAPI backend behind the Flutter web app.

## My role

I am **Alisher Romankul, co-founder of Urban Syrix**, and I built the **entire backend** (`backend/`): the FastAPI detection and routing services and their integrations with third-party platforms (OpenRouteService for safe routing, OpenRouter for AI scoring).

This repository is my fork (`Alishnis/urban-syrix`) of a teammate's repository, [shamanx64/hackathon_net](https://github.com/shamanx64/hackathon_net). The Flutter client and Supabase SQL are part of the same team project.

<!-- TODO(owner): add your teammates' roles and how they want to be credited; only your own role is documented here. -->

**Live demo:** [urbansyr-frontend.politewave-c26ab3bd.germanywestcentral.azurecontainerapps.io](https://urbansyr-frontend.politewave-c26ab3bd.germanywestcentral.azurecontainerapps.io) (hosted on Azure Container Apps and scaled to zero when idle, so the first request after a quiet period can take 10-20 s)

**Demo video:** [youtu.be/bxcA9Sg-ogw](https://youtu.be/bxcA9Sg-ogw)

[![Urban Syrix demo video](https://img.youtube.com/vi/bxcA9Sg-ogw/maxresdefault.jpg)](https://youtu.be/bxcA9Sg-ogw)

<!-- TODO(owner): add 2-3 screenshots (map, incident report, safe route) under docs/images/ and embed them here. -->

## Features

- Interactive map of city objects (building, construction, road, incident) with incident subtypes `fire`, `car accident`, `other`
- Public read-only map for signed-out visitors; sign-in is needed to add a marker or comment
- Email/password auth with roles `resident`, `builder`, `admin` (Supabase Auth + row-level security)
- Fire detection and traffic-accident detection on uploaded images and videos (YOLOv8), with an annotated preview image and the bounding-box region (for example `top-left`)
- Safe-route planning: accident locations are sent as circular avoid-zones to OpenRouteService so the route goes around them
- LLM scoring of a place (mobility, environment, resources, transparency, inclusivity, safety, plus traffic risk, CO2 footprint, green coverage) and of the impact of a review
- Swipe-style review flow with admin moderation, per-user rate limit and a reward ledger (see `supabase/swipe_review_system.sql`)
- Reverse geocoding of reported locations (Google Geocoding API)
- UI in English, Russian and Kazakh

## Architecture

```
                 +-------------------------+
                 |     Flutter Web app     |
                 |  map, dashboard, auth   |
                 +-----+-------------+-----+
                       |             |
          Supabase SDK |             | HTTPS / JSON + multipart
                       v             v
        +----------------+   +-----------------------------------------+
        |    Supabase    |   |          FastAPI backend (:8002)        |
        | Auth + Postgres|   |  /api/fire      YOLOv8 fire model      |
        |  (RLS, RPCs)   |   |  /api/accident  YOLOv8 accident model  |
        +----------------+   |                 + YOLOv8n vehicles     |
                             |  /api/route     -> OpenRouteService    |
                             |  /api/ai        -> OpenRouter (LLM)    |
                             +-----------------------------------------+
```

The client talks to Supabase directly for auth and data, and to the backend for everything that needs a model or a third-party API key. API keys for OpenRouter and OpenRouteService therefore live only on the server.

### Backend (`backend/`)

| File | Responsibility |
|---|---|
| `main.py` | App factory: loads `.env`, configures CORS from `ALLOWED_ORIGINS`, mounts the four routers under `/api/*`, exposes `/api/health` |
| `fire_router.py` | `/api/fire/*`: loads `modules/fire-detection/fire_model.pt` lazily; image and video analysis (every 5th frame, at most 300 frames); writes an annotated preview |
| `accident_router.py` | `/api/accident/*`: accident model (`best-versi-1.pt`, falling back to `yolov8m-dataset-7000-300.pt`) plus `yolov8n.pt` to count vehicles (COCO classes bicycle, car, motorcycle, bus, truck) for context |
| `route_router.py` | `/api/route/safe-route`: turns accident points into 16-segment circular polygons (great-circle offsets, `MultiPolygon`) and asks OpenRouteService for a driving route that avoids them |
| `ai_router.py` | `/api/ai/*`: builds a system prompt and forces a JSON object answer from OpenRouter (`deepseek/deepseek-v4-flash`); the key stays server-side |

Blocking OpenCV / YOLO work runs in `asyncio.to_thread` so the event loop is not blocked. Uploaded files are written to `backend/tmp/` under a random name and deleted after analysis; preview images stay in `backend/tmp/*_previews/`.

### Backend API

All endpoints are under the base URL of the backend (default `http://localhost:8002`). Interactive docs are served by FastAPI at `/docs`.

| Method and path | Request | Response |
|---|---|---|
| `GET /api/health` | - | `{"status": "ok"}` |
| `POST /api/fire/analyze` | multipart: `file` (video), `sensitivity` (float, default `0.4`, clamped to 0.1-0.9) | `{"fire_detected": bool, "stats": {frames_total, frames_processed, frames_with_fire, max_confidence, best_frame_confidence, preview_name, best_box, video_name, threshold}}` (`video_name` is always `null`) |
| `POST /api/fire/analyze-image` | multipart: `file` (image), `sensitivity` (default `0.4`, clamped to 0.1-0.9) | `{"fire_detected": bool, "stats": {max_confidence, preview_name, best_box, threshold}}` |
| `POST /api/accident/analyze-image` | multipart: `file` (image), `sensitivity` (default `0.2`, clamped to 0.05-0.9) | `{"accident_detected": bool, "stats": {vehicles_count, accident_boxes, max_confidence, preview_name, best_box, threshold}}` |
| `POST /api/accident/analyze-video` | multipart: `file` (video), `sensitivity` (default `0.2`, clamped to 0.05-0.9) | `{"accident_detected": bool, "stats": {frames_total, frames_processed, frames_with_accident, max_confidence, preview_name, best_box, threshold}}` |
| `GET /api/fire/preview/{name}`, `GET /api/accident/preview/{name}` | `name` = `preview_name` from the stats | annotated JPEG, or `404` `{"detail": "Preview not found."}` |
| `POST /api/route/safe-route` | JSON, see below | route geometry |
| `POST /api/ai/place-analysis` | JSON: `name`, `type_label`, `incident_subtype_label?`, `address`, `description` | `{"output_text": "<JSON string with description and 0-100 scores>"}` |
| `POST /api/ai/review-impact` | JSON: `place_name`, `place_type_label`, `place_address`, `place_description`, `selected_category_label`, `message` | `{"output_text": "<JSON string: sentiment and -12..12 impact per category>"}` |

`best_box` is `{"x1", "y1", "x2", "y2", "region"}` in pixels, where `region` is a 3x3 position label such as `middle-center`, or `null` when nothing was detected. An upload that has the right type but cannot be decoded (corrupt image, unreadable video) is not an error: the response is `200` with `*_detected: false` and a reduced `stats` object (some keys above are absent). Videos are sampled every 5th frame and reading stops after 300 frames.

**Safe route**

```jsonc
// POST /api/route/safe-route
{
  "origin":      {"latitude": 43.2389, "longitude": 76.8897},
  "destination": {"latitude": 43.2567, "longitude": 76.9286},
  "avoid_points": [{"latitude": 43.245, "longitude": 76.90}],  // optional accident locations
  "avoid_radius_m": 50                                          // optional, default 50, clamped to 10-200
}
// 200 response
{
  "coordinates": [[76.8897, 43.2389], ...],   // [longitude, latitude] pairs
  "distance_m": 4321.5,                        // null if ORS returns no summary
  "duration_s": 612.0,                         // null if ORS returns no summary
  "avoided_points": 1                          // number of avoid_points sent
}
```

Latitude and longitude only have to be numbers; their ranges are not checked by the backend, so out-of-range values are rejected by OpenRouteService and come back as `400`.

**Error responses** (body is `{"detail": ...}`)

| Status | When |
|---|---|
| `400` | Uploaded file is neither the expected type nor has an allowed extension (`Please upload an image file.` / `Please upload a video file.`); OpenRouteService / OpenRouter answered with an HTTP error (any 4xx or 5xx), in which case `detail` is the upstream message; OpenRouteService returned no route geometry |
| `404` | Preview image does not exist |
| `422` | Request body or form fields are missing or have the wrong type (FastAPI validation, including a non-numeric `sensitivity`) |
| `500` | `OPENROUTESERVICE_API_KEY` / `OPENROUTER_API_KEY` is not configured on the server; a YOLO weights file is missing or inference fails (generic `Internal Server Error`) |
| `502` | OpenRouteService / OpenRouter could not be reached (connection error) |
| `504` | OpenRouteService / OpenRouter timed out (30 s) |

### Supabase (`supabase/`)

SQL scripts for the tables `profiles`, `urban_places`, `urban_place_reviews`, `review_swipes`, `swipe_reviews`, `organization_reputation`, `reward_ledger`, the RPCs `submit_swipe_review` and `moderate_swipe_review`, row-level-security policies, and optional demo seed data.

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (web), `google_maps_flutter`, `supabase_flutter` |
| Auth and data | Supabase (Postgres, Auth, RLS) |
| Backend | Python 3.11, FastAPI, Uvicorn, httpx |
| Computer vision | Ultralytics YOLOv8, OpenCV |
| AI scoring | OpenRouter (`deepseek/deepseek-v4-flash`) |
| Routing | OpenRouteService (driving-car, `avoid_polygons`) |
| Packaging and hosting | Docker, Docker Compose, Nginx, Azure Container Apps |
| Backend tests and CI | pytest, FastAPI TestClient, ruff, GitHub Actions |

## Quick start

### 1. Backend

Requires Python 3.11+. The first install downloads PyTorch via `ultralytics`, so it is large.

```bash
cp .env.example .env            # then fill in OPENROUTESERVICE_API_KEY and OPENROUTER_API_KEY
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --port 8002    # run from backend/ so yolov8n.pt is found
```

```bash
curl http://localhost:8002/api/health        # {"status":"ok"}
curl -F file=@some_photo.jpg http://localhost:8002/api/fire/analyze-image
```

Detection works without any API key. `/api/route/*` needs `OPENROUTESERVICE_API_KEY` and `/api/ai/*` needs `OPENROUTER_API_KEY`; without them those endpoints return `500` with an explanatory message.

### 2. Supabase

Create a Supabase project with email auth, then run these scripts in the SQL editor in order: `supabase/profiles.sql`, `urban_places.sql`, `urban_place_reviews.sql`, `swipe_review_system.sql`, `allow_anonymous_reads.sql`. Public sign-up only creates `resident` or `builder`; promote an admin manually:

```sql
update public.profiles set role = 'admin' where email = 'you@example.com';
```

Optional: `supabase/seed_demo_data.sql` / `reset_and_seed_demo_places.sql` insert demo places (replace the placeholder email inside first; the reset script deletes existing places and reviews).

### 3. Frontend

Requires the Flutter SDK. Configuration is passed at compile time (the `.env` file is not read by the web build).

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=DETECTION_API_BASE_URL=http://localhost:8002
```

`DETECTION_API_BASE_URL` defaults to `http://localhost:8002` when omitted. Without Supabase values the app shows a "Supabase is not configured" screen.

### Docker Compose

```bash
cp .env.example .env            # fill in values
docker compose up --build
```

Frontend at http://localhost:8080 (Nginx), backend at http://localhost:8002/api/health. Frontend values are baked into the web bundle at image build time, so rebuild the frontend image after changing them.

## Configuration

Copy `.env.example` to `.env` (gitignored). Variables marked "frontend" are compile-time values that end up in the public JS bundle, so never put a secret there.

| Variable | Used by | Required | Description |
|---|---|---|---|
| `SUPABASE_URL` | frontend | yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | frontend | yes | Supabase public anon key (protected by RLS) |
| `DETECTION_API_BASE_URL` | frontend | no | Backend URL as seen from the browser; defaults to `http://localhost:8002` |
| `GOOGLE_MAPS_API_KEY` | frontend | no | Google Maps key. The repo currently falls back to a built-in key, see Security notes |
| `OPENROUTER_API_KEY` | backend | for `/api/ai/*` | OpenRouter key; server-side only |
| `OPENROUTESERVICE_API_KEY` | backend | for `/api/route/*` | OpenRouteService key (`ORS_API_KEY` accepted as an alias) |
| `ALLOWED_ORIGINS` | backend | no | Comma-separated CORS origins; defaults to `*` |

## Project structure

```text
backend/                  FastAPI service (detection, routing, AI proxy)
  main.py, *_router.py      app + routers, see the table above
  tests/                    pytest suite (third-party calls are mocked)
  requirements.txt          runtime deps (incl. ultralytics/torch)
  requirements-test.txt     light deps for lint + tests
  yolov8n.pt                COCO vehicle detector
modules/                  YOLOv8 weights: fire-detection/, traffic-accident-detection/
lib/                      Flutter app (core/config, features/{auth,map,reviews,dashboard,account,public,shell})
supabase/                 SQL schema, RLS, RPCs, demo seed data
docs/                     notes on the swipe-review rollout
Dockerfile, nginx.conf    Flutter web build -> Nginx image
docker-compose.yml        frontend + backend
.github/workflows/ci.yml  backend lint + tests
```

## Testing

Backend (no model weights or network needed; `ultralytics` is stubbed, YOLO models are replaced by fakes, and OpenRouteService / OpenRouter calls are mocked):

```bash
cd backend
pip install -r requirements-test.txt
ruff check .
pytest
```

The suite (`backend/tests/`) covers:

- **Route planning around accident zones:** each accident becomes a closed circular avoid-polygon (checked for radius, closure, and that it encloses the accident but not the trip endpoints) in the `avoid_polygons` option sent to OpenRouteService; radius clamping; the returned route is passed through unchanged.
- **Request validation** on every endpoint: malformed or missing JSON fields, non-numeric values, wrong or missing upload types (images vs. videos, unknown extensions), non-numeric `sensitivity`, sensitivity clamping.
- **External-service failures:** OpenRouteService and OpenRouter timeouts (`504`), connection errors (`502`), 4xx/5xx responses with JSON, HTML or empty bodies (`400` with the upstream message), 200 responses with invalid JSON or no usable content, and a missing or blank API key (`500`), all without any real network call.
- **YOLO detection with a mocked model:** the real OpenCV code runs against fake model output (thresholds, region labels, vehicle counts, frame sampling on a generated video, preview files); model inference errors and missing weights return `500`, clean up the upload and leave the server responsive.
- CORS configuration, and regressions for two bugs (path-like upload filenames and directory preview lookups returning `500`).

Frontend: `flutter test` runs one widget test (the "Supabase is not configured" screen); `flutter analyze` reports two deprecation infos.

## Security notes

- Frontend `--dart-define` values are public. The OpenRouter key is never sent to the client; the Docker build only passes a non-secret flag telling the UI that AI scoring is available.
- `ALLOWED_ORIGINS` defaults to `*`; set it to your real frontend origin in production.
- The backend endpoints have no authentication, rate limiting or upload-size limit (see limitations).
- Google Maps key: a key is hardcoded as a fallback in `lib/core/config/google_maps_config.dart`, `web/index.html` and the Android manifest. Maps browser keys are public by design, so restrict it by HTTP referrer / app in Google Cloud Console, and rotate it if it has not been restricted.

## Limitations

- Hackathon-grade project: backend tests cover routing, validation, proxy and detection plumbing with mocked models and services; the real YOLO weights and the live third-party APIs are not exercised by automated tests, and the Flutter client has one widget test.
- Detection accuracy has not been evaluated in this repo, and the training data and licence of the weights in `modules/` are not documented here. Treat results as a demo, not as a safety system.
- Safe routing only avoids circular zones around reported points (10-200 m) for driving routes; it does not check the zones' freshness or resolve incidents.
- The backend is unauthenticated: anyone who can reach it can use the detection, routing and LLM endpoints. Uploads have no size limit and preview images in `backend/tmp/` are not cleaned up.
- AI answers are returned as the model's JSON text (`output_text`); the backend does not validate the scores. The client falls back to default scores when AI scoring is unavailable.
- Docker images are large because they include PyTorch and the model weights.

## License

TODO(owner): no `LICENSE` file is present. Confirm the intended licence (MIT?). Note that Ultralytics YOLOv8 is AGPL-3.0, which can affect how the combined project may be licensed.
