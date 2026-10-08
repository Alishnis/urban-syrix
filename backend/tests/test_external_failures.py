"""Third-party failures (OpenRouteService, OpenRouter): clear status + message, never an unhandled crash.

httpx is replaced by `FakeAsyncClient`, so no network is used.
"""
import httpx
import pytest

from conftest import FakeResponse

ROUTE_BODY = {
    "origin": {"latitude": 43.2389, "longitude": 76.8897},
    "destination": {"latitude": 43.2567, "longitude": 76.9286},
    "avoid_points": [{"latitude": 43.245, "longitude": 76.90}],
}
PLACE_BODY = {
    "name": "Library",
    "type_label": "Building",
    "address": "1 Main St",
    "description": "Step-free entrance",
}
REVIEW_BODY = {
    "place_name": "Bridge",
    "place_type_label": "Infrastructure",
    "place_address": "River St",
    "place_description": "Old bridge",
    "selected_category_label": "Safety",
    "message": "Railing is broken",
}

# (url, request body, name of the key fixture that must be active)
SERVICES = {
    "ors": ("/api/route/safe-route", ROUTE_BODY, "ors_key", "OpenRouteService"),
    "openrouter_place": ("/api/ai/place-analysis", PLACE_BODY, "openrouter_key", "OpenRouter"),
    "openrouter_review": ("/api/ai/review-impact", REVIEW_BODY, "openrouter_key", "OpenRouter"),
}


@pytest.fixture(params=list(SERVICES))
def service(request, fake_http, ors_key, openrouter_key):
    url, body, _, name = SERVICES[request.param]
    return url, body, name, fake_http


def test_upstream_timeout_returns_504_with_message(client, service):
    url, body, name, fake_http = service
    fake_http.error = httpx.ReadTimeout("timed out")

    resp = client.post(url, json=body)

    assert resp.status_code == 504
    assert resp.json()["detail"] == f"{name} timed out."


def test_upstream_connection_error_returns_502_with_message(client, service):
    url, body, name, fake_http = service
    fake_http.error = httpx.ConnectError("connection refused")

    resp = client.post(url, json=body)

    assert resp.status_code == 502
    assert resp.json()["detail"] == f"{name} is unreachable."


@pytest.mark.parametrize("status", [500, 502, 503])
def test_upstream_5xx_with_json_error_is_surfaced_as_400(client, service, status):
    url, body, _, fake_http = service
    fake_http.response = FakeResponse(status, {"error": {"message": "upstream exploded"}})

    resp = client.post(url, json=body)

    assert resp.status_code == 400
    assert resp.json()["detail"] == "upstream exploded"


def test_upstream_5xx_with_html_body_does_not_crash(client, service):
    url, body, _, fake_http = service
    fake_http.response = FakeResponse(502, None, text="<html>Bad Gateway</html>")

    resp = client.post(url, json=body)

    assert resp.status_code == 400
    assert resp.json()["detail"] == "<html>Bad Gateway</html>"


def test_upstream_5xx_with_string_error_field(client, service):
    url, body, _, fake_http = service
    fake_http.response = FakeResponse(503, {"error": "service unavailable"})

    resp = client.post(url, json=body)

    assert resp.status_code == 400
    assert resp.json()["detail"] == "service unavailable"


def test_upstream_5xx_with_empty_body_still_gives_a_message(client, service):
    url, body, _, fake_http = service
    fake_http.response = FakeResponse(500, None, text="")

    resp = client.post(url, json=body)

    assert resp.status_code == 400
    assert resp.json()["detail"]  # non-empty


# --- OpenRouteService: a 200 that is not a usable route ----------------------


@pytest.mark.parametrize(
    "response",
    [
        FakeResponse(200, None, text="<html>not json</html>"),  # invalid JSON
        FakeResponse(200, ["unexpected", "list"]),  # JSON, but not an object
        FakeResponse(200, {"features": [{"geometry": None}]}),  # feature without geometry
        FakeResponse(200, {"features": [{"geometry": {"coordinates": []}}]}),  # empty route
        FakeResponse(200, {}),
    ],
    ids=["invalid-json", "json-list", "no-geometry", "empty-coordinates", "empty-object"],
)
def test_ors_200_without_a_route_returns_400(client, fake_http, ors_key, response):
    fake_http.response = response

    resp = client.post("/api/route/safe-route", json=ROUTE_BODY)

    assert resp.status_code == 400
    assert resp.json()["detail"] == "Safe route geometry is unavailable for these points."


def test_ors_route_with_missing_summary_returns_null_totals(client, fake_http, ors_key):
    fake_http.response = FakeResponse(200, {"features": [{"geometry": {"coordinates": [[1, 2], [3, 4]]}}]})

    resp = client.post("/api/route/safe-route", json=ROUTE_BODY)

    assert resp.status_code == 200
    assert resp.json() == {
        "coordinates": [[1, 2], [3, 4]],
        "distance_m": None,
        "duration_s": None,
        "avoided_points": 1,
    }


# --- OpenRouter specifics ----------------------------------------------------


@pytest.mark.parametrize("key", ["", "   "])
def test_blank_openrouter_key_is_treated_as_missing(client, fake_http, monkeypatch, key):
    monkeypatch.setenv("OPENROUTER_API_KEY", key)

    resp = client.post("/api/ai/review-impact", json=REVIEW_BODY)

    assert resp.status_code == 500
    assert resp.json()["detail"] == "OpenRouter API key is not configured on the backend."
    assert fake_http.calls == []


@pytest.mark.parametrize(
    "response",
    [
        FakeResponse(200, None, text="<html>not json</html>"),
        FakeResponse(200, ["unexpected"]),
        FakeResponse(200, {"choices": [{"message": {"content": None}}]}),
        FakeResponse(200, {"choices": [{}]}),
    ],
    ids=["invalid-json", "json-list", "null-content", "no-message"],
)
def test_openrouter_200_without_content_falls_back_to_empty_json(client, fake_http, openrouter_key, response):
    fake_http.response = response

    resp = client.post("/api/ai/place-analysis", json=PLACE_BODY)

    assert resp.status_code == 200
    assert resp.json() == {"output_text": "{}"}


def test_upstream_secrets_are_not_leaked_in_error_responses(client, fake_http, openrouter_key):
    fake_http.error = httpx.ConnectError("connect failed for Bearer test-openrouter-key")

    resp = client.post("/api/ai/place-analysis", json=PLACE_BODY)

    assert "test-openrouter-key" not in resp.text
