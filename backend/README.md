## Detection Backend

This folder contains the FastAPI backend needed by `urban syrix` for:

- `POST /api/fire/analyze`
- `POST /api/fire/analyze-image`
- `POST /api/accident/analyze-image`
- `POST /api/accident/analyze-video`

### Local run

```bash
cd /Users/aliserromankul/Desktop/arsen/hackathon_net/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

Flutter web uses `http://localhost:8001` by default for detection in local development.
