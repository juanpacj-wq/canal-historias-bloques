# Registro de licencias: In This World, Friendships Have a Battery

Fecha del registro: 2026-11-13.

## Voz

- Voz sintética local Kokoro-82M (hexgrad), voz `af_heart`, con el paquete
  `kokoro-onnx` 0.6.1. Modelo con licencia Apache 2.0. Origen de los archivos y
  sumas SHA256 en `voz/LEEME-voz.txt`.
- Hay una versión alterna lista con la voz `am_puck` en `voz/alt_am_puck/` y
  `tiempos/alt_am_puck/`.
- Casilla de contenido alterado o sintético de YouTube: el criterio ya está
  en `metadatos/publicacion.txt` (línea ALTERED CONTENT, según `docs/07`,
  sección 3.3).

## Música

| Archivo | Título | Autor | Fuente | Licencia | Descargado |
|---|---|---|---|---|---|
| `montaje/musica_carefree.mp3` | Carefree | Kevin MacLeod | https://incompetech.com/music/royalty-free/mp3-royaltyfree/Carefree.mp3 | CC BY 4.0, atribución obligatoria | 2026-11-13 |

- La licencia CC BY 4.0 sale de las preguntas frecuentes de Incompetech, no de
  una ficha por pista (ver `docs/09`). La ficha individual quedó sin verificar.
- Riesgo conocido: puede aparecer un reclamo de Content ID aunque el crédito
  esté puesto. Sube el video como privado unas horas antes para comprobarlo.
- Si prefieres una pista de la Biblioteca de audio de YouTube, reemplaza el
  archivo y vuelve a correr `montar.py`; lo demás no cambia.

## Efectos de sonido

- Todos son propios: los sintetiza `montaje/hacer_efectos.py` con numpy (tonos,
  barridos y ruido). No se descargó ningún efecto y no hay licencias de
  terceros. Los archivos quedan en `montaje/efectos/` y los tiempos en
  `montaje/efectos.json`.

## Imagen

- Personajes, escenarios y utilería: piezas propias de la biblioteca
  `studio/`, sin recursos del catálogo de Roblox ni marcas.
- Fuente de los subtítulos: Lilita One, SIL Open Font License 1.1
  (`herramientas/fuentes/OFL.txt`).

## Texto de créditos puesto en la descripción

Está en `metadatos/publicacion.txt`, bloque DESCRIPTION.

## Reclamos

Ninguno registrado (el video no se ha subido).
