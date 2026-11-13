# Pendientes de la biblioteca compartida

Los chats productores no editan `studio/`, `herramientas/`, `canal/` ni
`audio/`. Cuando encuentran un error o echan en falta algo, lo anotan aquí en
una línea y lo resuelven dentro de la carpeta de su video. Un chat de
mantenimiento (`arranque/5-chat-mantenimiento.txt`) corrige la biblioteca y
tacha la línea.

Formato: `- [ ] AAAA-MM-DD, video NNN, archivo: qué pasa y cómo lo resolviste por ahora.`

## Abiertos

- [ ] 2026-11-13, sin video, `studio/`: la biblioteca nunca se ha ejecutado
      dentro de Roblox Studio. Validarla con
      `arranque/1-primera-prueba-en-studio.txt` antes de producir.
- [ ] 2026-11-13, sin video, `herramientas/voz_elevenlabs.py`: la llamada real
      a la API no se ha probado (solo con una respuesta simulada).
- [ ] 2026-11-13, sin video, `herramientas/ritmo.py`: el umbral de silencio
      (-40 dB) solo se probó con la voz sintética de Windows. Ajustarlo con la
      primera voz real.
- [ ] 2026-11-13, sin video, `herramientas/revisar.py`: la zona segura de
      Shorts es una estimación. Comprobarla con el primer video subido.

## Resueltos
