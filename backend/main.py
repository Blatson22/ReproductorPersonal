"""
Motor de extracción de audio (Fase 1 del plan).

Expone una API REST minimalista sobre yt-dlp:
  GET /search?q=...        -> lista de resultados de búsqueda
  GET /metadata/{video_id} -> título, carátula, duración
  GET /stream/{video_id}   -> URL de streaming de audio (SIEMPRE fresca)
  GET /health               -> chequeo de vida

IMPORTANTE: /stream debe llamarse justo antes de reproducir cada pista.
Las URLs de streaming de YouTube expiran a las pocas horas; no las
caches ni las guardes en base de datos.
"""

from __future__ import annotations

import time
from pathlib import Path
from typing import Optional

import yt_dlp
from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

import db

app = FastAPI(title="YT Audio Engine", version="0.2.0")

db.init_db()

# En producción, restringe esto al dominio/IP de tu app en vez de "*".
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

YDL_OPTS_BASE = {
    "format": "bestaudio[ext=m4a]/bestaudio/best",
    "quiet": True,
    "no_warnings": True,
    "noplaylist": True,
    "skip_download": True,
}


class TrackResult(BaseModel):
    id: str
    title: str
    thumbnail: Optional[str] = None
    duration: Optional[int] = None
    uploader: Optional[str] = None


class StreamResult(BaseModel):
    id: str
    stream_url: str
    note: str = "Vuelve a pedir este endpoint antes de cada reproducción; el enlace expira."


class RegisterRequest(BaseModel):
    username: str
    password: str


class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    token: str
    username: str


class TrackIn(BaseModel):
    id: str
    title: Optional[str] = None
    thumbnail: Optional[str] = None
    duration: Optional[int] = None
    uploader: Optional[str] = None


def _best_thumbnail(entry: dict) -> Optional[str]:
    thumbs = entry.get("thumbnails")
    if thumbs:
        return thumbs[-1].get("url")
    return entry.get("thumbnail")


@app.get("/search", response_model=list[TrackResult])
def search(q: str, limit: int = 5):
    if not q.strip():
        raise HTTPException(400, "La búsqueda no puede estar vacía")
    if not 1 <= limit <= 25:
        raise HTTPException(400, "limit debe estar entre 1 y 25")

    query = f"ytsearch{limit}:{q}"
    opts = {**YDL_OPTS_BASE, "extract_flat": "in_playlist"}

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(query, download=False)
    except Exception as e:  # noqa: BLE001
        raise HTTPException(502, f"Búsqueda fallida: {e}") from e

    entries = (info or {}).get("entries", []) or []
    results: list[TrackResult] = []
    for entry in entries:
        if not entry:
            continue
        results.append(
            TrackResult(
                id=entry.get("id"),
                title=entry.get("title") or "Sin título",
                thumbnail=_best_thumbnail(entry),
                duration=entry.get("duration"),
                uploader=entry.get("uploader") or entry.get("channel"),
            )
        )
    return results


@app.get("/metadata/{video_id}", response_model=TrackResult)
def metadata(video_id: str):
    url = f"https://www.youtube.com/watch?v={video_id}"
    try:
        with yt_dlp.YoutubeDL(YDL_OPTS_BASE) as ydl:
            info = ydl.extract_info(url, download=False)
    except Exception as e:  # noqa: BLE001
        raise HTTPException(502, f"No se pudo obtener metadata: {e}") from e

    return TrackResult(
        id=info.get("id"),
        title=info.get("title") or "Sin título",
        thumbnail=_best_thumbnail(info),
        duration=info.get("duration"),
        uploader=info.get("uploader"),
    )


@app.get("/stream/{video_id}", response_model=StreamResult)
def stream(video_id: str):
    url = f"https://www.youtube.com/watch?v={video_id}"
    try:
        with yt_dlp.YoutubeDL(YDL_OPTS_BASE) as ydl:
            info = ydl.extract_info(url, download=False)
    except Exception as e:  # noqa: BLE001
        raise HTTPException(502, f"Extracción de stream fallida: {e}") from e

    stream_url = info.get("url")
    if not stream_url:
        # Fallback: buscar manualmente un formato solo-audio entre los disponibles
        for fmt in info.get("formats", []) or []:
            if fmt.get("acodec") not in (None, "none") and fmt.get("vcodec") == "none":
                stream_url = fmt.get("url")
                break

    if not stream_url:
        raise HTTPException(404, "No se encontró un stream de audio para este video")

    return StreamResult(id=video_id, stream_url=stream_url)


@app.get("/recommendations/{video_id}", response_model=list[TrackResult])
def recommendations(video_id: str, limit: int = 10):
    """Recomendaciones basadas en un video: más canciones del mismo canal/artista.

    Reutiliza el canal del video actual y hace una búsqueda relacionada,
    excluyendo el propio video. Es un enfoque estable (el mix de radio de
    YouTube no siempre es extraíble).
    """
    if not 1 <= limit <= 25:
        raise HTTPException(400, "limit debe estar entre 1 y 25")

    url = f"https://www.youtube.com/watch?v={video_id}"
    try:
        with yt_dlp.YoutubeDL({**YDL_OPTS_BASE}) as ydl:
            current = ydl.extract_info(url, download=False)
    except Exception as e:  # noqa: BLE001
        raise HTTPException(502, f"No se pudo extraer el video actual: {e}") from e

    channel = current.get("channel") or current.get("uploader")
    if not channel:
        raise HTTPException(502, "No se pudo determinar el artista para recomendar")

    query = f"ytsearch{limit * 2}:{channel}"
    opts = {**YDL_OPTS_BASE, "extract_flat": "in_playlist"}
    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(query, download=False)
    except Exception as e:  # noqa: BLE001
        raise HTTPException(502, f"No se pudieron obtener recomendaciones: {e}") from e

    entries = (info or {}).get("entries", []) or []
    results: list[TrackResult] = []
    for entry in entries:
        if not entry or not entry.get("id") or entry.get("id") == video_id:
            continue
        results.append(
            TrackResult(
                id=entry.get("id"),
                title=entry.get("title") or "Sin título",
                thumbnail=_best_thumbnail(entry),
                duration=entry.get("duration"),
                uploader=entry.get("uploader") or entry.get("channel"),
            )
        )
        if len(results) >= limit:
            break
    return results


def _current_user(authorization: Optional[str] = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(401, "Falta el token de autenticación")
    token = authorization.split(" ", 1)[1].strip()
    user = db.get_user_by_token(token)
    if not user:
        raise HTTPException(401, "Token inválido o sesión expirada")
    return user


@app.post("/auth/register", response_model=TokenResponse)
def register(body: RegisterRequest):
    username = body.username.strip()
    if not username or not body.password:
        raise HTTPException(400, "Usuario y contraseña son obligatorios")
    if len(body.password) < 4:
        raise HTTPException(400, "La contraseña debe tener al menos 4 caracteres")
    if db.get_user_by_username(username):
        raise HTTPException(409, "Ese usuario ya existe")
    user = db.create_user(username, body.password)
    token = db.create_session(user["id"])
    return TokenResponse(token=token, username=user["username"])


@app.post("/auth/login", response_model=TokenResponse)
def login(body: LoginRequest):
    user = db.get_user_by_username(body.username.strip())
    if not user or not db.verify_password(
        body.password, user["salt"], user["password_hash"]
    ):
        raise HTTPException(401, "Usuario o contraseña incorrectos")
    token = db.create_session(user["id"])
    return TokenResponse(token=token, username=user["username"])


@app.post("/auth/logout")
def logout(authorization: Optional[str] = Header(None)):
    if authorization and authorization.startswith("Bearer "):
        db.delete_session(authorization.split(" ", 1)[1].strip())
    return {"status": "ok"}


@app.get("/auth/me")
def me(user=Depends(_current_user)):
    return {"username": user["username"]}


@app.get("/favorites", response_model=list[TrackResult])
def favorites(user=Depends(_current_user)):
    return db.list_favorites(user["id"])


@app.post("/favorites")
def add_favorite(body: TrackIn, user=Depends(_current_user)):
    db.add_favorite(user["id"], body.model_dump())
    return {"status": "ok", "id": body.id}


@app.get("/favorites/check/{video_id}")
def favorite_check(video_id: str, user=Depends(_current_user)):
    return {"is_favorite": db.is_favorite(user["id"], video_id)}


@app.delete("/favorites/{video_id}")
def remove_favorite(video_id: str, user=Depends(_current_user)):
    db.remove_favorite(user["id"], video_id)
    return {"status": "ok"}


@app.get("/history", response_model=list[TrackResult])
def history(user=Depends(_current_user), limit: int = 100):
    return db.list_history(user["id"], limit)


@app.post("/history")
def add_history(body: TrackIn, user=Depends(_current_user)):
    db.add_history(user["id"], body.model_dump())
    return {"status": "ok", "id": body.id}


@app.delete("/history")
def clear_history(user=Depends(_current_user)):
    with db.get_conn() as conn:
        conn.execute("DELETE FROM history WHERE user_id = ?", (user["id"],))
    return {"status": "ok"}


@app.get("/health")
def health():
    return {"status": "ok", "time": time.time()}


# Sirve la build web de Flutter (mobile/build/web) en la raíz. Se monta al
# final para que las rutas de la API definidas arriba tengan prioridad.
_WEB_DIR = Path(__file__).resolve().parent.parent / "mobile" / "build" / "web"
if _WEB_DIR.is_dir():
    app.mount("/", StaticFiles(directory=str(_WEB_DIR), html=True), name="web")
