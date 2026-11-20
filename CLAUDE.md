# Instrucciones del proyecto para cada chat

Este repositorio produce un canal de YouTube de micro-ficción animada con
personajes de bloques: cuentos de 90 a 160 segundos que empiezan con "In this
world, [una regla imposible]", narrados en inglés. Varios chats de Claude Code
pueden trabajar aquí al mismo tiempo, cada uno en un video distinto.

## Antes de hacer cualquier cosa

1. Define tu **papel**:
   - **Productor de un video**: lleva un guion hasta el MP4 final. Usa la skill
     `producir-video` y síguela paso a paso. No leas los `docs/` ni los fuentes
     de la biblioteca salvo que un paso falle: la skill y los encabezados de
     las herramientas tienen lo necesario.
   - **Mantenimiento**: mejora la biblioteca, los guiones o los documentos. No
     toca carpetas de videos tomados por otros.
2. Corre `herramientas\.venv\Scripts\python.exe herramientas\nuevo_video.py estado`
   para ver qué videos están libres y quién tiene cada uno.

El método completo y su porqué están en `docs/11-metodo-probado.md`. El primer
video terminado (`videos/001-friendships-have-a-battery/`) es el ejemplo de
referencia de puesta, efectos, licencias y metadatos.

## Reglas de convivencia (obligatorias)

- **Un chat, un video, una carpeta.** Solo escribes dentro de
  `videos/NNN-slug/` del video que tomaste. Lo demás es de solo lectura, salvo
  que tu papel sea mantenimiento.
- **Toma el video antes de tocarlo**:
  `nuevo_video.py tomar NNN --chat <nombre-del-chat>`. Si otro lo tiene, elige
  otro. Nunca borres el archivo `.tomado` de otro chat.
- **Suelta el video al terminar o al abandonar**: `nuevo_video.py soltar NNN`,
  con una nota en `estado.md` de lo que falta.
- **Marca tu avance** en `videos/NNN-slug/estado.md` al cerrar cada etapa. Es
  la única memoria compartida entre chats.
- **No edites la biblioteca compartida** (`studio/`, `herramientas/`,
  `canal/`, `audio/`) desde un chat productor. Si encuentras un error, anótalo
  en `pendientes-biblioteca.md` (una línea, con fecha y número de video) y
  resuélvelo dentro de tu carpeta. Excepción: si eres el único chat abierto y
  el dueño lo autoriza, corrige la biblioteca y déjalo anotado.
- **No modifiques guiones ajenos.** Las correcciones al guion de tu video se
  hacen en `guiones/NNN-slug.md` y `.txt` a la vez, y solo de tu video.

## Reglas para Roblox Studio

- **Una ventana de Studio por video**, con su lugar guardado como
  `videos/NNN-slug/NNN-slug.rbxl`. `herramientas/studio/puente.py --video NNN
  abrir` lo crea desde la plantilla, lo abre y comprueba el atributo `VideoId`.
- Las herramientas de `herramientas/studio/` solo hablan con la ventana cuyo
  nombre contiene `NNN-slug`. **Nunca uses otra instancia**, y nunca la del
  dueño ("Experiencia sin título" u otra).
- **Rodaje: de a uno.** La vista previa y la toma capturan la pantalla, así que
  solo puede rodar un chat a la vez y el equipo queda ocupado. `rodar.py` toma
  y suelta `grabacion.lock` solo. Si el archivo existe y no es tuyo, espera, y
  mientras tanto no lances trabajo pesado (voz, montaje).
- **Personajes propios, no el avatar clásico.** Nunca el logo de Roblox ni
  recursos del catálogo con marcas. Motivo:
  `docs/04-monetizacion-y-politicas.md`, sección "Derechos de Roblox".

## El camino de un video

Cada etapa corresponde a una casilla de `estado.md`. Las órdenes exactas están
en la skill `producir-video`.

1. **guion**: lee `guiones/NNN-slug.md`.
2. **voz**: `producir.py voz NNN` (Kokoro local, o `--audio` con la voz que dé
   el dueño). La voz definitiva la decide el dueño.
3. **tiempos**: salen del mismo paso; corrige la tabla de planos si hay avisos.
4. **escenas**: `escenas/hacer_puesta.py` con `herramientas/studio/puesta.py`,
   revisión con `ver.py` y vista previa con `rodar.py previa`.
5. **grabación**: `rodar.py toma`, cuadro a cuadro. No se usa OBS.
6. **montaje**: `producir.py montar NNN`, con música registrada en
   `montaje/licencias.md` y efectos propios.
7. **revisión**: mira tú mismo `revision/hoja_contactos.png` y el informe.
8. **metadatos**: `metadatos/publicacion.txt` con la plantilla de `docs/08`,
   sección 3.1.
9. **publicado**: lo hace el dueño. Un chat **nunca** sube ni publica nada.

Si una etapa depende del dueño, deja el video listo hasta ese punto, anótalo en
`estado.md` y avísale con una lista corta. No te quedes esperando.

## Forma de trabajar (ahorra tiempo y tokens)

- Archivos: escríbelos y edítalos con las herramientas de escritura y edición o
  con un script de Python. Nunca con `Set-Content`, `Out-File` ni reemplazos
  de PowerShell (agregan BOM y fallan con textos de varias líneas).
- Revisa imágenes en hojas (10 planos por imagen), no plano por plano.
- No ruedes la toma final sin mirar antes las hojas de la vista previa.
- Las órdenes de más de 10 minutos van en segundo plano.
- No delegues en subagentes lo que ya hace una orden de `producir.py`.

## Estilo de escritura

- Documentos y mensajes en español de Colombia neutro, con tuteo. La narración
  de los videos va en inglés.
- Nunca el carácter raya larga (U+2014), en ningún archivo ni idioma.
- Texto para pegar en otra parte (títulos, descripciones, comentarios): en
  archivos `.txt`, a ras de margen, sin viñetas ni comillas envolventes.
- Marca como "sin verificar" lo que no comprobaste. No inventes cifras.

## Git

- Haz commit o push solo cuando el dueño lo pida.
- El único autor de los commits es el dueño del repositorio. No agregues
  líneas de coautoría ni firmas de herramientas en commits, PR ni
  comentarios, y no cambies la identidad de git.
- El repositorio es **público**: nunca subas claves, correos, rutas con el
  nombre de usuario de Windows ni datos del equipo. Los archivos pesados de
  cada video (voz, grabación, MP4, música, lugares de Studio) están en
  `.gitignore`.

## Límites

- No crees cuentas, no inicies sesión en nombre del dueño y no publiques en
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
| `.claude/skills/` | La skill `producir-video`: el paso a paso de un video. |
| `docs/` | Investigación y plan (01 a 10) y el método probado (11). |
| `guiones/` | 25 guiones con lista de planos (`.md`) y narración (`.txt`). |
| `videos/` | Una carpeta de trabajo por video, con `estado.md`. |
| `herramientas/` | `producir.py`, los scripts de voz, tiempos y montaje, y `studio/` (puente, revisión, rodaje, puesta y efectos). |
| `studio/` | Biblioteca Luau, director de planos y plantilla de lugar. |
| `canal/` | Nombre, textos e imágenes del canal. |
| `audio/` | Música y efectos compartidos, con `creditos.md`. |
| `arranque/` | Mensajes listos para abrir cada tipo de chat. |
| `investigacion/` | Informes técnicos y datos crudos. |
| `contexto/` | Historial, memoria y conversación del primer equipo. |
