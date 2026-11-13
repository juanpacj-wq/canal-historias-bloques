# Roblox Studio por MCP y trabajo en paralelo: informe técnico

Fecha de la investigación: 2026-11-13. Versión de Studio analizada: 0.747.0.7471481
(`version-63eb6055af4e4688`), `StudioMCP.exe` 1.0.0 (362829b).

## Cómo leer este informe

Cada afirmación lleva una de estas etiquetas:

- **[OFICIAL]**: confirmado en documentación oficial de Roblox, OBS o Anthropic, o en una
  publicación firmada por personal de Roblox en DevForum.
- **[BINARIO]**: leído directamente en los archivos de Studio 0.747 (cadenas de texto de
  `StudioMCP.exe` y del plugin integrado `Assistant.rbxm`, y la salida de
  `StudioMCP.exe --help`). Es un hecho sobre esta versión, pero no está documentado y puede
  cambiar o estar apagado por una bandera remota.
- **[COMUNIDAD]**: reportado por usuarios en DevForum o GitHub, sin confirmación oficial.
- **[INFERENCIA]**: deducción mía a partir de lo anterior. No está probado.

Nada de este informe se probó contra un Studio en ejecución, porque en este equipo Studio
no abre. Todo lo marcado como inferencia, y también lo marcado como binario, debe
comprobarse en el equipo de casa antes de darlo por cierto. La sección 9 trae la lista de
comprobaciones.

### Hallazgo previo: Studio ya no está instalado en este equipo

La tarea partía de que `%LOCALAPPDATA%\Roblox\Versions\version-63eb6055af4e4688` contenía
`StudioMCP.exe`. Hoy esa carpeta solo contiene `RobloxStudioInstaller.exe`. El registro
`%LOCALAPPDATA%\Roblox\logs\RobloxStudioInstaller_68C81.log` muestra que a las 07:07 (hora
local) el instalador corrió en modo `Uninstall` y borró `RobloxStudioBeta.exe` y el resto.
No lo reinstalé ni intenté abrir Studio.

Para poder inspeccionar los binarios descargué a una carpeta temporal los paquetes públicos
de esa misma versión desde el servidor de instalación de Roblox
(`https://setup.rbxcdn.com/version-63eb6055af4e4688-RobloxStudio.zip` y
`...-BuiltInStandalonePlugins.zip`), extraje `StudioMCP.exe` (SHA-256
`023162f8689a3ef6043387269fe0ccc6a9eca0fc55afd6567dbb3cc567cec7aa`) y
`Assistant.rbxm`, y busqué cadenas de texto. Solo ejecuté `StudioMCP.exe --help` y
`--version`, que no lanzan Studio.

`mcp.bat` no viene en ningún paquete de instalación y no existe en este equipo: lo genera
Studio cuando llega a ejecutarse **[INFERENCIA]**. Por eso su contenido no se pudo leer.

---

## 1. Servidor MCP integrado de Studio

### 1.1 Arquitectura

- **[OFICIAL]** El servidor viene dentro de Studio, corre como proceso local y habla con el
  cliente por transporte `stdio`
  ([doc oficial](https://create.roblox.com/docs/studio/mcp),
  [fuente en GitHub](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/studio/mcp.md),
  última actualización del archivo: 2026-11-12).
- **[BINARIO]** `StudioMCP.exe` se describe a sí mismo como "MCP proxy for Roblox Studio".
  Sus únicas opciones son `-v/--verbose`, `-s/--stdio` ("No-opt for now"), `-h` y `-V`.
- **[BINARIO]** Funciona en tres capas:
  1. Cada cliente MCP (cada sesión de Claude Code) lanza **su propio** proceso
     `StudioMCP.exe` por stdio.
  2. El primer `StudioMCP.exe` que arranca abre un servidor WebSocket local ("WS host") en
     el puerto **13469** de `localhost`, con las rutas `/studio`, `/proxy`, `/health` y
     `/capture`. Los `StudioMCP.exe` siguientes encuentran el puerto ocupado ("Port already
     in use ... this process is not the host") y se conectan al primero como "proxy" por
     `ws://127.0.0.1:13469/proxy`.
  3. Cada ventana de Studio con el MCP activado se conecta a `ws://localhost:13469/studio`
     y se registra con un identificador.
  El host enruta cada petición al Studio indicado por `studio_id` y devuelve la respuesta
  al proxy que la pidió ("Routing request from proxy ... to studio ...", "Forwarding
  response ... to proxy ...").
- **[BINARIO]** Si el proceso host muere, los demás intentan tomar el puerto ("WS host
  server exited, will try to re-bind", "Reconnecting in ..."). Hay un token de
  autenticación guardado en la carpeta de datos de Roblox
  (`FFlagStudioMCPProxyTokenEnforce`, "Rejected WebSocket request: mode=enforce ...
  status=401") y se rechazan peticiones con cabecera `Origin` de navegador.
- **[COMUNIDAD]** Ese control de token causó un fallo temporal: desde el 2026-10-27 hubo
  reportes de Studio recibiendo 401 de StudioMCP
  ([DevForum](https://devforum.roblox.com/t/studio-mcp-studio-always-gets-401-unauthorized-from-studiomcp-token-enforcement-on-studio-never-passes/4960526)).

### 1.2 Activación y conexión de Claude Code

- **[OFICIAL]** Activar: abrir Assistant, menú "...", Manage MCP Servers, encender "Enable
  Studio as MCP server". Con un cliente conectado aparece un indicador verde con el número
  de clientes.
- **[OFICIAL]** Conexión rápida (Quick connect): Assistant Settings, MCP Servers,
  desplegable Quick connect, encender "Claude Code". Clientes soportados: Antigravity,
  Codex CLI, Claude Code, Claude Desktop, Cursor, Gemini CLI y Visual Studio Code.
- **[OFICIAL]** Comando manual en Windows: `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`.
  Configuración JSON equivalente:

```json
{
  "mcpServers": {
    "Roblox_Studio": {
      "command": "cmd.exe",
      "args": ["/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"]
    }
  }
}
```

- **[BINARIO]** El plugin de Assistant arma para Claude Code exactamente esta plantilla:
  `claude mcp add --transport stdio Roblox_Studio -- <comando>`. Con el comando oficial de
  Windows queda:

```
claude mcp add --transport stdio --scope user Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
```

  El `--scope user` lo agrego yo para que sirva en todas las carpetas de proyecto; la
  plantilla del plugin no trae alcance. Esto confirma el comando que `docs/03` daba como
  "sin verificar", aunque sigue sin probarse en vivo.
- **[BINARIO]** Quick connect busca y edita `~/.claude.json` (o
  `%CLAUDE_CONFIG_DIR%\.claude.json`) y también lee `~/.claude/settings.json`. Antes de
  modificar deja una copia con sufijo `.roblox-studio-backup`. En el mismo módulo hay
  código que agrega ganchos (`UserPromptSubmit`, `PostToolUse`, `PostToolUseFailure`) a la
  configuración de Claude Code, ligado a un ajuste llamado "Data access" cuyo texto es: "To
  help improve the Studio experience, provide Roblox with access to prompt information. You
  can change this setting at any time." **[INFERENCIA]** Si ese ajuste queda encendido,
  Studio puede instalar un gancho que comparte con Roblox información de tus prompts.
  Revisa ese interruptor y el contenido de `~/.claude/settings.json` después de usar Quick
  connect. Si prefieres control total, usa el comando manual.
- **[OFICIAL]** Alcances de Claude Code
  ([doc de Claude Code](https://code.claude.com/docs/en/mcp)): `local` (por defecto, en
  `~/.claude.json`, solo el proyecto actual), `project` (archivo `.mcp.json` en la raíz del
  proyecto, pensado para compartir) y `user` (en `~/.claude.json`, todos los proyectos).
  `.mcp.json` admite expansión `${VAR}` y `${VAR:-valor}`. Sintaxis:
  `claude mcp add [opciones] <nombre> -- <comando> [args...]`.
- **[COMUNIDAD]** `mcp.bat` falla si la ruta del perfil de Windows tiene un espacio (por
  ejemplo un nombre de usuario con espacio); la salida es apuntar el cliente directo a
  `StudioMCP.exe`
  ([DevForum](https://devforum.roblox.com/t/mcpbat-fails-to-launch-studio-mcp-due-to-unquoted-path-containing-spaces-roblox-is-not-recognized/4975979)).
  **[INFERENCIA]** Apuntar directo a `StudioMCP.exe` tiene un costo: vive en
  `Versions\version-XXXX\`, y esa carpeta cambia con cada actualización de Studio, así que
  habría que corregir la ruta cada semana. En el equipo de casa conviene un usuario de
  Windows sin espacios y usar `mcp.bat`.
- **[OFICIAL]** Después de que Studio se actualiza hay que reiniciar una vez el cliente de
  IA ([DevForum, personal de Roblox, 2026-08-19](https://devforum.roblox.com/t/studio-mcp-multi-agent-improvements-and-connected-ai-clients/4820583)).

### 1.3 Lista de herramientas

**[OFICIAL]** Lista publicada en la doc al 2026-11-12. "Every tool call takes a `studio_id`
parameter that names the Studio instance it targets."

| Grupo | Herramienta | Qué hace y parámetros conocidos |
|---|---|---|
| Sesión | `list_roblox_studios` | Lista las instancias conectadas. **[BINARIO]** Cada resultado trae `id`, `name` (incluye el id del lugar o el nombre del archivo), `mode` (`Edit`/`Play`), `state`, y `persistedToCloud`, `placeId`, `universeId` o `file` según cómo esté guardado el lugar. |
| Luau | `execute_luau` | Ejecuta Luau y devuelve el resultado o el error. Requiere `datamodel_type`: `Edit`, `Client` o `Server`. |
| Scripts | `script_read` | Lee un script por ruta con puntos (`game.ServerScriptService.MyScript`), completo o por rango de líneas. |
| Scripts | `multi_edit` | Aplica varias ediciones a un script; si la ruta no existe, **crea el script**. Requiere `datamodel_type` (Edit). **[BINARIO]** Forma: `{"file_path":"ReplicatedStorage.X","edits":[{"old_string":"...","new_string":"..."}]}`. |
| Scripts | `script_search` | Búsqueda difusa por nombre de script, máximo 10 resultados. |
| Scripts | `script_grep` | Busca un patrón en todos los scripts, máximo 50 coincidencias. |
| Explorar | `search_game_tree` | Árbol de instancias en JSON plano. **[BINARIO]** Parámetros: `datamodel_type`, `path`, `instance_type`, `keywords`, `max_depth`, `head_limit`. |
| Explorar | `inspect_instance` | Propiedades, atributos y resumen de hijos de una instancia. |
| Explorar | `subagent` | Lanza un subagente interno de tipo `explore` o `playtest`. |
| Prueba | `get_studio_state` | Estado de Studio: si está en juego y qué `datamodel_type` hay disponibles. |
| Prueba | `start_stop_play` | Inicia o detiene la prueba. **[BINARIO]** Parámetro `is_start` (booleano): "true to start the game, false to stop the game and return to edit mode". |
| Prueba | `get_console_output` | Devuelve la salida de la ventana Output. |
| Prueba | `screen_capture` | Captura el visor y devuelve la imagen. **[BINARIO]** `capture_id` (texto, obligatorio), y opcionales `camera_position` y `look_at_position` (arreglos de 3 números, deben ir juntos). Descripción interna: "Capture current edit-time screen". |
| Entrada | `character_navigation` | Mueve al personaje del jugador a una posición o instancia. |
| Entrada | `user_keyboard_input` | Secuencia de teclas: keyDown, keyUp, keyPress, textInput, wait. |
| Entrada | `user_mouse_input` | Secuencia de ratón: mover, clic, botón, rueda, wait (0 a 10000 ms). |
| Recursos | `search_asset` | Busca en Creator Store y en el inventario del creador. |
| Recursos | `insert_asset` | Inserta un recurso por su id numérico (modelos, mallas, imágenes, audio, video, animaciones, paquetes). |
| Recursos | `upload_image` | "Uploads a batch of images from HTTP URLs to the Roblox asset server, returning an image path to asset ID map." **[BINARIO]** Recibe un arreglo de rutas HTTP; el ejemplo interno es `{"http://localhost/image.png": "rbxassetid://12345678"}`. |
| Recursos | `store_image` | Carga una imagen **local** y devuelve un URI `IMAGEID_<id>` para pasarlo a otras herramientas de generación. **No sube nada a Roblox.** **[BINARIO]** Solo png, jpg, jpeg; máximo 5 MB; ruta absoluta. |
| Generación | `generate_mesh`, `generate_material`, `generate_procedural_model`, `wait_job_finished` | Malla con textura, variante de material, modelo procedural de piezas primitivas y espera del trabajo. |
| Generación | `generate_animation` | Animación **R15** desde texto, o convierte una animación R6 existente a R15; hasta 10 segundos. |
| Docs | `http_get` | Lee URLs permitidas de la documentación de Roblox. |
| Docs | `skill` | Carga guías internas (por ejemplo `rbx-open-cloud-usage`, `rbx-permissions`, `rbx-import-asset`). |
| Lugar | `save_place` | Guarda como Archivo, Guardar; sin diálogos. **[BINARIO]** Devuelve `Saved`, `NotNeeded`, `NeedsUserAction` (lugar nunca guardado: necesita Guardar como a mano una vez), `Busy` (hay una prueba en curso) o `Failed`. Nunca publica. |
| Open Cloud | `open_cloud_invoke` | Llama APIs de Open Cloud sin llave. Parámetros `method`, `endpoint`, `body`, `scopes`, `files`. Solo en lugares de un juego publicado ([doc oficial](https://create.roblox.com/docs/studio/mcp-open-cloud)). |
| Otros | `submit_feedback` | Envía comentarios a Roblox sobre las herramientas. |

**[BINARIO]** Nombres de herramientas que existen en el plugin de esta versión pero **no**
están en la doc pública. Pueden ser internas de Assistant o estar apagadas por bandera; la
única forma de saber si tu Studio las expone es mirar la lista real (`/mcp` en Claude
Code):

- `video_capture`: "Start or stop recording a video of the game." Parámetro `is_start`.
  Al detener devuelve JSON con `recording_id`, `status` (`completed` o `partial`; "partial"
  indica que la captura terminó antes, "for example the duration limit") y rutas de
  archivos (`video`, `manifest`, `frame_times`). Controlada por
  `FFlagAssistantMCPVideoCapture`. Es relevante para la sección 5.
- `list_place`, `open_place`, `close_place`: listar y abrir lugares desde la página de
  inicio (`FFlagAssistantMcpListPlaceTool`).
- `generate_texture`, `generate_scene`, `generate_avatar`, `auto_setup_avatar`,
  `segment_mesh`, `capture_plugin_gui`, `list_plugin_guis`, `list_skills`,
  `cloud_execute_luau`.
- `set_active_studio` todavía aparece en textos de guías viejas dentro del plugin, pero
  fue retirada (ver sección 2).

### 1.4 Límites conocidos

**Contexto de ejecución**

- **[OFICIAL]** `execute_luau` exige `datamodel_type`: `Edit`, `Client` o `Server`.
- **[BINARIO]** "use "Edit" in edit mode, or "Client"/"Server" during a playtest. "Edit"
  is rejected while playing".
- **[OFICIAL]** "Play mode takes over Studio": durante una prueba fallan las herramientas
  que apuntan al modelo de edición
  ([personal de Roblox, 2026-08-19](https://devforum.roblox.com/t/studio-mcp-multi-agent-improvements-and-connected-ai-clients/4820583)).

**Tiempo de ejecución**

- **[BINARIO]** No hay un tiempo máximo declarado. La descripción de la herramienta dice:
  "Code runs on Studio's main thread; until it yields, Studio is frozen, the script can't
  be stopped, and the MCP connection may drop." Recomienda partir el trabajo pesado en
  tandas (unos 1000 elementos), llamar `task.wait()` una vez por tanda y armar cada tanda
  fuera del DataModel antes de asignarle `Parent`.
- **[BINARIO]** El proxy tiene un mensaje "Request timeout", pero el valor no es visible.
- **[OFICIAL]** Del lado de Claude Code, `MCP_TOOL_TIMEOUT` fija el tiempo máximo por
  llamada y `MCP_TIMEOUT` el de arranque
  ([doc](https://code.claude.com/docs/en/mcp)).
- **[INFERENCIA]** Trata cada llamada como algo que debe terminar en pocos segundos. Si un
  código lanza un hilo con `task.spawn` que sigue vivo después de responder, no se sabe si
  sobrevive; hay que probarlo.

**Tamaño de respuesta**

- **[BINARIO]** Existen los topes `FIntExecuteLuauMaxStringLength` y
  `FIntExecuteLuauMaxJsonLength`; sus valores vienen del servidor de banderas y no se
  pudieron leer.
- **[OFICIAL]** Claude Code avisa cuando una respuesta MCP pasa de 10.000 tokens y la
  limita a 25.000 por defecto; se sube con `MAX_MCP_OUTPUT_TOKENS`.
- **[INFERENCIA]** Devuelve siempre resúmenes cortos (conteos, nombres), nunca volcados
  del árbol completo.

**Permisos del hilo**

- **[COMUNIDAD]** El código corre en un hilo con capacidades restringidas, no con
  identidad plena de plugin. En 0.741 no podía hacer `require` de ModuleScripts
  ([DevForum, 2026-10-02](https://devforum.roblox.com/t/studios-mcp-executeluau-can-no-longer-require-modulescripts/4909614)).
  En 0.746 corría sin la capacidad `Network` y no podía asignar `Parent` a scripts.
- **[OFICIAL]** Personal de Roblox confirmó el arreglo de lo segundo: "we rolled out a fix
  for the script parenting issue" (versión mínima 0.746.0.7461269) el 2026-11-06, y el de
  HttpService el 2026-11-11
  ([DevForum](https://devforum.roblox.com/t/studio-mcp-executeluau-now-runs-without-the-network-capability-cant-parent-scripts-or-require-modules/4976763)).
- **[OFICIAL]** Problema conocido vigente: "In a place that hasn't been saved to Roblox,
  `execute_luau` can't make HTTP requests"
  ([DevForum, 2026-11-04](https://devforum.roblox.com/t/studio-mcp-server-updates-open-cloud-access-in-your-mcp-client-and-asset-import-workflows/4975849)).
- **[OFICIAL]** Los permisos de Open Cloud, las carpetas de subida, el acceso a DataStore y
  las peticiones HTTP se conceden por juego en la pestaña MCP Permissions. Cada juego
  arranca en nivel "Balanced". Solo aplican a lugares de un juego publicado.

**Escribir scripts**

- **[OFICIAL]** Sí puede: `multi_edit` crea el script si no existe.
- **[BINARIO]** La descripción de `execute_luau` prohíbe usarlo para editar código: "DO NOT
  use this tool to edit, create, rename, or refactor the source of any Script... Setting
  `script.Source = ...` from this tool is NOT a valid substitute". Es una instrucción al
  modelo, no un bloqueo comprobado, pero conviene respetarla: el script director se crea
  con `multi_edit`.

**Leer la salida**

- **[OFICIAL]** `execute_luau` devuelve el valor o el error; lo impreso con `print` se lee
  con `get_console_output`.
- **[BINARIO]** "returns the value of the last expression" (como la barra de comandos).

**Cámara**

- **[BINARIO]** Después de cada `execute_luau`, Studio compara `CameraType` y lo
  restaura: "The execute_luau changed camera type. Resetting from ... back to ..."
  (bandera `FFlagAssistantRestoreCameraStateInExec`). Es decir, dejar la cámara en
  `Scriptable` desde `execute_luau` no se sostiene.
- **[COMUNIDAD]** `screen_capture` "frequently breaks the camera" y deja al agente colgado
  hasta que se agota el tiempo; la causa que señalan es el `CameraType` en `Scriptable`
  ([DevForum, 2026-11-04](https://devforum.roblox.com/t/studio-mcp-server-updates-open-cloud-access-in-your-mcp-client-and-asset-import-workflows/4975849)).
  También se reportó que en modo juego omite `BillboardGui` visibles
  ([DevForum](https://devforum.roblox.com/t/assistant-updates-studio-built-in-mcp-server-and-playtest-automation/4474643)).

**Otros**

- **[OFICIAL]** `start_stop_play` deja de funcionar después de varias ejecuciones para
  algunos creadores; la salida es reiniciar Studio y Roblox no ha identificado la causa
  (mismo hilo del 2026-08-19).
- **[BINARIO]** Buena práctica que usan las guías internas: cerrar cada edición con
  `game:GetService("ChangeHistoryService"):SetWaypoint("descripción")` para que se pueda
  deshacer.

---

## 2. Paralelismo

### 2.1 Respuestas cortas

| Pregunta | Respuesta | Etiqueta |
|---|---|---|
| ¿Varias ventanas de Studio a la vez en un Windows, cada una con un lugar distinto? | Sí, es el escenario que Roblox da por hecho. No hay una página oficial que lo garantice ni que fije un máximo. | OFICIAL (indirecto) y COMUNIDAD |
| ¿El servidor MCP atiende a varias instancias? | Sí. | OFICIAL |
| ¿Cómo sabe el cliente a cuál Studio le habla? | Cada llamada lleva `studio_id`; `list_roblox_studios` entrega los id. No se elige por puerto: todos comparten el 13469. | OFICIAL y BINARIO |
| ¿Varios clientes MCP a la vez? | Sí. Cada sesión de Claude Code lanza su `StudioMCP.exe`; el primero hace de host y los demás de proxy. | BINARIO; OFICIAL en cuanto a "multiple agents or clients" |
| ¿Dos sesiones de Claude Code contra el **mismo** Studio sin pisarse? | Técnicamente se conectan, pero no hay ningún bloqueo ni aislamiento. No lo hagas. | BINARIO e INFERENCIA; pregunta sin respuesta oficial |

### 2.2 Lo confirmado

- **[OFICIAL]** "You can connect a single MCP client to multiple running instances of
  Studio at the same time. Every tool call includes a `studio_id` that identifies the
  Studio instance to target, which makes workflows with multiple Studio instances and
  multiple agents or clients reliable."
  ([doc](https://create.roblox.com/docs/studio/mcp), sección "Use multiple Studio
  instances").
- **[OFICIAL]** `list_roblox_studios`: "Lists all connected Studio instances, including
  their name, Studio instance ID, and place ID. Local places that don't have a place ID are
  listed by name only... if two open Studio instances share the same name, the place ID
  lets you tell apart."
- **[OFICIAL]** Historia del cambio
  ([personal de Roblox, 2026-08-19](https://devforum.roblox.com/t/studio-mcp-multi-agent-improvements-and-connected-ai-clients/4820583)):
  "Before this release, an MCP client was bound to a single Studio instance through the
  set_active_studio tool. If several agents shared a single MCP connection, they couldn't
  reliably address different Studios." y "set_active_studio is removed, so if you were
  calling it directly, pass studio_id instead." La primera versión multiinstancia salió el
  2026-03-05 marcada como experimental
  ([DevForum](https://devforum.roblox.com/t/assistant-updates-studio-built-in-mcp-server-and-playtest-automation/4474643)).
- **[BINARIO]** Si hay varios Studio conectados y una llamada llega sin `studio_id`, el host
  responde: "This call is missing the required `studio_id` argument. Call
  `list_roblox_studios` to get the connected instance ids, then include `studio_id` on
  every tool call." Si el id ya no existe: "The requested `studio_id` is not connected...
  that Roblox Studio instance may have been closed or its place unloaded."
- **[OFICIAL]** El id no es estable: cada lugar recibe un id nuevo cuando cambias de lugar
  en una ventana; hay que guardar el id por sesión y volver a listar después de un cambio
  ([personal de Roblox, 2026-11-04](https://devforum.roblox.com/t/studio-mcp-server-updates-open-cloud-access-in-your-mcp-client-and-asset-import-workflows/4975849)).
  **[BINARIO]** La guía interna dice lo mismo: "Studio instance IDs change when a place is
  reopened; if a call says the ID is not connected, list again."
- **[OFICIAL]** Assistant Settings muestra la lista de clientes conectados.

### 2.3 Lo reportado por la comunidad

- **A favor.** Un usuario que trabaja justo así: `studio_id` "has made running multiple
  studio sessions with multiple Claude Code agents at the same time workable in a safe way
  (with some custom automation)". Personal de Roblox respondió: "it's great to hear the
  studio_id solution is working for you in a safe way"
  ([DevForum, 2026-08-23 y 2026-08-26](https://devforum.roblox.com/t/multiple-studio-window-title-differentiation/4825983)).
- **Advertencia del mismo usuario.** "that id is only a handle to a Studio process" y
  "Cardinality is not identity": que haya un solo Studio conectado no prueba que sea el
  tuyo. Dos copias del mismo lugar muestran el mismo nombre y el mismo PlaceId. Roblox
  respondió: "We haven't considered this painpoint before, and will take a look."
- **Fallo abierto.** Si se abre una ventana de Studio cuando `StudioMCP.exe` ya está
  corriendo, `list_roblox_studios` puede devolver una lista vacía o incompleta. Reportado el
  2026-07-10 en 0.729 y de nuevo el 2026-08-29 (tres ventanas, solo dos encontradas) y el
  2026-09-10. Sin respuesta de Roblox. Salida temporal: abrir el panel de MCP dentro de esa
  ventana de Studio
  ([DevForum](https://devforum.roblox.com/t/studiomcp-fails-to-list-studio-instances-after-new-studio-window-opens-while-studiomcp-is-already-running/4729586)).
- **Varios agentes sobre un mismo Studio.** "Last time I tried working with subagents they
  started fighting over the Studio MCP, will that ever work?" (2026-11-04, sin respuesta).
  Las preguntas directas a Roblox sobre este caso tampoco tuvieron respuesta.
- **Abrir varias ventanas.** Hay un reporte del 2026-08-18 de que abrir una ventana nueva
  cierra la anterior; Roblox contestó "We cannot reproduce this issue"
  ([DevForum](https://devforum.roblox.com/t/studio-closes-existing-window-when-opening-a-new-one/4817979)).
  Otro reporte de 2025 muestra que existe un tope por memoria: "You've reached the limit
  for open Studio window. Please close some to free up memory."
  ([DevForum](https://devforum.roblox.com/t/latest-studio-update-doesnt-allow-multiple-windows-open-at-the-same-time/3679128)).
- **Servidor viejo y bifurcaciones.**
  - `Roblox/studio-rust-mcp-server`, archivado el 2026-04-03, usaba el puerto 44755 con una
    sola cola de comandos: no podía dirigirse a un Studio concreto
    ([GitHub](https://github.com/Roblox/studio-rust-mcp-server)).
  - `boshyxd/robloxstudio-mcp` está archivado y remite a Chrrxs
    ([GitHub](https://github.com/boshyxd/robloxstudio-mcp)).
  - `Chrrxs/robloxstudio-mcp` sigue activo (último cambio 2026-11-09) y también usa un solo
    puente compartido: puerto 58741 (`ROBLOX_STUDIO_PORT`), herramienta
    `get_connected_instances` y parámetro `instance_id`. Su documentación dice: "Per-place
    port tabs such as `58742` are not the supported routing model."
    ([GitHub](https://raw.githubusercontent.com/Chrrxs/robloxstudio-mcp/main/docs/configuration.md)).
  - Ninguna de las opciones aísla por puerto. Todas dependen de que el agente pase el
    identificador correcto.

### 2.4 Inferencias mías

- El aislamiento entre chats **no lo impone el servidor**: cualquier sesión puede escribir
  en cualquier Studio conectado con solo pasar otro `studio_id`. La seguridad depende de la
  disciplina del agente, así que hay que dársela por escrito y con una comprobación
  automática (ver 2.5).
- Dos sesiones sobre el mismo Studio comparten el hilo principal, el estado de juego
  (Play/Edit), la cámara, la selección y el historial de deshacer. Una puede detener la
  prueba que la otra está grabando. No hay forma de repartirlo.
- La sesión de Claude Code que arrancó primero es dueña del host. Si la cierras, las demás
  pierden la conexión unos segundos mientras otra toma el puerto.
- Las ventanas de Studio son procesos separados, así que una prueba en una no debería
  afectar a otra. Lo que sí comparten es GPU, CPU y memoria.
- La grabación es el único paso que no admite paralelo real: con dos o más Studio
  renderizando, el que se graba puede perder cuadros.

### 2.5 Arquitectura recomendada para 2 a 4 chats

**Regla base: un chat, una ventana de Studio, un lugar, una carpeta.**

1. **Una carpeta por video**, por ejemplo `videos/012-el-secreto/`, con el guion, la lista de
   planos, el audio y el lugar `012-el-secreto.rbxl`. Cada chat de Claude Code se abre en su
   carpeta.
2. **Nombres únicos.** El `name` que devuelve `list_roblox_studios` incluye el nombre del
   archivo o el id del lugar. Si cada lugar se llama distinto, el agente puede elegir sin
   ambigüedad. Nunca abras dos copias con el mismo nombre.
3. **Marca de identidad dentro del lugar.** Al crear el lugar desde la plantilla, guarda un
   atributo, por ejemplo `workspace:SetAttribute("VideoId", "012")`. El chat lo lee antes de
   cualquier tanda de cambios. Así se cubre el caso "un solo Studio conectado pero no es el
   mío".
4. **Protocolo de arranque escrito en el `CLAUDE.md` de cada carpeta de video:**
   - Llamar `list_roblox_studios` y elegir la instancia cuyo `name` contiene el nombre del
     archivo de esta carpeta. Si no aparece, detenerse y avisar; no usar otra.
   - Verificar el atributo `VideoId` con `execute_luau` (`datamodel_type: "Edit"`).
   - Pasar ese `studio_id` en todas las llamadas.
   - Si una llamada responde "not connected", volver a listar y repetir la verificación.
   - Prohibido usar un `studio_id` que no haya pasado la verificación.
5. **Orden de apertura**, para esquivar el fallo abierto de 2.3: abre primero todas las
   ventanas de Studio, activa el MCP en cada una y deja visible el panel de MCP; después
   abre los chats de Claude Code. Si agregas una ventana más tarde y no aparece en la
   lista, abre su panel de MCP o reinicia el chat.
6. **Servidor MCP registrado una sola vez con alcance `user`** (comando de 1.2). No hace
   falta un `.mcp.json` por video.
7. **Biblioteca compartida de solo lectura.** Caras, ropa, escenarios y el script director
   viven en una plantilla `plantilla.rbxl` y en un registro `biblioteca/recursos.json` con
   los id de recurso. Solo un chat (o tú) sube recursos nuevos; los chats de video solo
   leen el registro. Así no hay dos chats subiendo la misma cara ni chocando con el límite
   de subidas de la cuenta.
8. **Turno único de grabación.** Un archivo de bloqueo, por ejemplo `grabacion.lock` en la
   raíz del proyecto, con el número del video que está grabando. Un chat que va a grabar lo
   crea, y los demás no entran a modo juego ni lanzan trabajo pesado mientras exista. Lo
   ideal es que tú lances la grabación a mano, video por video.
9. **Ventanas a la vista.** No minimices las ventanas de Studio. **[BINARIO]** Para las
   capturas de paneles de plugin el propio Studio advierte que si la ventana está tapada o
   minimizada la captura devuelve lo que haya en pantalla en esa posición. Para el visor
   3D no hay dato; es prudente asumir lo mismo. Un segundo monitor ayuda mucho.
10. **Guardado.** Cada lugar es un archivo local `.rbxl`; `save_place` lo escribe sin
    diálogo, pero la primera vez hay que hacer Guardar como a mano (estado
    `NeedsUserAction`). Limitación: en lugares locales no publicados no hay
    `open_cloud_invoke` ni HTTP desde `execute_luau`. Si necesitas esas funciones, usa un
    solo juego privado publicado con un lugar por video.

Cuántos chats: con 16 GB de memoria, dos. Con 32 GB y tarjeta gráfica dedicada, hasta
cuatro en edición, grabando de a uno. Es una estimación mía; Roblox no publica consumo por
instancia.

### 2.6 Plan B: solo una instancia de Studio

Si en el equipo de casa no se sostienen varias ventanas (por el fallo de 2.3, por memoria o
porque el MCP no las lista), el paralelismo se mueve fuera de Studio:

- **Los chats trabajan en paralelo todo lo que no toca Studio**: guion, voz, tiempos por
  palabra, lista de planos en JSON, caras dibujadas, subtítulos y montaje con ffmpeg. Eso
  es la mayor parte del tiempo de un video.
- **Un solo chat "operador de Studio"** atiende una cola: toma la carpeta del siguiente
  video, abre su lugar, carga la lista de planos, revisa encuadres, graba, guarda y pasa al
  siguiente. Como el video es datos (JSON) sobre una plantilla común, el tiempo dentro de
  Studio por video es corto.
- La cola puede ser una carpeta `cola-studio/` con un archivo por video y un estado
  (`pendiente`, `en-studio`, `grabado`).
- La Ruta B de `docs/03` (render en código, sin Studio) queda como segundo respaldo y sí es
  paralela sin límite.

---

## 3. Personajes R6 por script

### 3.1 Crear el rig

- **[OFICIAL]** `Players:CreateHumanoidModelFromDescriptionAsync(description, rigType,
  assetTypeVerification)` devuelve un `Model` de personaje R6 o R15 según `rigType`.
  Suspende la ejecución (Yields) y su seguridad es `None`
  ([referencia](https://create.roblox.com/docs/reference/engine/classes/Players#CreateHumanoidModelFromDescriptionAsync)).
  La variante sin `Async` (`CreateHumanoidModelFromDescription`) sigue existiendo, pero la
  referencia dice que fue reemplazada por la `Async` y que esta es la que debe usarse.
- **[OFICIAL]** Para copiar un avatar real:
  `Players:GetHumanoidDescriptionFromUserIdAsync(userId)` y
  `Players:CreateHumanoidModelFromUserIdAsync(userId)`.
- **[OFICIAL]** La herramienta manual ahora se llama **Rig Generator** (antes Rig Builder):
  pestaña Avatar o Home, botón Character; inserta un R6 o R15 con el nombre `Rig`. La doc
  advierte que la ropa y los accesorios en capas solo se pueden equipar en R15
  ([doc](https://create.roblox.com/docs/studio/rig-builder)).
- **[COMUNIDAD]** Estos métodos funcionan en modo edición: es lo que usan los plugins de
  tipo "Load Character"
  ([DevForum](https://devforum.roblox.com/t/load-character-plugin/1848301)).
- **[INFERENCIA]** Desde `execute_luau` deberían funcionar igual, pero el hilo tiene
  capacidades restringidas (ver 1.4) y estos métodos descargan recursos. Es la primera
  prueba del piloto. Si fallan, el respaldo es insertar un R6 una sola vez con Rig
  Generator, guardarlo en la plantilla y clonarlo por script.

```lua
-- execute_luau, datamodel_type = "Edit"
local Players = game:GetService("Players")

local desc = Instance.new("HumanoidDescription")
desc.HeadColor = Color3.fromRGB(245, 205, 48)
desc.TorsoColor = Color3.fromRGB(13, 105, 172)
desc.LeftArmColor = Color3.fromRGB(245, 205, 48)
desc.RightArmColor = Color3.fromRGB(245, 205, 48)
desc.LeftLegColor = Color3.fromRGB(40, 127, 71)
desc.RightLegColor = Color3.fromRGB(40, 127, 71)

local rig = Players:CreateHumanoidModelFromDescriptionAsync(desc, Enum.HumanoidRigType.R6)
rig.Name = "Actor_Ana"
rig:PivotTo(CFrame.new(0, 3, 0))
rig.Parent = workspace

local root = rig:FindFirstChild("HumanoidRootPart")
if root then
	root.Anchored = true -- para que no se caiga ni camine al entrar a modo juego
end

game:GetService("ChangeHistoryService"):SetWaypoint("Crear Actor_Ana")
return rig:GetFullName()
```

### 3.2 Vestirlo

- **[OFICIAL]** `HumanoidDescription` tiene, entre otras, las propiedades `Shirt`, `Pants`,
  `GraphicTShirt`, `Face`, `HatAccessory`, `HairAccessory`, `FaceAccessory`,
  `NeckAccessory`, `ShouldersAccessory`, `FrontAccessory`, `BackAccessory`,
  `WaistAccessory` y los colores del cuerpo. Los accesorios son texto con id separados por
  coma. `SetAccessories(accessories, includeRigidAccessories)` acepta una tabla
  ([referencia](https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription),
  [guía](https://create.roblox.com/docs/characters/appearance)).
- **[OFICIAL]** Para cambiar la apariencia de un rig ya creado:
  `Humanoid:ApplyDescriptionAsync(desc)`; si el personaje se modificó por otros medios,
  `Humanoid:ApplyDescriptionResetAsync(desc)`.
- **[INFERENCIA, conocimiento general de la plataforma]** `Shirt` y `Pants` en
  `HumanoidDescription` esperan el id del artículo de ropa del catálogo, no el id de la
  imagen. Para ropa propia sin publicarla en el catálogo, crea las instancias directamente:
  la clase `Shirt` tiene la propiedad `ShirtTemplate` y `Pants` tiene `PantsTemplate`, que
  reciben el id de una imagen subida por ti.

```lua
local shirt = rig:FindFirstChildOfClass("Shirt") or Instance.new("Shirt")
shirt.ShirtTemplate = "rbxassetid://ID_DE_TU_IMAGEN"
shirt.Parent = rig
```

### 3.3 Posarlo sin animación

- **[OFICIAL]** `Motor6D.Transform` es la propiedad que mueve un `Animator`. Sus cambios no
  se aplican de inmediato sino en lote antes del paso de física, y si el modelo tiene un
  `Animator` con animaciones, este la sobrescribe en cada cuadro. Además está marcada
  `Hidden` y `NotReplicated`
  ([referencia](https://create.roblox.com/docs/reference/engine/classes/Motor6D#Transform)).
- **[OFICIAL]** `C0` y `C1` sí se aplican de inmediato (la misma página lo contrasta).
- **[INFERENCIA]** Para poses fijas la opción robusta es **`C0`**: se ve al instante en
  edición, se guarda con el lugar y ningún `Animator` la pisa. `Transform` no se guarda y
  en edición puede no refrescarse. Guarda el `C0` original en un atributo para poder volver
  a la pose neutra. Si el rig trae un script `Animate`, bórralo para que no cargue
  animaciones de reposo al entrar a modo juego.
- **[COMUNIDAD, conocimiento general]** En R6 las articulaciones están dentro de `Torso` y
  se llaman `Neck`, `Left Shoulder`, `Right Shoulder`, `Left Hip`, `Right Hip`; `RootJoint`
  está en `HumanoidRootPart`. Por la orientación de sus `C0`, el eje que levanta un brazo
  hacia adelante no es el que uno espera; hay que encontrarlo una vez con capturas y
  dejarlo fijo en una tabla de poses.

```lua
local function posar(rig, nombre, giro)
	local torso = rig:FindFirstChild("Torso")
	local motor = torso and torso:FindFirstChild(nombre)
	if not motor or not motor:IsA("Motor6D") then
		return false
	end
	local base = motor:GetAttribute("C0Base")
	if base == nil then
		base = motor.C0
		motor:SetAttribute("C0Base", base)
	end
	motor.C0 = base * giro
	return true
end

-- Brazo derecho levantado (el eje exacto se confirma con una captura)
posar(workspace.Actor_Ana, "Right Shoulder", CFrame.Angles(0, 0, math.rad(90)))
-- Cabeza inclinada
posar(workspace.Actor_Ana, "Neck", CFrame.Angles(math.rad(-15), 0, 0))
```

### 3.4 Cambiar la cara

- **[COMUNIDAD]** En R6 la cara es un `Decal` llamado `face` dentro de `Head`
  ([DevForum](https://devforum.roblox.com/t/how-to-import-high-quality-character-faces-on-roblox-characters-works-with-r15-and-r6/622433)).
- **[OFICIAL]** `Decal.Texture` está marcada como obsoleta: "This property has been
  deprecated. Use `ColorMapContent` for future work." El tipo nuevo es `Content`, con
  `Content.fromAssetId(id)` y `Content.fromUri(uri)`
  ([Decal](https://create.roblox.com/docs/reference/engine/classes/Decal),
  [Content](https://create.roblox.com/docs/reference/engine/datatypes/Content)). El formato
  `rbxassetid://ID` sigue siendo el estándar para recursos subidos
  ([doc de recursos](https://create.roblox.com/docs/projects/assets)).

```lua
local function ponerCara(rig, assetId)
	local head = rig:FindFirstChild("Head")
	if not head then
		return false
	end
	local cara = head:FindFirstChild("face")
	if not cara then
		cara = Instance.new("Decal")
		cara.Name = "face"
		cara.Face = Enum.NormalId.Front
		cara.Parent = head
	end
	cara.ColorMapContent = Content.fromAssetId(assetId)
	-- Forma antigua, todavía funcional: cara.Texture = "rbxassetid://" .. assetId
	return true
end
```

- **[INFERENCIA]** Para que el cambio de cara no parpadee en la grabación, carga antes
  todas las caras con `ContentProvider:PreloadAsync` y, mejor aún, deja un `Decal` por
  expresión en la cabeza y alterna su `Transparency` entre 0 y 1.

**Subir caras propias**

- **[OFICIAL y BINARIO]** `upload_image` recibe **URLs HTTP**, no rutas locales. Para
  imágenes en disco hay que servirlas por HTTP (por ejemplo `python -m http.server 8123` en
  la carpeta de caras y pasar `http://localhost:8123/susto.png`). Devuelve un mapa de ruta
  a `rbxassetid://...`.
- **[OFICIAL]** Alternativa: `open_cloud_invoke` con `files`, que sí sube archivos locales,
  pero exige un lugar de un juego publicado, los permisos `asset:read` y `asset:write`, y
  que la carpeta esté aprobada en MCP Permissions. El agente no puede copiar archivos a una
  carpeta aprobada para saltarse esa restricción
  ([doc](https://create.roblox.com/docs/studio/mcp-open-cloud)).
- **[OFICIAL]** `store_image` **no sube nada**: solo convierte un archivo local en un URI
  para herramientas de generación.
- **[OFICIAL]** Moderación: "Roblox performs both human and automated asset moderation".
  Las subidas son permanentes, quedan a nombre del dueño del juego y Open Cloud no puede
  borrarlas. Los recursos son privados por defecto
  ([doc](https://create.roblox.com/docs/projects/assets#asset-moderation)).
- **Tiempos de moderación**: no encontré ninguna cifra oficial. **[INFERENCIA]** Sube el
  paquete completo de caras un día antes de grabar y verifica en Studio que todas cargan.
  Las caras deben ser PNG con transparencia; evita cualquier rasgo que la moderación pueda
  leer como contenido inapropiado.

### 3.5 Animaciones en modo edición

- **[OFICIAL]** Sí existe una vía: `Animator:StepAnimations(deltaTime)` avanza las
  animaciones cargadas. "For use in the command bar or by plugins only"; requiere seguridad
  de nivel plugin
  ([referencia](https://create.roblox.com/docs/reference/engine/classes/Animator#StepAnimations)).
- **[INFERENCIA]** Como `execute_luau` corre con capacidades restringidas, no está
  garantizado que pueda llamarlo. Además `generate_animation` solo produce R15. Para este
  formato (planos casi estáticos) conviene posar con `C0` y, cuando haga falta movimiento,
  interpolar `C0` en modo juego desde el script director con `TweenService` o cuadro a
  cuadro. Las animaciones de verdad solo se reproducen con normalidad en modo juego.

---

## 4. Cámara y reproducción

### 4.1 Edición frente a juego

- **[OFICIAL]** La cámara se mueve asignando `Camera.CFrame`. Los scripts de cámara por
  defecto también la mueven, así que la doc recomienda poner
  `CameraType = Enum.CameraType.Scriptable`
  ([referencia](https://create.roblox.com/docs/reference/engine/classes/Camera#CFrame)).
- **[INFERENCIA]** En modo edición no hay scripts de cámara del juego: la cámara es la de
  navegación de Studio y basta con asignar `workspace.CurrentCamera.CFrame` desde
  `execute_luau` para encuadrar. Para revisar planos en edición es más simple usar
  `screen_capture` con `camera_position` y `look_at_position`, que coloca la cámara, captura
  y la devuelve.
- **[BINARIO]** `execute_luau` restaura `CameraType` al terminar (ver 1.4). Conclusión: **la
  secuencia de planos no se puede dirigir llamada por llamada desde el chat**. Debe ser un
  `LocalScript` que corre en modo juego.
- **[OFICIAL]** Modos de prueba: Test (con jugador), Test Here y Run (solo servidor, sin
  jugador)
  ([doc](https://create.roblox.com/docs/studio/testing-modes)). `start_stop_play` no
  documenta qué modo usa. **[INFERENCIA]** Usa el modo con cliente, porque `CoreGui`, la
  cámara `Scriptable` y `RenderStepped` son del cliente.

### 4.2 Campo de visión y giro de 90 grados

- **[OFICIAL]** `Camera.FieldOfView` es el ángulo vertical por defecto; `FieldOfViewMode`
  permite que el valor mande sobre otro eje y existen `MaxAxisFieldOfView` y
  `DiagonalFieldOfView`.
- **[OFICIAL]** `Camera:SetRoll` está desaconsejado: "This method is outdated... you are
  advised to instead apply roll to the Camera using the CFrame property", con el ejemplo
  `CFrame.Angles(0, 0, roll)`
  ([referencia](https://create.roblox.com/docs/reference/engine/classes/Camera#SetRoll)).
- **[INFERENCIA]** Con la cámara girada 90 grados, el eje vertical de la pantalla pasa a
  ser el eje horizontal del video final. Por eso el `FieldOfView` que pongas define el
  ancho del video vertical, no su alto. Un valor de 30 a 40 da un encuadre cerrado. El
  sentido del giro (positivo o negativo) decide si luego se rota la grabación a la derecha
  o a la izquierda; se fija una vez en el piloto.

### 4.3 Ocultar la interfaz

- **[OFICIAL]** En el juego: `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)` y
  `StarterGui:SetCore("TopbarEnabled", false)`
  ([referencia](https://create.roblox.com/docs/reference/engine/classes/StarterGui)).
- **[INFERENCIA]** `SetCore` puede fallar si se llama antes de que el núcleo registre la
  opción; se reintenta con `pcall`. Para que no aparezca tu avatar, pon
  `Players.CharacterAutoLoads = false` en un script de servidor. Oculta el cursor con
  `UserInputService.MouseIconEnabled = false`.
- **[OFICIAL]** En el visor de Studio hay un botón de opciones de visualización (esquina
  superior derecha) para ocultar capas de interfaz, y la apariencia de la selección se
  ajusta en la configuración de Studio, sección Selection
  ([doc](https://create.roblox.com/docs/studio/overview)).
- **[COMUNIDAD, guía de personal de Roblox de 2024]** Recomienda Editor Quality en 21,
  calidad gráfica al máximo y el atajo Ctrl izquierdo + Shift izquierdo + C para alternar
  la interfaz básica en cámara libre
  ([DevForum](https://devforum.roblox.com/t/tips-for-capturing-high-quality-screenshots-and-videos-in-studio/2723897)).
- Los atajos Ctrl+H y F11 que cita `docs/03` no los pude confirmar en documentación oficial
  (la página de atajos no está en el repositorio de la doc). **[INFERENCIA]** En modo juego
  no hay rejilla ni cajas de selección, así que lo único que queda por resolver es el marco
  de Studio alrededor del visor: se soluciona recortando la captura en OBS al área del
  visor o poniendo el visor a pantalla completa.

### 4.4 Secuencia de planos con tiempos exactos

- **[OFICIAL]** `task.wait(n)` reanuda el hilo "on the next Heartbeat step" después de que
  pasa el tiempo, sin limitación artificial, y devuelve el tiempo real transcurrido
  ([referencia](https://create.roblox.com/docs/reference/engine/libraries/task#wait)).
  `RunService` ofrece `PreRender` (antes `RenderStepped`), `Heartbeat` y
  `BindToRenderStep`
  ([referencia](https://create.roblox.com/docs/reference/engine/classes/RunService)).
- **[INFERENCIA] Precisión esperable.** Cualquier cambio cae en un cuadro, así que el error
  por plano es de hasta un cuadro: unos 17 ms a 60 cuadros por segundo. Encadenar
  `task.wait(duración)` acumula ese error plano tras plano (con 50 planos puede pasar de
  medio segundo). La forma correcta es un reloj absoluto: guardar `os.clock()` al inicio y,
  en cada cuadro, decidir qué plano toca según el tiempo transcurrido. Así el error nunca
  se acumula. Las pérdidas de cuadros por carga de recursos se evitan precargando todo
  antes de arrancar.

```lua
-- LocalScript en StarterPlayer.StarterPlayerScripts (se crea con multi_edit)
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")

local GIRO_VERTICAL = CFrame.Angles(0, 0, math.rad(90))

-- Cada plano: inicio en segundos, cámara inicial y final, campo de visión inicial y final
local planos = {
	{ t = 0.00, desde = CFrame.lookAt(Vector3.new(0, 5, 12), Vector3.new(0, 4.5, 0)),
	  hasta = CFrame.lookAt(Vector3.new(0, 5, 10), Vector3.new(0, 4.5, 0)), fov0 = 40, fov1 = 36 },
	{ t = 1.45, desde = CFrame.lookAt(Vector3.new(4, 5, 6), Vector3.new(0, 4.5, 0)),
	  hasta = CFrame.lookAt(Vector3.new(4, 5, 6), Vector3.new(0, 4.5, 0)), fov0 = 30, fov1 = 30 },
}
local DURACION_TOTAL = 3.0

local camara = workspace.CurrentCamera
camara.CameraType = Enum.CameraType.Scriptable

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
for _ = 1, 20 do
	local ok = pcall(function()
		StarterGui:SetCore("TopbarEnabled", false)
	end)
	if ok then
		break
	end
	task.wait(0.25)
end
UserInputService.MouseIconEnabled = false

ContentProvider:PreloadAsync({ workspace })
task.wait(3) -- margen para que OBS ya esté grabando

local indice = 1
local inicio = os.clock()

RunService:BindToRenderStep("Director", Enum.RenderPriority.Camera.Value + 1, function()
	local t = os.clock() - inicio
	if t >= DURACION_TOTAL then
		RunService:UnbindFromRenderStep("Director")
		return
	end
	while planos[indice + 1] and t >= planos[indice + 1].t do
		indice += 1
	end
	local plano = planos[indice]
	local fin = planos[indice + 1] and planos[indice + 1].t or DURACION_TOTAL
	local a = math.clamp((t - plano.t) / (fin - plano.t), 0, 1)
	camara.CFrame = plano.desde:Lerp(plano.hasta, a) * GIRO_VERTICAL
	camara.FieldOfView = plano.fov0 + (plano.fov1 - plano.fov0) * a
end)
```

El cambio de caras y poses por plano se agrega dentro del `while`, en el momento en que
`indice` avanza. La lista `planos` se genera desde el JSON de la lista de planos.

---

## 5. Grabación

### 5.1 OBS

- **[OFICIAL] Fuente de captura.** Game Capture "is the most efficient way you can add your
  games to OBS Studio and should always be tried first", pero "This is not suitable for
  non-game window capture"
  ([OBS](https://obsproject.com/kb/game-capture-source)). Window Capture tiene los métodos
  Automatic, BitBlt y Windows 10
  ([OBS](https://obsproject.com/kb/window-capture-sources)). No hay una indicación oficial
  sobre cuál funciona mejor con Roblox Studio. **[INFERENCIA]** Prueba primero Game Capture
  en modo "Capture specific window" sobre `RobloxStudioBeta.exe`; si sale en negro, usa
  Window Capture con el método Windows 10. Recorta la fuente al área del visor.
- **[OFICIAL] Codificador**
  ([guía de OBS](https://obsproject.com/kb/advanced-recording-settings-guide)):
  - NVIDIA NVENC: "Rate Control: Constant QP", "Constant QP: 16-23", "Keyframe Interval:
    2", "Preset: P5".
  - x264 (sin tarjeta NVIDIA): "Rate Control: CRF", "CRF: 16-23", "CPU Usage Preset:
    veryfast".
  - AMD: "Rate Control: CQP", "CQ Level: 16-23". Intel: "Rate Control: ICQ", "ICQ Quality:
    16-23".
- **[OFICIAL] Contenedor.** "MKV is recommended in case of unforeseen issues arising"; se
  convierte luego con Archivo, Remux Recordings
  ([OBS](https://obsproject.com/kb/standard-recording-output-guide)). Desde OBS 30.2 existe
  Hybrid MP4, que también sobrevive a un cierre inesperado
  ([OBS](https://obsproject.com/kb/hybrid-mp4)).
- **[INFERENCIA] Valores recomendados para este proyecto.** Lienzo base y salida iguales a
  la resolución nativa del monitor, sin reescalar en OBS; 60 cuadros por segundo como valor
  entero; calidad 16 a 18; MKV. Con la cámara girada 90 grados, una captura de 1920 por
  1080 da un video vertical de 1080 por 1920 completo después de rotar. Con monitor de 2560
  por 1440 obtienes 1440 por 2560 y margen para reducir. No encontré una página oficial de
  OBS sobre lienzos personalizados ni sobre el ajuste de cuadros por segundo.

Rotación posterior con ffmpeg (el sentido depende del signo del giro de cámara):

```
ffmpeg -i grabacion.mkv -vf "transpose=clock" -c:v libx264 -crf 16 -r 60 -an vertical.mp4
```

### 5.2 Sincronizar el inicio

- **[OFICIAL]** OBS trae obs-websocket desde la versión 28, en el puerto 4455 por defecto,
  con las peticiones `StartRecord`, `StopRecord` (devuelve `outputPath`) y
  `GetRecordStatus`
  ([GitHub](https://github.com/obsproject/obs-websocket),
  [protocolo](https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md)).
  Un script puede arrancar la grabación justo antes de lanzar la prueba.
- **[INFERENCIA] Método recomendado: destello de sincronía.** El script director muestra
  durante 2 o 3 cuadros un `Frame` de pantalla completa de un color puro que no aparezca en
  el video (magenta) y en el cuadro siguiente pone `inicio = os.clock()`. En el montaje se
  busca el último cuadro magenta y se corta ahí; ese es el tiempo cero que se alinea con el
  audio de la voz. Es más confiable que un tono porque no depende de capturar el audio del
  sistema. Si además quieres tono, reproduce un `Sound` corto en el mismo cuadro y
  detéctalo con el filtro `silencedetect` de ffmpeg.
- Orden práctico: `StartRecord` por websocket, `start_stop_play` con `is_start: true`, el
  director espera 3 segundos, destello, secuencia, destello final, `StopRecord`.

### 5.3 Grabador interno de Studio

- No encontré ninguna página oficial vigente que documente un grabador de video en Studio.
- **[COMUNIDAD]** Existe un grabador con la tecla F12 que falla en sesiones de tipo Run
  ([DevForum, 2025](https://devforum.roblox.com/t/unable-to-record-studio-in-run-session-using-f12/3850174));
  hilos más viejos se quejan de salida WMV, resolución reducida y cuadros perdidos
  ([DevForum](https://devforum.roblox.com/t/the-recording-tools-need-to-be-upgraded-urgently/2823204)).
  La guía del personal de Roblox de 2024 recomienda OBS y no menciona el grabador interno.
- **[OFICIAL]** La API `CaptureService:StartVideoCaptureAsync` graba video desde el juego,
  pero se detiene "when 30 seconds have passed", su parámetro `captureParams` "is currently
  non-operational" y el resultado hay que guardarlo con un diálogo al usuario
  ([referencia](https://create.roblox.com/docs/reference/engine/classes/CaptureService#StartVideoCaptureAsync)).
  No sirve para un video de 100 segundos.

### 5.4 Renderizar sin grabar pantalla

- **[OFICIAL]** La doc pública del MCP solo ofrece `screen_capture`, que es imagen fija.
- **[BINARIO]** En Studio 0.747 existe la herramienta `video_capture` (ver 1.3), que
  devuelve la ruta de un archivo de video, un manifiesto y los tiempos de cada cuadro, con
  un límite de duración no especificado. Está detrás de una bandera y no aparece en la doc.
  Si tu Studio la expone, es la mejor candidata para reemplazar OBS: hay que mirar la lista
  real de herramientas y medir resolución, cuadros por segundo y duración máxima.
- **[COMUNIDAD]** Moon Animator no exporta video; la recomendación es grabar la pantalla
  ([DevForum](https://devforum.roblox.com/t/how-to-record-trailers-with-moon-animation-suite/1923201)).
- **[INFERENCIA]** Un render cuadro a cuadro con `screen_capture` (avanzar el tiempo, posar,
  capturar, repetir 6.000 veces) sería determinista pero muy lento y sin garantía de
  resolución. No lo recomiendo salvo como experimento.

---

## 6. Iluminación y aspecto

### 6.1 Lo que cambió en la API

- **[OFICIAL]** `Lighting.Technology` está **obsoleta**, no se puede leer ni escribir desde
  scripts (seguridad `RobloxScriptSecurity`) y fue reemplazada por dos propiedades que sí
  son programables
  ([referencia](https://create.roblox.com/docs/reference/engine/classes/Lighting)):
  - `Lighting.LightingStyle`: `Enum.LightingStyle.Realistic` ("The most advanced and
    realistic lighting and shadows Roblox can deliver") o `Enum.LightingStyle.Soft` ("A
    flat, retro-Roblox look with softer lights and shadows").
  - `Lighting.PrioritizeLightingQuality`: con `true` se conservan sombras avanzadas y
    sombreado de alta calidad cuando baja el nivel de calidad.
- **[OFICIAL]** `ShadowSoftness` solo tiene efecto con `LightingStyle` en `Realistic`
  ([guía](https://create.roblox.com/docs/environment/lighting)).
- Equivalencia práctica **[INFERENCIA]**: lo que antes se pedía como "Future" es ahora
  `Realistic` con `PrioritizeLightingQuality = true`. El aspecto retro de los cortos R6
  clásicos se parece más a `Soft`. Vale la pena comparar ambos en el piloto.

### 6.2 Propiedades disponibles

**[OFICIAL]** `Lighting`: `Ambient`, `OutdoorAmbient`, `Brightness`, `ClockTime`,
`TimeOfDay`, `GeographicLatitude`, `ColorShift_Top`, `ColorShift_Bottom`,
`EnvironmentDiffuseScale`, `EnvironmentSpecularScale`, `ExposureCompensation`,
`GlobalShadows`, `ShadowSoftness`, `FogColor`, `FogStart`, `FogEnd`.
`Atmosphere` (hijo de `Lighting`): `Density`, `Offset`, `Color`, `Decay`, `Glare`, `Haze`
([doc](https://create.roblox.com/docs/environment/atmosphere)).
Efectos de posprocesado (hijos de `Lighting` o de la cámara): `BloomEffect` (`Intensity`,
`Size`, `Threshold`), `ColorCorrectionEffect` (`Brightness`, `Contrast`, `Saturation`,
`TintColor`), `DepthOfFieldEffect` (`FarIntensity`, `FocusDistance`, `InFocusRadius`,
`NearIntensity`), `SunRaysEffect` (`Intensity`, `Spread`)
([doc](https://create.roblox.com/docs/environment/post-processing-effects)).
`Sky` (`StarCount`, `SunAngularSize`, `MoonAngularSize`, `CelestialBodiesShown`) y `Clouds`
(`Cover`, `Density`, `Color`).

### 6.3 Valores de partida

**[INFERENCIA]** Todos los números de esta tabla son propuestas mías para arrancar; ninguna
fuente oficial da recetas. Se ajustan mirando capturas.

| Propiedad | Sol bajo, cálido | Noche | Nieve | Lluvia |
|---|---|---|---|---|
| `LightingStyle` | Realistic | Realistic | Realistic | Realistic |
| `ClockTime` | 17.4 | 0.5 | 10.5 | 13 |
| `GeographicLatitude` | 35 | 35 | 50 | 35 |
| `Brightness` | 3 | 1.2 | 2.2 | 1 |
| `Ambient` | 80, 66, 58 | 28, 32, 58 | 120, 128, 140 | 70, 76, 84 |
| `OutdoorAmbient` | 128, 108, 92 | 36, 42, 78 | 150, 158, 170 | 96, 102, 110 |
| `ColorShift_Top` | 255, 196, 140 | 110, 130, 255 | 230, 240, 255 | 190, 200, 215 |
| `ExposureCompensation` | 0.2 | -0.2 | 0.3 | -0.1 |
| `ShadowSoftness` | 0.15 | 0.4 | 0.5 | 0.8 |
| `Atmosphere.Density` | 0.3 | 0.35 | 0.4 | 0.5 |
| `Atmosphere.Offset` | 0.25 | 0 | 0.1 | 0 |
| `Atmosphere.Color` | 215, 185, 150 | 40, 50, 90 | 235, 240, 250 | 150, 158, 168 |
| `Atmosphere.Decay` | 150, 96, 64 | 20, 24, 48 | 200, 210, 225 | 96, 104, 112 |
| `Atmosphere.Glare` | 0.5 | 0 | 0.1 | 0 |
| `Atmosphere.Haze` | 1.8 | 1 | 2.2 | 2.8 |
| `Bloom` (Intensity, Size, Threshold) | 0.5, 24, 1.6 | 0.9, 32, 1.1 | 0.4, 24, 1.8 | 0.3, 24, 2 |
| `ColorCorrection.Contrast` | 0.15 | 0.2 | 0.05 | 0.1 |
| `ColorCorrection.Saturation` | 0.15 | -0.1 | -0.15 | -0.25 |
| `ColorCorrection.TintColor` | 255, 238, 220 | 205, 215, 255 | 238, 245, 255 | 215, 225, 235 |
| `SunRays` (Intensity, Spread) | 0.12, 0.6 | apagado | 0.03, 0.5 | apagado |
| `Clouds` (Cover, Density) | 0.35, 0.3 | 0.3, 0.3 | 0.7, 0.5 | 0.95, 0.9 |

Notas:

- Sol bajo: las sombras largas salen de un `ClockTime` cercano al atardecer (17 a 18) o al
  amanecer (6 a 7). `GeographicLatitude` cambia el ángulo del sol respecto al escenario.
- Noche: la luz de ambiente azulada da la base; la escena la definen las luces locales
  (`PointLight` y `SpotLight` cálidas en ventanas y faroles) y el `Bloom`.
- Nieve y lluvia: se hacen con `ParticleEmitter` en una pieza invisible grande colocada
  encima del encuadre. Lluvia: partículas alargadas, rápidas, casi verticales. Nieve:
  partículas pequeñas, lentas, con algo de deriva lateral. El suelo de nieve se logra con
  piezas blancas de material `Snow` o `Sand`.
- `DepthOfField` para planos cerrados: `FocusDistance` igual a la distancia cámara a
  personaje, `InFocusRadius` de 8 a 12, `FarIntensity` 0.3 a 0.5, `NearIntensity` 0.

```lua
-- execute_luau, datamodel_type = "Edit": aspecto "sol bajo, cálido"
local Lighting = game:GetService("Lighting")

Lighting.LightingStyle = Enum.LightingStyle.Realistic
Lighting.PrioritizeLightingQuality = true
Lighting.ClockTime = 17.4
Lighting.GeographicLatitude = 35
Lighting.Brightness = 3
Lighting.Ambient = Color3.fromRGB(80, 66, 58)
Lighting.OutdoorAmbient = Color3.fromRGB(128, 108, 92)
Lighting.ColorShift_Top = Color3.fromRGB(255, 196, 140)
Lighting.ExposureCompensation = 0.2
Lighting.ShadowSoftness = 0.15
Lighting.GlobalShadows = true

local function unico(clase)
	local objeto = Lighting:FindFirstChildOfClass(clase)
	if not objeto then
		objeto = Instance.new(clase)
		objeto.Parent = Lighting
	end
	return objeto
end

local atmosfera = unico("Atmosphere")
atmosfera.Density = 0.3
atmosfera.Offset = 0.25
atmosfera.Color = Color3.fromRGB(215, 185, 150)
atmosfera.Decay = Color3.fromRGB(150, 96, 64)
atmosfera.Glare = 0.5
atmosfera.Haze = 1.8

local bloom = unico("BloomEffect")
bloom.Intensity = 0.5
bloom.Size = 24
bloom.Threshold = 1.6

local color = unico("ColorCorrectionEffect")
color.Contrast = 0.15
color.Saturation = 0.15
color.TintColor = Color3.fromRGB(255, 238, 220)

local rayos = unico("SunRaysEffect")
rayos.Intensity = 0.12
rayos.Spread = 0.6

game:GetService("ChangeHistoryService"):SetWaypoint("Luz sol bajo")
return "ok"
```

---

## 7. Reglas de Roblox para videos monetizados

Este punto tiene una tensión entre dos textos oficiales. Cito ambos.

### 7.1 El permiso explícito (2022)

**[OFICIAL]** Publicación de Roblox en DevForum, "Update to Roblox Licensing Program & Brand
Guidelines", 2022-06-23
([enlace](https://devforum.roblox.com/t/update-to-roblox-licensing-program-brand-guidelines/1843674)).
A la pregunta "Do the new IP usage guidelines restrict me from creating videos or streaming
content using the R6 or R15 avatars?" responde:

- "You are free to continue using all avatar types in your social media content and you may
  continue monetizing that content (such as through YouTube ad revenue)."
- "Just note that if your channel or fan site uses “Roblox” or “Blox,” please make sure you
  say that your page is not affiliated with Roblox."
- "You will also need to contact us if you are considering producing content like a TV show
  or a movie using the classic R6 or R15 avatars."

### 7.2 El texto vigente de las pautas (2026)

**[OFICIAL]** "Roblox Name and Logo Guidelines", editado el 2026-11-01
([enlace](https://en.help.roblox.com/hc/en-us/articles/115001708126)). No contiene ninguna
frase sobre YouTube ni sobre videos, y dice:

- "The use of the Roblox name (and any name similar to Roblox), badge, logo, and other
  trademarks and copyrights including “Classic Roblox Avatars” (R6 and R15 avatars, as
  defined below*) is not permitted on physical products or commercial content and may not
  be tied to the development, distribution or sale of any products or services (including,
  but not limited to, physical products, packaging, retail displays, services, NFTs, film,
  TV, books, stage shows or amusement parks) without a Roblox licensing agreement."
- "Besides our official badge, we do not permit the general use of our logo in any creative
  or copy."
- Entre las prohibiciones: "Imply official Roblox partnership or endorsement."

### 7.3 Términos de uso (vigentes desde 2026-11-01)

**[OFICIAL]** ([enlace](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use)).
No tienen ninguna cláusula sobre grabar, transmitir o monetizar videos. Lo pertinente:

- "Roblox-Owned Content may not be used outside of the Services unless such use is both (a)
  expressly authorized by Roblox; and (b) consistent with Roblox's Name and Logo
  Guidelines." La definición de ese contenido incluye "trademarks, avatar models, clothing
  items, Roblox-published Games".
- Sobre artículos de otros creadores: "Any acquisition of UGC on the Services is solely for
  your personal entertainment."
- Música con licencia (Términos para creadores, 7.1): la licencia es "only to synchronize
  Licensed Music into a Game or other Content solely on the Services", y prohíbe "export,
  extract, download, or provide a way for anyone else to export, extract, or download the
  Licensed Music for use anywhere outside of the Services."

### 7.4 Normas de la comunidad

**[OFICIAL]** ([enlace](https://about.roblox.com/community-standards)): "Roblox isn't the
place for seeking offline or online romantic connections or engaging with sexual content or
behavior". Aplican a lo que se sube a Roblox (caras, ropa, el lugar si se publica), no al
video en YouTube, que se rige por las políticas de YouTube.

### 7.5 Lectura y recomendaciones

**[INFERENCIA]** Esto no es asesoría legal.

- La respuesta de 2022 es el único permiso explícito para monetizar videos con avatares R6
  y R15, y sigue publicada. El texto de 2026 prohíbe el uso en "commercial content" sin
  licencia y no excluye los videos de forma expresa, aunque todos sus ejemplos son
  productos y medios tradicionales (cine, TV, libros). Lo razonable es apoyarse en la
  respuesta de 2022, guardar una copia con fecha de ambos textos y revisar las pautas cada
  cierto tiempo. `docs/03` presenta el permiso como asunto resuelto; conviene matizarlo.
- No usar el logo de Roblox ni dar a entender afiliación. Si el canal o los títulos usan
  "Roblox" o "Blox", incluir la aclaración de no afiliación. Mejor no usar la palabra en el
  nombre del canal.
- Ropa y accesorios de otros creadores: no hay un permiso expreso para usarlos en video
  fuera de la plataforma, y los términos dicen que su adquisición es para entretenimiento
  personal. Lo prudente es ropa clásica o propia y caras propias.
- Audio: nunca usar música ni efectos del catálogo de Roblox en la pista del video. El
  script director no debe reproducir sonidos del catálogo que luego queden grabados.
- Un formato de serie para televisión o una película requiere contactar a Roblox.

---

## 8. Instalación para el equipo de casa

### 8.1 Comandos

Los identificadores se comprobaron hoy en este equipo con
`winget search --id <Id> --exact --source winget` (winget v1.29.380). Solo se comprobó que
existen y su versión; no se ejecutaron las instalaciones, salvo Roblox Studio, que sí se
había instalado antes por esta misma vía (el registro del instalador muestra la ruta
`WinGet\Roblox.RobloxStudio.1.6.3.172`).

```
winget install --id Roblox.RobloxStudio -e --source winget
winget install --id OBSProject.OBSStudio -e --source winget
winget install --id Gyan.FFmpeg -e --source winget
winget install --id Python.Python.3.13 -e --source winget
winget install --id OpenJS.NodeJS.LTS -e --source winget
winget install --id Git.Git -e --source winget
winget install --id Anthropic.ClaudeCode -e --source winget
```

| Paquete | Id | Versión vista hoy |
|---|---|---|
| Roblox Studio | `Roblox.RobloxStudio` | 1.6.3.172 (instalador; descarga Studio 0.747) |
| OBS Studio | `OBSProject.OBSStudio` | 33.0.0 |
| FFmpeg | `Gyan.FFmpeg` | 9.0.2 |
| Python 3.13 | `Python.Python.3.13` | 3.13.17 (también existe `Python.Python.3.14`, 3.14.10) |
| Node.js LTS | `OpenJS.NodeJS.LTS` | 26.13.1 |
| Git | `Git.Git` | 2.56.0.4 |
| Claude Code | `Anthropic.ClaudeCode` | 2.1.318 (comando `claude`) |

Después de instalar:

1. Abrir Studio, iniciar sesión, crear un lugar y guardarlo como archivo.
2. Assistant, "...", Manage MCP Servers, activar "Enable Studio as MCP server".
3. En una terminal nueva:
   `claude mcp add --transport stdio --scope user Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`
4. Abrir `claude`, ejecutar `/mcp` y confirmar que `Roblox_Studio` aparece conectado y que
   en Studio el indicador se pone verde.
5. En OBS: Herramientas, obs-websocket Settings, activar el servidor (puerto 4455) si se va
   a automatizar la grabación.

Node solo hace falta si se usa Remotion; Claude Code instalado por winget no lo requiere.

### 8.2 Requisitos de hardware

**[OFICIAL]** Tabla de requisitos de Studio
([doc](https://create.roblox.com/docs/studio/setup),
[fuente](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/includes/studio/system-reqs.md)):

| | Mínimo | Recomendado |
|---|---|---|
| Sistema | Windows 10, macOS 10.14 | Windows 11, macOS 14 o superior |
| Memoria | 3 GB | 8 GB |
| Resolución | (sin dato) | 1600 por 900 o más |

La tabla oficial actual no indica procesador, tarjeta gráfica ni disco.

**[INFERENCIA]** Para este proyecto (varias ventanas de Studio, OBS a 60 cuadros y
montaje): 16 GB de memoria como mínimo real y 32 GB para tres o cuatro ventanas; tarjeta
gráfica dedicada con codificador por hardware (NVENC o equivalente) para que grabar no le
quite procesador a Studio; disco de estado sólido; monitor de 1920 por 1080 o más, e
idealmente un segundo monitor para que las ventanas de Studio no se tapen.

---

## 9. Lo que hay que comprobar en el equipo de casa

En orden, porque cada punto condiciona el siguiente:

1. `/mcp` en Claude Code: lista real de herramientas. ¿Aparece `video_capture`? ¿Todas
   piden `studio_id`?
2. Abrir dos ventanas de Studio con lugares distintos. ¿Se mantienen las dos abiertas?
   ¿`list_roblox_studios` devuelve ambas con nombres distinguibles?
3. Dos chats de Claude Code, cada uno con su `studio_id`: crear una pieza de color distinto
   en cada uno y confirmar que no se cruzan.
4. `Players:CreateHumanoidModelFromDescriptionAsync` con R6 desde `execute_luau` en modo
   edición.
5. Pose con `C0` y cambio de cara, con una captura de `screen_capture` para cada una.
6. `upload_image` con una cara servida por `http://localhost`, y cuánto tarda en verse.
7. Script director en modo juego: cámara `Scriptable`, giro de 90 grados, interfaz oculta.
8. Grabación con OBS de una secuencia de 20 segundos con destello: medir cuadros perdidos
   y desfase contra el audio.
9. Repetir el punto 8 con otra ventana de Studio abierta en edición, para saber si el
   paralelo afecta la grabación.

---

## 10. Diferencias con `docs/03-produccion-y-herramientas.md`

No modifiqué ese archivo. Estos son los puntos donde lo investigado lo contradice o lo
corrige:

1. **Studio instalado.** `docs/03` dice que Studio quedó instalado y que la instalación
   incluye `StudioMCP.exe`. Hoy ya no lo está: se desinstaló a las 07:07 y solo queda el
   instalador.
2. **Comando de Claude Code.** Lo daba como "sin verificar". La plantilla
   `claude mcp add --transport stdio Roblox_Studio -- <comando>` está dentro del plugin de
   Studio; queda confirmado como comando, pendiente de prueba en vivo.
3. **Tabla de herramientas incompleta.** Faltan `list_roblox_studios` y el parámetro
   obligatorio `studio_id`, `multi_edit` y las demás herramientas de scripts,
   `search_game_tree`, `inspect_instance`, `get_studio_state`, las de entrada simulada,
   `open_cloud_invoke` y `subagent`.
4. **`store_image` no sube caras.** Solo carga una imagen local para herramientas de
   generación. Y `upload_image` recibe URLs HTTP, no archivos locales.
5. **"No hay herramienta de grabación de video".** En la doc pública es cierto, pero el
   binario de 0.747 contiene `video_capture`, detrás de una bandera.
6. **Script director por `execute_luau`.** La propia herramienta indica que los scripts se
   crean con `multi_edit`, y `execute_luau` restaura el tipo de cámara al terminar. La
   secuencia debe ser un `LocalScript` en modo juego.
7. **Reglas de Roblox.** El permiso de 2022 sigue en pie, pero las pautas vigentes de 2026
   prohíben el uso de los avatares clásicos en "commercial content" sin licencia y no
   mencionan los videos. Hay que citar ambos textos.
8. **Atajos Ctrl+H y F11.** No los pude confirmar. La guía del personal de Roblox menciona
   Ctrl izquierdo + Shift izquierdo + C para la interfaz en cámara libre.
9. **Rig Builder** ahora se llama Rig Generator.
10. **`generate_animation`** además convierte animaciones R6 existentes a R15 (sigue sin
    generar R6).
11. **Fork de respaldo.** `Chrrxs/robloxstudio-mcp` tampoco aísla por puerto; usa un puente
    compartido con `instance_id`.
