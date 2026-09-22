# ReproductorPersonal — YT Audio Player (Backend + App Flutter)

Arquitectura políglota: backend en Python (donde vive `yt-dlp` de forma
nativa) + cliente Flutter (multiplataforma, móvil y web).

## Qué hace

- **Búsqueda** de canciones y **reproducción** de audio extraído al vuelo con `yt-dlp`.
- **Recomendaciones** basadas en el artista/canal del tema en reproducción.
- **Cuentas de usuario**: registro, login/logout con token de sesión.
- **Favoritos** e **historial de reproducción** por usuario, persistidos en SQLite.
- Interfaz oscura con navegación inferior (Buscar / Favoritos / Historial).

## Estructura

```
project/
├── backend/             # FastAPI + yt-dlp + SQLite
│   ├── main.py          # API (búsqueda, stream, auth, favoritos, historial) + sirve la web
│   ├── db.py            # persistencia SQLite (usuarios, sesiones, favoritos, historial)
│   ├── requirements.txt
│   ├── start.ps1 / stop.ps1 / test-auth.ps1
│   └── README.md
└── mobile/              # Flutter
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart               # providers + enrutado login vs. app
    │   ├── theme/app_theme.dart    # paleta y estilos centralizados
    │   ├── models/track.dart
    │   ├── services/               # api, auth, player
    │   ├── screens/                # auth, search, favorites, history, player, home
    │   └── widgets/                # track_tile, empty_state
    └── README.md
```

## Cómo arrancar todo

1. **Backend**: sigue `backend/README.md` (crea un venv, instala
   dependencias, `.\start.ps1`).
2. **Web**: `cd mobile && flutter build web`. El backend ya sirve la build
   en la raíz (`http://localhost:8000`), así que no hace falta un servidor
   extra.
3. **Móvil**: `cd mobile && flutter run` (requiere el scaffolding nativo
   de Android/iOS, generado con `flutter create --platforms=android,ios .`).

## Exponerlo a Internet (para usarlo fuera de casa)

La app deriva la URL del backend del propio origen, así que basta un
túnel único. Con **Cloudflare Tunnel** (Quick Tunnel, sin cuenta):

```powershell
cloudflared tunnel --url http://localhost:8000 --no-autoupdate
```

Imprime una URL pública `https://<algo>.trycloudflare.com` que puedes
abrir desde el móvil o compartir. Ojo: la URL cambia en cada reinicio.
Para una URL estable usa un túnel "named" con tu dominio (requiere cuenta
de Cloudflare).

## Decisiones de arquitectura (resumen)

- **¿Por qué no `yt-dlp` directamente en el móvil?** Android e iOS no
  permiten ejecutar binarios/procesos arbitrarios (sandboxing), así que la
  extracción vive en un servidor propio.
- **¿Por qué no guardar las stream URLs?** Expiran a las pocas horas. Solo
  se guardan IDs/metadata; la URL de audio se pide fresca justo antes de
  cada reproducción.
- **¿Por qué el mismo origen?** En web, el backend sirve también la app
  estática, así la URL del backend se resuelve sola (local, LAN o túnel)
  sin configuración.

## Pendiente / siguientes pasos

- Reproducción en segundo plano y controles en notificación
  (`just_audio_background` + `audio_service`).
- Persistencia local de playlists manuales (hoy el historial es automático).
- Revisar los Términos de Servicio de YouTube antes de cualquier
  distribución pública de la app.
