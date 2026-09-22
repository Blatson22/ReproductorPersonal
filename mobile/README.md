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

Edita `lib/main.dart`:

```dart
const backendUrl = 'http://10.0.2.2:8000'; // emulador Android
```

- **Emulador Android**: `10.0.2.2` apunta al `localhost` de tu PC.
- **Dispositivo físico en la misma Wi-Fi**: usa la IP local de tu PC,
  ej. `http://192.168.1.50:8000`.
- **iOS Simulator**: puedes usar `http://localhost:8000` directamente.
- **Producción**: la URL pública de tu servidor desplegado (con HTTPS).

## Próximos pasos sugeridos

- **Controles en pantalla de bloqueo / notificación**: añade
  `just_audio_background` y `audio_service` — imprescindible en móvil,
  ahora mismo el audio se detiene si la app pasa a segundo plano.
- **Persistencia de listas**: añade `sqflite` o `drift` para guardar
  IDs/metadata de playlists (Fase 3 de tu plan) — de momento la cola
  vive solo en memoria.
- **Manejo de errores de red**: reintentos si el backend no responde,
  y mensaje claro si la URL de stream expiró antes de tiempo.
