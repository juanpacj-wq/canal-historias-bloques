# 01. El formato de referencia, desarmado

Análisis propio del short que origina este proyecto y del canal que lo publica.
Los números se tomaron directamente de YouTube con `yt-dlp` el 2026-11-12.

## El short

| Dato | Valor |
|---|---|
| Título | In This Town Secrets Turn To MICE |
| URL | https://www.youtube.com/shorts/nn3_MOuxoho |
| Canal | R6Rants (https://www.youtube.com/channel/UCdhQwHEYe8kKJn4Zv5dyPiA) |
| Suscriptores del canal | 155.000 |
| Publicado | 2026-10-29 |
| Duración | 100 segundos |
| Vistas | 3.850.130 (en 14 días) |
| Me gusta | 69.813 (1,8 % de las vistas) |
| Descripción | Solo `#rblx #roblox #entertainment` |

## Qué es, en una frase

Micro-ficción narrada en primera persona, construida sobre **una sola regla
fantástica** ("En este pueblo, cada secreto que dices en voz alta se convierte en
un ratón gris"), ilustrada con escenas de Roblox Studio y rematada con un giro
emotivo y un chiste final.

No es gameplay, no es un tutorial y no tiene cara: es un cuento corto con
muñecos de Roblox como actores.

## Medidas del video (lo que hay que igualar)

| Medida | Valor | Cómo se midió |
|---|---|---|
| Palabras narradas | cerca de 400 | subtítulos automáticos |
| Ritmo de narración | cerca de 240 palabras por minuto | 400 palabras en 100 s (voz acelerada, sin pausas) |
| Cortes de cámara | 62 | detección de escena con ffmpeg (umbral 0,3) |
| Duración media del plano | 1,6 s | 100 s entre 62 cortes |
| Escenarios distintos | 6 | pueblo, cafetería, sala de reuniones, cuarto, pueblo nevado, bosque nevado |
| Personajes con cara propia | 2 protagonistas y unos 8 extras | fotogramas |
| Resolución | vertical 9:16 | ffprobe |

Conclusión práctica: **cada frase del guion tiene su propio plano**. El ritmo
visual lo marca el texto, no la animación. Los planos son simples (un personaje
quieto con una cara expresiva, un objeto, una multitud), pero hay muchos.

## Estructura del guion (el molde)

| Tiempo | Bloque | Qué pasa en el short |
|---|---|---|
| 0 a 4 s | **La regla** | "En este pueblo, cada secreto que dices en voz alta se convierte en un ratón gris." Se entiende sin contexto. |
| 4 a 12 s | **Cómo funciona** | El ratón corre hacia la persona del secreto y se lo susurra. Secretos pequeños, ratones pequeños; secretos grandes, ratones grandes. |
| 12 a 25 s | **El mundo reacciona** (2 o 3 ejemplos cómicos) | 300 ratones persiguen a una niña en la cafetería; el alcalde se tapa la boca con cinta; cada familia tiene un gato. |
| 25 a 40 s | **El narrador y su vínculo** | "Soy el mejor guardando secretos." Su mejor amigo Milo le cuenta todo. Tres secretos tiernos y ridículos (se plantan aquí para usarlos después). |
| 40 a 48 s | **La crisis** | Una tormenta de nieve; Milo se pierde en el bosque; los adultos no pueden buscar. |
| 48 a 52 s | **La idea** | Un secreto sobre Milo correría directo hacia él. La regla pasa de ser un problema a ser una herramienta. |
| 52 a 64 s | **Regla de tres, fallando** | Grita los tres secretos. Cada ratón llega un poco más lejos (10, 20, 30 pasos) y se congela. Demasiado pequeños. |
| 64 a 72 s | **La confesión** | El único secreto que le queda es suyo: "Milo es mi mejor amigo y llevo tres años con miedo de no ser el suyo." Ratón del tamaño de un caballo. |
| 72 a 88 s | **Rescate y remate emotivo** | El ratón gigante no puede susurrar: todo el pueblo lo oye. Milo responde "¡Idiota!" y aparece un segundo ratón gigante que corre hacia el narrador (Milo tenía el mismo secreto). |
| 88 a 100 s | **Chiste final** | Vuelven a casa montados en los ratones. El gato de Milo los ve y se desmaya. |

Por qué funciona:

1. **Gancho inmediato.** La regla rara aparece en la primera frase y genera la
   pregunta "¿y qué pasa con eso?".
2. **Siembra y cosecha.** Todo lo que se menciona al principio (tamaño de los
   ratones, los tres secretos de Milo, los gatos) se usa al final. Nada sobra.
3. **La regla resuelve el conflicto.** El desenlace no viene de afuera: sale de
   la propia regla, usada de una forma que el espectador no anticipó.
4. **El giro es emocional, no de trama.** El secreto más grande no es un chisme:
   es una vulnerabilidad. Eso es lo que la gente comenta y comparte.
5. **Cierre con risa.** El chiste del gato baja la tensión y deja buen sabor, lo
   que invita a ver otro.

## Lenguaje visual

- **Avatares R6** (el cuerpo clásico de 6 piezas), con ropa de catálogo y pelo.
- **Caras 2D que cambian por plano**: sorpresa, llanto con lágrimas azules,
  ojos en espiral, cara de dormido. La emoción se cuenta con la cara, no con
  animación corporal compleja.
- **Escenarios de bloques muy simples**: pasto verde plano, casas de colores,
  árboles de esfera. En la segunda mitad, el mismo pueblo con nieve y niebla.
- **Utilería de piezas básicas**: los ratones son cubos grises con orejas
  rosadas; el ratón gigante es el mismo modelo escalado.
- **Partículas** para la nieve y el humo ("puf").
- **Subtítulos**: 2 a 4 palabras a la vez, centrados en el tercio superior,
  letra redonda blanca con borde negro, y la palabra clave en MAYÚSCULAS
  ("RUNS to the PERSON", "FROZEN", "LIPS BLUE").
- **Audio**: narración continua, música de fondo suave, efectos puntuales.

## El canal R6Rants: cómo llegó hasta aquí

Advertencia: R6Rants no es el líder del formato, es un seguidor pequeño. Los
canales grandes (studby, GreenBroRants, SoyGelo, Custerk Blox) están en
`02-casos-de-exito.md`. Sirve como referencia porque muestra el recorrido de un
canal mediano.

El canal no nació con este formato. Lo encontró probando. La lista de shorts
(ordenada del más antiguo al más reciente) muestra cuatro etapas:

| Etapa | Época aproximada | Ejemplos | Rango de vistas |
|---|---|---|---|
| 1. Quejas y situaciones ("rants") | nov 2025 en adelante | "We Need Help", "Why do MOMS do this bro...", "Why Do POPULAR Girls Do This!?" | 190 mil a 9,9 millones |
| 2. Sketches cortos (10 a 40 s) | mediados de 2026 | "Mom VS Dad" (11 s, 9,6 millones), "When The Bell Rings", "Teacher Left For 5 Seconds" | 90 mil a 9,6 millones |
| 3. Serie "In This World..." (30 a 60 s) | sep a oct 2026 | "People Can't See Colors Until They Touch Their SOULMATE" (4,3 millones), "You See The Relationship's End" (2,2 millones) | 117 mil a 4,3 millones |
| 4. Cuentos largos con título corto (75 a 160 s) | desde finales de oct 2026 | "In This Town Secrets Turn To MICE" (3,8 millones), "The Lantern" (5,9 millones), "The Hollows" (5,9 millones) | 100 mil a 5,9 millones |

Datos de los shorts más recientes (fecha, duración, vistas):

| Fecha | Duración | Vistas | Título |
|---|---|---|---|
| 2026-11-12 | 162 s | 103.852 (recién publicado) | No Names |
| 2026-11-10 | 149 s | 469.798 | The Collector |
| 2026-11-08 | 131 s | 388.064 | The Ferry |
| 2026-11-07 | 152 s | 5.904.319 | The Hollows |
| 2026-11-04 | 157 s | 5.910.402 | The Lantern |
| 2026-11-02 | 77 s | 343.201 | Captain Pickles |
| 2026-11-01 | 92 s | 866.710 | The Listener |
| 2026-10-30 | 96 s | 115.983 | The Grinner |
| 2026-10-29 | 100 s | 3.850.130 | In This Town Secrets Turn To MICE |
| 2026-10-26 | 36 s | 179.744 | This Girl HATED Me |
| 2026-10-23 | 31 s | 158.669 | In This World Parents Must Reveal A SECRET... |
| 2026-09-29 | 34 s | 4.363.002 | In This World, People Can't See Colors Until They Touch Their SOULMATE |
| 2026-09-22 | 57 s | 812.248 | In This World, Everyone Can See How Many People You've Made Cry |

Lecturas:

- **Cadencia actual: un video cada 1 a 3 días.** Es el ritmo a igualar una vez
  la producción esté aceitada.
- **Los videos se están alargando.** En tres semanas pasaron de 30 s a más de
  150 s, y los dos más vistos del mes duran más de dos minutos y medio. YouTube
  permite shorts de hasta 3 minutos y el canal lo está aprovechando.
- **La distribución es de "éxitos y normales".** De 13 videos recientes, 4
  superan los 3,8 millones y el resto queda entre 100 mil y 900 mil. No todos
  pegan; se gana por volumen y consistencia.
- **Títulos**: o la regla completa ("In This World, ...") o un sustantivo con
  artículo ("The Lantern"). Descripción mínima, tres etiquetas.
- **Tema recurrente**: relaciones (pareja, amistad, familia) vistas a través de
  una regla mágica. El público es adolescente y joven adulto.
