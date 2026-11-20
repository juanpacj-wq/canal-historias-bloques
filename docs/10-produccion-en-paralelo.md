# 10. Producción en paralelo: varios chats, varios videos

> **Actualización del 2026-11-13.** Este documento se escribió antes de poder
> abrir Studio. El primer video ya se produjo y el método real está en
> `docs/11-metodo-probado.md`, que manda sobre este. Quedaron superadas las
> secciones 2 y 3 (traslado y validación, ya hechos), la grabación con OBS, la
> versión gris y el plan B con un chat operador (sección 5). Sigue vigente la
> idea de un chat por video con su propia ventana de Studio, con un cambio: el
> rodaje captura la pantalla, así que solo un chat puede rodar a la vez y el
> equipo queda ocupado mientras tanto. Varios chats pueden escribir puestas y
> revisar planos en paralelo; el rodaje se turna con `grabacion.lock`. Eso
> (paso C) sigue **sin probar**.

Cómo pasar del kit al primer video, y de ahí a varios chats de Claude Code
produciendo al mismo tiempo.

## 1. Qué está listo y qué no

| Pieza | Estado | Dónde |
|---|---|---|
| 25 guiones con lista de planos | Escritos. Falta tu pasada sobre gancho y remate | `guiones/` |
| Herramientas de voz, tiempos, subtítulos, montaje y revisión | **Probadas de punta a punta** con voz sintética de Windows y video falso | `herramientas/` |
| Reclamo de videos entre chats | **Probado** con 12 procesos simultáneos | `herramientas/nuevo_video.py` |
| Cadena voz, ritmo, tiempos, planos y subtítulos sobre los 25 guiones | **Probada**, tres guiones a la vez, con voz sintética de Windows: los 25 terminaron y todos los planos anclaron a su narración (93 a 99 % de palabras reconocidas). Quedan 27 avisos (23 planos de menos de 0,6 s y 4 de más de 3,5 s), que dependen de la voz real y se resuelven en la etapa de tiempos | `herramientas/prueba/ensayo_25_guiones.ps1` |
| Biblioteca Luau y script director | Escrita y analizada; **nunca corrió en Studio** | `studio/` |
| Conexión de Claude Code con Studio | Comando confirmado en la documentación; sin probar en vivo | `preparar-equipo.ps1` |
| Varias ventanas de Studio a la vez | Documentado por Roblox; sin probar | `investigacion/studio-mcp-y-paralelismo.md` |
| Nombre, textos e imágenes del canal | Listos | `canal/` |
| Guía de cuenta y monetización | Lista | `docs/07-canal-y-cuenta.md` |
| Metadatos y publicación | Listos | `docs/08-descubrimiento-y-metadatos.md` |
| Voz, música y efectos | Guía lista; falta que elijas la voz | `docs/09-audio-voz-musica-efectos.md` |
| Llamada real a ElevenLabs | Sin probar (no hay clave) | `herramientas/voz_elevenlabs.py` |

## 2. Llevar el proyecto al equipo de casa

1. Copia la carpeta completa del proyecto (memoria USB, nube o un repositorio
   privado de git). No hace falta copiar `herramientas/.venv` ni
   `herramientas/prueba`: se regeneran.
2. Usa un usuario de Windows **sin espacios en el nombre**. El archivo
   `mcp.bat` de Studio falla si la ruta del perfil tiene un espacio (reporte de
   la comunidad).
3. Abre PowerShell en la carpeta del proyecto y corre:

```powershell
powershell -ExecutionPolicy Bypass -File .\preparar-equipo.ps1
```

   Instala lo que falte (Git, Python, FFmpeg, Node, Claude Code, OBS, Roblox
   Studio), crea el entorno de Python, corre la prueba de las herramientas y
   al final imprime qué quedó listo y qué pasos son tuyos.
4. Haz los pasos manuales que el script lista (iniciar sesión en Studio,
   activar el servidor MCP) y vuelve a correrlo para que registre la conexión.

## 3. Primer día en el equipo de casa

No abras varios chats todavía. El orden importa, porque cada paso condiciona
el siguiente.

### Paso A. Validar Studio con un solo chat (1 a 3 horas)

Abre una ventana de Studio con un lugar vacío guardado como archivo, abre
`claude` en la carpeta del proyecto y pega el contenido de
`arranque/1-primera-prueba-en-studio.txt`.

Ese chat prueba la conexión, carga la biblioteca y recorre personajes, poses,
caras, escenarios, luz, cámara y el Director. Lo que falle lo corrige ahí
mismo. Cuenta con que algo falle: la biblioteca se escribió sin poder
ejecutarla.

### Paso B. El piloto, con un solo chat (medio día a un día)

Produce el video 001 completo con `arranque/2-chat-productor.txt`. Mide cuánto
tarda cada etapa y anótalo en `videos/001-.../estado.md`. Es el piloto de
`docs/06-plan-de-accion.md`: decide con sus criterios si el flujo sirve.

Dos decisiones que el piloto debe cerrar:

- **Cómo grabar.** Opciones, de mejor a peor: la herramienta `video_capture`
  de Studio si tu versión la ofrece; OBS capturando la ventana a 60 cuadros;
  el grabador interno de Studio. Ajustes de OBS y forma de sincronizar con el
  destello inicial: `investigacion/studio-mcp-y-paralelismo.md`, sección 5.
- **Vertical real o recorte.** El modo vertical de la cámara (girada 90
  grados) da 1080 por 1920 reales; el recorte de una toma horizontal pierde
  resolución. `montar.py --rotar` revierte el giro.

### Paso C. Probar el paralelo (1 hora)

1. Abre **dos** ventanas de Studio, cada una con su lugar guardado en la
   carpeta de su video: `videos/002-.../002-....rbxl` y
   `videos/003-.../003-....rbxl`. Activa el servidor MCP en ambas.
2. Abre **después** dos terminales con `claude` y pega en cada una
   `arranque/2-chat-productor.txt`, cambiando la letra del chat y el número.
3. Comprueba que cada chat encuentra su ventana, que no escribe en la otra y
   que la grabación de uno no se entrecorta con el otro trabajando.

Si funciona, ese es tu modo de trabajo (plan A). Si las ventanas no aparecen
en la lista, se cruzan o el equipo no aguanta, pasa al plan B.

## 4. Plan A: un chat por video, cada uno con su Studio

Regla base: **un chat, una ventana de Studio, un lugar, una carpeta**.

Rutina para abrir una tanda de N videos:

1. Decide cuáles (`nuevo_video.py estado` muestra los libres).
2. Crea las carpetas: `nuevo_video.py crear NNN` para cada uno.
3. Abre N ventanas de Studio. En cada una: lugar nuevo, guardar como
   `videos/NNN-slug/NNN-slug.rbxl`, activar el servidor MCP.
4. Abre N terminales con `claude` en la raíz del proyecto y pega
   `arranque/2-chat-productor.txt` con la letra y el número de cada uno.
5. Abre **primero todas las ventanas de Studio y después los chats**. Hay un
   fallo reportado: una ventana abierta después puede no aparecer en la lista.
6. Atiende los avisos: cada chat te llama solo para la voz (si es propia), la
   grabación y la aprobación final.

Lo que evita que se pisen (todo está en `CLAUDE.md`, que cada chat lee solo):

| Riesgo | Protección |
|---|---|
| Dos chats toman el mismo video | Archivo `.tomado` creado con apertura exclusiva |
| Un chat escribe en el Studio de otro | Cada llamada lleva `studio_id`; el chat verifica el nombre del lugar y el atributo `VideoId` antes de escribir |
| Dos grabaciones a la vez | Archivo `grabacion.lock` en la raíz |
| Dos chats editan la biblioteca | Solo el chat de mantenimiento la toca; los demás anotan en `pendientes-biblioteca.md` |
| Se pierde el hilo al cerrar un chat | `estado.md` de cada video guarda etapa y notas |

Cuántos a la vez (estimación, Roblox no publica consumo): con 16 GB de
memoria, dos ventanas de Studio; con 32 GB y tarjeta gráfica dedicada, tres o
cuatro en edición, grabando de a una. No minimices las ventanas de Studio: las
capturas pueden salir mal. Un segundo monitor ayuda.

## 5. Plan B: una sola ventana de Studio

Si no se sostienen varias ventanas, el paralelo se mueve fuera de Studio, que
es donde se va la mayor parte del tiempo de un video.

- **Dos a cuatro chats productores sin Studio**
  (`arranque/3-chat-productor-sin-studio.txt`): guion, voz, tiempos, puesta en
  escena en `puesta.json`, metadatos y, cuando vuelve la grabación, montaje y
  revisión.
- **Un chat operador** (`arranque/4-chat-operador-studio.txt`): atiende la
  cola de videos marcados "LISTO PARA STUDIO", arma escenas, te avisa para
  grabar y los devuelve marcados "GRABADO".

Como cada video es un archivo de datos sobre una biblioteca común, el tiempo
dentro de Studio por video debería ser corto. Eso también lo mide el piloto.

## 6. Tu parte en cada video

Lo que no se puede delegar, y cuánto toma (estimaciones, a confirmar con el
piloto):

| Qué | Cuándo | Tiempo |
|---|---|---|
| Reescribir gancho y remate del guion | Antes de la voz | 10 min |
| Grabar la voz (si es propia) | Etapa voz | 10 a 15 min |
| Revisar las capturas de la versión gris | Etapa escenas | 5 min |
| Grabar la pantalla | Etapa grabación | 5 min |
| Ver el video final completo, con sonido | Etapa revisión | 5 min |
| Subir y publicar | Al final | 5 min |

Esa edición humana no es un trámite: es lo que separa un canal original de uno
"producido en masa" ante la política de contenido no auténtico de YouTube
(`docs/04-monetizacion-y-politicas.md`). Con varios chats es fácil caer en
publicar sin mirar. No lo hagas: un video flojo cuesta más de lo que suma.

## 7. Ritmo sugerido

- **Semana 1**: pasos A, B y C. Un video, el piloto.
- **Semana 2**: dos chats a la vez. Meta: 3 a 5 videos terminados y la
  biblioteca corregida con lo aprendido. No publiques hasta tener 5 listos.
- **Semana 3 en adelante**: tandas de 2 a 4 videos. Publicación diaria, con
  una reserva de al menos 5 videos terminados sin publicar.
- Un chat de mantenimiento (`arranque/5-chat-mantenimiento.txt`) una vez por
  semana: corrige la biblioteca y escribe guiones nuevos. Los 25 guiones
  alcanzan para unas cuatro semanas a ritmo diario.

Orden de producción recomendado: empieza por los guiones que reutilizan los
escenarios base (colegio, casa, parque, pueblo) y deja para después los que
piden escenarios nuevos. La tabla está en `guiones/INDICE.md`.

## 8. Si algo sale mal

| Síntoma | Qué hacer |
|---|---|
| `Roblox_Studio` no aparece en `/mcp` | Activa el servidor en Studio, corre de nuevo `preparar-equipo.ps1`, reinicia `claude` |
| Dejó de funcionar tras actualizarse Studio | Reinicia el chat una vez (indicación oficial de Roblox) |
| Una ventana no aparece en `list_roblox_studios` | Abre su panel de servidores MCP; si no, reinicia el chat |
| Un chat se cerró con un video tomado | `nuevo_video.py soltar NNN` y otro chat lo retoma leyendo `estado.md` |
| Quedó un `grabacion.lock` huérfano | Confirma que nadie graba y bórralo |
| Los cortes no coinciden con la voz | `montar.py --desfase`; revisa el destello de sincronía |
| Studio no abre | Mira el registro en `%LOCALAPPDATA%\Roblox\logs`. En el primer equipo lo causaba el agente de seguridad (`docs/03`) |
