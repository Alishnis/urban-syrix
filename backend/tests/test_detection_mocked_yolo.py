"""Detection endpoints with a mocked YOLO model: no weights, no GPU, no network.

The real `_detect_*` functions (OpenCV decoding, thresholding, region labelling,
preview writing) run against a fake model that returns canned boxes.
"""
import cv2
import numpy as np
import pytest

import accident_router
import fire_router

WIDTH, HEIGHT = 90, 60


def png_bytes():
    ok, buf = cv2.imencode(".png", np.zeros((HEIGHT, WIDTH, 3), dtype=np.uint8))
    assert ok
    return buf.tobytes()


class FakeTensor(list):
    """Minimal stand-in for the one-element tensors ultralytics returns."""


class FakeBox:
    def __init__(self, cls, conf, xyxy):
        self.cls = FakeTensor([cls])
        self.conf = FakeTensor([conf])
        self.xyxy = FakeTensor([xyxy])


class FakeResult:
    names = {0: "person", 2: "car"}

    def __init__(self, boxes):
        self.boxes = boxes


class FakeModel:
    """Callable like a YOLO model; records the keyword arguments it was called with."""

    def __init__(self, boxes=(), error=None):
        self.boxes = list(boxes)
        self.error = error
        self.calls = []

    def __call__(self, image, **kwargs):
        self.calls.append(kwargs)
        if self.error is not None:
            raise self.error
        return [FakeResult(self.boxes)]


@pytest.fixture
def previews(monkeypatch, tmp_path):
    """Redirect uploads and previews into tmp_path so the tests leave nothing behind."""
    for module in (fire_router, accident_router):
        monkeypatch.setattr(module, "BASE_DIR", tmp_path)
        monkeypatch.setattr(module, "PREVIEW_DIR", tmp_path / f"{module.__name__}_previews")
    return tmp_path


def avi_bytes(tmp_path, frames=12):
    """A tiny real video (MJPG/AVI) so OpenCV's decoder runs for real."""
    path = tmp_path / "clip.avi"
    writer = cv2.VideoWriter(str(path), cv2.VideoWriter_fourcc(*"MJPG"), 10, (WIDTH, HEIGHT))
    for _ in range(frames):
        writer.write(np.zeros((HEIGHT, WIDTH, 3), dtype=np.uint8))
    writer.release()
    return path.read_bytes()


def upload(client, url, data=None, content=None, name="photo.png", ctype="image/png"):
    return client.post(url, files={"file": (name, content or png_bytes(), ctype)}, data=data or {})


# --- fire --------------------------------------------------------------------


def test_fire_image_detected_above_threshold(client, monkeypatch, previews):
    model = FakeModel([FakeBox(0, 0.8, [0, 0, 20, 10])])
    monkeypatch.setattr(fire_router, "_model", model)

    resp = upload(client, "/api/fire/analyze-image")

    assert resp.status_code == 200
    body = resp.json()
    assert body["fire_detected"] is True
    stats = body["stats"]
    assert stats["max_confidence"] == 0.8
    assert stats["threshold"] == 0.4
    assert stats["best_box"] == {"x1": 0, "y1": 0, "x2": 20, "y2": 10, "region": "top-left"}
    assert (fire_router.PREVIEW_DIR / stats["preview_name"]).is_file()
    # ... and the preview can be fetched through the API
    assert client.get(f"/api/fire/preview/{stats['preview_name']}").status_code == 200


def test_fire_below_threshold_or_wrong_class_is_not_a_detection(client, monkeypatch, previews):
    monkeypatch.setattr(fire_router, "_model", FakeModel([FakeBox(0, 0.3, [0, 0, 5, 5]), FakeBox(1, 0.95, [0, 0, 5, 5])]))

    stats = upload(client, "/api/fire/analyze-image").json()

    assert stats["fire_detected"] is False
    assert stats["stats"]["best_box"] is None


def test_fire_sensitivity_changes_the_decision(client, monkeypatch, previews):
    monkeypatch.setattr(fire_router, "_model", FakeModel([FakeBox(0, 0.3, [60, 40, 80, 58])]))

    strict = upload(client, "/api/fire/analyze-image", data={"sensitivity": "0.5"}).json()
    lenient = upload(client, "/api/fire/analyze-image", data={"sensitivity": "0.2"}).json()

    assert strict["fire_detected"] is False
    assert lenient["fire_detected"] is True
    assert lenient["stats"]["best_box"]["region"] == "bottom-right"


def test_fire_undecodable_image_returns_not_detected(client, monkeypatch, previews):
    monkeypatch.setattr(fire_router, "_model", FakeModel([FakeBox(0, 0.9, [0, 0, 5, 5])]))

    resp = upload(client, "/api/fire/analyze-image", content=b"definitely not a png")

    assert resp.status_code == 200
    assert resp.json()["fire_detected"] is False


def test_fire_unreadable_video_returns_empty_stats(client, monkeypatch, previews):
    monkeypatch.setattr(fire_router, "_model", FakeModel([FakeBox(0, 0.9, [0, 0, 5, 5])]))

    resp = upload(client, "/api/fire/analyze", content=b"not a video", name="clip.mp4", ctype="video/mp4")

    assert resp.status_code == 200
    assert resp.json()["fire_detected"] is False
    assert resp.json()["stats"]["frames_processed"] == 0


def test_fire_video_samples_every_fifth_frame(client, monkeypatch, previews):
    model = FakeModel([FakeBox(0, 0.8, [0, 0, 20, 10])])
    monkeypatch.setattr(fire_router, "_model", model)

    resp = upload(client, "/api/fire/analyze", content=avi_bytes(previews), name="clip.avi", ctype="video/x-msvideo")

    assert resp.status_code == 200
    stats = resp.json()["stats"]
    assert resp.json()["fire_detected"] is True
    assert stats["frames_total"] == 12
    assert stats["frames_processed"] == 3  # frames 0, 5 and 10
    assert stats["frames_with_fire"] == 3
    assert stats["best_box"]["region"] == "top-left"
    assert len(model.calls) == 3


def test_accident_video_samples_every_fifth_frame(client, monkeypatch, previews):
    monkeypatch.setattr(accident_router, "_accident_model", FakeModel([FakeBox(0, 0.6, [30, 20, 60, 40])]))

    resp = upload(
        client, "/api/accident/analyze-video", content=avi_bytes(previews), name="clip.avi", ctype="video/x-msvideo"
    )

    assert resp.status_code == 200
    stats = resp.json()["stats"]
    assert resp.json()["accident_detected"] is True
    assert (stats["frames_total"], stats["frames_processed"], stats["frames_with_accident"]) == (12, 3, 3)


# --- accident ----------------------------------------------------------------


def test_accident_image_counts_vehicles_and_accident_boxes(client, monkeypatch, previews):
    # The same fake feeds both models: class 2 (car) is a vehicle, and any box is an accident box.
    vehicles = FakeModel([FakeBox(2, 0.9, [10, 10, 30, 30]), FakeBox(0, 0.9, [40, 10, 50, 30])])
    accidents = FakeModel([FakeBox(0, 0.7, [30, 20, 60, 40])])
    monkeypatch.setattr(accident_router, "_vehicle_model", vehicles)
    monkeypatch.setattr(accident_router, "_accident_model", accidents)

    resp = upload(client, "/api/accident/analyze-image", data={"sensitivity": "0.3"})

    assert resp.status_code == 200
    body = resp.json()
    assert body["accident_detected"] is True
    stats = body["stats"]
    assert stats["vehicles_count"] == 1  # the person (class 0) is not a vehicle
    assert stats["accident_boxes"] == 1
    assert stats["max_confidence"] == 0.7
    assert stats["best_box"]["region"] == "middle-center"
    assert accidents.calls[0]["conf"] == 0.3  # sensitivity is forwarded to the model
    assert (accident_router.PREVIEW_DIR / stats["preview_name"]).is_file()


def test_accident_image_without_accident_boxes(client, monkeypatch, previews):
    monkeypatch.setattr(accident_router, "_vehicle_model", FakeModel())
    monkeypatch.setattr(accident_router, "_accident_model", FakeModel())

    body = upload(client, "/api/accident/analyze-image").json()

    assert body["accident_detected"] is False
    assert body["stats"]["accident_boxes"] == 0


# --- model failures ----------------------------------------------------------


@pytest.mark.parametrize(
    "module, attrs, url",
    [
        (fire_router, ["_model"], "/api/fire/analyze-image"),
        (accident_router, ["_vehicle_model", "_accident_model"], "/api/accident/analyze-image"),
    ],
)
def test_model_inference_error_returns_500_and_server_keeps_working(
    client_no_raise, monkeypatch, previews, module, attrs, url
):
    for attr in attrs:
        monkeypatch.setattr(module, attr, FakeModel(error=RuntimeError("CUDA out of memory")))

    failed = upload(client_no_raise, url)
    health = client_no_raise.get("/api/health")

    assert failed.status_code == 500
    assert "CUDA" not in failed.text  # internal details are not echoed to the client
    assert health.status_code == 200


def test_uploads_are_cleaned_up_when_the_model_fails(client_no_raise, monkeypatch, previews):
    monkeypatch.setattr(fire_router, "_model", FakeModel(error=RuntimeError("boom")))

    upload(client_no_raise, "/api/fire/analyze-image")

    uploads = previews / "tmp" / "fire_uploads"
    assert list(uploads.iterdir()) == []


def test_missing_fire_weights_return_500_without_crashing(client_no_raise, monkeypatch, previews):
    monkeypatch.setattr(fire_router, "_model", None)
    monkeypatch.setattr(fire_router, "MODEL_PATH", previews / "does-not-exist.pt")

    resp = upload(client_no_raise, "/api/fire/analyze-image")

    assert resp.status_code == 500
    assert client_no_raise.get("/api/health").status_code == 200


def test_missing_accident_weights_return_500_without_crashing(client_no_raise, monkeypatch, previews):
    monkeypatch.setattr(accident_router, "_vehicle_model", FakeModel())
    monkeypatch.setattr(accident_router, "_accident_model", None)
    monkeypatch.setattr(accident_router, "WEIGHTS_DIR", previews / "empty-weights-dir")

    resp = upload(client_no_raise, "/api/accident/analyze-image")

    assert resp.status_code == 500
    assert client_no_raise.get("/api/health").status_code == 200
