import math
import os
from typing import Any

import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

ORS_URL = "https://api.openrouteservice.org/v2/directions/driving-car/geojson"
DEFAULT_AVOID_RADIUS_M = 50.0
EARTH_RADIUS_M = 6371000.0


class RoutePoint(BaseModel):
    latitude: float
    longitude: float


class SafeRouteRequest(BaseModel):
    origin: RoutePoint
    destination: RoutePoint
    avoid_points: list[RoutePoint] = []
    avoid_radius_m: float = DEFAULT_AVOID_RADIUS_M


def _ors_key() -> str:
    key = (
        os.getenv("OPENROUTESERVICE_API_KEY")
        or os.getenv("ORS_API_KEY")
        or ""
    ).strip()
    if key.startswith("OPENROUTESERVICE_API_KEY-"):
        key = key.replace("OPENROUTESERVICE_API_KEY-", "", 1)
    if not key:
        raise HTTPException(
            status_code=500,
            detail="OpenRouteService API key is not configured on the backend.",
        )
    return key


def _offset_point(
    latitude: float,
    longitude: float,
    distance_m: float,
    heading_deg: float,
) -> tuple[float, float]:
    lat1 = math.radians(latitude)
    lon1 = math.radians(longitude)
    angular_distance = distance_m / EARTH_RADIUS_M
    heading = math.radians(heading_deg)

    lat2 = math.asin(
        math.sin(lat1) * math.cos(angular_distance)
        + math.cos(lat1) * math.sin(angular_distance) * math.cos(heading)
    )
    lon2 = lon1 + math.atan2(
        math.sin(heading) * math.sin(angular_distance) * math.cos(lat1),
        math.cos(angular_distance) - math.sin(lat1) * math.sin(lat2),
    )

    return math.degrees(lat2), math.degrees(lon2)


def _build_circle_ring(
    latitude: float,
    longitude: float,
    radius_m: float,
    segments: int = 16,
) -> list[list[float]]:
    ring: list[list[float]] = []
    for i in range(segments + 1):
        heading = (i / segments) * 360.0
        lat, lng = _offset_point(latitude, longitude, radius_m, heading)
        ring.append([lng, lat])
    return ring


def _avoid_polygons(
    points: list[RoutePoint],
    radius_m: float,
) -> dict[str, Any] | None:
    if not points:
        return None

    return {
        "type": "MultiPolygon",
        "coordinates": [
            [_build_circle_ring(point.latitude, point.longitude, radius_m)]
            for point in points
        ],
    }


@router.post("/safe-route")
async def safe_route(payload: SafeRouteRequest):
    body: dict[str, Any] = {
        "coordinates": [
            [payload.origin.longitude, payload.origin.latitude],
            [payload.destination.longitude, payload.destination.latitude],
        ],
    }

    avoid_polygons = _avoid_polygons(
        payload.avoid_points,
        max(10.0, min(payload.avoid_radius_m, 200.0)),
    )
    if avoid_polygons is not None:
        body["options"] = {"avoid_polygons": avoid_polygons}

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            ORS_URL,
            headers={
                "Authorization": _ors_key(),
                "Content-Type": "application/json",
            },
            json=body,
        )

    try:
        data = response.json()
    except Exception:
        data = {"raw": response.text}

    if response.status_code >= 400:
        error_message = (
            data.get("error", {}).get("message")
            if isinstance(data.get("error"), dict)
            else data.get("error")
            or data.get("message")
            or response.text
            or f"ORS error {response.status_code}"
        )
        raise HTTPException(status_code=400, detail=str(error_message))

    feature = (data.get("features") or [None])[0]
    geometry = feature.get("geometry") if isinstance(feature, dict) else None
    properties = feature.get("properties") if isinstance(feature, dict) else {}
    summary = properties.get("summary") if isinstance(properties, dict) else {}
    coordinates = geometry.get("coordinates") if isinstance(geometry, dict) else None

    if not coordinates:
        raise HTTPException(
            status_code=400,
            detail="Safe route geometry is unavailable for these points.",
        )

    return {
        "coordinates": coordinates,
        "distance_m": summary.get("distance"),
        "duration_s": summary.get("duration"),
        "avoided_points": len(payload.avoid_points),
    }
