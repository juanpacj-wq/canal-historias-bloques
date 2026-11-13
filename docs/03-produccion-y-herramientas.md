# 03. Cómo se hacen los videos y qué herramientas se necesitan

Estado de la información: noviembre de 2026. Cada afirmación trae su fuente; lo
que no se pudo comprobar está marcado como **sin verificar**.

## Restricción encontrada en este equipo

La red desde la que se hizo esta investigación **bloquea los dominios de
Roblox**. Comprobado el 2026-11-12: `www.roblox.com`, `create.roblox.com` y
`setup.rbxcdn.com` (el servidor de instalación de Studio) responden 403 "Web
Page Blocked" desde el firewall. Además, Roblox Studio no está instalado aquí.

No se intentó saltar el bloqueo: es una decisión de quien administra la red.

**Actualización del 2026-11-13**: los tres dominios ya responden y Roblox
Studio quedó instalado en este equipo con `winget` (versión 0.747, en
`%LOCALAPPDATA%\Roblox\Versions`). La instalación incluye `StudioMCP.exe`. **Pero Studio no abre en este equipo.** Se cierra en menos de un segundo con
el error `HardAssert (Expect to have mimalloc working, but it was not
detected!)`. El diagnóstico de mimalloc dice: "mimalloc-redirect.dll seems to
be initialized after ucrtbase.dll". Es decir, otra DLL entra al proceso antes
que las de Studio y carga primero la biblioteca de C de Windows. El equipo
tiene software de seguridad que inyecta DLL en los procesos; es la causa más
probable, aunque no se comprobó cuál programa en concreto. No es
un problema de la instalación ni se arregla reinstalando.

Salidas: pedirle a quien administra el equipo una excepción para
`RobloxStudioBeta.exe` en el agente de seguridad, o usar Studio en un equipo
personal. No se debe desactivar ni esquivar el agente. Mientras tanto, la Ruta
B sigue disponible aquí.

Ese mismo día Studio fue desinstalado de este equipo (el registro del
instalador marca las 07:07). **Decisión tomada: Studio va en el equipo de
casa.** Todo quedó preparado para ese equipo:
`10-produccion-en-paralelo.md` y `preparar-equipo.ps1`.

## Correcciones posteriores a este documento

El informe `investigacion/studio-mcp-y-paralelismo.md` (2026-11-13) leyó la
documentación oficial y el plugin de Studio, y corrige varios puntos de abajo.
Donde haya diferencia, **manda el informe**:

- **Cada llamada al MCP lleva `studio_id`**, y `list_roblox_studios` entrega
  los id. Eso permite varios chats con varias ventanas de Studio.
- El comando de conexión quedó confirmado:
  `claude mcp add --transport stdio --scope user Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`.
- `store_image` no sube nada a Roblox, y `upload_image` recibe direcciones
  HTTP, no archivos locales. Por eso la biblioteca dibuja las caras con
  código y deja las imágenes subidas como mejora opcional.
- El script director debe ser un `LocalScript` en modo juego, creado con
  `multi_edit`: `execute_luau` restaura la cámara al terminar.
- Puede existir una herramienta `video_capture` para grabar sin OBS (sin
  documentar, detrás de una bandera). Hay que mirar si tu Studio la ofrece.
- `Lighting.Technology` ya no se cambia por código (se usa `LightingStyle`) y
  `Decal.Texture` está obsoleta (se usa `ColorMapContent`).
- Rig Builder ahora se llama Rig Generator. Ctrl+H y F11 no se confirmaron.
- Los avatares clásicos tienen una restricción de marca nueva: ver
  `04-monetizacion-y-politicas.md`, "Derechos de Roblox". El plan usa un
  elenco de personajes propio.
- Voz, música y efectos: la guía vigente es
  `09-audio-voz-musica-efectos.md`. Las voces predeterminadas de ElevenLabs
  expiran el 2026-12-31 y los modelos de voz de OpenAI se apagan el
  2027-01-06.
- Subtítulos y montaje: ya no son una propuesta. Están construidos y probados
  en `herramientas/`.

## Cómo se hace un video de este tipo

No existe un tutorial público de R6Rants ni una declaración de cómo trabajan
(**sin verificar** su flujo exacto). Lo que sigue es el flujo estándar de la
comunidad de animación en Roblox, más la parte que Claude puede automatizar.

### Las piezas

1. **Roblox Studio** (gratis). Es donde se arman los escenarios, se colocan los
   personajes y se reproduce la escena.
2. **Personajes R6.** El Rig Builder de Studio inserta muñecos R6 y también tu
   propio avatar con accesorios
   ([doc oficial](https://create.roblox.com/docs/studio/rig-builder)). Hay
   plugins "Load Character" que cargan cualquier avatar por nombre de usuario
   ([DevForum](https://devforum.roblox.com/t/load-character-plugin/1848301)).
3. **Caras.** En R6 la cara es una calcomanía (Decal) pegada a la cabeza. La
   expresión se cambia reemplazando su textura. Las caras propias se dibujan y
   se suben como imágenes
   ([DevForum](https://devforum.roblox.com/t/how-to-import-high-quality-character-faces-on-roblox-characters-works-with-r15-and-r6/622433)).
4. **Animación y cámara.** Tres caminos:
   - **Moon Animator 2**: el plugin estándar para animación cinemática
     (personajes, cámara, luces). De pago; la cifra más repetida es 29,99 USD de
     pago único (**sin verificar** en la ficha oficial).
   - **Animation Editor integrado**: gratis; varios creadores dicen que alcanza
     si la cámara se maneja por script
     ([DevForum](https://devforum.roblox.com/t/how-to-make-roblox-animations-for-trailersyoutube/2572053)).
   - **Scripts de Luau**: mover cámara y personajes con código. Es el camino
     que mejor encaja con Claude (ver más abajo).
5. **Grabación.** Ocultar la interfaz (Ctrl+H), pantalla completa (F11) y grabar
   con **OBS** (gratis). El grabador interno de Studio baja la calidad
   ([DevForum](https://devforum.roblox.com/t/how-to-record-trailers-with-moon-animation-suite/1923201)).
   No hay visor 9:16 nativo: lo habitual es grabar en horizontal a buena
   resolución y recortar a vertical en el montaje, por lo que hay que encuadrar
   al personaje en el centro.
6. **Voz.** Narración con voz sintética o propia.
7. **Subtítulos, música y montaje.** Editor de video o un flujo por comandos.

### Por qué el formato es viable para una sola persona

El análisis del short de referencia (ver `01-formato-de-referencia.md`) muestra
que casi no hay animación corporal: son muchos planos estáticos o con un
movimiento simple, y la emoción la lleva la cara. Un plano típico es "personaje
quieto, cara de susto, cámara cerca". Eso se puede describir con datos (qué
escenario, qué personajes, dónde están, qué cara, dónde va la cámara, cuánto
dura) y por tanto se puede generar con un script.

## Claude dentro de Roblox Studio (MCP)

- **Studio ya trae un servidor MCP integrado.** El repositorio antiguo
  `Roblox/studio-rust-mcp-server` fue archivado en abril de 2026 y remite al
  integrado ([GitHub](https://github.com/Roblox/studio-rust-mcp-server)).
- **Activación:** en Studio, Assistant, menú "...", Manage MCP Servers, activar
  "Enable Studio as MCP server". En "Quick connect" aparecen Claude Code y
  Claude Desktop
  ([doc oficial](https://create.roblox.com/docs/studio/mcp),
  [espejo en GitHub](https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/studio/mcp.md)).
- **Configuración manual en Windows**, según la doc oficial:

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

- El comando equivalente para Claude Code sería
  `claude mcp add --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`
  (**sin verificar**: deducido de la doc, no probado).

### Qué puede hacer Claude con ese servidor

| Herramienta MCP | Para qué sirve en este proyecto |
|---|---|
| `execute_luau` | Ejecutar código en Studio: construir escenarios con piezas, colocar personajes, mover cámara, cambiar caras, clima con partículas. Es la herramienta central. |
| `search_asset`, `insert_asset` | Buscar e insertar modelos del Creator Store (muebles, árboles, casas). |
| `generate_procedural_model`, `generate_mesh`, `generate_material` | Generar utilería y materiales. |
| `upload_image`, `store_image` | Subir las caras 2D propias. |
| `screen_capture` | Capturar el visor para que Claude revise el encuadre de cada plano. |
| `start_stop_play`, `get_console_output`, `save_place` | Reproducir, depurar y guardar. |

Límites:

- `generate_animation` solo crea animaciones **R15** de hasta 10 segundos. **No
  hay herramienta nativa de animación R6** ni de grabación de video.
- No se encontró ningún ejemplo público de cortos animados hechos con Claude por
  MCP; solo de juegos. Un autor que construyó un juego completo así reporta que
  gastó más tiempo corrigiendo lo visual que la lógica
  ([Medium](https://medium.com/@andy.a.g/i-built-a-roblox-game-using-only-ai-agents-heres-what-happened-ed57b553facc)).
  Hay que contar con revisión humana plano por plano.

Alternativa comunitaria si el integrado se queda corto: el fork activo
[Chrrxs/robloxstudio-mcp](https://github.com/Chrrxs/robloxstudio-mcp).

## Lo que ya hacen otros con Claude (tutoriales de noviembre de 2026)

Se revisaron las transcripciones de dos tutoriales recientes. Ambos canales
venden cursos o comunidades, así que sus resultados no están verificados, pero
el método que describen es concreto y coincide con la documentación.

### Ruta A: Claude dentro de Roblox Studio

Fuente: [Simply Azan, 2026-11-11](https://www.youtube.com/watch?v=qGhhl_mp5Pk).
Afirma que no puso un solo bloque a mano.

1. Activar el MCP de Studio (Assistant, Manage MCP Servers, Enable Studio as MCP
   server), usar "Quick connect", elegir Claude Code y pegar en la terminal el
   comando que entrega Studio. Prueba de conexión: pedirle a Claude un bloque
   rojo en el centro del mapa y una captura.
2. Un solo prompt largo que obliga a trabajar por etapas: historia, **versión
   gris** (solo cajas: calles, edificios, posiciones), mundo detallado,
   iluminación, personajes, lista de planos, cámara y, al final, reproducir y
   comprobar que cada plano corrió.
3. **Versión gris primero.** Si algo está mal ubicado se corrige en dos minutos
   y no después de construir todo.
4. **Iluminación.** Según el autor, fue lo que más cambió el resultado: sol
   bajo, sombras largas y oscuras, cielo pálido, colores cálidos.
5. **Cámara.** Midió un video líder: 133 planos en poco más de dos minutos. La
   cámara se mueve en casi todos los planos (acercamiento lento, de vez en
   cuando un acercamiento brusco sobre una palabra) y cerca de la mitad van
   ligeramente inclinados.
6. **Truco para el formato vertical**: el script gira la cámara 90 grados. En
   Studio se ve de lado, pero al rotar la grabación queda un video vertical a
   resolución completa en lugar de un recorte pequeño.
7. Se graba la pantalla mientras Studio reproduce todos los planos.
8. Voz: gratis con la función de voz de Google AI Studio, o ElevenLabs.
9. Montaje: una herramienta de pago que alinea planos, voz y subtítulos (el
   autor dice que le costó poco más de 1 USD por video). Se puede reemplazar
   por el montaje con ffmpeg descrito más abajo.
10. Advertencia del propio autor: los canales grandes no lo hacen con un solo
    prompt; pasan días puliendo cada animación. **Hay que dirigir a Claude.**

Errores que reporta: el pueblo construido lejos del centro del mapa (la cámara
solo mostraba cielo) y un primer resultado que "se veía barato" por la luz.

### Ruta B: todo en código, sin Roblox Studio

Fuente: [What If Animator, 2026-11-06](https://www.youtube.com/watch?v=gR6hWp8y09M).

- Claude genera en código los personajes (seis cajas: cabeza, torso, dos brazos,
  dos piernas), 15 expresiones de cara dibujadas, el pueblo, la luz, la cámara y
  los subtítulos, y un comando renderiza cuadro a cuadro a 1080 por 1920 y 60
  cuadros por segundo. No se abre Roblox ni se graba la pantalla.
- Medidas que tomaron de los 15 mejores videos del género: 223 palabras por
  minuto sin pausas, una sola pista de música unos 12 dB por debajo de la voz,
  casi sin efectos, un plano nuevo cada segundo y medio, subtítulos de una
  palabra a la vez. Su video: 66 planos en 95 segundos, cada plano anclado a una
  palabra de la voz.
- Dos prácticas útiles: un **verificador de cámara** que comprueba cada plano
  contra paredes y árboles antes de renderizar, y una **hoja de contactos** (un
  cuadro por plano) para ver todos los problemas de un vistazo.
- El kit queda: el siguiente video solo necesita historia y lista de planos.
- El video no dice qué librería usan (**sin verificar**); lo natural sería
  three.js con render por navegador sin interfaz, o Remotion.

### Cuál ruta elegir

| Criterio | Ruta A: Roblox Studio con MCP | Ruta B: todo en código |
|---|---|---|
| Aspecto | Roblox auténtico: avatares, ropa y accesorios reales | Imitación del estilo; se nota la diferencia |
| Funciona en la red actual | **No**: la red ya lo permite, pero Studio se cierra al abrir por el agente de seguridad | **Sí** |
| Grabación | Captura de pantalla manual | Render automático, repetible |
| Automatización | Alta, con un paso manual | Total |
| Riesgo con la marca | Uso permitido por Roblox para videos | No usa recursos de Roblox; conviene no presentarlo como Roblox si no lo es |
| Lo que usan los líderes | Probablemente esta (**sin verificar**) | No |

Recomendación: **la ruta A es la principal**, porque la audiencia responde a la
estética real de Roblox. **La ruta B es el plan de respaldo** y además sirve
para arrancar desde este equipo mientras se resuelve dónde correr Studio. El
piloto debe decidir entre ambas con un mismo guion.

## El flujo propuesto: "Claude dirige, tú grabas"

Esta es una propuesta de diseño propia, armada a partir de lo verificado arriba
y de los tutoriales. **Hay que validarla con un piloto** antes de comprometerse
(ver `06-plan-de-accion.md`, fase 1).

| Paso | Qué se hace | Quién | Herramienta |
|---|---|---|---|
| 1. Guion | Premisa, guion de 300 a 400 palabras con los 8 bloques | Claude y edición humana | Claude |
| 2. Voz | Generar la narración y obtener el tiempo de cada palabra | Automático | ElevenLabs (o voz propia más WhisperX) |
| 3. Lista de planos | Partir el guion en 40 a 60 planos, cada uno con tiempo de inicio y fin tomado del audio, escenario, personajes, cara y cámara | Claude | Archivo JSON |
| 4. Escenarios y personajes | Construir o reutilizar los sets, colocar los rigs, subir caras | Claude por MCP, con revisión humana | Roblox Studio |
| 5. Script director | Un script de Luau que lee la lista de planos y, al reproducir, pone cámara, posiciones y caras en el tiempo exacto de cada plano | Claude por MCP | `execute_luau` |
| 6. Revisión | Claude captura cada plano con `screen_capture`; tú corriges lo que se vea mal | Ambos | Studio |
| 7. Grabación | Reproducir la escena completa y grabarla de corrido | Tú | OBS |
| 8. Montaje | Recortar a 9:16, sincronizar con la voz, quemar subtítulos palabra por palabra, mezclar música y efectos | Automático | ffmpeg (o Remotion) |
| 9. Publicación | Título, descripción, etiquetas, subida | Tú | YouTube Studio |

La ventaja de sincronizar el script director con los tiempos del audio es que
la grabación sale **ya montada**: un solo clip continuo que solo necesita
recorte, voz, subtítulos y música.

### Biblioteca reutilizable (lo que abarata cada video)

- 8 a 10 escenarios base: pueblo, colegio (salón, cafetería, pasillo), casa
  (sala, cuarto), parque, bosque, calle de noche. Cada uno con variantes de
  clima (sol, lluvia, nieve, noche).
- Un elenco de 10 a 15 rigs R6 con ropa propia o clásica.
- Un paquete de 15 a 20 caras propias (neutra, feliz, triste, llanto, susto,
  rabia, enamorado, dormido, pícaro, mareado).
- Utilería genérica hecha con piezas.
- Plantilla de subtítulos y plantilla de mezcla de audio.

## Voz

Precios de la [página oficial de ElevenLabs](https://elevenlabs.io/pricing):

| Plan | Precio al mes | Créditos | Licencia comercial |
|---|---|---|---|
| Free | 0 USD | 10 mil (unos 10 min) | No figura |
| Starter | 6 USD | 30 mil (unos 30 min) | Sí |
| Creator | 22 USD | 121 mil (unos 121 min) | Sí |

- Un video de 100 segundos consume cerca de 2.500 caracteres. Starter alcanza
  para unos 12 videos al mes sin contar repeticiones; para publicar a diario
  hace falta Creator.
- La API de ElevenLabs puede devolver el tiempo de cada carácter junto con el
  audio, lo que ahorra el paso de Whisper (**sin verificar** en esta
  investigación; comprobar en el piloto).
- Alternativa gratuita y la más segura frente a las políticas de YouTube:
  **grabar tu propia voz**.
- Alternativa sintética gratuita mencionada en los tutoriales: la generación de
  voz de Google AI Studio (condiciones de uso comercial **sin verificar**).
- Ritmo del género: unas 220 a 240 palabras por minuto, sin pausas. Se logra
  cortando silencios y acelerando un poco la voz en el montaje.
- No se pudo determinar qué voz usa R6Rants.

## Subtítulos y montaje

Opción recomendada (automatizable con Claude Code, costo cero):

- **WhisperX** para obtener el tiempo de cada palabra si la voz es propia
  ([GitHub](https://github.com/m-bain/whisperX)). Este equipo no tiene GPU
  NVIDIA; en CPU funciona, más lento, pero para 100 segundos de audio es
  aceptable.
- Un script que genere el archivo de subtítulos **ASS** con 2 a 4 palabras por
  bloque y las palabras clave en mayúsculas.
- **ffmpeg** (ya instalado en este equipo) para recortar a 9:16, quemar los
  subtítulos y mezclar voz, música y efectos.
- Alternativa con más control visual: **Remotion**, gratis para individuos y
  equipos de hasta 3 personas
  ([licencia](https://www.remotion.dev/docs/license/pricing.md)).

Opción manual: **CapCut**. Los subtítulos automáticos ya no son ilimitados en el
plan gratis y los precios del plan pago varían según la fuente (entre 8 y 20 USD
al mes, **sin verificar** en la página oficial). **DaVinci Resolve** tiene
versión gratuita.

## Música y efectos

- **Biblioteca de audio de YouTube**: gratis y la más segura. YouTube indica que
  sus pistas no reciben reclamos de Content ID
  ([ayuda oficial](https://support.google.com/youtube/answer/3376882)).
- **Pixabay**: gratis, sin atribución obligatoria
  ([licencia](https://pixabay.com/service/license-summary/)). Algunos autores
  registran sus pistas en Content ID, así que puede tocar disputar reclamos.
- **Epidemic Sound** o **Uppbeat**: entre 10 y 18 USD al mes según terceros
  (**sin verificar** en páginas oficiales). Opcionales.

Regla dura: un Short de más de 1 minuto con un reclamo activo de Content ID
queda bloqueado
([ayuda oficial](https://support.google.com/youtube/answer/15424877?hl=en-GB)).
Como estos videos duran más de 60 segundos, **solo música de la Biblioteca de
audio de YouTube o con licencia clara**, y nunca audio del catálogo de Roblox.

## Reglas de Roblox para videos

- Roblox permite crear videos con sus avatares y monetizarlos con anuncios de
  YouTube
  ([FAQ oficial en DevForum](https://devforum.roblox.com/t/update-to-roblox-licensing-program-brand-guidelines/1843674)).
- Si el nombre del canal usa "Roblox" o "Blox", hay que aclarar que no está
  afiliado a Roblox. El logo no es de uso libre. Recomendación: no usar la
  palabra en el nombre del canal.
- Sobre ropa UGC del catálogo en videos no se encontró una cláusula específica
  (**sin verificar**). Lo prudente: ropa clásica o propia, sin marcas reales.

## Lista de herramientas

| Pieza | Opción sin costo | Opción paga |
|---|---|---|
| Guion y dirección | Claude (suscripción que ya tienes) | Igual |
| Escenas | Roblox Studio con el MCP integrado | Igual |
| Animación fina (opcional) | Animation Editor integrado | Moon Animator 2, unos 30 USD una vez (sin verificar) |
| Grabación | OBS | Igual |
| Voz | Voz propia | ElevenLabs Starter (6 USD) o Creator (22 USD) |
| Tiempos por palabra | WhisperX | Incluido en ElevenLabs |
| Subtítulos y montaje | ffmpeg con ASS, o Remotion | CapCut (8 a 20 USD, opcional) |
| Música | Biblioteca de audio de YouTube, Pixabay | Epidemic Sound o Uppbeat (10 a 18 USD, opcional) |
| Caras | Dibujadas a mano o en un editor gratuito | Igual |
| **Total mensual** | **0 USD** | **6 a 22 USD lo esencial** |

Además: una cuenta de Roblox, una cuenta de Google para el canal y un equipo
donde Roblox Studio abra (en este todavía no abre).

## Tiempo por video (estimación, sin verificar)

| Etapa | Tiempo por video de 100 s |
|---|---|
| Primeros videos (armando la biblioteca) | 10 a 20 horas |
| Con biblioteca hecha y flujo aceitado | 3 a 6 horas |

El cuello de botella es la revisión visual plano por plano, no el guion ni el
montaje.
