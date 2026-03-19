"""
Accident Detection Router — port of modules/traffic-accident-detection
Uses YOLOv8 best-versi-1.pt to detect traffic accidents in images and videos.
Also detects vehicles (cars, trucks, buses, motorcycles, bicycles) for context.
"""
import asyncio
from pathlib import Path
from uuid import uuid4
import math

import cv2
from fastapi import APIRouter, File, UploadFile, HTTPException, Form
from fastapi.responses import FileResponse
from ultralytics import YOLO

router = APIRouter()

BASE_DIR = Path(__file__).resolve().parent
MODULE_DIR = BASE_DIR.parent / "modules" / "traffic-accident-detection"
WEIGHTS_DIR = MODULE_DIR / "YOLO-Weights"
PREVIEW_DIR = BASE_DIR / "tmp" / "accident_previews"

VEHICLE_CLASS_IDS = {1, 2, 3, 5, 7}  # bicycle, car, motorcycle, bus, truck
COLOR_VEHICLE = (0, 255, 100)
COLOR_ACCIDENT = (0, 100, 255)

# Performance: cap video analysis
MAX_VIDEO_FRAMES = 300

_vehicle_model = None
_accident_model = None
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png"}
VIDEO_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv", ".webm"}


def _get_vehicle_model():
    global _vehicle_model
    if _vehicle_model is None:
        _vehicle_model = YOLO("yolov8n.pt")
    return _vehicle_model


def _get_accident_model():
    global _accident_model
    if _accident_model is None:
        for w in ["best-versi-1.pt", "yolov8m-dataset-7000-300.pt"]:
            p = WEIGHTS_DIR / w
            if p.exists():
                _accident_model = YOLO(str(p))
                break
        if _accident_model is None:
            raise FileNotFoundError(f"No accident model found in {WEIGHTS_DIR}")
    return _accident_model


def _has_allowed_extension(filename: str | None, allowed: set[str]) -> bool:
    if not filename:
        return False
    return Path(filename).suffix.lower() in allowed


def _draw_box(frame, x1, y1, x2, y2, label, color, thickness=2):
    t_size = cv2.getTextSize(label, 0, fontScale=0.6, thickness=1)[0]
    c2 = x1 + t_size[0], y1 - t_size[1] - 4
    cv2.rectangle(frame, (x1, y1), (x2, y2), color, thickness)
    cv2.rectangle(frame, (x1, y1), c2, color, -1, cv2.LINE_AA)
    cv2.putText(frame, label, (x1, y1 - 2), 0, 0.6, [255, 255, 255], thickness=1, lineType=cv2.LINE_AA)


def _detect_accident_image(image_path: Path, conf_threshold: float = 0.2):
    vehicle_model = _get_vehicle_model()
    accident_model = _get_accident_model()

    img = cv2.imread(str(image_path))
    if img is None:
        return {
            "accident_detected": False, "vehicles_count": 0,
            "max_confidence": 0.0, "preview_name": None, "threshold": conf_threshold,
        }

    annotated = img.copy()
    vehicles_count = 0
    accident_detected = False
    max_confidence = 0.0
    accident_boxes = 0

    # Detect vehicles — imgsz=640, no augment
    for r in vehicle_model(img, stream=True, conf=0.35, verbose=False, imgsz=640):
        for box in r.boxes:
            cls = int(box.cls[0])
            if cls in VEHICLE_CLASS_IDS:
                vehicles_count += 1
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                conf = math.ceil(float(box.conf[0]) * 100) / 100
                _draw_box(annotated, x1, y1, x2, y2, f"{r.names[cls]} {conf}", COLOR_VEHICLE, 2)

    # Detect accidents — imgsz=640, NO augment (augment=True triples time)
    for r in accident_model(img, stream=True, conf=conf_threshold, imgsz=640, verbose=False):
        for box in r.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            conf = float(box.conf[0])
            max_confidence = max(max_confidence, conf)
            accident_detected = True
            accident_boxes += 1
            _draw_box(annotated, x1, y1, x2, y2, f"Accident {math.ceil(conf * 100) / 100}", COLOR_ACCIDENT, 3)

    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    preview_name = f"{uuid4().hex}.jpg"
    cv2.imwrite(str(PREVIEW_DIR / preview_name), annotated)

    return {
        "accident_detected": accident_detected,
        "vehicles_count": vehicles_count,
        "accident_boxes": accident_boxes,
        "max_confidence": round(max_confidence, 3),
        "preview_name": preview_name,
        "threshold": conf_threshold,
    }


def _detect_accident_video(video_path: Path, conf_threshold: float = 0.2):
    vehicle_model = _get_vehicle_model()
    accident_model = _get_accident_model()

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        return {
            "accident_detected": False, "frames_total": 0, "frames_processed": 0,
            "frames_with_accident": 0, "max_confidence": 0.0, "preview_name": None,
            "threshold": conf_threshold,
        }

    frame_skip = 5  # only process every 5th frame
    frame_idx = 0
    frames_total = 0
    frames_processed = 0
    frames_with_accident = 0
    max_confidence = 0.0
    best_frame_conf = 0.0
    best_frame = None
    accident_detected = False

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

            # Only run accident model (skip vehicle detection for speed)
            frame_accident = False
            for r in accident_model(frame, stream=True, conf=conf_threshold, imgsz=640, verbose=False):
                for box in r.boxes:
                    conf = float(box.conf[0])
                    max_confidence = max(max_confidence, conf)
                    frame_accident = True
                    accident_detected = True

            if frame_accident:
                frames_with_accident += 1
                if max_confidence > best_frame_conf:
                    best_frame_conf = max_confidence
                    # Annotate this frame for preview
                    annotated = frame.copy()
                    for r in accident_model(frame, stream=True, conf=conf_threshold, imgsz=640, verbose=False):
                        for box in r.boxes:
                            x1, y1, x2, y2 = map(int, box.xyxy[0])
                            c = float(box.conf[0])
                            _draw_box(annotated, x1, y1, x2, y2, f"Accident {math.ceil(c * 100) / 100}", COLOR_ACCIDENT, 3)
                    best_frame = annotated
    finally:
        cap.release()

    preview_name = None
    if best_frame is not None:
        PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
        preview_name = f"{uuid4().hex}.jpg"
        cv2.imwrite(str(PREVIEW_DIR / preview_name), best_frame)

    return {
        "accident_detected": accident_detected,
        "frames_total": frames_total,
        "frames_processed": frames_processed,
        "frames_with_accident": frames_with_accident,
        "max_confidence": round(max_confidence, 3),
        "preview_name": preview_name,
        "threshold": conf_threshold,
    }


# ── Endpoints ──
# Using asyncio.to_thread so blocking YOLO/CV2 code doesn't freeze the server

@router.post("/analyze-image")
async def analyze_image(file: UploadFile = File(...), sensitivity: float = Form(0.2)):
    if (
        (not file.content_type or not file.content_type.startswith("image/"))
        and not _has_allowed_extension(file.filename, IMAGE_EXTENSIONS)
    ):
        raise HTTPException(status_code=400, detail="Please upload an image file.")

    tmp_dir = BASE_DIR / "tmp" / "accident_uploads"
    tmp_dir.mkdir(parents=True, exist_ok=True)
    tmp_path = tmp_dir / f"{uuid4().hex}_{file.filename}"
    conf = max(0.05, min(sensitivity, 0.9))

    try:
        with tmp_path.open("wb") as f:
            f.write(await file.read())
        stats = await asyncio.to_thread(_detect_accident_image, tmp_path, conf)
        return {"accident_detected": stats["accident_detected"], "stats": stats}
    finally:
        if tmp_path.exists():
            tmp_path.unlink()


@router.post("/analyze-video")
async def analyze_video(file: UploadFile = File(...), sensitivity: float = Form(0.2)):
    if (
        (not file.content_type or not file.content_type.startswith("video/"))
        and not _has_allowed_extension(file.filename, VIDEO_EXTENSIONS)
    ):
        raise HTTPException(status_code=400, detail="Please upload a video file.")

    tmp_dir = BASE_DIR / "tmp" / "accident_uploads"
    tmp_dir.mkdir(parents=True, exist_ok=True)
    tmp_path = tmp_dir / f"{uuid4().hex}_{file.filename}"
    conf = max(0.05, min(sensitivity, 0.9))

    try:
        with tmp_path.open("wb") as f:
            f.write(await file.read())
        stats = await asyncio.to_thread(_detect_accident_video, tmp_path, conf)
        return {"accident_detected": stats["accident_detected"], "stats": stats}
    finally:
        if tmp_path.exists():
            tmp_path.unlink()


@router.get("/preview/{filename}")
async def get_preview(filename: str):
    path = PREVIEW_DIR / filename
    if not path.exists():
        raise HTTPException(status_code=404, detail="Preview not found.")
    return FileResponse(path, media_type="image/jpeg")
