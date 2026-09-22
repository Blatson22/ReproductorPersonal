# Backend — Motor de extracción (yt-dlp + FastAPI + SQLite)

## Endpoints

| Método | Ruta | Descripción |
| --- | --- | --- |
| GET | `/search?q=...` | Búsqueda de canciones |
| GET | `/metadata/{video_id}` | Título, carátula, duración |
| GET | `/stream/{video_id}` | URL de streaming de audio (SIEMPRE fresca) |
| GET | `/recommendations/{video_id}` | Más temas del mismo artista/canal |
| POST | `/auth/register` | Crear cuenta (`{username, password}`) |
| POST | `/auth/login` | Login → token de sesión |
| POST | `/auth/logout` | Cerrar sesión |
| GET | `/auth/me` | Usuario autenticado |
| GET/POST | `/favorites` | Listar / añadir favorito |
| DELETE | `/favorites/{video_id}` | Quitar favorito |
| GET | `/favorites/check/{video_id}` | ¿Está en favoritos? |
| GET/POST | `/history` | Listar / registrar reproducción |
| DELETE | `/history` | Vaciar historial |
| GET | `/health` | Chequeo de vida |
| GET | `/` | Sirve la build web de Flutter (`mobile/build/web`) |

Los endpoints de favoritos e historial requieren el header
`Authorization: Bearer <token>`.

## Ejecutar en local

```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
.\start.ps1        # arranca en http://localhost:8000 (guarda el PID en backend.pid)
.\stop.ps1         # lo detiene
```

Prueba rápida (flujo completo de auth/favoritos/historial):

```powershell
.\test-auth.ps1
```

## Servir la app web

El backend monta `mobile/build/web` en la raíz si existe. Para generarla:

```powershell
cd mobile
flutter build web
```

Entonces `http://localhost:8000` sirve la app (login incluido) y la API en
el mismo origen.

## Por qué necesitas un servidor (y no correr yt-dlp en el móvil)

Android e iOS no permiten ejecutar binarios/procesos arbitrarios como lo
haría una app de escritorio. `yt-dlp` es una librería Python, así que el
"motor" vive en un servidor accesible desde el móvil.

## Mantenimiento

YouTube cambia su frontend/API con cierta frecuencia, lo que puede romper
la extracción. Mantén `yt-dlp` actualizado:

```bash
pip install -U yt-dlp
```

## Nota

Extraer streams de audio de YouTube sin pasar por su API oficial no
respeta los Términos de Servicio de YouTube. Es una práctica común en
proyectos personales/educativos, pero tenlo presente si en algún momento
piensas distribuir la app públicamente.
