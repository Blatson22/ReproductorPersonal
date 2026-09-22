# Mobile — App Flutter

## Requisitos

- Flutter SDK instalado (`flutter --version`)
- El backend (`../backend`) corriendo y accesible desde tu móvil/emulador

## Poner en marcha

```bash
cd mobile
flutter pub get
flutter run
```

## Configurar la URL del backend

La URL se resuelve automáticamente en `lib/main.dart` (`_resolveBackendUrl`):

- **Web**: usa el origen actual (`Uri.base.origin`), así que funciona en
  local, en LAN o detrás de un túnel/dominio sin tocar nada.
- **Nativo (Android/iOS)**: usa `http://10.0.2.2:8000` (alias de
  `localhost` del PC desde el emulador Android). Si usas un dispositivo
  físico, cambia ese valor por la IP local de tu PC (ej.
  `http://192.168.1.50:8000`).

## Estructura

```
lib/
├── main.dart                  # Providers + decide login vs. app según la sesión guardada
├── theme/app_theme.dart       # Paleta y estilos (todo el color vive aquí)
├── models/track.dart
├── services/
│   ├── api_service.dart       # Cliente HTTP: búsqueda, stream, auth, favoritos, historial
│   ├── auth_service.dart      # Sesión: login/registro/logout, token persistido en disco
│   └── player_service.dart    # Reproducción, cola y registro en historial
├── screens/
│   ├── auth_screen.dart       # Login / registro
│   ├── home_shell.dart        # Navegación inferior
│   ├── search_screen.dart
│   ├── favorites_screen.dart
│   ├── history_screen.dart
│   └── player_screen.dart     # Reproductor + favorito + recomendaciones
└── widgets/
    ├── track_tile.dart        # Fila de canción reutilizada en todas las listas
    └── empty_state.dart
```

## Primera vez que usas la app

1. Abre la app → verás la pantalla de login.
2. Toca "¿Sin cuenta? Regístrate" y crea un usuario (contraseña mínimo
   4 caracteres — es un proyecto personal, no hace falta más).
3. La sesión queda guardada en el dispositivo; no tendrás que volver a
   loguearte salvo que cierres sesión manualmente.

## Próximos pasos sugeridos

- **Controles en pantalla de bloqueo / notificación**: añade
  `just_audio_background` y `audio_service` — imprescindible en móvil,
  ahora mismo el audio se detiene si la app pasa a segundo plano.
- **Manejo de errores de red**: reintentos si el backend no responde,
  y mensaje claro si la URL de stream expiró antes de tiempo.
- **Colas/playlists persistentes**: más allá del historial automático,
  listas armadas a mano que sobrevivan a un reinicio de la app.
