"""Input validation on every public endpoint (no third-party calls are made)."""
import pytest

from conftest import FakeResponse

VALID_POINT = {"latitude": 43.24, "longitude": 76.89}


def test_health(client):
    resp = client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


# --- /api/route/safe-route -------------------------------------------------


@pytest.mark.parametrize(
    "body",
    [
        {},  # nothing
        {"origin": VALID_POINT},  # destination missing
        {"origin": {"latitude": 1}, "destination": VALID_POINT},  # longitude missing
        {"origin": {"latitude": "north", "longitude": 1}, "destination": VALID_POINT},  # not a number
        {"origin": VALID_POINT, "destination": VALID_POINT, "avoid_points": "nope"},  # wrong type
        {"origin": VALID_POINT, "destination": VALID_POINT, "avoid_points": [{"latitude": 1}]},
        {"origin": VALID_POINT, "destination": VALID_POINT, "avoid_radius_m": "wide"},
    ],
)
def test_safe_route_rejects_malformed_bodies(client, fake_http, ors_key, body):
    resp = client.post("/api/route/safe-route", json=body)

    assert resp.status_code == 422
    assert fake_http.calls == [], "invalid input must never reach OpenRouteService"


def test_safe_route_rejects_non_json_body(client, fake_http, ors_key):
    resp = client.post("/api/route/safe-route", content="not json", headers={"content-type": "application/json"})
    assert resp.status_code == 422


# --- /api/ai/* -------------------------------------------------------------


def test_place_analysis_requires_all_fields(client, fake_http, openrouter_key):
    resp = client.post("/api/ai/place-analysis", json={"name": "Park"})

    assert resp.status_code == 422
    assert fake_http.calls == []


def test_review_impact_requires_all_fields(client, fake_http, openrouter_key):
    assert client.post("/api/ai/review-impact", json={"message": "hi"}).status_code == 422
    assert fake_http.calls == []


def test_ai_endpoints_return_500_when_key_missing(client, fake_http, monkeypatch):
    monkeypatch.delenv("OPENROUTER_API_KEY", raising=False)
    body = {
        "name": "Library",
        "type_label": "Building",
        "address": "1 Main St",
        "description": "Step-free entrance",
    }

    resp = client.post("/api/ai/place-analysis", json=body)

    assert resp.status_code == 500
    assert "not configured" in resp.json()["detail"]
    assert fake_http.calls == []


PLACE_BODY = {
    "name": "Library",
    "type_label": "Building",
    "address": "1 Main St",
    "description": "Step-free entrance and bike parking",
}


def test_place_analysis_proxies_openrouter_and_returns_output_text(client, fake_http, openrouter_key):
    fake_http.response = FakeResponse(200, {"choices": [{"message": {"content": '{"mobility": 80}'}}]})

    resp = client.post("/api/ai/place-analysis", json=PLACE_BODY)

    assert resp.status_code == 200
    assert resp.json() == {"output_text": '{"mobility": 80}'}
    call = fake_http.calls[0]
    assert call["headers"]["Authorization"] == "Bearer test-openrouter-key"
    assert call["json"]["response_format"] == {"type": "json_object"}
    assert "Library" in call["json"]["messages"][1]["content"]


def test_review_impact_proxies_openrouter(client, fake_http, openrouter_key):
    fake_http.response = FakeResponse(200, {"choices": [{"message": {"content": '{"sentiment": -3}'}}]})

    resp = client.post(
        "/api/ai/review-impact",
        json={
            "place_name": "Bridge",
            "place_type_label": "Infrastructure",
            "place_address": "River St",
            "place_description": "Old bridge",
            "selected_category_label": "Safety",
            "message": "Railing is broken",
        },
    )

    assert resp.status_code == 200
    assert resp.json() == {"output_text": '{"sentiment": -3}'}


def test_openrouter_error_is_reported_as_400(client, fake_http, openrouter_key):
    fake_http.response = FakeResponse(401, {"error": {"message": "invalid key"}})

    resp = client.post("/api/ai/place-analysis", json=PLACE_BODY)

    assert resp.status_code == 400
    assert resp.json()["detail"] == "invalid key"


def test_empty_openrouter_choices_fall_back_to_empty_json(client, fake_http, openrouter_key):
    fake_http.response = FakeResponse(200, {"choices": []})

    resp = client.post("/api/ai/place-analysis", json=PLACE_BODY)

    assert resp.json() == {"output_text": "{}"}


# --- fire / accident upload endpoints ---------------------------------------

UPLOAD_ENDPOINTS = [
    ("/api/fire/analyze", "video"),
    ("/api/fire/analyze-image", "image"),
    ("/api/accident/analyze-image", "image"),
    ("/api/accident/analyze-video", "video"),
]


@pytest.mark.parametrize("url, kind", UPLOAD_ENDPOINTS)
def test_upload_endpoints_reject_wrong_file_type(client, url, kind):
    resp = client.post(url, files={"file": ("notes.txt", b"hello", "text/plain")})

    assert resp.status_code == 400
    assert f"Please upload a{'n' if kind == 'image' else ''} {kind} file." == resp.json()["detail"]


@pytest.mark.parametrize("url, kind", UPLOAD_ENDPOINTS)
def test_upload_endpoints_require_a_file(client, url, kind):
    assert client.post(url).status_code == 422


@pytest.mark.parametrize("url", ["/api/fire/preview/missing.jpg", "/api/accident/preview/missing.jpg"])
def test_missing_preview_returns_404(client, url):
    assert client.get(url).status_code == 404


@pytest.mark.parametrize(
    "module_name, url",
    [("fire_router", "/api/fire/preview/%2e%2e"), ("accident_router", "/api/accident/preview/%2e%2e")],
)
def test_preview_of_a_directory_returns_404_not_500(client, monkeypatch, tmp_path, module_name, url):
    # Regression: `..` exists on disk, so it used to reach FileResponse and crash (500).
    import importlib

    previews = tmp_path / "previews"
    previews.mkdir()
    monkeypatch.setattr(importlib.import_module(module_name), "PREVIEW_DIR", previews)

    assert client.get(url).status_code == 404


def test_existing_preview_is_served(client, monkeypatch, tmp_path):
    import fire_router

    (tmp_path / "abc.jpg").write_bytes(b"\xff\xd8jpeg")
    monkeypatch.setattr(fire_router, "PREVIEW_DIR", tmp_path)

    resp = client.get("/api/fire/preview/abc.jpg")

    assert resp.status_code == 200
    assert resp.headers["content-type"] == "image/jpeg"


def test_image_upload_runs_detector_and_clamps_sensitivity(client, monkeypatch):
    import fire_router

    seen = {}

    def fake_detect(path, conf):
        seen["conf"] = conf
        seen["name"] = path.name
        return {"fire_detected": True, "max_confidence": 0.91, "preview_name": None, "threshold": conf}

    monkeypatch.setattr(fire_router, "_detect_fire_image", fake_detect)

    resp = client.post(
        "/api/fire/analyze-image",
        files={"file": ("../../etc/photo.jpg", b"\xff\xd8fake", "image/jpeg")},
        data={"sensitivity": "5"},
    )

    assert resp.status_code == 200
    assert resp.json()["fire_detected"] is True
    assert seen["conf"] == 0.9  # clamped to the 0.9 maximum
    # Regression: client-supplied directory parts used to cause a 500; now they are stripped.
    assert seen["name"].endswith("_photo.jpg")


def test_accident_image_upload_clamps_sensitivity_to_minimum(client, monkeypatch):
    import accident_router

    seen = {}

    def fake_detect(path, conf):
        seen["conf"] = conf
        return {"accident_detected": False, "vehicles_count": 0, "max_confidence": 0.0, "preview_name": None}

    monkeypatch.setattr(accident_router, "_detect_accident_image", fake_detect)

    resp = client.post(
        "/api/accident/analyze-image",
        files={"file": ("crash.png", b"fake", "image/png")},
        data={"sensitivity": "0"},
    )

    assert resp.status_code == 200
    assert resp.json()["accident_detected"] is False
    assert seen["conf"] == 0.05


def test_extension_is_accepted_when_content_type_is_missing(client, monkeypatch):
    import fire_router

    monkeypatch.setattr(
        fire_router, "_detect_fire_video", lambda path, conf: {"fire_detected": False, "frames_total": 0}
    )

    resp = client.post("/api/fire/analyze", files={"file": ("clip.mp4", b"x", "application/octet-stream")})

    assert resp.status_code == 200


def test_uploaded_temp_file_is_removed_after_analysis(client, monkeypatch):
    import fire_router

    paths = []

    def fake_detect(path, conf):
        paths.append(path)
        assert path.exists()
        return {"fire_detected": False}

    monkeypatch.setattr(fire_router, "_detect_fire_image", fake_detect)

    client.post("/api/fire/analyze-image", files={"file": ("a.jpg", b"x", "image/jpeg")})

    assert paths and not paths[0].exists()


def test_cors_origins_are_configurable(monkeypatch):
    """ALLOWED_ORIGINS is read at import time; reload main to apply it."""
    import importlib

    import main as main_module
    from fastapi.testclient import TestClient

    monkeypatch.setenv("ALLOWED_ORIGINS", "https://a.example, https://b.example")
    reloaded = importlib.reload(main_module)
    try:
        c = TestClient(reloaded.app)
        ok = c.get("/api/health", headers={"Origin": "https://b.example"})
        other = c.get("/api/health", headers={"Origin": "https://evil.example"})
        assert ok.headers.get("access-control-allow-origin") == "https://b.example"
        assert "access-control-allow-origin" not in other.headers
    finally:
        monkeypatch.delenv("ALLOWED_ORIGINS", raising=False)
        importlib.reload(main_module)
