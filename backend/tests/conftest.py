"""Shared fixtures for the backend test-suite.

Nothing here talks to the network or loads a YOLO model:
* `ultralytics` is replaced by a stub when it is not installed (CI installs only
  requirements-test.txt); with the full requirements it is imported for real
  but models are still never instantiated because tests patch the detectors.
* Third-party HTTP calls (OpenRouteService, OpenRouter) are replaced by
  `FakeAsyncClient`, which records the request and returns a canned response.
"""
import sys
import types

import pytest

try:  # pragma: no cover - depends on the environment
    import ultralytics  # noqa: F401
except ImportError:  # pragma: no cover
    stub = types.ModuleType("ultralytics")

    class YOLO:  # minimal stand-in; never called by the tests
        def __init__(self, *args, **kwargs):
            raise RuntimeError("YOLO is stubbed in tests")

    stub.YOLO = YOLO
    sys.modules["ultralytics"] = stub

import dotenv  # noqa: E402

# Keep the suite hermetic: never read a developer's real .env during tests.
dotenv.load_dotenv = lambda *args, **kwargs: False

from fastapi.testclient import TestClient  # noqa: E402

import main  # noqa: E402


class FakeResponse:
    def __init__(self, status_code=200, json_data=None, text=""):
        self.status_code = status_code
        self._json = json_data
        self.text = text

    def json(self):
        if self._json is None:
            raise ValueError("no json")
        return self._json


class FakeAsyncClient:
    """Drop-in replacement for httpx.AsyncClient that records POST calls."""

    response = FakeResponse(200, {})
    calls: list[dict] = []

    def __init__(self, *args, **kwargs):
        pass

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    async def post(self, url, headers=None, json=None, **kwargs):
        type(self).calls.append({"url": url, "headers": headers or {}, "json": json})
        return type(self).response


@pytest.fixture
def client():
    return TestClient(main.app)


@pytest.fixture
def fake_http(monkeypatch):
    """Patch httpx.AsyncClient in both routers that call third-party APIs."""
    import ai_router
    import route_router

    FakeAsyncClient.calls = []
    FakeAsyncClient.response = FakeResponse(200, {})
    monkeypatch.setattr(route_router.httpx, "AsyncClient", FakeAsyncClient)
    monkeypatch.setattr(ai_router.httpx, "AsyncClient", FakeAsyncClient)
    return FakeAsyncClient


@pytest.fixture
def ors_key(monkeypatch):
    monkeypatch.setenv("OPENROUTESERVICE_API_KEY", "test-ors-key")
    monkeypatch.delenv("ORS_API_KEY", raising=False)


@pytest.fixture
def openrouter_key(monkeypatch):
    monkeypatch.setenv("OPENROUTER_API_KEY", "test-openrouter-key")
