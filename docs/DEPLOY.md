# Running it

The hosted demo is offline: the Azure student credit that hosted it ran out.
See the demo video linked in the README: <https://youtu.be/bxcA9Sg-ogw>.

`Dockerfile`, `backend/Dockerfile` and `nginx.conf` are kept as reference for
the former Azure deployment. They also drive the local Docker Compose setup.

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
