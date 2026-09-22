# Backend — Motor de extracción (yt-dlp + FastAPI)

## Ejecutar en local

```bash
cd backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Prueba rápida:

```bash
curl "http://localhost:8000/search?q=bohemian+rhapsody"
curl "http://localhost:8000/stream/fJ9rUzIMcZQ"
```

## Por qué necesitas un servidor (y no correr yt-dlp en el móvil)

Android e iOS no permiten ejecutar binarios/procesos arbitrarios como
lo haría una app de escritorio. `yt-dlp` es una librería Python, así
que el "motor" vive en un servidor accesible desde el móvil:

- **Desarrollo**: tu propia máquina en la misma red Wi-Fi que el móvil.
  Usa la IP local de tu PC (ej. `http://192.168.1.50:8000`), no
  `localhost`, o el emulador/dispositivo no la encontrará.
- **Producción**: un VPS barato (Fly.io, Hetzner, DigitalOcean) o,
  si es solo para uso personal, un Raspberry Pi en casa con un túnel
  (Tailscale o Cloudflare Tunnel) para acceder desde fuera de tu red.

## Mantenimiento

YouTube cambia su frontend/API con cierta frecuencia, lo que puede
romper la extracción. Mantén `yt-dlp` actualizado:

```bash
pip install -U yt-dlp
```

Si vas a dejar esto corriendo de forma desatendida, vale la pena
programar esta actualización (cron, o un workflow de n8n si ya lo usas
para otras cosas) en vez de hacerlo a mano.

## Nota

Extraer streams de audio de YouTube sin pasar por su API oficial no
respeta los Términos de Servicio de YouTube. Es una práctica común en
proyectos personales/educativos, pero tenlo presente si en algún
momento piensas distribuir la app públicamente.
