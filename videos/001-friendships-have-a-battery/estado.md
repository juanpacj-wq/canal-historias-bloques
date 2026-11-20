# Estado del video 001-friendships-have-a-battery

- Guion: `guiones/001-friendships-have-a-battery.md`
- Creado: 2026-11-13

Marca cada casilla con una x cuando termines la etapa: `- [x]`.
La etapa actual es la primera casilla sin marcar.

## Etapas

- [x] **guion**: Guion revisado y texto de la narración listo
- [x] **voz**: Voz generada y pasada por ritmo.py
- [x] **tiempos**: palabras.json y planos.json generados
- [x] **escenas**: Escenarios, personajes y script director listos
- [x] **grabación**: Grabación continua hecha
- [x] **montaje**: Video montado con montar.py
- [x] **revisión**: revisar.py aprobado y hoja de contactos revisada
- [x] **metadatos**: Título, descripción y etiquetas escritos
- [ ] **publicado**: Subido a YouTube

## Carpetas

- `voz/`: audio original y audio con el ritmo ajustado
- `tiempos/`: palabras.json, planos.json y subtitulos.ass
- `escenas/`: notas y scripts de los escenarios
- `grabacion/`: la grabación continua o los clips por plano
- `montaje/`: música, efectos y el MP4 final
- `revision/`: hoja de contactos e informe de revisar.py
- `metadatos/`: título, descripción y etiquetas

## Notas

Chat piloto-001, 2026-11-13.

- **guion**: se cambió una sola fila de la tabla de planos (la 19 ahora empieza
  en "Our bar never moved") para que el plano del letrero no se alargue. El
  texto de la narración no cambió.
- **voz**: Kokoro-82M local, voz `af_heart`, 93,4 s a 230 palabras por minuto.
  Decisión provisional del chat: el dueño no ha escuchado ni aprobado la voz.
  Alterna lista en `voz/alt_am_puck/`. Whisper oyó "has" como "his" en
  "The bar has two halves": conviene escucharlo.
- **tiempos**: 61 planos anclados, sin avisos (mínimo 0,66 s, máximo 2,60 s).
- **escenas**: la puesta se genera con `escenas/hacer_puesta.py` y se revisa
  con `herramientas/studio/ver.py`. No se hizo la versión gris: se revisó directo en
  detalle, plano por plano.
- **grabación**: no se usó OBS. `herramientas/studio/rodar.py` rueda cuadro a cuadro en
  modo juego y captura la pantalla (60 cps, unos 22 minutos por toma). La
  vista útil mide 808 px de ancho: el 1080x1920 final es un escalado de 1,33.
- **montaje**: `producir.py montar 001` con música "Carefree" de Kevin
  MacLeod (CC BY 4.0, crédito obligatorio) y efectos propios sintetizados.
  Licencias en `montaje/licencias.md`.
- **revisión**: informe en `revision/informe_revisar.txt`. El detector de
  cortes no ve los cortes entre planos de lluvia (imágenes parecidas); los 61
  planos sí están, comprobado en la hoja de contactos.
- **metadatos**: `metadatos/publicacion.txt`. Se conservó el archivo que ya venía escrito; se
  agregaron el crédito de la música y el cuadro de portada (00:37.9).
- **publicado**: lo hace el dueño.
- **método**: lo que funcionó quedó en `herramientas/studio/`, en la skill
  `producir-video` y en `docs/11-metodo-probado.md`. Esta carpeta es el
  ejemplo de referencia: `escenas/hacer_puesta.py` y `montaje/hacer_efectos.py`.
