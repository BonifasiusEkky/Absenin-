import os
import tempfile
from typing import Optional, Dict, Any

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
from deepface import DeepFace
try:
    from deepface.detectors import FaceDetector  
except Exception:
    FaceDetector = None  # Fallback

_BASE_HOME = os.path.expanduser("~")
env_home = os.environ.get("DEEPFACE_HOME")
if env_home:
    # If DEEPFACE_HOME erroneously points to the .deepface directory, normalize it back to the base home
    norm = env_home.replace("\\", "/").rstrip("/")
    if norm.endswith("/.deepface"):
        os.environ["DEEPFACE_HOME"] = os.path.dirname(env_home)
else:
    os.environ["DEEPFACE_HOME"] = _BASE_HOME

# Our resolved DeepFace directory and weights path
DEEPFACE_DIR = os.path.join(os.environ.get("DEEPFACE_HOME", _BASE_HOME), ".deepface")
WEIGHTS_DIR = os.path.join(DEEPFACE_DIR, "weights")
os.makedirs(WEIGHTS_DIR, exist_ok=True)
try:
    # Hint DeepFace to use the resolved directory directly
    DeepFace.home = DEEPFACE_DIR  # type: ignore[attr-defined]
except Exception:
    pass

# Configurable defaults (env overridable)
DEFAULT_MODEL_NAME = os.environ.get("FACE_MODEL", "ArcFace")
DEFAULT_DETECTOR_BACKEND = os.environ.get("FACE_DETECTOR", "retinaface")
DEFAULT_DISTANCE_METRIC = os.environ.get("FACE_DISTANCE", "cosine")

app = FastAPI(title="Face Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def clamp(value: float, min_v: float = 0.0, max_v: float = 1.0) -> float:
    return max(min_v, min(max_v, value))


def compute_confidence(distance: float, threshold: Optional[float]) -> Optional[float]:
    if threshold is None or threshold == 0:
        return None
    return clamp(1.0 - (distance / threshold))


@app.get("/health")
async def health():
    return {"ok": True}


def _weights_status() -> Dict[str, Any]:
    weights_dir = WEIGHTS_DIR
    arcface_path = os.path.join(weights_dir, "arcface_weights.h5")
    retinaface_path = os.path.join(weights_dir, "retinaface.h5")
    return {
        "deepface_home": DEEPFACE_DIR,
        "weights_dir": weights_dir,
        "arcface_weights": os.path.exists(arcface_path),
        "retinaface_weights": os.path.exists(retinaface_path),
    }


@app.get("/status")
async def status():
    # Report model/detector defaults and whether weights are present
    return {
        "ok": True,
        "defaults": {
            "model": DEFAULT_MODEL_NAME,
            "detector_backend": DEFAULT_DETECTOR_BACKEND,
            "distance_metric": DEFAULT_DISTANCE_METRIC,
        },
        "weights": _weights_status(),
        "env": {
            "DEEPFACE_HOME": os.environ.get("DEEPFACE_HOME"),
        }
    }


@app.on_event("startup")
async def preload_models():
    # Build and cache model and detector at startup to avoid first-request latency
    try:
        DeepFace.build_model(DEFAULT_MODEL_NAME)
    except Exception as e:
        # Don't crash app if preload fails; first request will retry
        print(f"[startup] Warning: failed to build model {DEFAULT_MODEL_NAME}: {e}")
    # Try to build detector if available; otherwise warm-up via represent
    if FaceDetector is not None:
        try:
            FaceDetector.build_model(DEFAULT_DETECTOR_BACKEND)
        except Exception as e:
            print(f"[startup] Warning: failed to build detector {DEFAULT_DETECTOR_BACKEND}: {e}")
    else:
        # Fallback warm-up: call represent on a tiny dummy image to trigger detector loading
        try:
            import numpy as np  # type: ignore
            import cv2  # type: ignore
            import tempfile as _tf
            # Create a small black image
            dummy = np.zeros((64, 64, 3), dtype=np.uint8)
            with _tf.NamedTemporaryFile(delete=False, suffix='.jpg') as _f:
                _tmp = _f.name
            cv2.imwrite(_tmp, dummy)
            try:
                DeepFace.represent(
                    img_path=_tmp,
                    model_name=DEFAULT_MODEL_NAME,
                    detector_backend=DEFAULT_DETECTOR_BACKEND,
                    enforce_detection=False,
                    align=True,
                )
            finally:
                try:
                    if os.path.exists(_tmp):
                        os.remove(_tmp)
                except Exception:
                    pass
        except Exception as e:
            print(f"[startup] Warning: detector warm-up via represent failed: {e}")


@app.post("/verify")
async def verify(
    file1: UploadFile = File(..., description="Reference image (registered primary face)"),
    file2: UploadFile = File(..., description="New image to verify"),
    model_name: str = Form(DEFAULT_MODEL_NAME),
    detector_backend: str = Form(DEFAULT_DETECTOR_BACKEND),
    distance_metric: str = Form(DEFAULT_DISTANCE_METRIC),
    enforce_detection: bool = Form(False),
    align: bool = Form(True),
    threshold: Optional[float] = Form(None),
):
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file1.filename or "ref")[1] or ".jpg") as f1:
            ref_path = f1.name
            f1.write(await file1.read())
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file2.filename or "new")[1] or ".jpg") as f2:
            new_path = f2.name
            f2.write(await file2.read())

        res = DeepFace.verify(
            img1_path=ref_path,
            img2_path=new_path,
            model_name=model_name,
            detector_backend=detector_backend,
            distance_metric=distance_metric,
            enforce_detection=enforce_detection,
            align=align,
        )

        # DeepFace typically returns threshold; if missing, use provided threshold
        used_threshold = res.get("threshold", threshold)
        confidence = None
        if used_threshold is not None and res.get("distance") is not None:
            # Convert to percentage with two decimals for readability
            conf_ratio = compute_confidence(float(res["distance"]), float(used_threshold))
            confidence = round(conf_ratio * 100.0, 2) if conf_ratio is not None else None

        payload = {
            "ok": True,
            "verified": bool(res.get("verified", False)),
            "distance": res.get("distance"),
            "threshold": used_threshold,
            "confidence": confidence,
            "model": res.get("model", model_name),
            "detector_backend": res.get("detector_backend", detector_backend),
            # Include both keys for compatibility
            "similarity_metric": res.get("similarity_metric", distance_metric),
            "metric": res.get("similarity_metric", distance_metric),
            # Pass through facial areas if provided by DeepFace
            "facial_areas": res.get("facial_areas"),
            "time": res.get("time"),
        }
        return payload
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        # Cleanup temp files
        try:
            if 'ref_path' in locals() and os.path.exists(ref_path):
                os.remove(ref_path)
            if 'new_path' in locals() and os.path.exists(new_path):
                os.remove(new_path)
        except Exception:
            pass


@app.post("/embed")
async def embed(
    file: UploadFile = File(..., description="Image to create embedding from"),
    model_name: str = Form(DEFAULT_MODEL_NAME),
    detector_backend: str = Form(DEFAULT_DETECTOR_BACKEND),
    enforce_detection: bool = Form(False),
    align: bool = Form(True),
):
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename or "img")[1] or ".jpg") as f:
            img_path = f.name
            f.write(await file.read())

        reps = DeepFace.represent(
            img_path=img_path,
            model_name=model_name,
            detector_backend=detector_backend,
            enforce_detection=enforce_detection,
            align=align,
        )
        # reps can be list of dicts; we take the first
        rep = reps[0] if isinstance(reps, list) and reps else reps
        embedding = rep.get("embedding") if isinstance(rep, dict) else None
        if embedding is None:
            raise ValueError("Embedding not found in DeepFace representation")

        return {
            "ok": True,
            "embedding": embedding,
            "embedding_dim": len(embedding),
            "model": rep.get("model_name", model_name),
            "detector_backend": detector_backend,
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        try:
            if 'img_path' in locals() and os.path.exists(img_path):
                os.remove(img_path)
        except Exception:
            pass


class VerifyByUrlBody(BaseModel):
    img1_url: HttpUrl
    img2_url: HttpUrl
    model_name: str = "ArcFace"
    detector_backend: str = "retinaface"
    distance_metric: str = "cosine"
    enforce_detection: bool = False
    align: bool = True
    threshold: Optional[float] = None


@app.post("/verify-by-url")
async def verify_by_url(body: VerifyByUrlBody):
    import requests

    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as f1:
            ref_path = f1.name
            r1 = requests.get(str(body.img1_url), timeout=30)
            r1.raise_for_status()
            f1.write(r1.content)
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as f2:
            new_path = f2.name
            r2 = requests.get(str(body.img2_url), timeout=30)
            r2.raise_for_status()
            f2.write(r2.content)

        res = DeepFace.verify(
            img1_path=ref_path,
            img2_path=new_path,
            model_name=body.model_name,
            detector_backend=body.detector_backend,
            distance_metric=body.distance_metric,
            enforce_detection=body.enforce_detection,
            align=body.align,
        )

        used_threshold = res.get("threshold", body.threshold)
        confidence = None
        if used_threshold is not None and res.get("distance") is not None:
            confidence = compute_confidence(float(res["distance"]), float(used_threshold))

        return {
            "ok": True,
            "verified": bool(res.get("verified", False)),
            "distance": res.get("distance"),
            "threshold": used_threshold,
            "confidence": confidence,
            "model": res.get("model", body.model_name),
            "detector_backend": res.get("detector_backend", body.detector_backend),
            "metric": res.get("similarity_metric", body.distance_metric),
            "time": res.get("time"),
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        try:
            if 'ref_path' in locals() and os.path.exists(ref_path):
                os.remove(ref_path)
            if 'new_path' in locals() and os.path.exists(new_path):
                os.remove(new_path)
        except Exception:
            pass


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", "8001"))
    uvicorn.run("app:app", host="0.0.0.0", port=port, reload=False)
