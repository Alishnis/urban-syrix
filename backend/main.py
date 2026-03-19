from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from accident_router import router as accident_router
from fire_router import router as fire_router

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


@app.get("/api/health")
async def health():
    return {"status": "ok"}
