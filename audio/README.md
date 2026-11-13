# Audio compartido

Música y efectos que usan todos los videos. La guía de fuentes, licencias y
mezcla es `docs/09-audio-voz-musica-efectos.md`.

- `musica/`: pistas descargadas. Nombre de archivo: `tono-titulo-autor.mp3`
  (por ejemplo `tierno-carefree-kevin-macleod.mp3`).
- `sfx/`: efectos de sonido. Nombre de archivo: `que-es.wav`
  (por ejemplo `puf.wav`, `pitido.wav`, `campana-colegio.wav`).
- `creditos.md`: una línea por archivo con título, autor, fuente, enlace,
  licencia y fecha de descarga. **Ningún archivo entra a estas carpetas sin su
  línea en `creditos.md`.**

Estas carpetas están vacías a propósito: descargar música es un paso tuyo,
porque varias fuentes piden cuenta y hay que leer la licencia vigente el día
de la descarga. Evita las pistas marcadas "Content ID Registered": un Short
de más de un minuto con un reclamo no cobra y puede quedar bloqueado.

Cada video anota además qué pista usó en `videos/NNN-slug/montaje/licencias.md`.
