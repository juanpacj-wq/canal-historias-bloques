# Instrucciones del proyecto para cada chat

Este repositorio produce un canal de YouTube de micro-ficción animada con
personajes de bloques: cuentos de 90 a 160 segundos que empiezan con "In this
world, [una regla imposible]", narrados en inglés. Varios chats de Claude Code
trabajan aquí **al mismo tiempo**, cada uno en un video distinto. Estas reglas
existen para que no se pisen.

## Antes de hacer cualquier cosa

0. Si es tu primera vez en este repositorio, lee `RETOMAR.md` (parte 2) y
   `contexto/HISTORIAL.md`: el proyecto viene de otro equipo y ahí está el
   contexto que no se deduce del código.
1. Lee `docs/10-produccion-en-paralelo.md` (el sistema completo) y
   `herramientas/README.md` (los comandos).
2. Pregunta o deduce tu **papel** en este chat. Hay tres:
   - **Productor de un video**: lleva un guion hasta el MP4 final.
   - **Operador de Studio**: solo existe en el plan B (una sola ventana de
     Roblox Studio); atiende la cola de videos que esperan escenas y grabación.
   - **Mantenimiento**: mejora la biblioteca, los guiones o los documentos. No
     toca carpetas de videos tomados por otros.
3. Corre `herramientas\.venv\Scripts\python.exe herramientas\nuevo_video.py estado`
   para ver qué videos están libres y quién tiene cada uno.

## Reglas de convivencia (obligatorias)

- **Un chat, un video, una carpeta.** Solo escribes dentro de
  `videos/NNN-slug/` del video que tomaste. Lo demás es de solo lectura, salvo
  que tu papel sea mantenimiento.
- **Toma el video antes de tocarlo**:
  `nuevo_video.py tomar NNN --chat <nombre-del-chat>`. Si falla porque otro lo
  tiene, elige otro. Nunca borres el archivo `.tomado` de otro chat.
- **Suelta el video al terminar o al abandonar**: `nuevo_video.py soltar NNN`.
  Deja antes una nota en `estado.md` con lo que falta.
- **Marca tu avance** en `videos/NNN-slug/estado.md` al cerrar cada etapa. Es
  la única memoria compartida entre chats.
- **No edites la biblioteca compartida** (`studio/`, `herramientas/`,
  `canal/`, `audio/`) desde un chat productor. Si encuentras un error, anótalo
  en `pendientes-biblioteca.md` (una línea, con fecha y número de video) y
  resuélvelo dentro de tu carpeta. Un chat de mantenimiento lo corrige después.
- **No modifiques guiones ajenos.** Las correcciones al guion de tu video se
  hacen en `guiones/NNN-slug.md` y `.txt` a la vez, y solo de tu video.

## Reglas para Roblox Studio

- **Una ventana de Studio por chat**, con un lugar guardado como
  `videos/NNN-slug/NNN-slug.rbxl`.
- Al empezar y cada vez que una llamada responda "not connected":
  1. Llama `list_roblox_studios`.
  2. Elige la instancia cuyo `name` contiene el nombre de tu archivo. Si no
     aparece, detente y avisa al usuario. **Nunca uses otra instancia.**
  3. Comprueba con `execute_luau` (modo `Edit`) que
     `workspace:GetAttribute("VideoId")` es tu número de video. Si el lugar es
     nuevo, pon el atributo tú mismo y guarda.
  4. Usa ese `studio_id` en todas las llamadas. El id cambia al reabrir Studio.
- **Grabación: de a uno.** Antes de pedir que se grabe, crea `grabacion.lock`
  en la raíz con tu número de video (`New-Item grabacion.lock -Value NNN`, que
  falla si ya existe). Si existe, espera. Bórralo al terminar la grabación.
- Mientras exista `grabacion.lock` de otro chat, no entres a modo juego ni
  lances trabajo pesado (transcripción, montaje).
- Todo se construye **cerca del origen** del mapa y dentro de un `Model` por
  escenario. La forma de usar la biblioteca está en `studio/README.md`.
- **Personajes propios, no el avatar clásico.** Usa el elenco de estilo
  "propio" de `studio/lib/Elenco.luau`. Nunca el logo de Roblox ni recursos del
  catálogo con marcas. Motivo: `docs/04-monetizacion-y-politicas.md`, sección
  "Derechos de Roblox".

## El camino de un video

Cada etapa corresponde a una casilla de `estado.md`.

1. **guion**: lee `guiones/NNN-slug.md`. Verifica que cumpla la lista de
   calidad de `docs/06-plan-de-accion.md` (grupo Guion). Corrige lo necesario.
2. **voz**: el usuario decide la voz (`docs/09-audio-voz-musica-efectos.md`).
   Con ElevenLabs: `voz_elevenlabs.py`. Con voz propia: el usuario deja el
   archivo en `voz/`. Después `ritmo.py`.
3. **tiempos**: `transcribir.py --guion`, luego `planos_tiempos.py`. Resuelve
   los avisos (planos de menos de 0,6 s o más de 3,5 s, frases sin anclar)
   ajustando la tabla de planos del guion.
4. **escenas**: escribe `escenas/puesta.json` (la puesta en escena concreta de
   cada plano, con el esquema de `studio/README.md`), carga la biblioteca en
   Studio, arma primero la **versión gris**, revisa con `screen_capture`,
   después la versión detallada y la luz. Corre el modo ensayo del Director.
5. **grabación**: turno con `grabacion.lock`. El usuario graba con OBS la
   secuencia completa (o se usa `video_capture` si Studio la ofrece). El
   archivo va a `grabacion/toma.mp4`.
6. **montaje**: `subtitulos.py` y `montar.py`. Música y efectos según
   `docs/09`; anota cada pista en `montaje/licencias.md`.
7. **revisión**: `hoja_contactos.py` y `revisar.py`. Mira tú mismo la hoja de
   contactos y seis cuadros. Pasa la lista de calidad completa de `docs/06`.
8. **metadatos**: escribe `metadatos/publicacion.txt` con la plantilla de
   `docs/08-descubrimiento-y-metadatos.md`.
9. **publicado**: lo hace el usuario. Un chat **nunca** sube ni publica nada.

Si una etapa depende del usuario (voz, grabación, publicación), deja el video
listo hasta ese punto, anótalo en `estado.md` y avísale con una lista corta de
lo que necesitas. No te quedes esperando: adelanta lo que no dependa de eso.

## Estilo de escritura

- Documentos y mensajes en español de Colombia neutro, con tuteo. La narración
  de los videos va en inglés.
- Nunca el carácter raya larga (U+2014), en ningún archivo ni idioma.
- Texto para pegar en otra parte (títulos, descripciones, comentarios): en
  archivos `.txt`, a ras de margen, sin viñetas ni comillas envolventes.
- Marca como "sin verificar" lo que no comprobaste. No inventes cifras.

## Git

- Haz commit o push solo cuando el usuario lo pida.
- El único autor de los commits es el dueño del repositorio. No agregues
  líneas de coautoría ni firmas de herramientas en commits, PR ni
  comentarios, y no cambies la identidad de git.
- El repositorio es **público**: nunca subas claves, correos, rutas con el
  nombre de usuario de Windows ni datos del equipo. Los archivos pesados de
  cada video (voz, grabación, MP4, lugares de Studio) están en `.gitignore`.

## Límites

- No crees cuentas, no inicies sesión en nombre del usuario y no publiques en
  YouTube, TikTok ni Instagram.
- Las claves (ElevenLabs y otras) van solo en variables de entorno de la
  sesión. Nunca en archivos.
- No descargues música ni recursos sin registrar su licencia.
- No uses historias, frases ni personajes de otros canales, de respuestas de
  Reddit, de películas o de libros. Las reglas están en
  `docs/05-guiones-y-fuentes.md`.

## Mapa del repositorio

| Carpeta | Qué hay |
|---|---|
| `docs/` | Investigación y plan (01 a 10). |
| `guiones/` | 25 guiones con lista de planos (`.md`) y narración (`.txt`). |
| `videos/` | Una carpeta de trabajo por video, con `estado.md`. |
| `herramientas/` | Scripts de voz, tiempos, subtítulos, montaje y revisión. |
| `studio/` | Biblioteca Luau y script director para Roblox Studio. |
| `canal/` | Nombre, textos e imágenes del canal. |
| `audio/` | Música y efectos compartidos, con `creditos.md`. |
| `arranque/` | Mensajes listos para abrir cada tipo de chat. |
| `investigacion/` | Informes técnicos y datos crudos. |
| `contexto/` | Historial, memoria y conversación del primer equipo. |
