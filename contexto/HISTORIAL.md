# Historial del proyecto: qué pasó, en orden

Resumen curado de la conversación de trabajo del 12 y 13 de noviembre de
2026, hecha en el primer equipo. La conversación completa, mensaje por
mensaje, está en `conversacion.md`. Este archivo es el atajo.

## 1. El encargo inicial (12 de noviembre)

Pedido del usuario: investigar, documentar y proponer un plan para crear un
canal de YouTube monetizado con videos de Roblox hechos con Claude, en el
formato del short https://www.youtube.com/shorts/nn3_MOuxoho. Debía incluir
casos reales de éxito, cómo se hacen los videos, las herramientas y las
fuentes de inspiración para los guiones.

Qué se hizo:

- Se descargó y desarmó el short de referencia: 100 segundos, cerca de 400
  palabras, 62 cortes, estructura de 8 bloques (`docs/01`).
- Se midieron 16 canales con `yt-dlp`. Hallazgo: el canal del short de
  referencia (R6Rants) es un seguidor pequeño; los líderes son studby,
  GreenBroRants, SoyGelo y Custerk Blox, que publican de 3 a 8 videos al día
  (`docs/02`).
- Se documentaron dos rutas de producción: A, Claude dentro de Roblox Studio
  por el servidor MCP integrado; B, todo en código sin Studio (`docs/03`).
- Se verificó en el blog oficial de YouTube el cambio de requisitos del
  Programa de Socios desde el 1 de febrero de 2027 (`docs/04`).
- Se armó el banco de 40 premisas, la estructura de guion y la plantilla de
  prompt (`docs/05`), el plan por fases (`docs/06`) y el guion piloto 001.

Conclusiones estratégicas: Shorts para crecer y videos largos para cobrar;
inglés primero y español después; cadencia diaria; ruta A como principal.

## 2. Roblox Studio en el primer equipo

- La red bloqueaba los dominios de Roblox. No se intentó saltar el bloqueo.
- El 13 de noviembre la red ya los permitía y Studio se instaló con
  `winget`, pero no abría: se cerraba con `HardAssert (Expect to have
  mimalloc working...)` porque el software de seguridad del equipo inyecta
  una DLL antes que las de Studio. No se desactivó ni se esquivó.
- Decisión: la producción con Studio va en el equipo de casa.

## 3. Los consejos de TikTok

El usuario preguntó si una carpeta de consejos sobre canales de YouTube con
Claude aportaba algo. Se rescataron tres ideas y se integraron al método: la
lista de calidad antes de publicar y el ritmo de revisión semanal y mensual
(`docs/06`), y la sección de títulos y miniaturas (`docs/05`).

## 4. El kit de producción (13 de noviembre)

Pedido del usuario: dejar todo listo para producir en paralelo con varios
chats cuando tuviera el equipo de casa, incluidas la cuenta, la monetización,
el descubrimiento y los guiones, usando los subagentes que hicieran falta.

Se lanzaron trece subagentes. Resultado:

| Qué | Dónde | Estado |
|---|---|---|
| 25 guiones con lista de planos, revisados en conjunto por un editor | `guiones/` | Escritos; falta la pasada del usuario |
| Herramientas de voz, tiempos, subtítulos, montaje y revisión | `herramientas/` | Probadas de punta a punta |
| Biblioteca Luau y script director | `studio/` | Analizada y probada contra un doble; nunca corrió en Studio |
| Informe del MCP de Studio y del trabajo en paralelo | `investigacion/` | Leído de la documentación y del plugin |
| Identidad del canal: nombre, textos, imágenes | `canal/` | Lista; imágenes dibujadas con código |
| Guía de cuenta y monetización desde Colombia | `docs/07` | Lista |
| Descubrimiento, con medición de 360 Shorts | `docs/08` | Lista |
| Voz, música y efectos | `docs/09` | Lista; el usuario elige la voz |
| Sistema para varios chats | `CLAUDE.md`, `docs/10`, `arranque/` | Diseñado; sin probar con Studio |
| Metadatos, calendario y listas de los 25 videos | `videos/` | Escritos |
| Instalador del equipo | `preparar-equipo.ps1` | Probado solo en modo de revisión |

Un ensayo final pasó los 25 guiones por la cadena de voz, ritmo, tiempos,
planos y subtítulos, tres a la vez, con la voz sintética de Windows: todos
terminaron y todos los planos anclaron (`investigacion/ensayo-25-guiones/`).

## 5. Hallazgos que cambiaron el plan

- **Marca de Roblox.** Las pautas editadas el 1 de noviembre de 2026
  restringen los avatares clásicos R6 y R15 en "commercial content". Por eso
  el kit usa personajes de bloques propios por defecto (`docs/04`).
- **Funciones avanzadas.** Sin verificar el canal con documento o video no
  hay video relacionado, comentario fijado ni solicitud de monetización.
- **Formulario W-8BEN.** Se envía el día en que aprueban AdSense.
- **Títulos.** En inglés los líderes no usan palabras en mayúsculas ni pasan
  de 10 palabras. Aplicado a los 25 guiones.
- **Voz.** Las voces predeterminadas de ElevenLabs expiran el 31 de
  diciembre de 2026.
- **API de Roblox.** `Lighting.Technology` ya no se cambia por código y
  `Decal.Texture` está obsoleta. `upload_image` recibe direcciones HTTP, no
  archivos locales; por eso las caras se dibujan con código.

## 6. El video de presentación

El usuario notó que los líderes tienen un video de bienvenida (por ejemplo
"Welcome to GreenBroRants") y pidió uno con esa receta. Quedó en
`canal/video-presentacion.txt`: misma estructura y tono, en plural, solo
escenas terminadas. No incluye "Blender" ni "my team and I" porque no
corresponden al proceso de este canal y son datos que un revisor de YouTube
podría pedir demostrar; el usuario puede agregarlos si quiere.

## 7. El paso al equipo de casa

El usuario ya está en casa y pidió publicar todo en un repositorio público
de GitHub, con el contexto de los chats y un instructivo para el chat que
retome. Eso es este repositorio. El instructivo es `RETOMAR.md`.

## Decisiones tomadas

- Formato: micro-ficción de una regla imposible, de 90 a 125 segundos.
- Idioma: inglés primero; canal hermano en español después.
- Producción: ruta A (Roblox Studio con MCP); ruta B como respaldo.
- Personajes: elenco propio, no el avatar clásico.
- Nombre recomendado: Almostville (identificador libre en YouTube el 13 de
  noviembre de 2026). Alternativas: Rulefolk y OneOddRule.
- Trabajo en paralelo: un chat, una ventana de Studio, un lugar, una carpeta.

## Decisiones pendientes del usuario

- Confirmar el nombre del canal.
- Voz propia o sintética, y cuál.
- Mantener el elenco propio o volver al avatar clásico aceptando el riesgo.
- Crear la cuenta de Google y el canal (requiere su identidad y su teléfono).

## Lo que nunca se probó

- La biblioteca de `studio/` dentro de Roblox Studio.
- La conexión MCP en vivo y el trabajo con varias ventanas de Studio.
- La grabación de pantalla y el montaje sobre una grabación real.
- La llamada real a la API de ElevenLabs.
- `preparar-equipo.ps1` instalando de verdad en un equipo limpio.
