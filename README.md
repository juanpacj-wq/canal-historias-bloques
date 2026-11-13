# Canal de YouTube: micro-ficción con Roblox, producida con Claude

Investigación y plan para crear y monetizar un canal de historias animadas con
estética de Roblox, en el formato "En este pueblo, [regla fantástica]...".
Video de referencia: https://www.youtube.com/shorts/nn3_MOuxoho

Fecha de la investigación: 12 de noviembre de 2026.

**¿Vas a continuar este proyecto en otro equipo?** Empieza por
[RETOMAR.md](RETOMAR.md). El contexto de la conversación de trabajo está en
[contexto/](contexto/).

## Resumen

- **El formato**: un cuento de 90 a 160 segundos, narrado en primera persona,
  que parte de una sola regla imposible ("cada secreto se convierte en un
  ratón") y termina con un giro emotivo o cómico. Muñecos R6, un plano nuevo
  cada segundo y medio, subtítulos palabra por palabra.
- **Sí hay casos de éxito, y son enormes**: studby (831 millones de vistas en
  Shorts), GreenBroRants (1.111 millones), SoyGelo en español (1.777 millones,
  4,48 millones de suscriptores). La ola empezó a mediados de octubre de 2026.
  El canal del video de referencia es un seguidor pequeño.
- **Sí se puede hacer con Claude**: Roblox Studio trae un servidor MCP
  integrado y Claude Code construye el pueblo, los personajes y la cámara. Hay
  también una ruta sin Roblox Studio, todo en código. Ya circulan tutoriales de
  ambas.
- **La monetización es más difícil de lo que parece**: desde el 1 de febrero de
  2027 un canal nuevo necesita 1.000 suscriptores y 8.000 horas de videos
  largos o 20 millones de vistas de Shorts en 90 días. Los Shorts pagan poco
  (20 a 100 USD por millón de vistas con audiencia joven). El plan combina
  Shorts para crecer y videos largos para cobrar.
- **Costo de arranque**: entre 0 y 50 USD al mes, sin contar Claude.
- **Riesgos principales**: saturación (la competencia crece cada semana), la
  política de contenido no auténtico de YouTube y la clasificación como
  contenido para niños.
- **Estado del equipo**: en el primer equipo Roblox Studio no abre (el
  agente de seguridad lo hace fallar al arrancar). La producción va en el
  equipo de casa y el kit para ese equipo está listo.
- **Riesgo de marca nuevo**: las pautas de Roblox editadas el 1 de noviembre
  de 2026 restringen los avatares clásicos R6 y R15 en "contenido comercial".
  El plan usa personajes de bloques propios
  (`docs/04-monetizacion-y-politicas.md`).

## Documentos

| Archivo | Contenido |
|---|---|
| [docs/01-formato-de-referencia.md](docs/01-formato-de-referencia.md) | El short de referencia desarmado: medidas, estructura del guion, lenguaje visual, evolución del canal. |
| [docs/02-casos-de-exito.md](docs/02-casos-de-exito.md) | 16 canales con cifras verificadas, en inglés y español; estimaciones de ingresos; patrones de los ganadores; tutoriales con Claude. |
| [docs/03-produccion-y-herramientas.md](docs/03-produccion-y-herramientas.md) | Cómo se hacen los videos, las dos rutas de producción con Claude, lista de herramientas con precios y tiempos. |
| [docs/04-monetizacion-y-politicas.md](docs/04-monetizacion-y-politicas.md) | Requisitos del Programa de Socios, cuánto paga, impuestos desde Colombia, políticas de riesgo, idioma. |
| [docs/05-guiones-y-fuentes.md](docs/05-guiones-y-fuentes.md) | Origen del formato, fuentes de inspiración, derechos de autor, estructura de 8 bloques, títulos y miniaturas, banco de 40 premisas, plantilla de prompt. |
| [docs/06-plan-de-accion.md](docs/06-plan-de-accion.md) | Plan por fases con metas, rutina por video, lista de calidad antes de publicar, presupuesto, indicadores, revisión semanal y mensual, y reglas de decisión. |
| [docs/07-canal-y-cuenta.md](docs/07-canal-y-cuenta.md) | Guía paso a paso para crear la cuenta y el canal, configurarlo, solicitar la monetización, AdSense desde Colombia y el formulario fiscal. |
| [docs/08-descubrimiento-y-metadatos.md](docs/08-descubrimiento-y-metadatos.md) | Cómo recomienda YouTube los Shorts, medición de los canales líderes, plantilla de metadatos y calendario de publicación. |
| [docs/09-audio-voz-musica-efectos.md](docs/09-audio-voz-musica-efectos.md) | Voz sintética y propia, música y efectos con sus licencias, y la cadena de mezcla. |
| [docs/10-produccion-en-paralelo.md](docs/10-produccion-en-paralelo.md) | Cómo llevar el proyecto al equipo de casa, validarlo y producir con varios chats a la vez. **Empieza por aquí cuando tengas el equipo.** |

## El kit de producción

| Carpeta o archivo | Contenido |
|---|---|
| [RETOMAR.md](RETOMAR.md) | Instructivo para recibir el proyecto en otro equipo: qué haces tú y qué hace el chat que continúa. |
| [contexto/](contexto/) | Historial curado, memoria del proyecto y la conversación completa, sin datos personales. |
| [CLAUDE.md](CLAUDE.md) | Reglas que lee cada chat de Claude Code: papeles, reclamo de videos, uso de Studio, camino de un video. |
| [preparar-equipo.ps1](preparar-equipo.ps1) | Instala y comprueba todo en el equipo de casa. |
| [arranque/](arranque/) | Cinco mensajes listos para pegar al abrir cada tipo de chat. |
| [guiones/](guiones/) | 25 guiones con lista de planos (`.md`) y narración para la voz (`.txt`). Índice y orden de producción en `guiones/INDICE.md`. |
| [herramientas/](herramientas/) | Scripts probados: voz, ritmo, tiempos por palabra, subtítulos, montaje, hoja de contactos, control de calidad y reclamo de videos. |
| [studio/](studio/) | Biblioteca Luau (elenco propio, caras, escenarios, luz, utilería, cámara) y script director. Sin probar en Studio. |
| [canal/](canal/) | Nombre recomendado con disponibilidad comprobada, textos del canal e imágenes (perfil, banner, marca de agua, plantilla de miniatura). |
| [videos/](videos/) | Una carpeta de trabajo por video, con su `estado.md` y sus metadatos de publicación ya escritos (`metadatos/publicacion.txt`). Calendario de los primeros 25 días en `videos/CALENDARIO.md` y listas de reproducción en `videos/LISTAS.md`. |
| [investigacion/](investigacion/) | Informe técnico del MCP de Studio y datos crudos de la competencia. |

## Siguiente paso

1. Tú, cuando quieras: crear la cuenta y el canal con
   [docs/07-canal-y-cuenta.md](docs/07-canal-y-cuenta.md) y los textos e
   imágenes de `canal/`. No depende del equipo de casa.
2. Tú: elegir la voz ([docs/09](docs/09-audio-voz-musica-efectos.md)) y darle
   una pasada al gancho y al remate de los primeros guiones.
3. En el equipo de casa: seguir
   [docs/10-produccion-en-paralelo.md](docs/10-produccion-en-paralelo.md).

## Sobre la confiabilidad de los datos

- Las cifras de canales y videos se tomaron directamente de YouTube.
- El cambio de requisitos de 2027 se leyó en el blog oficial de YouTube.
- Los ingresos son estimaciones a partir de RPM publicados por terceros; ningún
  creador de este formato ha publicado sus ganancias.
- El flujo de producción con Claude está descrito en documentación oficial y en
  tutoriales, pero **no se ha probado en este proyecto**. Para eso es el piloto.
- Lo que sí se probó en este equipo: toda la posproducción (`herramientas/`),
  con voz sintética de Windows y un video falso. Lo que no: la biblioteca de
  Studio, la conexión MCP, la grabación y la voz de ElevenLabs.
- Cada documento marca como "sin verificar" lo que no se pudo comprobar.
