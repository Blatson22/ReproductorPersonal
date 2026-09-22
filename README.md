# YT Audio Player — Proyecto (Backend + App Flutter)

Arquitectura políglota: backend en Python (donde vive `yt-dlp` de forma
nativa) + cliente Flutter/Dart (multiplataforma, apuntado aquí a móvil).

```
project/
├── backend/     # FastAPI + yt-dlp — Fase 1: extracción de enlaces
│   ├── main.py
│   ├── requirements.txt
│   └── README.md
└── mobile/      # Flutter — Fases 2 y 3: reproductor, búsqueda, cola
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart
    │   ├── models/track.dart
    │   ├── services/api_service.dart
    │   ├── services/player_service.dart
    │   └── screens/search_screen.dart, player_screen.dart
    └── README.md
```

## Cómo arrancar todo

1. **Backend**: sigue `backend/README.md` (crea un venv, instala
   dependencias, `uvicorn main:app --reload`).
2. **Mobile**: sigue `mobile/README.md` (`flutter pub get`, ajusta la
   URL del backend en `lib/main.dart`, `flutter run`).

## Decisiones de arquitectura (resumen)

- **¿Por qué no `yt-dlp` directamente en el móvil?** Android e iOS no
  permiten ejecutar binarios/procesos arbitrarios (sandboxing), así
  que la extracción vive en un servidor propio.
- **¿Por qué no n8n como motor central?** n8n es un orquestador de
  workflows, no un servicio HTTP de baja latencia para responder cada
  vez que el usuario pulsa "Play". Puede ser útil como tarea auxiliar
  (por ejemplo, para recordarte que actualices `yt-dlp` periódicamente)
  pero no debería estar en el camino crítico de reproducción.
- **¿Por qué no guardar las stream URLs?** Expiran a las pocas horas.
  Solo se guardan IDs/metadata; la URL de audio se pide fresca justo
  antes de cada reproducción.

## Pendiente / siguientes pasos

- Persistencia local de playlists (`sqflite`/`drift`) en el cliente.
- Reproducción en segundo plano y controles en notificación
  (`just_audio_background` + `audio_service`).
- Despliegue del backend en un servidor accesible desde fuera de tu
  red local si quieres usar la app fuera de casa.
- Revisar los Términos de Servicio de YouTube antes de cualquier
  distribución pública de la app.
