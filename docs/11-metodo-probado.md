# 11. Método probado: cómo se hace un video sin repetir los errores del primero

Este documento sale de auditar la producción completa del video 001
(2026-11-13), el primero que se hizo de verdad en Roblox Studio. Separa lo que
funcionó, que quedó convertido en herramientas y reglas, de lo que hizo perder
tiempo, que quedó eliminado o prohibido. Manda sobre `docs/03` y `docs/10` en
todo lo que se contradiga: esos se escribieron antes de poder abrir Studio.

El paso a paso para un chat está en la skill `producir-video`
(`.claude/skills/producir-video/SKILL.md`). Aquí está el porqué.

## Resultado del video 001

- 61 planos, 93,9 s, 1080x1920 a 60 cps, voz sintética, subtítulos, música y
  40 efectos. `revisar.py` aprueba todo salvo el conteo de cortes entre planos
  de lluvia, que es un límite del detector.
- Nadie lo ha visto en movimiento ni lo ha escuchado todavía: se revisó por
  cuadros y por mediciones. La aprobación del dueño está pendiente.
- La primera vez tomó una sesión larga, casi toda gastada en descubrir cómo
  hacerlo. Con este método, el trabajo de máquina de un video igual es de unos
  45 minutos (5 de voz, 4 de vista previa, 21 de toma final, 4 de montaje y el
  resto en revisiones), más el tiempo de escribir la puesta.

## El método, en siete pasos

| # | Paso | Orden | Tiempo de máquina |
|---|---|---|---|
| 1 | Tomar el video y abrir su lugar | `nuevo_video.py tomar`, `studio/puente.py abrir` e `instalar` | 1 min |
| 2 | Voz, tiempos y subtítulos | `producir.py voz NNN` | 6 min |
| 3 | Escribir la puesta | `escenas/hacer_puesta.py` con `studio/puesta.py` | (escritura) |
| 4 | Revisar planos en edición | `studio/ver.py ... todos` y corregir | 2 min por pasada |
| 5 | Vista previa completa | `studio/rodar.py previa` y mirar las hojas | 4 min |
| 6 | Toma final | `studio/rodar.py toma` | 21 min |
| 7 | Montaje y revisión | `producir.py montar NNN` | 4 min |

Reglas de orden que ahorran tomas:

- No se rueda la toma final sin haber mirado las hojas de la vista previa. La
  vista previa cuesta 4 minutos y la toma 21.
- No se corre la vista previa sin haber pasado `ver.py` por todos los planos.
- La voz va antes que la puesta: los tiempos de cada plano dependen del audio
  y la tabla de planos puede cambiar.
- Cambiar la voz obliga a repetir desde el paso 2 completo, toma incluida.

## Lo que funcionó y se conserva

### Conexión con Studio

- **El puente** (`herramientas/studio/base.py` y `puente.py`). Mantiene un solo
  servidor MCP vivo y lo comparte por HTTP local; se arranca solo. Sirve aunque
  el chat no tenga cargadas las herramientas MCP, y evita una llamada de
  herramienta por cada acción.
- **`cargar.luau` por `execute_luau`** instala la biblioteca completa (178 KB)
  en una llamada, asignando `Source`. `require` funciona. Las vías de
  `multi_edit` y del monolito no hicieron falta.
- **Lugar desde plantilla.** `puente.py abrir` copia
  `studio/plantilla/lugar-vacio.rbxl`, lo abre, borra la base y marca el
  `VideoId`. El dueño ya no tiene que crear ni guardar nada a mano.
- **`workspace.StreamingEnabled = false`** se puede apagar desde
  `execute_luau`; sin eso el cliente no recibe todo.

### Voz y tiempos

- **Kokoro-82M local** (`herramientas/voz_kokoro.py`, entorno en
  `herramientas/kokoro/`). Gratis y con licencia limpia. Sintetizar oración por
  oración y unir con pausas de 0,20 s dio 61 de 61 planos anclados sin avisos.
- **La cadena `ritmo.py`, `transcribir.py --guion`, `planos_tiempos.py`,
  `subtitulos.py`** funcionó a la primera con voz real.
- **Comparar la transcripción cruda de Whisper con el guion** detecta posibles
  errores de pronunciación sin escuchar (`tiempos/palabras_crudo.json`).

### Imagen

- **La puesta como programa** (`hacer_puesta.py` con `studio/puesta.py`), no
  como JSON a mano. 61 planos caben en unas 200 líneas y un cambio de encuadre
  es una cifra.
- **Encuadre por punto y ancho** (`C(x, y, z, ancho)`). Es predecible; los
  encuadres automáticos G, M y C sobre personajes quedaban muy abiertos o muy
  cerrados.
- **Personajes con pelo redondo** (una bola algo mayor que la cabeza, corrida
  hacia arriba y hacia la nuca). Con las tapas de bloque parecían llevar un
  sombrero cuadrado en los primeros planos.
- **Vida en cada plano**: respiración por defecto, `anim`, `mover`, `cambios`
  de cara o pose a mitad de plano, y la batería que flota. Sin eso cada plano
  era una foto.
- **La batería**: verde `#2BD94E` (el anterior se veía turquesa), texto con
  borde oscuro (el blanco se perdía sobre el ámbar) y un resplandor suave.
- **Lluvia**: gotas alargadas con `Squash` negativo y una nube pequeña y densa
  encima del encuadre. La nube del escenario sola dejaba cuatro gotas en
  cuadro.
- **Luces de noche y de lluvia más claras.** Las originales dejaban a los
  personajes en silueta.

### Grabación

- **Rodaje cuadro a cuadro** (`herramientas/studio/rodar.py` con
  `studio/empaque/RodajeCuadros.client.luau`). Reemplaza a OBS y al modo en
  tiempo real. Cada cuadro se monta en modo juego en su instante exacto y se
  captura de la pantalla. Sincronía exacta con la voz, cero cuadros perdidos,
  sin destello de sincronía ni desfase que medir, y 0,22 s por cuadro.
- **Calibración con pantalla magenta**: ubica sola la vista del juego en el
  escritorio.
- **Partículas frenadas** (`TimeScale`) para que avancen un cuadro de película
  por cuadro capturado, con un momento en tiempo real al empezar cada plano de
  lluvia.
- **Vista previa a 10 cps** con hojas de dos cuadros por plano: es la revisión
  más barata y la que encontró casi todos los problemas.
- **En modo juego el giro vertical sí funciona** y se endereza con
  `--rotar antihorario`, como decía la documentación.

### Sonido y montaje

- **Efectos sintetizados** (`herramientas/studio/efectos.py`): 17 sonidos
  propios. No hay descargas, licencias ni reclamos.
- **Música de Incompetech por enlace directo**
  (`https://incompetech.com/music/royalty-free/mp3-royaltyfree/NOMBRE.mp3`) con
  el crédito en la descripción. La Biblioteca de YouTube sigue siendo mejor,
  pero pide que el dueño inicie sesión.
- **`montar.py --pico -2`**. Con el valor por defecto (-1,5) el pico real quedó
  en -0,9 dBTP y `revisar.py` lo marcó.
- **`producir.py`** encadena los pasos e imprime solo el resumen.

## Lo que hizo perder tiempo y se descarta

| Qué pasó | Costo | Qué se hace ahora |
|---|---|---|
| Leer documentos enteros y los fuentes de la biblioteca antes de empezar | Mucho contexto | La skill y los encabezados de cada herramienta bastan. Los `docs/01` a `10` son consulta, no lectura obligatoria |
| Validar la biblioteca con muestrarios y con la puesta de ejemplo de 49 planos (ya no coincidía con el guion de 61) | Una hora | La biblioteca ya está validada. El ejemplo viejo (`studio/ejemplos/`) queda solo para las pruebas fuera de Studio; el ejemplo real es `videos/001-.../escenas/hacer_puesta.py` |
| Lanzar un proceso MCP por llamada: dejaba procesos huérfanos y respondía "not connected" | Varias vueltas | El puente |
| Escribir archivos con `Set-Content` o `Out-File` de PowerShell 5.1: agregan BOM y `execute_luau` responde "Failed to parse command code" | Dos vueltas | Los archivos se escriben con la herramienta de escritura. El puente tolera el BOM |
| Reemplazos de texto con PowerShell: una función llamada `R` es un alias de `Invoke-History`, y los textos de varias líneas no coinciden por los saltos de línea | Dos tandas de cambios perdidas | Ediciones con la herramienta de edición o con un script de Python. Nunca con PowerShell |
| Revisar planos con la cámara girada en modo edición: Studio no respeta siempre el giro y las capturas salían con tres orientaciones distintas | Una hora | `ver.py` quita el giro y abre el campo de visión |
| Usar `mira` para que dos personajes se miren: quedan de perfil y la cara, que es un panel plano, desaparece | Tres rondas de corrección | `giro` de +30 y -30. Nunca más de 40 grados |
| Usar las anclas A y B para un dúo: quedan a 6 studs y el encuadre se abre | Una ronda | Posiciones directas en x = -1,7 y +1,7 |
| Descubrir después de la toma final que el subtítulo pisaba la batería en seis planos | Una toma repetida (21 min) | Regla de altura en `puesta.py` y marcas rojas de la franja de subtítulos en `ver.py` y en las hojas |
| Ajustar la luz de la batería mirando solo capturas de edición: en modo juego el resplandor es más fuerte y pintó las caras de verde | Un ciclo de rodaje | La vista previa en modo juego manda sobre las capturas de edición |
| Lluvia invisible y luego atravesada | Tres ciclos | Corregido en la biblioteca |
| Cargar el video final entero en memoria para hacer hojas | Una orden colgada 10 minutos | `hojas.py` saca solo los cuadros que necesita |
| Lanzar en primer plano órdenes de más de 10 minutos | Riesgo de corte | La toma final va en segundo plano y se espera con un bucle corto |
| Delegar la voz a un subagente con un encargo largo | Unos 80 mil tokens | `producir.py voz NNN` |
| Buscar a ciegas los botones de Studio para agrandar la vista | Media hora | Los pasos están en `ui.py`; Studio recuerda la disposición |
| Escribir `metadatos/publicacion.txt` desde cero sin mirar que ya venía escrito, con lista, episodio y fecha decididos | Hubo que restaurarlo | El archivo ya existe en cada video: solo se le agregan el crédito de la música y el cuadro de portada |
| Hacer la versión gris antes de la detallada | Nada: se omitió | Se elimina del camino. La versión detallada se construye en menos de un segundo |
| Creer la lista de "tapados" del ensayo | Ruido | Con encuadres por punto da falsos positivos. `puente.py reconstruir` ya no la muestra |

Cosas que se evaluaron y se dejaron por fuera a propósito:

- **OBS y la grabación en tiempo real.** No se necesitan.
- **El destello de sincronía y `montar.py --desfase`.** El rodaje cuadro a
  cuadro empieza en el instante cero exacto.
- **El estilo `r6`.** Sigue sin revisar y no se usa.
- **Renderizar por mosaicos o agrandar la ventana más allá de la pantalla**
  para ganar resolución. Demasiado complejo para lo que aporta hoy.

## Límites conocidos

- **Resolución.** En esta pantalla (1920x1080 con escala del 150 %) la vista
  del juego mide 808 px de alto en pantalla completa, y ese alto es el ancho
  del video. El 1080x1920 final es un escalado de 1,33. Dos ideas sin probar
  para mejorarlo: bajar la escala de Windows al 100 % mientras se rueda (la
  interfaz de Studio ocuparía menos) o rodar en un monitor más grande.
- **El botón de Roblox** de la esquina no se oculta en modo juego. Queda fuera
  del recorte 9:16 porque está en un extremo del lado largo.
- **El detector de cortes de `revisar.py`** no ve cortes entre planos de color
  parecido (lluvia, mismo escenario). Se confirma en la hoja de contactos.
- **Sin revisar a ojo:** nieve, niebla y los escenarios `salon`, `bosque` y
  `calle_noche`. La primera vez que un video los use, mira su panorama antes
  de escribir la puesta.
- **Las pruebas fuera de Studio** (`studio/pruebas/`) no se han vuelto a
  correr desde los cambios del 2026-11-13.
- **El equipo queda ocupado** durante la vista previa y la toma: la ventana de
  Studio tiene que estar al frente. Si pierde el foco, el programa la trae de
  vuelta y repite el cuadro.

## Decisiones del dueño que siguen abiertas

- La voz definitiva: Kokoro (y cuál), ElevenLabs o voz propia.
- El nombre del canal.
- Si la música sale de Incompetech con crédito o de la Biblioteca de YouTube.
