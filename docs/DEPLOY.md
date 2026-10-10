# Running it

Only the Flutter web frontend can be hosted for free (GitHub Pages, below). The
FastAPI/YOLO backend is not hosted anywhere, so the public demo is frontend
only. See the demo video linked in the README: <https://youtu.be/bxcA9Sg-ogw>.

`Dockerfile`, `backend/Dockerfile` and `nginx.conf` drive the local Docker
Compose setup.

## Frontend on GitHub Pages (free)

The workflow `.github/workflows/deploy-pages.yml` builds the Flutter web app and
publishes it to `https://alishnis.github.io/urban-syrix/`. One-time setup:

1. **Settings -> Pages -> Source: GitHub Actions.**
2. **Settings -> Secrets and variables -> Actions -> Secrets**, add:
   - `SUPABASE_URL` and `SUPABASE_ANON_KEY`. Both are public by design (they
     ship inside the web bundle); data is protected by Row Level Security.
     Never use the `service_role` key here.
   - `GOOGLE_MAPS_API_KEY` (optional). Restrict it by HTTP referrer to
     `https://alishnis.github.io/*` in Google Cloud. Note: the map script tag in
     `web/index.html` carries its own key, so restrict that key as well.
3. In Supabase, **Authentication -> URL Configuration**, add
   `https://alishnis.github.io/urban-syrix/` to the Redirect URLs (and set it as
   Site URL if this is the primary deployment).
4. Push to `main` (changes under `lib/`, `web/`, `assets/`, `pubspec.*` or the
   workflow) or run the workflow manually from the Actions tab.

If `SUPABASE_URL` or `SUPABASE_ANON_KEY` is missing the workflow skips the
deploy with a notice instead of failing.

**The backend is intentionally not hosted.** The workflow leaves
`DETECTION_API_BASE_URL` unset and passes `DETECTION_API_DISABLED=true`, so the
fire/accident detection, safe routing and AI scoring features show a "not hosted
in this demo" message instead of calling a missing server. Everything backed by
Supabase (sign-in, places, reviews, swipe reviews) and the map itself work. To
get the full experience, run the stack locally (below) or host the backend
yourself and add a `DETECTION_API_BASE_URL` build define (and drop
`DETECTION_API_DISABLED`).

**Deep links work** because the app uses Flutter's default hash URL strategy
(`/urban-syrix/#/...`), which needs no server-side rewrites; the workflow also
copies `index.html` to `404.html` as a fallback.

## Docker Compose (frontend + backend)

```bash
cp .env.example .env            # fill in values
docker compose up --build
```

Frontend at <http://localhost:8080> (Nginx), backend at
<http://localhost:8002/api/health>. Frontend values are baked into the web
bundle at image build time, so rebuild the frontend image after changing them.

## Backend only

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --port 8002    # run from backend/ so yolov8n.pt is found
```

Needs `OPENROUTESERVICE_API_KEY` (routing) and `OPENROUTER_API_KEY` (AI
scoring) in `.env`; detection endpoints work without keys. `ALLOWED_ORIGINS`
sets CORS (default `*`).

## Frontend only

Requires the Flutter SDK. Configuration is passed at compile time:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=DETECTION_API_BASE_URL=http://localhost:8002
```

Without the YOLO/ORS backend running, detection, routing and AI features do
not work.

## Note on `OPENAI_API_KEY`

`OPENAI_API_KEY` is only a client-side enable flag (`lib/core/config/openai_config.dart` checks that it is non-empty); the actual AI calls go through the backend in `backend/ai_router.py`, so never put a real key in a `--dart-define`.
