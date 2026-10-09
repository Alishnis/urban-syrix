# Free hosting guide

The project runs at no cost on:

| Part | Host | How it deploys |
|---|---|---|
| FastAPI backend (YOLOv8, routing, AI proxy) | Hugging Face Space (Docker SDK, free CPU: 2 vCPU / 16 GB) | `.github/workflows/deploy-hf-space.yml` |
| Flutter web frontend | GitHub Pages at `https://alishnis.github.io/urban-syrix/` | `.github/workflows/deploy-pages.yml` |
| Auth + data | Supabase (unchanged) | see `supabase/` |

Both workflows trigger on pushes to `main` (with path filters) and on manual
`workflow_dispatch`. Both **skip cleanly** (no red CI) until the settings below
exist, so merging this change is safe before any setup.

> The Azure files (`Dockerfile`, `nginx.conf`, `docker-compose.yml`, the Azure
> Container Apps deployment) are **legacy**. They are kept for local Docker use
> but are no longer the hosting target.

## 1. Backend on a Hugging Face Space

1. Create a free account at <https://huggingface.co>.
2. Create an access token with **write** permission: Settings -> Access Tokens.
3. Pick a Space id `<hf-user>/<space-name>` (e.g. `your-user/urban-syrix-api`).
   You do not need to create the Space by hand; the workflow creates it
   (`create_repo(exist_ok=True, space_sdk="docker")`).
4. Store the token and the Space id in GitHub:

   ```bash
   gh secret set HF_TOKEN --repo Alishnis/urban-syrix            # paste the token when prompted
   gh variable set HF_SPACE_ID --repo Alishnis/urban-syrix --body "<hf-user>/<space-name>"
   ```

5. Run the workflow once: Actions -> "Deploy backend to Hugging Face Space" ->
   Run workflow (or push a change under `backend/` or `modules/` to `main`).
   The first Docker build on Hugging Face takes several minutes (PyTorch).
6. Add the backend secrets on the Space: Space -> Settings -> Variables and
   secrets -> New secret. Names only (values are yours, never commit them):

   | Name | Needed for | Notes |
   |---|---|---|
   | `OPENROUTER_API_KEY` | `/api/ai/*` (place scoring, review impact) | server-side only |
   | `OPENROUTESERVICE_API_KEY` | `/api/route/*` (safe routing) | `ORS_API_KEY` is accepted as an alias |
   | `ALLOWED_ORIGINS` | CORS (see below) | not a secret; may be a plain Variable |

   Detection endpoints work without any key. Without the two API keys the
   matching endpoints return `500` with an explanatory message.
7. The backend URL is `https://<hf-user>-<space-name>.hf.space` (check the
   "Embed this Space" / "Direct URL" entry in the Space menu). Verify with
   `curl https://<hf-user>-<space-name>.hf.space/api/health` -> `{"status":"ok"}`.

### CORS

The backend already reads `ALLOWED_ORIGINS` (comma-separated origins, default
`*`). Set it on the Space to the Pages origin, which has **no path and no
trailing slash**:

```text
ALLOWED_ORIGINS=https://alishnis.github.io
```

Add more origins separated by commas (e.g. `,http://localhost:8080` for local
testing).

### Cold starts

A free Space goes to sleep after about 48 hours without traffic and wakes on
the next request in about a minute (the first request, and the first AI/YOLO
call, are slow). Free CPU hardware has no GPU, so video analysis is slow by
design (frame count is capped in the code).

### What the container does

HF runs containers as UID 1000. `backend/Dockerfile` therefore creates that
user, makes `/app/tmp` (previews and uploads) writable, and sets `HOME` so
ultralytics can write its settings. Local staging dry run:

```bash
python3 scripts/stage_hf_space.py /tmp/hf_space   # lays out README.md, Dockerfile, backend/, modules/
```

The staged `README.md` carries the Space front matter (`sdk: docker`,
`app_port: 8002`). Only git-tracked files are staged, never `.env`.

## 2. Frontend on GitHub Pages

1. Repo -> Settings -> Pages -> **Build and deployment -> Source: GitHub Actions**.
2. Set the build configuration (the build reads these at compile time):

   ```bash
   gh secret set SUPABASE_URL        --repo Alishnis/urban-syrix
   gh secret set SUPABASE_ANON_KEY   --repo Alishnis/urban-syrix
   gh secret set GOOGLE_MAPS_API_KEY --repo Alishnis/urban-syrix   # optional; see note
   gh variable set DETECTION_API_BASE_URL --repo Alishnis/urban-syrix --body "https://<hf-user>-<space-name>.hf.space"
   ```

   `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `DETECTION_API_BASE_URL` are required;
   if any is missing the workflow logs a notice and skips. If
   `GOOGLE_MAPS_API_KEY` is unset the app keeps its built-in fallback key (see
   the README security notes). Whatever key you use ends up in the public
   bundle: restrict it by HTTP referrer (`https://alishnis.github.io/*`) in
   Google Cloud Console.
3. In Supabase -> Authentication -> URL Configuration, add
   `https://alishnis.github.io/urban-syrix/` to the Site URL / Redirect URLs so
   sign-in works from the new origin.
4. Run Actions -> "Deploy web app to GitHub Pages" -> Run workflow. The site is
   then at `https://alishnis.github.io/urban-syrix/`.

Routing: the app uses Flutter's default hash URL strategy (no path strategy is
configured), so deep links work on Pages. The workflow also copies
`index.html` to `404.html` as a safety net in case a path strategy is enabled
later.

### `OPENAI_API_KEY` and the client bundle

Everything passed with `--dart-define` is shipped to every visitor's browser.
`OPENAI_API_KEY` is **not** used as a real key client-side: the Flutter code
(`lib/core/config/openai_config.dart`) only checks that it is non-empty to show
"AI scoring enabled", and the actual calls go to the FastAPI backend
(`/api/ai/place-analysis`, `/api/ai/review-impact`, in `backend/ai_router.py`),
which uses the server-side `OPENROUTER_API_KEY`. The Pages workflow therefore
passes the literal non-secret marker `backend-proxied` (the same trick
`docker-compose.yml` uses) and never wires a real OpenAI key into the build.
Do not put a real key into that define. If anything ever needs a real LLM key
in the browser, move that call behind the backend instead.

## Quick checklist

- [ ] Hugging Face account + write token
- [ ] `gh secret set HF_TOKEN`, `gh variable set HF_SPACE_ID`
- [ ] Run the Space deploy workflow; set Space secrets (`OPENROUTER_API_KEY`, `OPENROUTESERVICE_API_KEY`, `ALLOWED_ORIGINS`)
- [ ] Pages source = GitHub Actions
- [ ] `gh secret set SUPABASE_URL / SUPABASE_ANON_KEY / GOOGLE_MAPS_API_KEY`, `gh variable set DETECTION_API_BASE_URL`
- [ ] Supabase redirect URL for the Pages origin; Maps key referrer restriction
- [ ] Run the Pages workflow; fill in the live URLs in the README (`TODO(owner)`)
