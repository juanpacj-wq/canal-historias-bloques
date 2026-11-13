# Cómo retomar este proyecto en otro equipo

Este repositorio es el traslado completo del trabajo hecho en un primer
equipo, donde Roblox Studio no abría. Aquí está todo: investigación, plan,
guiones, herramientas, biblioteca de Studio, identidad del canal y el contexto
de la conversación. Este archivo dice cómo recibirlo.

Tiene dos partes: lo que haces tú y lo que debe hacer el chat de Claude Code
que continúe.

## Parte 1. Para ti (30 a 60 minutos)

1. **Clona el repositorio** en una ruta corta y sin espacios, por ejemplo
   `C:\proyectos\canal`. Usa un usuario de Windows cuyo nombre no tenga
   espacios: el archivo `mcp.bat` de Studio falla si la ruta del perfil los
   tiene (reporte de la comunidad).

```powershell
git clone https://github.com/juanpacj-wq/canal-historias-bloques.git C:\proyectos\canal
cd C:\proyectos\canal
```

2. **Prepara el equipo.** Instala lo que falte (Git, Python, FFmpeg, Node,
   Claude Code, OBS, Roblox Studio), crea el entorno de Python y corre la
   prueba de las herramientas:

```powershell
powershell -ExecutionPolicy Bypass -File .\preparar-equipo.ps1
```

3. **Roblox Studio**, a mano:
   - Ábrelo e inicia sesión con tu cuenta de Roblox.
   - Crea un lugar con la plantilla Baseplate y guárdalo como archivo
     (Archivo, Guardar en archivo como) en `videos\prueba\prueba.rbxl`.
   - En Assistant, menú "...", Manage MCP Servers: activa "Enable Studio as
     MCP server". Mira el interruptor "Data access": si queda encendido,
     Studio puede compartir tus prompts con Roblox.
4. **Corre de nuevo** `preparar-equipo.ps1`. Ahora sí registra el servidor
   MCP en Claude Code.
5. **Abre Claude Code** en la carpeta del proyecto (`claude`), escribe `/mcp`
   y confirma que `Roblox_Studio` aparece conectado.
6. **Pega el contenido de `arranque/0-retomar-en-casa.txt`** como primer
   mensaje. Ese chat lee el contexto y sigue desde donde quedó.

Si algo de esto falla, la tabla de problemas está al final de
`docs/10-produccion-en-paralelo.md`.

## Parte 2. Para el chat que retoma

### Qué leer, en este orden

1. `CLAUDE.md`: reglas del proyecto y de convivencia entre chats.
2. `contexto/HISTORIAL.md`: qué pasó, qué se decidió y qué nunca se probó.
3. `README.md`: resumen de la investigación e índice de todo.
4. `docs/10-produccion-en-paralelo.md`: el plan de arranque en este equipo.
5. `studio/README.md`: la biblioteca de Studio y su guion de primera prueba.
6. Solo si necesitas el detalle de una decisión: `contexto/conversacion.md`
   (la conversación completa, larga; búscala por palabra, no la leas entera).

### El estado, en una frase

Todo lo que no toca Roblox Studio está hecho y probado; todo lo que toca
Studio está escrito pero **nunca se ejecutó**. Tu primer trabajo es
comprobarlo, y es normal que algo falle.

### Orden de trabajo en este equipo

| # | Tarea | Con qué | Cuándo se da por hecha |
|---|---|---|---|
| 1 | Validar la conexión y la biblioteca de Studio | `arranque/1-primera-prueba-en-studio.txt` y el guion de 15 pasos de `studio/README.md` | Personaje, poses, caras, un escenario, luz, cámara y el Director funcionan, con capturas. Lo corregido queda en `studio/` y anotado |
| 2 | Recrear la imagen del canal con capturas de Studio | `canal/recrear-imagen-en-studio.md` | Perfil, banner, marca de agua y plantilla de miniatura en `canal/imagen/studio/`, revisadas |
| 3 | Acompañar al usuario a crear la cuenta y el canal | `docs/07-canal-y-cuenta.md`, sección 6, y `canal/textos-canal.txt` | El canal existe, con imagen, descripción y ajustes. Los pasos de identidad los hace el usuario |
| 4 | Piloto: el video 001 completo | `arranque/2-chat-productor.txt` | MP4 aprobado por `revisar.py` y por el usuario; tiempos de cada etapa anotados |
| 5 | Probar dos chats con dos ventanas de Studio | `docs/10`, paso C | Cada chat encuentra su ventana y no escribe en la otra |
| 6 | Producción por tandas | `guiones/INDICE.md` y `videos/CALENDARIO.md` | Reserva de 5 videos antes de publicar el primero |

No saltes al paso 4 sin el 1: producir sobre una biblioteca sin validar
desperdicia el tiempo de todos los chats.

### Decisiones que el usuario todavía debe tomar

Pregúntalas cuando haga falta, no todas de entrada:

- Nombre definitivo del canal. Recomendado: Almostville. La disponibilidad
  se comprobó el 2026-11-13; vuelve a comprobarla el día de la creación.
- Voz: propia o sintética, y cuál (`docs/09-audio-voz-musica-efectos.md`).
- Personajes: el kit usa un elenco propio por el riesgo de marca de Roblox
  (`docs/04-monetizacion-y-politicas.md`). Puede preferir el avatar clásico.

### Reglas que no están escritas en ningún otro lado

- **Commits**: el único autor es el dueño del repositorio. No agregues
  líneas de coautoría ni firmas de herramientas en commits, PR o
  comentarios. Haz commit o push solo cuando el usuario lo pida.
- **Idioma**: español de Colombia neutro, con tuteo. La narración de los
  videos va en inglés.
- **Nunca** el carácter raya larga (U+2014), en ningún archivo.
- **Texto para pegar** en otra parte: en `.txt`, a ras de margen, sin
  viñetas decorativas ni comillas envolventes.
- **No crees cuentas ni publiques** en nombre del usuario.
- **No esquives controles de seguridad** del equipo o de la red.

### Memoria

El asistente del primer equipo guardó una nota de memoria del proyecto. Está
copiada en `contexto/memoria.md`. Guárdala en tu propia memoria al empezar,
actualizada con lo que cambie en este equipo (por ejemplo, que aquí Studio sí
abre).

## Qué no está en este repositorio

| Qué | Por qué | Cómo se recupera |
|---|---|---|
| El entorno de Python (`herramientas/.venv`) | Pesa 350 MB y depende del equipo | `preparar-equipo.ps1` lo crea |
| La transcripción cruda de la sesión | Trae datos personales y del primer equipo | `contexto/conversacion.md` es la versión legible y saneada |
| La carpeta de consejos de TikTok que el usuario tenía | Son capturas de un tercero | Sus tres ideas útiles están integradas en `docs/05` y `docs/06` |
| El video de referencia descargado y sus cuadros | Es contenido de otro canal | El enlace y el análisis están en `docs/01` |
| Música y efectos | Hay que descargarlos leyendo la licencia vigente | `docs/09` y `audio/README.md` |
| Lugares de Studio (`.rbxl`) | Todavía no existe ninguno | Se crean en este equipo |
