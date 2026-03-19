from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from accident_router import router as accident_router
from fire_router import router as fire_router
from route_router import router as route_router

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

app = FastAPI(title="urban syrix detection backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(fire_router, prefix="/api/fire", tags=["Fire Detection"])
app.include_router(
    accident_router,
    prefix="/api/accident",
    tags=["Accident Detection"],
)
app.include_router(route_router, prefix="/api/route", tags=["Safe Routing"])


@app.get("/api/health")
async def health():
    return {"status": "ok"}
