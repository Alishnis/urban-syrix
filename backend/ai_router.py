import os
from typing import Any

import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
MODEL = "deepseek/deepseek-v4-flash"


def _openrouter_key() -> str:
    key = (os.getenv("OPENROUTER_API_KEY") or "").strip()
    if not key:
        raise HTTPException(
            status_code=500,
            detail="OpenRouter API key is not configured on the backend.",
        )
    return key


async def _call_openrouter(system_text: str, user_text: str, schema: dict[str, Any]) -> dict[str, Any]:
    schema_prompt = (
        f"{system_text}\n\n"
        "Respond with only a single JSON object (no markdown, no commentary) matching this shape: "
        f"{schema}"
    )
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            OPENROUTER_URL,
            headers={
                "Authorization": f"Bearer {_openrouter_key()}",
                "Content-Type": "application/json",
            },
            json={
                "model": MODEL,
                "messages": [
                    {"role": "system", "content": schema_prompt},
                    {"role": "user", "content": user_text},
                ],
                "response_format": {"type": "json_object"},
            },
        )

    try:
        payload = response.json()
    except Exception:
        payload = {"raw": response.text}

    if response.status_code >= 400:
        error_message = (
            payload.get("error", {}).get("message")
            if isinstance(payload.get("error"), dict)
            else payload.get("error") or response.text or f"OpenRouter error {response.status_code}"
        )
        raise HTTPException(status_code=400, detail=str(error_message))

    return payload


def _extract_output_text(payload: dict[str, Any]) -> str:
    choices = payload.get("choices") or []
    if choices:
        message = choices[0].get("message") or {}
        content = message.get("content")
        if isinstance(content, str):
            return content
    return "{}"


class PlaceAnalysisRequest(BaseModel):
    name: str
    type_label: str
    incident_subtype_label: str | None = None
    address: str
    description: str


PLACE_ASSESSMENT_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "description": {"type": "string"},
        "mobility": {"type": "integer"},
        "environment": {"type": "integer"},
        "resources": {"type": "integer"},
        "transparency": {"type": "integer"},
        "inclusivity": {"type": "integer"},
        "safety": {"type": "integer"},
        "traffic_risk": {"type": "integer"},
        "co2_footprint": {"type": "integer"},
        "green_coverage": {"type": "integer"},
    },
    "required": [
        "description",
        "mobility",
        "environment",
        "resources",
        "transparency",
        "inclusivity",
        "safety",
        "traffic_risk",
        "co2_footprint",
        "green_coverage",
    ],
}


@router.post("/place-analysis")
async def place_analysis(payload: PlaceAnalysisRequest):
    system_text = (
        "You are an urban planning analyst. Return concise, realistic ratings for city locations. "
        "Assess the location using these criteria: mobility, environment, resources, transparency, inclusivity, safety. "
        "Every score must be an integer from 0 to 100. "
        "Rewrite the description into one polished sentence in English for a product demo. "
        "Be realistic for the place type and avoid hype. "
        "Use the textual evidence directly. "
        "If the description explicitly mentions strong transit access, safe pedestrian access, bike parking, drop-off zones, or barrier-free circulation, mobility should usually be high (75-95). "
        "If the description explicitly mentions energy efficiency, water-saving systems, recycling, waste sorting, or efficient building systems, resources should usually be high (75-95). "
        "If the description explicitly mentions accessibility for disabled people, step-free entrances, tactile navigation, wide aisles, inclusive design, accessible counters, or use by people of different ages and abilities, inclusivity should usually be high (75-95). "
        "Do not default those categories to medium when the description gives direct evidence."
    )
    user_text = (
        "Analyze this place.\n"
        f"Name: {payload.name}\n"
        f"Type: {payload.type_label}\n"
        f"Incident subtype: {payload.incident_subtype_label or 'n/a'}\n"
        f"Address: {payload.address}\n"
        f"Description: {payload.description}"
    )
    response = await _call_openrouter(system_text, user_text, PLACE_ASSESSMENT_SCHEMA)
    return {"output_text": _extract_output_text(response)}


class ReviewImpactRequest(BaseModel):
    place_name: str
    place_type_label: str
    place_address: str
    place_description: str
    selected_category_label: str
    message: str


REVIEW_IMPACT_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "sentiment": {"type": "integer"},
        "mobility": {"type": "integer"},
        "environment": {"type": "integer"},
        "resources": {"type": "integer"},
        "transparency": {"type": "integer"},
        "inclusivity": {"type": "integer"},
        "safety": {"type": "integer"},
    },
    "required": [
        "sentiment",
        "mobility",
        "environment",
        "resources",
        "transparency",
        "inclusivity",
        "safety",
    ],
}


@router.post("/review-impact")
async def review_impact(payload: ReviewImpactRequest):
    system_text = (
        "You analyze citizen feedback for urban projects. "
        "Return a structured sentiment and numeric score impact for these categories: "
        "mobility, environment, resources, transparency, inclusivity, safety. "
        "Each impact must be an integer between -12 and 12, where negative lowers the score and positive raises it. "
        "Stay realistic and conservative. Only reflect concerns actually present in the comment."
    )
    user_text = (
        f"Project: {payload.place_name}\n"
        f"Type: {payload.place_type_label}\n"
        f"Address: {payload.place_address}\n"
        f"Current description: {payload.place_description}\n"
        f"User selected category: {payload.selected_category_label}\n"
        f"Comment: {payload.message}"
    )
    response = await _call_openrouter(system_text, user_text, REVIEW_IMPACT_SCHEMA)
    return {"output_text": _extract_output_text(response)}
