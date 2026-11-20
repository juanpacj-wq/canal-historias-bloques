# Pendientes de la biblioteca compartida

Los chats productores no editan `studio/`, `herramientas/`, `canal/` ni
`audio/`. Cuando encuentran un error o echan en falta algo, lo anotan aquí en
una línea y lo resuelven dentro de la carpeta de su video. Un chat de
mantenimiento (`arranque/5-chat-mantenimiento.txt`) corrige la biblioteca y
tacha la línea.

Formato: `- [ ] AAAA-MM-DD, video NNN, archivo: qué pasa y cómo lo resolviste por ahora.`

## Abiertos

- [ ] 2026-11-13, video 001, `studio/pruebas/`: las pruebas fuera de Studio
      (luau-analyze y el intérprete) no se volvieron a correr después de los
      cambios de esta fecha; en este equipo no están los binarios de Luau.
      Además siguen usando la puesta vieja de 49 planos de `studio/ejemplos/`
      y no conocen los campos nuevos (`anim`, `mover`, `cambios`, `ancho`).
- [ ] 2026-11-13, video 001, `herramientas/studio/rodar.py`: la vista del
      juego mide 808 px de alto en esta pantalla, así que el video final es un
      escalado de 1,33. Probar a rodar con la escala de Windows al 100 % o en
      un monitor mayor (ideas sin probar, en `docs/11`).
- [ ] 2026-11-13, video 001, producción en paralelo: no se ha probado tener
      dos ventanas de Studio con dos chats. El rodaje captura la pantalla, así
      que solo uno puede rodar a la vez.
- [ ] 2026-11-13, video 001, `studio/lib/Escenarios.luau`: los faroles del
      pueblo se ven inclinados. Nieve, niebla y los escenarios `salon`,
      `bosque` y `calle_noche` siguen sin revisar a ojo, igual que el estilo
      `r6`.
- [ ] 2026-11-13, video 001, Studio: el botón de Roblox de la barra superior
      no se oculta en modo juego. Queda fuera del recorte 9:16.
- [ ] 2026-11-13, video 001, `herramientas/revisar.py`: el detector de cortes
      no ve los cortes entre planos de color parecido (los de lluvia) y marca
      REVISAR aunque los planos estén. Bajar el umbral o comparar contra
      `planos.json` de otra forma.
- [ ] 2026-11-13, sin video, `herramientas/voz_elevenlabs.py`: la llamada real
      a la API no se ha probado (solo con una respuesta simulada).
- [ ] 2026-11-13, sin video, `herramientas/revisar.py`: la zona segura de
      Shorts es una estimación. Comprobarla con el primer video subido.

## Resueltos

- [x] 2026-11-13, video 001, `studio/`: la biblioteca ya se ejecutó dentro de
      Roblox Studio 0.747 y produjo el video 001 completo. Corregido en la
      misma fecha por el chat del video 001, con permiso del dueño para actuar
      también como mantenimiento: pelo redondo en vez de bloques, luces de
      noche y de lluvia más claras, borde en el texto de la batería y verde
      más puro, resplandor de la batería, lluvia bien orientada con una nube
      densa frente a la cámara, movimiento dentro del plano y encuadre por
      punto y ancho.
- [x] 2026-11-13, video 001, herramientas de Studio: el puente MCP, la
      revisión de planos, el rodaje cuadro a cuadro, las ayudas de puesta y los
      efectos pasaron de la carpeta del video a `herramientas/studio/`,
      generalizados con `--video NNN`. `studio/README.md` quedó al día.
- [x] 2026-11-13, video 001, `herramientas/ritmo.py`: el umbral de silencio
      (-40 dB) funcionó con voz real (Kokoro): 230 palabras por minuto exactas
      y 61 de 61 planos anclados.
