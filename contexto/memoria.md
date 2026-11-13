# Memoria del proyecto (copia de la nota del primer equipo)

El asistente guarda notas persistentes por proyecto fuera del repositorio.
Esta es la del primer equipo, al 2026-11-13, sin datos personales. El chat
que retome debe guardarla en su propia memoria y corregir lo que ya no
aplique.

---

El repositorio es la investigación, el plan y el kit de producción de un
canal de YouTube monetizado de historias animadas (formato "In this world,
[regla fantástica]"). Documentación en `docs/01` a `docs/10`, índice en
`README.md`, reglas para los chats en `CLAUDE.md`, instructivo de traslado en
`RETOMAR.md`.

Decisiones y hechos que no se deducen del código:

- La producción con Roblox Studio va en el **equipo de casa** del usuario.
  En el primer equipo Studio no abría: lo tumbaba el software de seguridad,
  que no se debía desactivar ni esquivar.
- El usuario quiere producir con **varios chats de Claude Code a la vez**. El
  sistema está en `docs/10-produccion-en-paralelo.md`: un chat, una ventana
  de Studio, un lugar, una carpeta; reclamo con
  `herramientas/nuevo_video.py tomar`.
- Las pautas de marca de Roblox (editadas el 2026-11-01) restringen los
  avatares clásicos R6 y R15 en "commercial content". Por eso el kit usa un
  elenco de personajes de bloques propio. Ver `docs/04`.
- Nombre de canal recomendado: Almostville (identificador libre en YouTube
  el 2026-11-13). La cuenta y el canal los crea el usuario; no crear cuentas
  por él.
- El usuario pidió rehacer la imagen del canal con capturas hechas en
  Roblox Studio: `canal/recrear-imagen-en-studio.md`.
- El usuario quiere un video de presentación del canal con la receta del de
  GreenBroRants: `canal/video-presentacion.txt`.
- Probado en el primer equipo: toda la posproducción (`herramientas/`) y la
  cadena de voz a subtítulos sobre los 25 guiones. Sin probar: biblioteca
  `studio/`, conexión MCP, grabación, API de ElevenLabs.
- Desde el 2027-02-01 YouTube exige a los canales nuevos 1.000 suscriptores
  y 8.000 horas de videos largos o 20 millones de vistas de Shorts en 90
  días.

Preferencias permanentes del usuario:

- Español de Colombia neutro con tuteo; nunca voseo.
- Nunca el carácter raya larga (U+2014).
- Texto para copiar y pegar: plano, a ras de margen, y además en un `.txt`.
- Commits y PR sin líneas de coautoría ni firmas de herramientas; el único
  autor es el usuario.

Cómo aplicarla: al retomar, seguir `RETOMAR.md`, parte 2. Lo primero es
validar la biblioteca de Studio; después la imagen del canal, la creación
del canal con el usuario, el piloto y el trabajo en paralelo.
