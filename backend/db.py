"""
Persistencia en SQLite (stdlib): usuarios, sesiones, favoritos e historial.

Uso personal/educativo. Las contraseñas se guardan con PBKDF2-SHA256
(seco a 100k iteraciones). En producción, considera bcrypt/argon2 y un
sistema de tokens JWT con expiración.
"""

from __future__ import annotations

import hashlib
import hmac
import os
import secrets
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent / "app.db"

_PBKDF2_ITERATIONS = 100_000


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def get_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def hash_password(password: str, salt: bytes | None = None) -> tuple[str, str]:
    if salt is None:
        salt = os.urandom(16)
    dk = hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), salt, _PBKDF2_ITERATIONS
    )
    return dk.hex(), salt.hex()


def verify_password(password: str, salt_hex: str, expected_hex: str) -> bool:
    dk = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        bytes.fromhex(salt_hex),
        _PBKDF2_ITERATIONS,
    )
    return hmac.compare_digest(dk.hex(), expected_hex)


def init_db() -> None:
    with get_conn() as conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                salt TEXT NOT NULL,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS sessions (
                token TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS favorites (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                video_id TEXT NOT NULL,
                title TEXT NOT NULL,
                thumbnail TEXT,
                duration INTEGER,
                uploader TEXT,
                created_at TEXT NOT NULL,
                UNIQUE(user_id, video_id)
            );

            CREATE TABLE IF NOT EXISTS history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                video_id TEXT NOT NULL,
                title TEXT NOT NULL,
                thumbnail TEXT,
                duration INTEGER,
                uploader TEXT,
                played_at TEXT NOT NULL
            );
            """
        )


# --- usuarios / sesiones ---


def create_user(username: str, password: str) -> sqlite3.Row:
    pw_hex, salt_hex = hash_password(password)
    with get_conn() as conn:
        cur = conn.execute(
            "INSERT INTO users (username, password_hash, salt, created_at) "
            "VALUES (?, ?, ?, ?)",
            (username, pw_hex, salt_hex, _now()),
        )
        row = conn.execute("SELECT * FROM users WHERE id = ?", (cur.lastrowid,)).fetchone()
    return row


def get_user_by_username(username: str) -> sqlite3.Row | None:
    with get_conn() as conn:
        return conn.execute(
            "SELECT * FROM users WHERE username = ?", (username,)
        ).fetchone()


def create_session(user_id: int) -> str:
    token = secrets.token_urlsafe(32)
    with get_conn() as conn:
        conn.execute(
            "INSERT INTO sessions (token, user_id, created_at) VALUES (?, ?, ?)",
            (token, user_id, _now()),
        )
    return token


def get_user_by_token(token: str) -> sqlite3.Row | None:
    with get_conn() as conn:
        row = conn.execute(
            "SELECT u.* FROM sessions s JOIN users u ON u.id = s.user_id "
            "WHERE s.token = ?",
            (token,),
        ).fetchone()
    return row


def delete_session(token: str) -> None:
    with get_conn() as conn:
        conn.execute("DELETE FROM sessions WHERE token = ?", (token,))


# --- favoritos ---


def add_favorite(user_id: int, track: dict) -> None:
    with get_conn() as conn:
        conn.execute(
            "INSERT OR IGNORE INTO favorites "
            "(user_id, video_id, title, thumbnail, duration, uploader, created_at) "
            "VALUES (?, ?, ?, ?, ?, ?, ?)",
            (
                user_id,
                track["id"],
                track.get("title", ""),
                track.get("thumbnail"),
                track.get("duration"),
                track.get("uploader"),
                _now(),
            ),
        )


def remove_favorite(user_id: int, video_id: str) -> None:
    with get_conn() as conn:
        conn.execute(
            "DELETE FROM favorites WHERE user_id = ? AND video_id = ?",
            (user_id, video_id),
        )


def list_favorites(user_id: int) -> list[dict]:
    with get_conn() as conn:
        rows = conn.execute(
            "SELECT video_id AS id, title, thumbnail, duration, uploader, created_at "
            "FROM favorites WHERE user_id = ? ORDER BY created_at DESC",
            (user_id,),
        ).fetchall()
    return [dict(r) for r in rows]


def is_favorite(user_id: int, video_id: str) -> bool:
    with get_conn() as conn:
        row = conn.execute(
            "SELECT 1 FROM favorites WHERE user_id = ? AND video_id = ?",
            (user_id, video_id),
        ).fetchone()
    return row is not None


# --- historial ---


def add_history(user_id: int, track: dict) -> None:
    with get_conn() as conn:
        conn.execute(
            "INSERT INTO history "
            "(user_id, video_id, title, thumbnail, duration, uploader, played_at) "
            "VALUES (?, ?, ?, ?, ?, ?, ?)",
            (
                user_id,
                track["id"],
                track.get("title", ""),
                track.get("thumbnail"),
                track.get("duration"),
                track.get("uploader"),
                _now(),
            ),
        )


def list_history(user_id: int, limit: int = 100) -> list[dict]:
    with get_conn() as conn:
        rows = conn.execute(
            "SELECT video_id AS id, title, thumbnail, duration, uploader, played_at "
            "FROM history WHERE user_id = ? ORDER BY played_at DESC LIMIT ?",
            (user_id, limit),
        ).fetchall()
    return [dict(r) for r in rows]