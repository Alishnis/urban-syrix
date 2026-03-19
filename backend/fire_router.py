"""
Fire Detection Router — port of modules/fire-detection/app.py
Uses YOLOv8 fire_model.pt to detect fire in videos and images.
"""
import asyncio
from pathlib import Path
from uuid import uuid4

import cv2
from fastapi import APIRouter, File, UploadFile, HTTPException, Form
from fastapi.responses import FileResponse
from ultralytics import YOLO

router = APIRouter()

BASE_DIR = Path(__file__).resolve().parent
MODULE_DIR = BASE_DIR.parent / "modules" / "fire-detection"
MODEL_PATH = MODULE_DIR / "fire_model.pt"
PREVIEW_DIR = BASE_DIR / "tmp" / "fire_previews"
VIDEO_OUT_DIR = BASE_DIR / "tmp" / "fire_outputs"

# Performance: cap video analysis
MAX_VIDEO_FRAMES = 300  # stop after this many frames

_model = None
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png"}
VIDEO_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv", ".webm"}


def _get_model():
    global _model
    if _model is None:
        if not MODEL_PATH.exists():
            raise FileNotFoundError(f"Fire model not found at {MODEL_PATH}")
        _model = YOLO(str(MODEL_PATH))
    return _model


def _has_allowed_extension(filename: str | None, allowed: set[str]) -> bool:
    if not filename:
        return False
    return Path(filename).suffix.lower() in allowed


def _region_label(
    x1: int,
    y1: int,
    x2: int,
    y2: int,
    frame_width: int,
    frame_height: int,
) -> str:
    center_x = (x1 + x2) / 2
    center_y = (y1 + y2) / 2

    horizontal = (
        "left"
        if center_x < frame_width / 3
        else "right"
        if center_x > frame_width * 2 / 3
        else "center"
    )
    vertical = (
        "top"
        if center_y < frame_height / 3
        else "bottom"
        if center_y > frame_height * 2 / 3
        else "middle"
    )

    return f"{vertical}-{horizontal}"


def _detect_fire_video(video_path: Path, conf_threshold: float = 0.4):
    model = _get_model()
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        return {
            "fire_detected": False, "frames_total": 0, "frames_processed": 0,
            "frames_with_fire": 0, "max_confidence": 0.0, "best_frame_confidence": 0.0,
            "preview_name": None, "video_name": None, "threshold": conf_threshold,
        }

    frame_skip = 5  # only process every 5th frame
    frame_idx = 0
    frames_total = 0
    frames_processed = 0
    frames_with_fire = 0
    max_confidence = 0.0
    best_frame_confidence = 0.0
    best_frame = None
    best_box = None
    fire_detected = False

    try:
        while True:
            success, frame = cap.read()
            if not success:
                break
            frames_total += 1
            if frames_total > MAX_VIDEO_FRAMES:
                break

            if frame_idx % frame_skip != 0:
                frame_idx += 1
                continue

            frame_idx += 1
            frames_processed += 1

            results = model(frame, stream=True, verbose=False, imgsz=640)
            for info in results:
                for box in info.boxes:
                    confidence = float(box.conf[0])
                    cls = int(box.cls[0])
                    max_confidence = max(max_confidence, confidence)
                    if cls == 0 and confidence >= conf_threshold:
                        fire_detected = True
                        frames_with_fire += 1
                        if confidence > best_frame_confidence:
                            best_frame_confidence = confidence
                            # Draw box on best frame for preview
                            annotated = frame.copy()
                            x1, y1, x2, y2 = map(int, box.xyxy[0])
                            best_box = {
                                "x1": x1,
                                "y1": y1,
                                "x2": x2,
                                "y2": y2,
                                "region": _region_label(
                                    x1,
                                    y1,
                                    x2,
                                    y2,
                                    frame.shape[1],
                                    frame.shape[0],
                                ),
                            }
                            cv2.rectangle(annotated, (x1, y1), (x2, y2), (0, 0, 255), 3)
                            label = f"fire {confidence * 100:.1f}%"
                            cv2.putText(annotated, label, (x1, max(y1 - 10, 20)),
                                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2, cv2.LINE_AA)
                            best_frame = annotated
    finally:
        cap.release()

    preview_name = None
    if best_frame is not None:
        PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
        preview_name = f"{uuid4().hex}.jpg"
        cv2.imwrite(str(PREVIEW_DIR / preview_name), best_frame)

    return {
        "fire_detected": fire_detected,
        "frames_total": frames_total,
        "frames_processed": frames_processed,
        "frames_with_fire": frames_with_fire,
        "max_confidence": round(max_confidence, 3),
        "best_frame_confidence": round(best_frame_confidence, 3),
        "preview_name": preview_name,
        "best_box": best_box,
        "video_name": None,
        "threshold": conf_threshold,
    }


def _detect_fire_image(image_path: Path, conf_threshold: float = 0.4):
    model = _get_model()
    image = cv2.imread(str(image_path))
    if image is None:
        return {"fire_detected": False, "max_confidence": 0.0, "preview_name": None, "threshold": conf_threshold}

    max_confidence = 0.0
    fire_detected = False
    annotated = image.copy()
    best_box = None

    results = model(image, stream=True, verbose=False, imgsz=640)
    for info in results:
        for box in info.boxes:
            confidence = float(box.conf[0])
            cls = int(box.cls[0])
            max_confidence = max(max_confidence, confidence)
            if cls == 0 and confidence >= conf_threshold:
                fire_detected = True
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                if best_box is None or confidence >= max_confidence:
                    best_box = {
                        "x1": x1,
                        "y1": y1,
                        "x2": x2,
                        "y2": y2,
                        "region": _region_label(
                            x1,
                            y1,
                            x2,
                            y2,
                            image.shape[1],
                            image.shape[0],
                        ),
                    }
                cv2.rectangle(annotated, (x1, y1), (x2, y2), (0, 0, 255), 3)
                label = f"fire {confidence * 100:.1f}%"
                cv2.putText(annotated, label, (x1, max(y1 - 10, 20)),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2, cv2.LINE_AA)

    preview_name = None
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    preview_name = f"{uuid4().hex}.jpg"
    cv2.imwrite(str(PREVIEW_DIR / preview_name), annotated)

    return {
        "fire_detected": fire_detected,
        "max_confidence": round(max_confidence, 3),
        "preview_name": preview_name,
        "best_box": best_box,
        "threshold": conf_threshold,
    }


# ── Endpoints ──
# Using asyncio.to_thread so blocking YOLO/CV2 code doesn't freeze the server

@router.post("/analyze")
async def analyze_video(file: UploadFile = File(...), sensitivity: float = Form(0.4)):
    if (
        (not file.content_type or not file.content_type.startswith("video/"))
        and not _has_allowed_extension(file.filename, VIDEO_EXTENSIONS)
    ):
        raise HTTPException(status_code=400, detail="Please upload a video file.")

    tmp_dir = BASE_DIR / "tmp" / "fire_uploads"
    tmp_dir.mkdir(parents=True, exist_ok=True)
    tmp_path = tmp_dir / f"{uuid4().hex}_{file.filename}"
    conf = max(0.1, min(sensitivity, 0.9))

    try:
        with tmp_path.open("wb") as f:
            f.write(await file.read())
        stats = await asyncio.to_thread(_detect_fire_video, tmp_path, conf)
        return {"fire_detected": stats["fire_detected"], "stats": stats}
    finally:
        if tmp_path.exists():
            tmp_path.unlink()


@router.post("/analyze-image")
async def analyze_image(file: UploadFile = File(...), sensitivity: float = Form(0.4)):
    if (
        (not file.content_type or not file.content_type.startswith("image/"))
        and not _has_allowed_extension(file.filename, IMAGE_EXTENSIONS)
    ):
        raise HTTPException(status_code=400, detail="Please upload an image file.")

    tmp_dir = BASE_DIR / "tmp" / "fire_uploads"
    tmp_dir.mkdir(parents=True, exist_ok=True)
    tmp_path = tmp_dir / f"{uuid4().hex}_{file.filename}"
    conf = max(0.1, min(sensitivity, 0.9))

    try:
        with tmp_path.open("wb") as f:
            f.write(await file.read())
        stats = await asyncio.to_thread(_detect_fire_image, tmp_path, conf)
        return {"fire_detected": stats["fire_detected"], "stats": stats}
    finally:
        if tmp_path.exists():
            tmp_path.unlink()


@router.get("/preview/{filename}")
async def get_preview(filename: str):
    path = PREVIEW_DIR / filename
    if not path.exists():
        raise HTTPException(status_code=404, detail="Preview not found.")
    return FileResponse(path, media_type="image/jpeg")
