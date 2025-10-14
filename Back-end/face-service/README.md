# Face Service (DeepFace + FastAPI)

This service provides face embedding and verification endpoints used by the Laravel backend.

## Endpoints
- GET /health — basic liveness
- GET /status — reports defaults (model/detector), DeepFace cache location, and whether weights are present
- POST /embed — returns an embedding vector for an uploaded image
- POST /verify — compares two uploaded images and returns match metrics
- POST /verify-by-url — server-side verify using two image URLs

## First-run downloads (why you saw large files)
DeepFace downloads model weights on first use and caches them under a weights directory. For the defaults in this service:
- ArcFace weights: `arcface_weights.h5` (~137 MB)
- RetinaFace detector: `retinaface.h5` (~119 MB)

By default, these are stored at:
- Windows: `C:\\Users\\<you>\\.deepface\\weights`
- Controlled via the `DEEPFACE_HOME` environment variable. This service ensures the directory exists at startup.

After the first download, subsequent calls reuse the cached weights and are fast.

## Startup preloading (faster first request)
On startup, the service preloads:
- the face model via `DeepFace.build_model(FACE_MODEL)`
- the detector via `FaceDetector.build_model(FACE_DETECTOR)`

This triggers the first-time downloads at boot (rather than the first API call), then keeps them cached.

## Configuration (env vars)
- `DEEPFACE_HOME` — cache base directory for DeepFace (default: `~/.deepface`)
- `FACE_MODEL` — face recognition model (default: `ArcFace`)
- `FACE_DETECTOR` — face detector backend (default: `retinaface`)
- `FACE_DISTANCE` — distance metric (default: `cosine`)
- `PORT` — service port (default: `8001`)

You can verify current values and cache state via `GET /status`.

## Persisting the cache (recommended)
- Keep the `DEEPFACE_HOME/weights` directory persistent across deployments so downloads don't repeat.
- In containers: mount a volume at that path or bake weights into the image by running a warm-up during build.

## Troubleshooting
- Offline startup: If the server is offline on first boot, preloading may fail; the first API call will retry the download. You can disable preloading by ignoring the warnings; once online, call `/embed` to trigger downloads.
- Permissions: Ensure the process can write to `DEEPFACE_HOME/weights`.
- Different models/detectors: Switching to a new model or detector may trigger additional one-time downloads.
# Face Service (FastAPI + DeepFace)

A small microservice providing REST endpoints to verify two face images using DeepFace.

## Endpoints

- GET /health
- POST /verify (multipart/form-data)
  - file1: reference image (e.g., user's primary face)
  - file2: new image captured for verification
  - optional form fields: model_name, detector_backend, distance_metric, enforce_detection, align, threshold
- POST /verify-by-url (application/json)
  - { img1_url, img2_url, model_name?, detector_backend?, distance_metric?, enforce_detection?, align?, threshold? }

## Run locally

1. Create virtual environment and install deps

```
python -m venv .venv
. .venv/Scripts/activate
pip install -r requirements.txt
```

2. Start server

```
python app.py  # listens on 0.0.0.0:8001
```

## Response shape

```
{
  "ok": true,
  "verified": true|false,
  "distance": 0.123,
  "threshold": 0.68,
  "confidence": 0.81,      # computed if threshold known
  "model": "ArcFace",
  "detector_backend": "retinaface",
  "metric": "cosine",
  "time": 0.45
}
```

## Notes
- You can tweak model_name (ArcFace, VGG-Face, Facenet512, etc.) and detector_backend (retinaface, mtcnn, mediapipe, opencv).
- Confidence is computed as `1 - (distance / threshold)` and clamped to [0,1] when threshold is available.
- For production, consider GPU-accelerated images and pinning versions for stable thresholds.
