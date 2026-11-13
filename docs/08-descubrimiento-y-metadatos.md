# 08. Descubrimiento y metadatos: cómo lograr que cada video sea recomendado

Corte de la información: 13 de noviembre de 2026. Tiene tres partes: qué dice
YouTube sobre cómo recomienda los Shorts (parte 1), qué hacen de verdad los
canales líderes del formato, medido con datos propios (parte 2), y los
entregables para usar en cada publicación (parte 3).

Cómo se etiqueta cada afirmación:

| Etiqueta | Qué significa |
|---|---|
| **Oficial** | Lo dice YouTube en su ayuda o en su blog, y la página se abrió y se leyó. |
| **Oficial vía prensa** | Lo dijo personal de YouTube (Todd Beaupré, Todd Sherman, Rene Ritchie) en un video o publicación que no se pudo abrir directamente; la cita se tomó de un medio que la transcribe. |
| **Terceros** | Análisis de medios, herramientas o consultores. No es postura de YouTube. |
| **Medido** | Sale de `investigacion/metadatos-competencia.csv` (parte 2). |
| **Sin verificar** | No se encontró fuente primaria o no se pudo abrir. |

## Lo más importante

1. **En Shorts no se optimiza el clic, se optimiza que no deslicen.** YouTube
   no publica pesos de sus señales; lo que sí dice es que usa cientos, que
   ninguna métrica sola decide y que para videos cortos pesa más el porcentaje
   visto que los minutos vistos (oficial).
2. **Los metadatos son higiene, no palanca.** Las etiquetas ocultas "no son
   importantes" (oficial), `#shorts` no hace falta para que el video sea un
   Short (oficial) y los líderes medidos usan desde cero hashtags hasta cinco,
   con vistas igual de grandes (medido).
3. **Lo que sí se mueve con metadatos**: el idioma declarado (activa el doblaje
   automático, que casi todos los líderes tienen), el título corto que nombra
   el objeto de la historia, la portada, el video relacionado y la serie.
4. **La hora de publicación no cambia el resultado a largo plazo** (oficial).
   Los líderes publican repartido en las 24 horas, a intervalos fijos (medido).
5. **Publicar mucho no penaliza, pero tampoco es la causa del éxito** (oficial
   vía prensa). Los líderes publican de 2,5 a 8 al día (medido).
6. **No borrar ni resubir** (oficial y oficial vía prensa).
7. **Desde octubre de 2026 el feed de Shorts prioriza contenido original** y
   reduce el alcance de las resubidas (oficial vía prensa). Publicar el mismo
   archivo propio en TikTok e Instagram no está prohibido, pero cada plataforma
   castiga las marcas de agua de las otras.

## Parte 1. Cómo recomienda YouTube los Shorts hoy

### 1.1 Qué señales pesan

Lo confirmado:

- **Shorts y videos largos se recomiendan con sistemas separados**: "we've
  built separate recommendation systems optimized for each" (oficial,
  [blog de YouTube, 6 de mayo de 2025](https://blog.youtube/creator-and-artist-stories/debunking-common-myths-about-youtube-shorts/)).
  El mismo artículo niega que los Shorts perjudiquen a los videos largos del
  canal y que los sonidos de moda sean necesarios.
- **Entradas generales del sistema**: lo que el espectador ve y no ve, lo que
  busca, me gusta, suscripciones, "No me interesa" y encuestas de satisfacción
  (oficial,
  [Cómo funciona YouTube](https://www.youtube.com/howyoutubeworks/product-features/recommendations/)
  y [preguntas frecuentes de rendimiento](https://support.google.com/youtube/answer/141805?hl=en)).
- **Porcentaje visto frente a minutos vistos**: "relative watch time is more
  important for short videos"; para videos largos pesa más el tiempo absoluto
  (oficial, mismas preguntas frecuentes). Para un Short de 120 s esto significa
  que importa qué fracción se ve, no solo que dure más.
- **Me gusta**: "Likes and dislikes are some of the hundreds of signals we
  consider for ranking" (oficial, mismas preguntas frecuentes). Desde el 25 de
  junio de 2026 los Shorts ya no tienen botón de "No me gusta" y el pulgar se
  cambió por un corazón; la señal negativa explícita es "No me interesa", que
  ahora pide un motivo (oficial,
  [blog de YouTube](https://blog.youtube/news-and-events/youtube-shorts-experience-updates-features/);
  el detalle del motivo es de terceros,
  [ppc.land](https://ppc.land/youtube-shorts-removes-dislike-button-adds-heart-icon-and-2x-speed/)).
- **Ninguna métrica sola decide**: "We have to look at many different metrics,
  because no metric on its own is a good indicator of value"; la meta declarada
  es el valor de largo plazo para el espectador (oficial vía prensa, Todd
  Beaupré en Creator Insider, 1 de septiembre de 2026, citado por
  [OutlierKit](https://outlierkit.com/resources/how-youtube-recommendations-work/)).
- **"The audience is the algorithm"**: el sistema sigue lo que hace la
  audiencia; una vista debe reflejar la intención de ver (oficial vía prensa,
  Todd Sherman, líder de producto de Shorts, agosto de 2023, citado por
  [Search Engine Journal](https://www.searchenginejournal.com/youtube-explains-how-shorts-algorithm-works/494953/)).

Lo que **no** está confirmado:

| Señal | Estado |
|---|---|
| "Vieron frente a deslizaron" | Es una métrica de YouTube Analytics. No se encontró ninguna declaración oficial de que esa cifra sea, tal cual, la señal de clasificación ni de un umbral. Los "70 a 80 %" que circulan son de blogs (ver `05-guiones-y-fuentes.md`). |
| Repeticiones (bucles) | Cuentan como vistas desde 2025 (sección 1.2). Sin declaración oficial sobre su peso en la recomendación. |
| Compartidos y comentarios | Aparecen en listas de terceros ([Social Media Today](https://www.socialmediatoday.com/news/youtube-advice-for-shorts-creators-hashtags-algorithm/691835/)). Sin peso oficial. |
| Suscripciones desde el Short | Las suscripciones son una entrada general (oficial). Sin dato específico para Shorts. |

Lectura práctica: como no hay pesos publicados, lo sensato es mirar en
Analytics, para cada video, tres cosas contra la mediana del propio canal: el
porcentaje que vio en vez de deslizar, el porcentaje promedio visto y las
vistas con interacción por hora en las primeras 48 horas.

### 1.2 Cómo se cuentan las vistas desde 2025

- Desde el **31 de marzo de 2025**, "Views will count the number of times a
  Short starts to play or replay, with no minimum watch time requirement". La
  métrica anterior se conserva en Analytics con el nombre **"Engaged views"**
  (vistas con interacción), que muestra cuántos espectadores eligieron seguir
  viendo (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/10059070?hl=en)).
- **El Programa de Socios y el reparto de ingresos usan las vistas con
  interacción**, no las vistas públicas: "They will both be based on 'Engaged
  Shorts views'" (oficial, misma página, y
  [política de monetización de Shorts](https://support.google.com/youtube/answer/12504220?hl=en)).
- Consecuencia para este proyecto: **las vistas públicas de los competidores
  (las de la parte 2) están infladas** frente a lo que cuenta para los umbrales
  de `04-monetizacion-y-politicas.md`. La proporción entre unas y otras no es
  pública; solo se ve en el Analytics propio.
- Según prensa, desde el 24 de agosto de 2026 las vistas públicas de videos
  largos también cuentan desde el primer cuadro (terceros,
  [Engadget](https://engadget.com/2238611/youtube-public-view-counts-will-likely-get-higher-starting-next-week/);
  el anuncio oficial no se pudo abrir).

### 1.3 Cómo prueba YouTube un video nuevo y cuándo lo vuelve a empujar

- **Audiencia semilla**: el sistema busca "a seed audience, find a set of
  people that may enjoy your video"; según cómo responda ese grupo, el Short
  sube o se estanca (oficial vía prensa, Todd Sherman, agosto de 2023,
  [TechCrunch](https://techcrunch.com/2023/08/25/youtube-demystifies-the-shorts-algorithm-views-and-answers-other-creator-questions/)).
- **Para un primer video sin historial**, el sistema parte de las preferencias
  temáticas del espectador y de lo que entiende sobre el tema del video: "we
  hope that we'll find some viewers who are interested, and build from there";
  y si no los encuentra, "maybe that video just won't get more impressions"
  (oficial vía prensa, Todd Beaupré, 1 de septiembre de 2026,
  [OutlierKit](https://outlierkit.com/resources/how-youtube-recommends-new-channels/)).
- **Frescura**: la única frase oficial encontrada es que el feed de Shorts
  "may tune up on the recency of content" (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/16559651?hl=en)).
- **El "límite de 30 días" es una teoría de terceros.** Mario Joos (consultor
  de retención) reportó que desde septiembre de 2025 los Shorts de más de 28 a
  30 días pierden impresiones; él mismo lo llama "a carefully constructed
  working theory and not a confirmed fact", y YouTube no lo ha confirmado
  (terceros,
  [Search Engine Journal](https://www.searchenginejournal.com/youtube-shorts-algorithm-may-now-favor-fresh-over-evergreen/562661/),
  [Tubefilter](https://www.tubefilter.com/2025/12/05/youtube-shorts-algorithm-change-new-uploads/)).
- **Sin verificar**: que YouTube "reempuje" un Short en momentos fijos (a las
  24 horas, a los 7 días). No hay declaración oficial. Lo que sí dice la ayuda,
  para videos en general, es que un video viejo puede despegar cuando sube el
  interés por su tema o cuando espectadores nuevos recorren el canal (oficial,
  [preguntas frecuentes](https://support.google.com/youtube/answer/141805?hl=en)).

Lectura práctica: el catálogo viejo rinde menos en Shorts que en videos largos,
así que el crecimiento depende de seguir publicando. Y un video nuevo que
"pega" es la mejor oportunidad para que los espectadores recorran los
anteriores; por eso importan la serie y el video relacionado (parte 3).

### 1.4 Frecuencia y varios videos al día

- "Growth in views across uploads is not correlated with time between uploads".
  Tampoco hay castigo por hacer pausas: YouTube dice haber estudiado miles de
  canales que pararon sin hallar relación entre el largo de la pausa y el
  cambio en vistas (oficial,
  [preguntas frecuentes](https://support.google.com/youtube/answer/141805?hl=en)).
- **No hay tope algorítmico por día**: "There is nothing in our systems that's
  like when you hit the five video or 10 short threshold per day"; y agrega que
  esa energía "is probably better spent in just making a better video and fewer
  of them" (oficial vía prensa, Todd Sherman, 2023,
  [Social Media Today](https://www.socialmediatoday.com/news/youtube-advice-for-shorts-creators-hashtags-algorithm/691835/)).
- **Sí hay un tope técnico de subidas diarias**, sin número publicado, más bajo
  para canales con acceso estándar y más alto con funciones avanzadas (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/9890437?hl=en)).
- **Sin verificar**: que dos Shorts del mismo canal publicados muy seguidos se
  quiten vistas entre sí. Un análisis de terceros sobre 18.148 Shorts encontró
  que separar las publicaciones 12 a 48 horas rinde más que hacerlo menos de 3
  horas, pero es una correlación y solo se leyó el resumen
  ([OverseerOS](https://www.overseeros.com/blog/how-long-to-wait-between-youtube-shorts)).
  Los líderes medidos publican cada 4 a 6 horas con vistas enormes (parte 2).

### 1.5 Hora de publicación

- "Publish time is not known to impact a video's long-term performance".
  Publicar cuando la audiencia está activa puede ayudar a las primeras vistas,
  y la hora sí importa para directos y estrenos (oficial,
  [preguntas frecuentes](https://support.google.com/youtube/answer/141805?hl=en)).
- "It's not something that we think about optimizing for" (oficial vía prensa,
  Todd Sherman, 2023, mismo artículo de TechCrunch).
- Esperar un día o dos para publicar no ayuda: "Waiting 24 to 48 hours is no
  different than waiting 24 to 48 seconds" (oficial vía prensa, Rene Ritchie,
  [Search Engine Journal, 12 de noviembre de 2025](https://www.searchenginejournal.com/youtube-debunks-24-48-hour-upload-delay-recommendation/560613/)).
- **Los Shorts no envían notificación al publicarse** (oficial,
  [blog de YouTube, 28 de marzo de 2024](https://blog.youtube/culture-and-trends/renes-top-five-on-youtube-march-28-2024-edition/)).
  Por eso la hora pesa todavía menos que en videos largos.

### 1.6 Borrar, resubir y videos flojos

- "Don't delete videos unless you have a very, very good reason. When you
  delete a video, you delete your channel's connection to the audience that
  watched that video" (oficial, Todd Beaupré citado en el
  [blog de YouTube, 28 de marzo de 2024](https://blog.youtube/culture-and-trends/renes-top-five-on-youtube-march-28-2024-edition/)).
- Borrar y volver a subir un Short flojo: "I would not advise that"; además
  "there's also a risk that it gets seen as spam in our systems" (oficial vía
  prensa, Todd Sherman, 2023,
  [Social Media Today](https://www.socialmediatoday.com/news/youtube-advice-for-shorts-creators-hashtags-algorithm/691835/)).
- **Un video flojo no hunde el canal**: "What matters is how viewers reply to
  each video when it's recommended to them". Lo que sí baja las vistas del canal
  es que los espectadores dejen de ver la mayoría de los videos (oficial,
  [preguntas frecuentes](https://support.google.com/youtube/answer/141805?hl=en)).
- Cambiar título o portada después de publicar no castiga por sí mismo; el
  sistema responde a cómo cambia la reacción de los espectadores. "Changing
  your video title and thumbnail can be an effective way to get more views, but
  don't change what's working" (oficial, mismas preguntas frecuentes).

### 1.7 Título, descripción, hashtags, categoría, idioma y etiquetas

| Campo | Qué dice YouTube | Estado |
|---|---|---|
| Título | Máximo 100 caracteres. Junto con la descripción ayuda al sistema a entender el tema cuando todavía no hay datos de comportamiento. | Oficial ([ayuda](https://support.google.com/youtube/answer/10059070?hl=en)) y oficial vía prensa (Beaupré, 2026) |
| Descripción | Los títulos y descripciones traducidos se usan en la búsqueda. Los enlaces en la descripción de un Short no son clicables. | Oficial ([audio multilingüe](https://support.google.com/youtube/answer/13338784?hl=en), [enlaces](https://support.google.com/youtube/answer/13748639?hl=en)) |
| Hashtags | "Hashtags also allow viewers and listeners to find related content via search". Con más de 60, YouTube los ignora todos. | Oficial ([ayuda](https://support.google.com/youtube/answer/6390658?hl=en)) |
| `#shorts` | No es necesario: todo video cuadrado o vertical de hasta 3 minutos subido desde el 15 de octubre de 2024 se clasifica como Short. | Oficial ([ayuda](https://support.google.com/youtube/answer/15424877?hl=en)). No hay una frase que diga "ya no lo uses". |
| Hashtags de tema | Sherman dijo que sirven cuando están ligados a un evento o a un tema, y que conviene considerarlos. | Oficial vía prensa ([Social Media Today](https://www.socialmediatoday.com/news/youtube-advice-for-shorts-creators-hashtags-algorithm/691835/)) |
| Etiquetas ocultas | "Not important". Sirven sobre todo para corregir errores de ortografía frecuentes. | Oficial ([preguntas frecuentes](https://support.google.com/youtube/answer/141805?hl=en)) |
| Idioma del video | "It's also used to help viewers find videos in their language". También define el idioma de origen del doblaje. | Oficial ([ayuda](https://support.google.com/youtube/answer/6304325?hl=en)) |
| Categoría | No se encontró ninguna declaración sobre su efecto en la recomendación de Shorts. | Sin verificar |

### 1.8 Subtítulos y doblaje automático

- **Doblaje automático**: "This feature is enabled by default for eligible
  creators. When you upload a new video, dubs will be automatically generated"
  (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/15569972?hl=en)).
  Está en 27 idiomas y "having your videos dubbed has no negative impact on
  viewer discovery" (oficial,
  [blog de YouTube, 15 de mayo de 2026](https://blog.youtube/creator-and-artist-stories/youtube-auto-dubbing-explained/)).
- **Sí funciona en Shorts.** La ayuda no lo menciona de forma expresa, pero la
  medición de la parte 2 lo confirma: la mayoría de los Shorts de los líderes
  tienen pistas de audio dobladas automáticamente (medido). Esto resuelve la
  duda que quedó abierta en `04-monetizacion-y-politicas.md`.
- **Pistas de audio propias** (doblaje manual): se pueden subir a un video o a
  un Short, pero solo con funciones avanzadas activas (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/13338784?hl=en)).
- **Sin verificar**: que un canal nuevo y sin verificar reciba doblaje
  automático desde el primer video, y que los subtítulos cargados a mano
  aumenten el alcance de un Short. En este formato los subtítulos van quemados
  en la imagen, que es lo que ve quien mira sin sonido.

### 1.9 Listas de reproducción, series y video relacionado

- **Listas**: un Short se puede agregar a listas. Una lista que solo tiene
  Shorts no se puede reordenar (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/57792?hl=en)).
- **Series de Shorts**: anunciadas el 23 de septiembre de 2026 en Made on
  YouTube como "structured Shorts series" (oficial,
  [blog de Google](https://blog.google/products-and-platforms/products/youtube/made-on-youtube-updates-2026/)).
  Según prensa permiten organizar los Shorts en temporadas y episodios
  (terceros,
  [9to5Google](https://9to5google.com/2026/09/23/made-on-youtube-2026/)). No se
  encontró página de ayuda con los pasos ni los requisitos: **sin verificar**
  si está disponible para un canal nuevo.
- **Video relacionado**: "A related video allows you to showcase your Videos,
  Shorts, and Live in the Shorts player". Es el único enlace clicable dentro de
  un Short. Se configura en YouTube Studio en computador, exige funciones
  avanzadas y el destino debe ser público o no listado (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/14075157?hl=en)).

### 1.10 Comentarios fijados y enlaces

- Las URL en comentarios y descripciones de Shorts no son clicables, para
  frenar el spam (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/13748639?hl=en);
  la fecha de entrada, 31 de agosto de 2023, es de
  [Tubefilter](https://tubefilter.com/2023/08/10/youtube-shorts-comments-spam/)).
- Fijar comentarios figura entre las funciones avanzadas, que un canal nuevo
  obtiene con historial o verificando identidad (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/9890437?hl=en);
  conviene confirmar en la tabla de esa página qué nivel exige cada función,
  porque se leyó con una herramienta que resume).
- **Sin verificar**: que fijar un comentario mejore la recomendación. No hay
  declaración oficial. Sirve para orientar la conversación y para llevar al
  espectador al siguiente video.

### 1.11 Shorts de hasta 3 minutos

- Vigente para lo subido desde el 15 de octubre de 2024, en formato cuadrado o
  vertical (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/15424877?hl=en)).
- **Un Short de más de 1 minuto con cualquier reclamo de derechos activo queda
  bloqueado en todo el mundo**: no se reproduce ni se recomienda. La música de
  la biblioteca de Shorts se puede usar hasta 90 segundos en un Short de 3
  minutos (oficial, misma página y
  [ayuda de Content ID](https://support.google.com/youtube/answer/6013276?hl=en)).
  Para este formato, que dura de 90 a 160 s: solo música de la Biblioteca de
  audio de YouTube o con licencia clara, como ya dice `04`.
- **Sin verificar**: que los Shorts de 1 a 3 minutos se recomienden distinto de
  los más cortos. No hay declaración oficial. La medición de la parte 2 muestra
  que los líderes de este formato trabajan casi todos por encima de 2 minutos.

### 1.12 Búsqueda

- En enero de 2026 la búsqueda de YouTube agregó "Shorts" como opción del
  filtro de tipo (terceros,
  [Tubefilter](https://www.tubefilter.com/2026/01/09/youtube-search-filters-shorts-vs-long-form/);
  el anuncio oficial no se pudo abrir).
- Los hashtags y los títulos y descripciones traducidos alimentan la búsqueda
  (oficial, sección 1.7).
- **Sin verificar**: reglas de clasificación propias de la búsqueda de Shorts.
  En este formato la búsqueda es marginal: nadie busca "The Lantern". El valor
  de buscar está en la frase del formato ("in this town", "in this world") y en
  `roblox story`.

### 1.13 Qué cambia para un canal nuevo

- No hay historial: "When a new channel publishes for the first time, there
  are zero viewers who have that channel in their history. Does that mean that
  they're not appealing to any viewer? No" (oficial vía prensa, Todd Beaupré,
  2026, [OutlierKit](https://outlierkit.com/resources/how-youtube-recommends-new-channels/)).
  El sistema usa el tema del video y los gustos del espectador.
- "For new channels, gaining this credibility and building a community takes
  time" (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/16559651?hl=en)).
- **Sin verificar**: el "calentamiento" de cuentas nuevas y la "penalización de
  canal nuevo". Ninguna fuente oficial los confirma ni los niega con esas
  palabras.
- **Límites reales de un canal nuevo** (oficial,
  [funciones por nivel de acceso](https://support.google.com/youtube/answer/9890437?hl=en)):
  tope diario de subidas más bajo, y sin video relacionado, comentario fijado
  ni pistas de audio propias hasta activar las funciones avanzadas. **Verificar
  el canal con teléfono y luego con documento o video es la primera tarea de
  descubrimiento**, antes del primer Short.
- **Hype no aplica**: exige estar en el Programa de Socios y excluye los Shorts
  (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/15509925?hl=en)).

### 1.14 Portada del Short

- Desde el 24 de julio de 2026 se pueden subir **miniaturas personalizadas en
  Shorts**; el anuncio dice que empiezan los canales del Programa de Socios. En
  computador, Studio sugiere tres cuadros; en la aplicación del celular se puede
  elegir cualquier cuadro del video (oficial,
  [blog de YouTube](https://blog.youtube/news-and-events/youtube-studio-custom-thumbnail-updates/)).
- La miniatura personalizada de Shorts solo se carga desde Studio en computador
  y exige cuenta verificada; se recomienda 9:16 (oficial,
  [ayuda de YouTube](https://support.google.com/youtube/answer/72431?hl=en)).
- Para un canal fuera del programa, asume que solo hay selección de cuadro
  hasta ver la opción en Studio.

### 1.15 Originalidad, la regla nueva que más pesa

- El 1 de octubre de 2026 YouTube anunció: "we're updating our recommendation
  systems to further prioritize original content" y reducir el alcance de lo
  "re-uploaded from other creators without adding anything of your own"
  (oficial vía prensa,
  [Social Media Today](https://www.socialmediatoday.com/news/youtube-updates-shorts-algorithm-to-put-more-focus-on-original-content/831976/);
  la publicación oficial no se pudo abrir).
- Rene Ritchie precisó que no bastan una voz que describe lo que pasa en
  pantalla, ediciones técnicas menores ni cambios en serie hechos con plantilla
  (oficial vía prensa,
  [Search Engine Journal](https://www.searchenginejournal.com/youtube-original-shorts-reposted-clips-reach/591774/)).
- Va en la misma dirección que la política de contenido no auténtico
  ([ayuda oficial](https://support.google.com/youtube/answer/1311392?hl=en),
  detalle en `04`). Para este proyecto: guion propio, escenas propias y elenco
  recurrente; nunca recortar ni rehacer plano a plano el video de otro canal.

### 1.16 Folclor de creadores frente a lo que dice YouTube

| Creencia | Qué dice YouTube | Estado |
|---|---|---|
| "Hay que publicar a una hora exacta" | La hora no afecta el rendimiento a largo plazo. | Desmentido (oficial) |
| "La primera hora lo decide todo" | No hay desmentido literal. Lo más cercano: la hora no importa a largo plazo y el sistema sigue probando audiencias. | Sin confirmar |
| "Borrar los videos flojos limpia el canal" | No borres salvo por una razón muy buena. | Desmentido (oficial) |
| "Si no pegó, bórralo y súbelo otra vez" | No se aconseja; puede verse como spam. | Desaconsejado (oficial vía prensa) |
| "`#shorts` es obligatorio" | La clasificación depende del formato y la duración. | Innecesario (oficial) |
| "Las cuentas nuevas se calientan" | Nunca confirmado. El primer video se prueba por tema. | Sin confirmar |
| "Shadowban" | Ritchie atribuye la mayoría de los casos a bajo rendimiento normal ([TubeTalk, 16 de febrero de 2026](https://tubetalk.buzzsprout.com/271511/episodes/18630508-shadow-banning-inauthentic-content-and-dislikes-with-youtube-s-rene-ritchie)). | Sin desmentido formal |
| "Editar el título mata el alcance" | El cambio viene de la reacción de los espectadores, no de editar. | Desmentido (oficial) |
| "Más de 3 Shorts al día y te frenan" | No existe ese umbral. | Desmentido (oficial vía prensa) |
| "Hay que subir todos los días" | El crecimiento no se relaciona con el tiempo entre subidas. | Desmentido (oficial) |
| "Un video malo hunde el canal" | Cada video se evalúa por la respuesta que recibe. | Desmentido (oficial) |
| "Las etiquetas posicionan" | "Not important". | Desmentido (oficial) |
| "Los Shorts dañan los videos largos" | No hay evidencia de impacto negativo. | Desmentido (oficial) |
| "Un Short de más de 30 días está muerto" | Solo consta que el feed "puede" favorecer lo reciente. | Teoría de terceros |
| "Los videos monetizados se recomiendan más" | El sistema no sabe qué videos monetizan. | Desmentido (oficial) |

## Parte 2. Medición propia: qué hacen los canales líderes

### 2.1 Cómo se midió

- **Qué**: los 40 Shorts más recientes de 9 canales de
  `02-casos-de-exito.md`: 360 videos. Seis del formato en inglés (studby,
  GreenBroRants, VoidCast, Gelo Stories, R6Rants, FriendBob), dos en español
  (SoyGelo, Custerk Blox) y un formato vecino (Xenost).
- **Cuándo**: 13 de noviembre de 2026, entre las 14:41 y las 15:06 UTC.
- **Cómo**: `yt-dlp` sin descargar video. Script:
  `investigacion/medir_competencia.py` (órdenes `recoger` y `analizar`). Datos
  crudos: `investigacion/metadatos-competencia.csv` (360 filas, 30 columnas).
- **Videos maduros**: para comparar vistas solo se usan los videos con 48 horas
  o más de publicados (276 de 360), porque los más nuevos siguen sumando.
- **Índice**: vistas del video divididas por la mediana de vistas de los videos
  maduros de su mismo canal. Un índice de 2 significa "el doble de lo normal en
  ese canal". Permite juntar canales de tamaños distintos.
- **Muestra chica**: todo grupo con menos de 8 videos se marca y no se usa para
  concluir.

### 2.2 Resumen por canal

| Canal | Suscriptores | n | n maduros | Fechas de la muestra (UTC) | Mediana de vistas (maduros) | Mediana de duración | Videos por día |
|---|---|---|---|---|---|---|---|
| studby | 831 mil | 40 | 36 | 27 oct a 13 nov | 4.241.120 | 138 s | 2,4 |
| GreenBroRants | 1,40 millones | 40 | 31 | 5 a 13 nov | 3.581.817 | 142 s | 4,9 |
| VoidCast | 419 mil | 40 | 30 | 5 a 13 nov | 1.269.347 | 128 s | 5,0 |
| Gelo Stories | 764 mil | 40 | 30 | 6 a 13 nov | 120.748 | 128 s | 6,1 |
| R6Rants | 156 mil | 40 | 39 | 18 may a 12 nov | 468.842 | 33 s | 0,2 |
| FriendBob | 20,8 mil | 40 | 31 | 4 a 13 nov | 47.018 | 158 s | 4,3 |
| SoyGelo (es) | 4,49 millones | 40 | 27 | 6 a 13 nov | 2.748.194 | 126 s | 6,3 |
| Custerk Blox (es) | 1,37 millones | 40 | 28 | 6 a 13 nov | 5.332.875 | 126 s | 5,8 |
| Xenost (vecino) | 1,38 millones | 40 | 24 | 8 a 13 nov | 3.488.640 | 44 s | 8,0 |

Tres advertencias que afectan todo lo que sigue:

- **Las vistas son públicas, no "con interacción"** (sección 1.2). Sirven para
  comparar videos entre sí, no para calcular umbrales de monetización.
- **La muestra de R6Rants cubre seis meses y mezcla sus cuatro etapas** (ver
  `01-formato-de-referencia.md`); solo 9 de sus 40 videos son cuentos de 75 s o
  más. Las demás muestras cubren 5 a 17 días.
- La mediana reciente de Gelo Stories (120 mil) es mucho menor que la de todo
  su catálogo en `02` (513 mil): sus videos de la última semana rinden menos
  que los de octubre.

### 2.3 Títulos: longitud y forma

| Canal | n | Mediana de palabras | Mediana de caracteres | Título más largo | Con palabra en MAYÚSCULAS | Todo en mayúsculas | Con emoji | Con hashtag en el título |
|---|---|---|---|---|---|---|---|---|
| studby | 40 | 2 | 13 | 23 | 0 % | 0 % | 98 % | 0 % |
| GreenBroRants | 40 | 2 | 17 | 28 | 0 % | 0 % | 90 % | 0 % |
| VoidCast | 40 | 6 | 32 | 45 | 0 % | 0 % | 98 % | 0 % |
| Gelo Stories | 40 | 8 | 42 | 65 | 0 % | 0 % | 0 % | 0 % |
| R6Rants | 40 | 4 | 36 | 100 | 32 % | 2 % | 35 % | 45 % |
| FriendBob | 40 | 9 | 46 | 81 | 0 % | 0 % | 52 % | 2 % |
| SoyGelo (es) | 40 | 6 | 33 | 61 | 100 % | 100 % | 0 % | 0 % |
| Custerk Blox (es) | 40 | 4 | 20 | 27 | 100 % | 100 % | 100 % | 0 % |
| Xenost (vecino) | 40 | 8 | 37 | 59 | 100 % | 0 % | 0 % | 0 % |

Hay **dos familias de título** y cada canal se casa con una:

| Familia | Quién la usa | Forma | Ejemplos con su índice |
|---|---|---|---|
| A. El objeto | studby, GreenBroRants, R6Rants reciente | 1 a 3 palabras, mayúscula inicial en cada palabra, un emoji al final | "Kevin" (4,19), "Scan Day" (3,58), "The Lantern" (12,64) |
| B. La regla | VoidCast, Gelo Stories, FriendBob, SoyGelo, Custerk Blox | Una oración de 4 a 9 palabras que enuncia la regla | "Go Too Far, You Bounce Back To Mom" (6,11), "In This Town, Houses Grow If You Treat Them Well!!!" (7,84), "NO PIDAS MAS COMIDA" (3,51) |

Longitud frente a rendimiento:

| Palabras del título | n maduros (inglés, formato) | Mediana del índice | Con índice de 2 o más |
|---|---|---|---|
| 1 a 2 | 59 | 1,06 | 24 % |
| 3 a 4 | 38 | 0,87 | 21 % |
| 5 a 7 | 47 | 0,94 | 23 % |
| 8 a 10 | 35 | 1,30 | 46 % |
| 11 o más | 18 | 0,67 | 22 % |

En español (SoyGelo y Custerk Blox): 3 a 4 palabras, índice 1,09 (n = 32);
5 a 7, 0,96 (n = 14); 8 a 10, 0,96 (n = 9).

**Dentro de un mismo canal la longitud del título casi no se relaciona con las
vistas.** El cuartil superior de cada canal tiene la misma mediana de palabras
que el resto (2 y 2 en studby, 6 y 6 en VoidCast, 8 y 8 en Gelo Stories, 4 y 4
en Custerk Blox), y la correlación de Spearman entre palabras y vistas va de
-0,36 a 0,38 según el canal (n de 24 a 39), sin signo constante.

Lecturas:

- **La forma del título no es lo que separa un éxito de un video normal.** Los
  dos canales en inglés con mayor mediana usan títulos de 2 palabras, y el de
  mayor mediana de toda la muestra (Custerk Blox) usa 4. Lo que cambia entre un
  video de índice 4 y uno de 0,1 del mismo canal es la premisa, no la forma.
- **Los títulos de 11 palabras o más rinden menos** (0,67 con n = 18), pero
  todos son de R6Rants y FriendBob: puede ser el canal y no la longitud.
- **El pico de 8 a 10 palabras (1,30; 46 % con índice de 2 o más) lo producen
  los títulos "In This Town, ..." de los canales medianos y pequeños**, que se
  analizan en 2.4.

### 2.4 Mayúsculas, emoji y palabras iniciales

Mayúsculas y emoji:

| Grupo | n maduros | Mediana del índice | Con índice de 2 o más |
|---|---|---|---|
| Inglés, sin palabras en mayúsculas | 184 | 1,03 | 27 % |
| Inglés, con una palabra en MAYÚSCULAS | 12 | 0,79 | 33 % |
| Español, todo en mayúsculas | 55 | 1,00 | 24 % |
| Todos, con emoji | 144 | 0,96 | 20 % |
| Todos, sin emoji | 132 | 1,04 | 28 % |

- **En inglés los líderes no usan mayúsculas sostenidas**: 0 de 160 títulos de
  studby, GreenBroRants, VoidCast y Gelo Stories. Solo R6Rants las usa (32 %),
  y esos 12 videos no rinden más. Esto corrige la tabla de
  `05-guiones-y-fuentes.md`, que tomaba el estilo de R6Rants como patrón.
- **En español es al revés**: 80 de 80 títulos van completos en mayúsculas. Es
  una convención de idioma, no una palanca medible (no hay grupo de control).
- **El emoji es neutro**: tres líderes en inglés lo ponen al final en 90 a 98 %
  de los títulos, Gelo Stories y SoyGelo nunca, y el índice es casi igual.
- **Hashtags en el título**: solo R6Rants (45 %), y dos de sus tres peores
  videos los llevan. Es un solo canal: indicio, no prueba.

Palabras iniciales, canales en inglés del formato (240 títulos):

| Arranque | Veces | n maduros | Mediana del índice |
|---|---|---|---|
| "In this" | 44 | 40 | 2,31 |
| "The" | 24 | 18 | 0,87 |
| "Every" | 15 | 11 | 1,18 |
| "If" | 12 | 7 (muestra chica) | 0,95 |
| "Nobody" | 8 | 7 (muestra chica) | 1,67 |
| "My" | 7 | 6 (muestra chica) | 0,50 |
| "We" | 4 | 4 (muestra chica) | 1,99 |

"In this" frente al resto, dentro de cada canal que mezcla ambos:

| Canal | n con "In this" | Mediana del índice | n resto | Mediana del índice (resto) | Advertencia |
|---|---|---|---|---|---|
| Gelo Stories | 10 | 1,46 | 20 | 0,82 | Edades parecidas (5,8 y 4,5 días) |
| R6Rants | 9 | 1,75 | 30 | 0,89 | El resto incluye sketches viejos de otro formato |
| FriendBob | 21 | 2,69 | 10 | 0,68 | Sus "In this" son más viejos (6,6 días frente a 3,0) y en este canal la edad pesa mucho (Spearman 0,68) |
| Xenost | 4 (muestra chica) | 0,34 | 20 | 1,09 | Formato distinto; no concluye |

Lecturas:

- **En los canales medianos y pequeños, el título "In This Town/World, [regla]"
  rinde por encima de su propia mediana en los tres casos medibles.** La señal
  más limpia es Gelo Stories (1,46 frente a 0,82). No es prueba: son muestras de
  9 a 21 videos y en FriendBob está mezclada con la edad.
- **Los tres líderes en inglés (studby, GreenBroRants, VoidCast) no usan "In
  this" en ningún título de la muestra** (0 de 120). Ya tienen audiencia que
  reconoce el canal; el título corto les basta.
- "The" más sustantivo es el arranque más común de la familia A y rinde un poco
  bajo la mediana (0,87; n = 18). Los éxitos de studby no lo llevan ("Kevin",
  "Scan Day", "Bullet's Names").
- En español, "NO ..." abre 23 de 80 títulos (índice 0,92; n = 18) y "NADIE"
  9 (1,98, muestra chica).

### 2.5 Hashtags

| Canal | n | Hashtags por video | Usa `#shorts` | Cuáles |
|---|---|---|---|---|
| studby | 40 | 5 (siempre) | 100 % | `#shorts #roblox #entertainment #viral #relatable` |
| GreenBroRants | 40 | 0 | 0 % | ninguno |
| VoidCast | 40 | 0 | 0 % | ninguno |
| Gelo Stories | 40 | 3 (siempre) | 0 % | `#roblox #robloxshorts #sad` |
| R6Rants | 40 | 3 (de 2 a 12) | 35 % | `#roblox #entertainment #rblx`, a veces `#viral #shorts #relatable` |
| FriendBob | 40 | 5 (de 4 a 8) | 52 % | `#roblox #story #robloxstory #friendbob` y uno del tema |
| SoyGelo | 40 | 0 | 0 % | ninguno |
| Custerk Blox | 40 | 0 | 0 % | ninguno |
| Xenost | 40 | 0 | 0 % | ninguno |

| Número de hashtags | n maduros | Mediana del índice | Con índice de 2 o más |
|---|---|---|---|
| 0 | 140 | 1,00 | 21 % |
| 1 a 3 | 52 | 1,06 | 25 % |
| 4 a 5 | 66 | 1,09 | 30 % |
| 6 o más | 18 | 0,67 | 22 % |

- **Cinco de nueve canales no usan ningún hashtag**, entre ellos el de mayor
  mediana (Custerk Blox) y GreenBroRants. Los hashtags no son condición.
- **`#shorts` lo usa de forma constante un solo canal** (studby). Coincide con
  lo oficial: no hace falta.
- **Seis o más rinden menos** (0,67; n = 18), pero son videos de R6Rants y
  FriendBob: indicio.
- El único hashtag común a todos los que usan alguno es `#roblox`.

### 2.6 Descripción, etiquetas ocultas, categoría, idioma, doblaje y comentario fijado

| Canal | Descripción (mediana de caracteres) | Qué escriben | Etiquetas ocultas (mediana) | Categoría | Videos con doblaje automático | Idiomas doblados (mediana) | Comentario fijado |
|---|---|---|---|---|---|---|---|
| studby | 48 | Solo los 5 hashtags | 53 | Gaming | 95 % | 7 | 0 de 40 |
| GreenBroRants | 28 | Una frase que insinúa el giro: "He was never keeping us there" | 48 | Gaming | 90 % | 7 | 1 de 40 |
| VoidCast | 0 | Vacía | 0 | Entertainment | 98 % | 12 | 14 de 40 |
| Gelo Stories | 180 | Lista fija de palabras clave y 3 hashtags | 10 | Gaming | 100 % | 18 | 0 de 40 |
| R6Rants | 28 | Solo hashtags | 0 | People & Blogs | 0 % | 0 | 25 de 40 |
| FriendBob | 242 | Las dos primeras frases del cuento y hashtags | 0 | People & Blogs | 98 % | 7 | 0 de 40 |
| SoyGelo | 368 | Bloque fijo de redes sociales | 0 | Gaming | 100 % | 2 | 0 de 40 |
| Custerk Blox | 0 | Vacía | 0 | Gaming | 80 % | 1 | 0 de 40 |
| Xenost | 0 | Vacía | 0 | People & Blogs | 100 % | 7 | 0 de 40 |

Lecturas:

- **La descripción no es palanca**: tres canales de millones de vistas por
  video la dejan vacía. Lo único interesante es el uso de GreenBroRants, que la
  aprovecha para una frase de remate que solo entiende quien vio el video.
- **Las etiquetas ocultas tampoco**: studby y GreenBroRants cargan unas 50
  (casi idénticas entre los dos canales: `relatable`, `rant`, `roblox`,
  `robloxstory`, `school`...), y VoidCast, SoyGelo, Custerk Blox y Xenost,
  ninguna. Coincide con el "Not important" oficial.
- **Categoría**: Gaming en 5 canales, People & Blogs en 3, Entertainment en 1.
  Ninguno usa Film & Animation. No hay base para decir que una rinda más; se
  mantiene la recomendación de `07-canal-y-cuenta.md`.
- **El doblaje automático funciona en Shorts y lo tienen casi todos**: 8 de 9
  canales lo tienen en 80 a 100 % de sus videos. Las pistas más frecuentes en
  los 360 videos: español (299), portugués de Brasil (237), francés (227),
  indonesio (227), alemán (225), italiano (222) e hindi (217). Gelo Stories
  llega a 18 idiomas por video.
- **No se puede medir si el doblaje da más vistas**: el índice es 1,00 con
  doblaje (n = 232) y 0,97 sin él (n = 44), pero casi todos los videos sin
  doblaje son de un solo canal (R6Rants).
- **Ningún video de los 360 tiene subtítulos cargados a mano.** Todos dependen
  del texto quemado en la imagen y de los subtítulos automáticos.
- **Comentario fijado**: solo dos canales lo usan. R6Rants fija uno propio con
  una pregunta ("What secret would your parents reveal?", "Who would you swap
  with and why?"); VoidCast fija el de un espectador que lo pide. El índice es
  0,90 con fijado (n = 36) y 1,01 sin él (n = 240), y dentro de R6Rants 1,00
  frente a 0,96: **sin efecto medible**. El único fijado de GreenBroRants
  agradece a un espectador la idea de la historia, que es una práctica útil.
- "Idioma declarado": `yt-dlp` informa el idioma de la pista de audio original
  (`en-US` en casi todos, `es-US` en los de español), no el campo de Studio. No
  sirve para saber qué eligió cada canal en "Idioma del video".

### 2.7 Duración frente a vistas

| Duración | n maduros (inglés, formato) | Mediana del índice | Con índice de 2 o más |
|---|---|---|---|
| Hasta 59 s | 31 | 0,93 | 26 % |
| 60 a 89 s | 1 (muestra chica) | 0,74 | 0 % |
| 90 a 119 s | 5 (muestra chica) | 1,59 | 20 % |
| 120 a 149 s | 120 | 1,03 | 27 % |
| 150 a 185 s | 40 | 0,99 | 30 % |

| Canal | Mínima | Mediana | Máxima | Spearman duración y vistas (n) |
|---|---|---|---|---|
| studby | 94 s | 138 s | 175 s | -0,17 (36) |
| GreenBroRants | 120 s | 142 s | 179 s | 0,01 (31) |
| VoidCast | 120 s | 128 s | 131 s | 0,10 (30) |
| Gelo Stories | 116 s | 128 s | 135 s | 0,03 (30) |
| FriendBob | 141 s | 158 s | 171 s | -0,05 (31) |
| SoyGelo | 102 s | 126 s | 135 s | -0,15 (27) |
| Custerk Blox | 95 s | 126 s | 179 s | 0,27 (28) |

- **El formato hoy dura dos minutos largos**: en los 7 canales de cuentos, 280
  de 280 videos recientes pasan de 90 s (el más corto dura 94 s) y las medianas
  van de 126 a 158 s. VoidCast y Gelo Stories trabajan con un molde casi fijo
  (120 a 135 s).
- **Dentro de ese rango, más largo no es mejor**: ninguna correlación por canal
  pasa de 0,27 en valor absoluto, y los tramos de 120 a 149 s y de 150 a 185 s
  rinden igual (1,03 y 0,99).
- Los videos de menos de 60 s de la tabla son todos del R6Rants antiguo: no
  dicen nada sobre cuentos cortos hoy.
- FriendBob, el más pequeño, es el que hace los videos más largos (158 s). No
  hay señal de que alargar compense la falta de audiencia.

### 2.8 Día y hora de publicación

Franjas, canales en inglés del formato (240 videos):

| Franja UTC | Hora de Colombia | Publicados | Parte del total | n maduros | Mediana del índice |
|---|---|---|---|---|---|
| 00 a 02 h | 7 a 9 p. m. | 36 | 15 % | 28 | 0,66 |
| 03 a 05 h | 10 p. m. a 12 a. m. | 20 | 8 % | 16 | 1,13 |
| 06 a 08 h | 1 a 3 a. m. | 26 | 11 % | 23 | 1,10 |
| 09 a 11 h | 4 a 6 a. m. | 8 | 3 % | 7 (muestra chica) | 0,52 |
| 12 a 14 h | 7 a 9 a. m. | 42 | 18 % | 36 | 1,02 |
| 15 a 17 h | 10 a. m. a 12 m. | 41 | 17 % | 34 | 1,08 |
| 18 a 20 h | 1 a 3 p. m. | 37 | 15 % | 30 | 0,94 |
| 21 a 23 h | 4 a 6 p. m. | 30 | 12 % | 23 | 1,30 |

Hábito de cada canal:

| Canal | Patrón observado | Publicados en minuto 00, 15, 30 o 45 |
|---|---|---|
| studby | Repartido en 20 horas distintas del día | 65 % |
| GreenBroRants | Cada 4 horas: 00, 04, 08, 12, 16 y 20 h UTC | 62 % |
| VoidCast | Cada 4 horas, mismo esquema | 70 % |
| FriendBob | Cada 4 horas, mismo esquema | 82 % |
| Gelo Stories | Entre 15 y 04 h UTC (10 a. m. a 11 p. m. de Colombia), cada hora y media | 98 % |
| SoyGelo | Entre 15 y 01 h UTC (10 a. m. a 8 p. m. de Colombia), cada hora y media | 98 % |
| Custerk Blox | Cada 2 horas entre 14 y 02 h UTC (9 a. m. a 9 p. m. de Colombia) | 72 % |
| Xenost | Cada 3 horas exactas, las 24 horas | 98 % |
| R6Rants | Entre 12 y 22 h UTC (7 a. m. a 5 p. m. de Colombia), sin hora fija | 10 % |

Lecturas:

- **Los líderes no eligen "la mejor hora": llenan el día a intervalos fijos con
  videos programados.** Los tres grandes en inglés publican también de
  madrugada en Estados Unidos.
- **No hay una franja ganadora.** Las medianas van de 0,66 a 1,30 con 16 a 36
  videos por franja; en una distribución donde uno de cada cuatro videos
  duplica la mediana por la sola premisa, esas diferencias caben en el ruido.
  La franja más baja con muestra suficiente es la de 00 a 02 h UTC (0,66; n =
  28), que coincide con la noche en Estados Unidos: indicio débil.
- **Los canales en español sí concentran**: 79 de 80 videos entre las 15 y las
  02 h UTC, el día y la tarde de América Latina.
- **Día de la semana: no se puede concluir nada.** Las muestras cubren 8 o 9
  días seguidos, así que cada día de la semana es una o dos fechas. El "jueves"
  aparece con índice 1,96 solo porque casi todos sus videos maduros son del 5
  de noviembre, los más viejos de la muestra. Los líderes publican los siete
  días.

### 2.9 Cadencia

| Canal | Mediana de horas entre videos | Mínimo | Mediana de videos por día completo | Máximo en un día |
|---|---|---|---|---|
| studby | 5,0 | 2,8 | 2,5 | 6 |
| GreenBroRants | 4,0 | 2,1 | 5 | 7 |
| VoidCast | 4,2 | 3,0 | 5 | 6 |
| Gelo Stories | 1,5 | 1,5 | 5,5 | 8 |
| FriendBob | 4,0 | 3,8 | 4,5 | 6 |
| SoyGelo | 1,5 | 0,3 | 6 | 6 |
| Custerk Blox | 2,0 | 1,6 | 6 | 6 |
| Xenost | 3,0 | 2,9 | 8 | 8 |
| R6Rants | 68,7 | 22,0 | 1 | 1 |

- **Todos los canales grandes publican de 2,5 a 8 videos por día.** El único
  que publica uno cada tres días es el más pequeño de los medianos.
- **Publicar mucho no basta**: FriendBob publica 4,5 al día con el mismo
  esquema horario de GreenBroRants y tiene una mediana 76 veces menor (47 mil
  frente a 3,58 millones). La cadencia es condición de los líderes, no causa
  suficiente.
- Los líderes en inglés separan sus videos 4 a 5 horas; los de español, hora y
  media a dos horas, con medianas de vistas igual de altas. No hay señal de que
  publicar seguido se "coma" las vistas en canales con audiencia.

### 2.10 Me gusta

| Canal | n maduros | Me gusta por cada 100 vistas (mediana) | Spearman entre tasa y vistas |
|---|---|---|---|
| studby | 36 | 3,05 | -0,52 |
| GreenBroRants | 31 | 2,41 | -0,28 |
| VoidCast | 30 | 2,12 | 0,00 |
| Gelo Stories | 30 | 3,23 | -0,45 |
| R6Rants | 39 | 1,73 | -0,15 |
| FriendBob | 31 | 3,35 | -0,11 |
| SoyGelo | 27 | 2,91 | -0,08 |
| Custerk Blox | 28 | 2,62 | -0,21 |
| Xenost | 24 | 1,92 | -0,63 |

- Referencia para el canal propio: **1,7 a 3,4 me gusta por cada 100 vistas
  públicas** en este formato.
- La tasa **baja** cuando el video llega a más gente (correlación negativa en 8
  de 9 canales). Un video con tasa alta y pocas vistas no es "mejor": llegó
  solo a los fieles. No uses la tasa de me gusta para predecir alcance.

### 2.11 Limitaciones de la medición

- **Una sola captura** (13 de noviembre). No hay curva de vistas por hora, así
  que no se puede decir cuánto tarda un video en despegar ni si YouTube lo
  vuelve a empujar.
- **Ventanas cortas** (5 a 17 días, salvo R6Rants). Nada sobre día de la semana
  ni estacionalidad.
- **Efecto de la edad**: aun entre videos maduros, los más viejos tienden a
  tener más vistas (Spearman entre edad y vistas de 0,12 a 0,39 en los líderes
  y 0,68 en FriendBob). El índice no lo corrige.
- **Todo es correlación.** No hay experimento: los canales no asignan títulos u
  horas al azar. Y son 9 canales, no 9 pruebas independientes: los videos de un
  mismo canal se parecen entre sí.
- **Sesgo de supervivencia**: se midieron ganadores. Lo que comparten puede
  compartirlo también la multitud de canales que no despegó (FriendBob lo
  muestra: mismas prácticas, 76 veces menos vistas).
- **Vistas públicas**, no vistas con interacción, y sin retención, porcentaje
  de "vieron frente a deslizaron", compartidos ni suscripciones ganadas, que
  solo se ven en el Analytics de cada dueño.
- **Comentario fijado**: se leyó solo el primer comentario en orden
  "destacados". Si un canal fija y después quita, no se ve.
- **No se midió la primera frase hablada** de cada video (habría exigido bajar
  los subtítulos de 360 videos). Las reglas de primera frase de la parte 3 se
  apoyan en los títulos de la familia B, que son la regla enunciada, y en el
  análisis de `01-formato-de-referencia.md`.
- **Portadas y series**: no se midieron.

## Parte 3. Entregables

### 3.1 Plantilla de metadatos por video

Copia el bloque a un archivo `guiones/NNN-titulo.meta.txt` y llénalo antes de
subir. Lo que va entre corchetes se reemplaza; el texto que va a YouTube está
en inglés.

```text
VIDEO NNN
Internal name: [NNN-short-slug]
Scheduled: [YYYY-MM-DD] 15:00 Bogota (20:00 UTC)

TITLE (max 45 characters, Title Case, no hashtags, no ALL CAPS)
In This Town, [Rule In 4 To 7 Words]

ALT TITLE 1 (the object, 1 to 3 words)
[The Object]

ALT TITLE 2 (the rule without the opener)
[Subject] [Verb] [Consequence]

DESCRIPTION (1 or 2 sentences, then credits, then hashtags)
[One sentence that states the rule in plain words.] [One sentence that hints at the twist without spoiling it.]
Original story, written and animated by [Channel Name]. Not affiliated with Roblox Corporation.
#roblox #robloxstory #[onewordtheme]

HASHTAGS (already in the description; 3 at most; no #shorts needed)
#roblox #robloxstory #[onewordtheme]

PINNED COMMENT (needs advanced features; a question the story raises)
[What would YOUR rule be? / Who is the first person you would ...?]

PLAYLIST
[In This Town: Friendship | Love | Family | School | Spooky | Funny]

SERIES (only if the Shorts series feature is available)
[In This Town, Season 1, Episode NN]

COVER FRAME
Timecode: [mm:ss.d]
What is in it: [character face + the rule visible, no subtitle on top]

RELATED VIDEO
[URL of the long video of this family, or of the best Short of the same playlist]

AUDIENCE: No, it's not made for kids
VIDEO LANGUAGE: English (United States)
CATEGORY: [channel default]
ALTERED CONTENT: [per docs/07, section 3.3]

CHECK BEFORE PUBLISHING
[ ] Copyright check finished with no claims
[ ] Title has no hashtag and no word in ALL CAPS
[ ] First spoken sentence is the rule and matches the title
[ ] Cover frame chosen in the mobile app
[ ] Added to playlist; related video set
```

Ejemplo lleno, con el guion piloto:

```text
VIDEO 001
Internal name: 001-friendships-have-a-battery
Scheduled: 2026-12-08 15:00 Bogota (20:00 UTC)

TITLE
In This Town, Friendships Have a Battery

ALT TITLE 1
The Battery

ALT TITLE 2
Every Friendship Runs on a Battery

DESCRIPTION
In this town, every friendship has a battery you can see. Ours was at 2%.
Original story, written and animated by [Channel Name]. Not affiliated with Roblox Corporation.
#roblox #robloxstory #friendship

PINNED COMMENT
Which friendship of yours is at 2% right now?

PLAYLIST
In This Town: Friendship

COVER FRAME
What is in it: both friends, the battery between them in red at 2%

RELATED VIDEO
[best Short of the Friendship playlist until the first long video exists]
```

Notas sobre la plantilla:

- El título principal del ejemplo tiene 40 caracteres. Las frases de la
  descripción son ilustrativas: ajústalas al guion final.
- Los dos títulos alternos no son para cambiarlos a las dos horas: son para
  usar en TikTok e Instagram y para la revisión de las 48 horas (sección 3.4).
- La línea de crédito y la de no afiliación vienen de la plantilla de
  `07-canal-y-cuenta.md` (sección 2.5).
- El 8 de diciembre de 2026 es el primer martes de la fase 2 de `06`.

### 3.2 Reglas de título y de primera frase

Cada regla dice en qué dato se apoya. "Medido" remite a la parte 2.

| # | Regla de título | Sustento |
|---|---|---|
| 1 | **Mientras el canal sea pequeño, usa la familia B: "In This Town, [regla]"**, de 5 a 9 palabras y 45 caracteres como máximo. | Medido: en los tres canales medianos y pequeños que mezclan, "In this" rinde sobre su mediana (1,46 frente a 0,82; 1,75 frente a 0,89; 2,69 frente a 0,68, este último mezclado con la edad). Oficial vía prensa: sin historial, el sistema se guía por lo que entiende del tema del video. Es hipótesis de trabajo, no ley. |
| 2 | **Uno de cada tres videos, prueba la familia A**: el objeto de la historia en 1 a 3 palabras, sin "The" si se puede. | Medido: es la forma de los dos líderes en inglés (medianas de 2 palabras y de 13 y 17 caracteres). "The" más sustantivo rinde 0,87 (n = 18). Así el canal mide con sus propios datos cuál familia le sirve. |
| 3 | **Nunca más de 10 palabras.** | Medido: 11 o más palabras, índice 0,67 (n = 18; dos canales). |
| 4 | **Mayúscula inicial en cada palabra; ninguna palabra en mayúsculas sostenidas** (en inglés). | Medido: 0 de 160 títulos de los cuatro líderes en inglés las usan; los 12 que las llevan rinden 0,79. |
| 5 | **Sin hashtags en el título.** | Medido: solo R6Rants los pone, y están en dos de sus tres peores videos (indicio de un canal). |
| 6 | **Un emoji al final es opcional.** Si se usa, uno solo y que sea el objeto de la regla. | Medido: neutro (0,96 con, 1,04 sin). |
| 7 | **El título promete la regla, no el giro.** Nada de "... Then I Found Out Why". | Anecdótico: el peor video de FriendBob (índice 0,19) tiene ese molde de dos cláusulas. Criterio propio. |
| 8 | **Sin "Part 2" en el título.** La continuidad va en la lista y en el video relacionado. | Medido: 0 de 320 títulos de los 8 canales de cuentos numeran partes. Solo Xenost, de otro formato, lo hace (9 de 40). |
| 9 | **Si el canal abre versión en español: todo en mayúsculas, 3 a 6 palabras, prohibición o cuantificador** ("NO...", "NADIE..."). | Medido: 80 de 80 títulos en mayúsculas; medianas de 4 y 6 palabras. |

Reglas de primera frase. Aquí el sustento medido es indirecto: los títulos de
la familia B son la regla enunciada, pero no se transcribieron los audios.

| # | Regla de primera frase | Sustento |
|---|---|---|
| 1 | **La primera frase es la regla completa, en 4 segundos o menos, y se entiende sin contexto.** | Análisis del video de referencia (`01`) y forma de los 5 canales de la familia B. |
| 2 | **Título y primera frase dicen lo mismo.** Si el título es "In This Town, Friendships Have a Battery", la voz arranca con esa misma idea. | Criterio propio: quien llega desde la búsqueda o desde el canal confirma en un segundo que es lo que tocó. |
| 3 | **Arranca con un marco universal**: "In this town", "Nobody", "Every", "If you", "We". Evita arrancar con "My" o "I". | Medido en títulos: "In this" 2,31 (n = 40), "Every" 1,18 (n = 11), "Nobody" 1,67 (n = 7, muestra chica), "My" 0,50 (n = 6, muestra chica). |
| 4 | **La regla es una prohibición, un costo o un intercambio**, no una descripción. | Medido en títulos: entre los de mayor índice están "Nobody Can Touch the Water", "Cookies Are Money", "NO PIDAS MAS COMIDA", "CADA ESCALÓN CUESTA", "Houses Grow If You Treat Them Well". |
| 5 | **La regla se ve en el primer plano**, antes de que termine la frase. | `02-casos-de-exito.md` ("la regla se ve"). No medido aquí. |
| 6 | **Sin saludo, sin logo, sin "wait for the end".** | Oficial: lo que cuenta para ingresos y umbrales es que el espectador elija seguir viendo (vistas con interacción). |

### 3.3 Calendario de publicación

| Fase del plan (`06`) | Videos por semana | Días | Hora de Colombia | UTC |
|---|---|---|---|---|
| Fase 2, inicio | 3 | Martes, jueves y sábado | 3:00 p. m. | 20:00 |
| Fase 2, final | 5 | Martes a sábado | 3:00 p. m. | 20:00 |
| Fase 3 | 7 | Todos los días | 3:00 p. m. | 20:00 |
| Cuando haya dos videos en un día | 14 | Todos los días | 7:00 a. m. y 3:00 p. m. | 12:00 y 20:00 |

Por qué así:

- **La hora no decide el resultado** (oficial, sección 1.5) y la medición no
  encontró franja ganadora (sección 2.8). Por eso se fija una sola hora y no se
  gasta energía en optimizarla.
- **3:00 p. m. de Colombia** es la que ya propone `07-canal-y-cuenta.md`: salida
  del colegio en la costa este de Estados Unidos y mediodía en la oeste. Cae en
  la franja de 18 a 20 h UTC (índice 0,94; n = 30), ni mejor ni peor que las
  demás, y lejos de la única franja con indicio negativo (00 a 02 h UTC). El
  argumento de la salida del colegio es criterio propio, **sin verificar**.
- **Dos al día, con 8 horas entre uno y otro**: 12:00 y 20:00 UTC son dos de
  las seis horas del esquema de GreenBroRants y VoidCast, y los líderes en
  inglés separan sus videos al menos 4 horas (medido).
- **Los días**: no hay dato que favorezca ninguno (sección 2.8). Se reparten
  parejo y se incluye el sábado porque el público es escolar (criterio propio).
- **Siempre programado, nunca a mano**: 62 a 98 % de los videos de los líderes
  salen en minuto exacto, señal de que programan (medido). Programar permite
  subir el lote de la semana de una sola vez.
- Desde el 14 de marzo de 2027 Estados Unidos entra en horario de verano y las
  3:00 p. m. de Colombia pasan a ser las 4:00 p. m. del este. No hace falta
  mover nada.
- **No pruebes horas en los primeros 30 videos.** Con la dispersión medida (uno
  de cada cuatro videos duplica la mediana solo por la premisa), harían falta
  decenas de videos por franja para ver una diferencia real.

Sobre la cadencia: la de los líderes (2,5 a 8 al día) está fuera del alcance de
una sola persona al comienzo. YouTube dice que el intervalo entre subidas no se
relaciona con el crecimiento y que rinde más hacer menos videos y mejores
(sección 1.4), así que tres buenos por semana es un arranque defendible. Pero
la medición es clara en que ningún canal grande del formato publica menos de
dos al día: la meta de un video diario de `06` es el piso, no el techo.

### 3.4 Las primeras 2 horas (y las primeras 48)

Qué hacer:

| Cuándo | Acción | Por qué |
|---|---|---|
| Antes de la hora | Programar con todo listo: título, descripción, lista, cuadro de portada, video relacionado. Revisión de derechos terminada. | Un reclamo en un Short de más de 1 minuto lo bloquea (oficial). |
| Minuto 0 a 10 | Abrir el Short en el celular, sin la sesión del canal: que se vea como Short, con audio, subtítulos legibles y la portada correcta. | Los errores de subida se corrigen sin borrar. |
| Minuto 0 a 10 | Publicar y fijar el comentario con la pregunta (si ya hay funciones avanzadas). | Orienta la conversación. Sin efecto medido en alcance (sección 2.6). |
| Primera hora | Responder los primeros comentarios con una frase, no solo con el corazón. Anotar las reglas que proponga la gente: son premisas gratis. | Criterio propio. GreenBroRants agradece en un comentario fijado al espectador que dio la idea. |
| Hora 1 a 2 | Subir el mismo archivo a TikTok e Instagram (sección 3.6). | Alcance adicional sin tocar el Short. |
| Hora 2 | Anotar en la bitácora vistas, vistas con interacción y porcentaje que vio en vez de deslizar. Solo anotar. | Para construir la curva propia que esta investigación no pudo medir. |
| Hora 48 | Comparar con la mediana del canal: vistas con interacción, porcentaje visto, porcentaje que no deslizó. Decidir si la premisa merece una secuela. | 48 horas es el corte de "video maduro" usado en la parte 2. |

Qué no hacer:

| No hagas | Por qué |
|---|---|
| Borrar y resubir porque "no arrancó" | Desaconsejado por YouTube; puede verse como spam (sección 1.6). |
| Pasarlo a privado o no listado "para reiniciarlo" | No hay ningún mecanismo de reinicio documentado; solo se pierde tiempo de exposición. |
| Cambiar el título o la portada en las primeras 48 horas | "Don't change what's working", y a las 2 horas no sabes si funciona. La excepción es un error (una errata, un cuadro negro). |
| Pedir a conocidos que lo vean en bucle, intercambiar suscripciones o comprar vistas | Viola la [política de participación falsa](https://support.google.com/youtube/answer/3399767?hl=en) (oficial) y enseña al sistema una audiencia que no es la tuya. |
| Compartir el enlace en grupos que no son el público del formato | Criterio propio, apoyado en la idea oficial de audiencia semilla: si los primeros espectadores deslizan, el sistema aprende que el video no gusta. **Sin verificar**. |
| Publicar otro video encima para "tapar" uno flojo | Un video flojo no hunde el canal (oficial). Mantén el calendario. |
| Mirar el contador cada diez minutos y sacar conclusiones | No hay dato oficial ni medido de que la primera hora decida. |
| Poner enlaces en la descripción o en los comentarios | No son clicables en Shorts (oficial). El único enlace útil es el video relacionado. |

### 3.5 Series, listas y el paso a videos largos

Por qué importa: las horas de Shorts vistas en el feed de Shorts no cuentan
para la ruta de horas del Programa de Socios
([ayuda oficial](https://support.google.com/youtube/answer/72851?hl=en); ver
`04`). Los videos largos son la única forma de sumarlas, y los Shorts son la
única fuente de audiencia para esos videos largos.

**Series y universo**

- Un solo pueblo con nombre y un elenco de 4 a 6 personajes recurrentes (ya
  está en `06` como diferenciador). Cada Short es una regla nueva en el mismo
  pueblo.
- Cuando un video pase de índice 2 en el canal propio, hacer en la misma semana
  una segunda historia con el mismo personaje o la misma regla. Es la regla de
  `06` ("si un video pega fuerte, dos más de la misma familia"), con un umbral
  concreto.
- Numerar solo hacia adentro (regla 8 de título).
- Si la función de series de Shorts aparece en Studio, usarla con una temporada
  por tema. **Sin verificar** si está disponible para canales nuevos.

**Listas de reproducción**

- Una por tema, en inglés, con el nombre del universo adelante: "In This Town:
  Friendship", "In This Town: Family", "In This Town: Spooky". Coincide con las
  secciones de `07-canal-y-cuenta.md`.
- Una lista "Start Here" con los 5 mejores Shorts, que se rehace en la revisión
  mensual.
- Una lista "Full Stories" para los videos largos, primera sección del canal
  cuando exista.
- Cada Short entra a su lista al subirlo. Las listas solo de Shorts no se
  pueden reordenar (oficial): el orden es el de entrada.

**De Shorts a videos largos**

| Paso | Qué hacer | Sustento |
|---|---|---|
| 1 | Grabar cada escena pensando en los dos formatos: el mismo plano encuadrado en 9:16 y en 16:9, o un encuadre que aguante el recorte. | Un video vertical de menos de 3 minutos se clasifica como Short (oficial), y uno vertical más largo se ve mal en televisor. Criterio de producción. |
| 2 | Primer video largo en febrero (`06`): antología de 4 a 5 historias del mismo tema, de 8 a 12 minutos, con una historia marco y escenas puente nuevas. | Una simple unión de Shorts ya publicados arriesga la política de contenido no auténtico y la regla de originalidad de octubre de 2026 (sección 1.15 y `04`). |
| 3 | Título con la regla más fuerte y la promesa de conjunto: "In This Town, Friendships Have a Battery (and 4 More Rules)". Miniatura según `05`. | En videos largos sí manda el clic. |
| 4 | Poner ese video largo como **video relacionado** en todos los Shorts que lo componen, empezando por los de más vistas. | Es el único enlace clicable de un Short (oficial). Exige funciones avanzadas. |
| 5 | Fijar en esos Shorts un comentario que diga dónde sigue la historia, sin URL: "The full story is on our channel: [title]". | Los enlaces en comentarios de Shorts no son clicables (oficial). |
| 6 | Desde ahí, un video largo cada dos semanas (`06`), siempre con material nuevo: finales extendidos, la historia desde el otro personaje, lo que pasó después. | Los líderes lo hacen: SoyGelo tiene 149 videos largos y Custerk Blox 13 compilados con 11,2 millones de vistas (`02`). |
| 7 | Medir en Analytics cuántas vistas del video largo llegan desde el feed de Shorts y desde el video relacionado, y qué Shorts las traen. | Dato propio para decidir qué temas merecen antología. |

La cuenta de horas, con los supuestos de `04`: 8.000 horas son 480.000 minutos.
Un video largo de 10 minutos con 4 minutos vistos en promedio necesita 120.000
vistas para lograrlo solo; doce videos así necesitan 10.000 vistas cada uno. No
hay dato medido de qué fracción de los espectadores de un Short pasa al video
relacionado: **sin verificar**, y es la primera cifra que hay que anotar cuando
exista el primer video largo.

### 3.6 Publicación cruzada en TikTok e Instagram Reels

**Conviene, solo por alcance y con el archivo maestro limpio.** No es fuente de
ingreso desde Colombia (`04`, sin verificar en las aplicaciones).

Lo que dicen las plataformas:

| Plataforma | Regla | Estado |
|---|---|---|
| YouTube | No se encontró ninguna declaración vigente contra publicar tu propio video en otras plataformas. Lo que se castiga es resubir contenido de otros "without adding anything of your own", y el contenido no original no cuenta para ingresos. | Oficial ([política de spam](https://support.google.com/youtube/answer/2801973?hl=en), [monetización de Shorts](https://support.google.com/youtube/answer/12504220?hl=en)). Sobre marcas de agua de otras aplicaciones: sin verificar. |
| Instagram | "We aim to make certain reels less visible for other reasons, such as low-resolution or watermarked reels". Las cuentas que publican sobre todo contenido no original pierden recomendación a quienes no las siguen. | Oficial ([Mosseri, 31 de mayo de 2023](https://about.instagram.com/blog/announcements/instagram-ranking-explained), [pautas de contenido original](https://creators.instagram.com/original-content-guidelines/)) |
| TikTok | "Content is also ineligible for the FYF if it includes unoriginal or reused material without anything new". | Oficial ([normas de la comunidad](https://www.tiktok.com/community-guidelines/en/integrity-authenticity), vigentes desde el 24 de septiembre de 2026). La mención expresa a marcas de agua ajenas no se pudo abrir: sin verificar. |

Ajustes:

1. **Subir siempre el archivo exportado del montaje**, nunca uno descargado de
   YouTube, TikTok o Instagram. Así no hay marca de agua de nadie.
2. **Sin logos ni menciones de plataforma dentro del video** ("subscribe",
   flechas al botón de YouTube). El cierre del guion ya prohíbe despedidas.
3. **Zonas seguras**: subtítulos en el tercio superior, como en el formato de
   referencia. Las tres aplicaciones tapan la parte baja y el borde derecho con
   botones y texto; revisa el primer video en las tres antes de fijar la
   plantilla de montaje.
4. **Duración**: **sin verificar** el límite vigente de Reels y de TikTok para
   cuentas nuevas. Si alguna recorta un cuento de 120 a 150 s, esa plataforma
   queda fuera: no se publica un cuento sin final.
5. **Texto propio por plataforma**: en TikTok e Instagram el título va en el
   pie del video; usa uno de los títulos alternos y los hashtags de allá. No
   copies la descripción de YouTube.
6. **YouTube primero, las otras una o dos horas después.** Criterio propio:
   deja constancia de dónde nació el video. **Sin verificar** que el orden
   afecte la recomendación en alguna plataforma.
7. **Una firma propia y discreta en el cuadro** (el nombre del canal en letra
   pequeña, fijo, lejos de los subtítulos). No es una marca de agua de
   plataforma, y ayuda cuando otros resuban el video. Criterio propio.

Riesgos:

| Riesgo | Qué tan probable | Qué hacer |
|---|---|---|
| Que otra cuenta baje el video de TikTok y lo suba a YouTube Shorts | Alto en este formato: la competencia crece cada semana (`02`) | Publicar primero en YouTube; firma en el cuadro; reportar por derechos de autor con el archivo de Studio como prueba (la bitácora de `06`). |
| Que Instagram o TikTok traten la cuenta como agregador | Bajo si todo es original y sin marcas de agua | Ajuste 1. |
| Que atender tres plataformas le quite horas a la producción | Alto con una sola persona | Subir y nada más: sin responder comentarios fuera de YouTube hasta la fase 3. |
| Que la audiencia de TikTok no pase a YouTube | Sin dato | No medir TikTok por suscriptores de YouTube. Revisarlo en la revisión mensual y cortar si no aporta. |

## Qué cambia frente a los otros documentos

No se modificó ningún otro archivo; estas son las diferencias a tener en
cuenta.

| Documento | Qué decía | Qué muestra este |
|---|---|---|
| `04-monetizacion-y-politicas.md`, "Idioma" | "No se pudo confirmar que [el doblaje automático] funcione en Shorts." | Funciona: 8 de 9 canales lo tienen en 80 a 100 % de sus Shorts (sección 2.6). El canal en inglés puede recibir pista automática en español; eso no reemplaza un canal propio en español con títulos y guion localizados, que es lo que hacen SoyGelo y Custerk Blox. |
| `05-guiones-y-fuentes.md`, "Títulos y miniaturas" | Patrón en inglés: "la regla completa, con una palabra en mayúsculas". | Ese es el estilo de R6Rants. Los líderes en inglés no usan mayúsculas sostenidas (sección 2.4). |
| `05-guiones-y-fuentes.md`, "Títulos y miniaturas" | "2 a 6 palabras, sin etiquetas". | Vale para studby y GreenBroRants. VoidCast, Gelo Stories y FriendBob usan 6 a 9 palabras, y para un canal pequeño "In This Town, ..." es la mejor apuesta inicial (sección 3.2). |
| `07-canal-y-cuenta.md`, 3.4 | La portada personalizada de Shorts se trata "como no disponible". | Desde el 24 de julio de 2026 existe, desde Studio en computador, empezando por canales del Programa de Socios (sección 1.14). Para un canal nuevo, elegir el cuadro en el celular sigue siendo lo correcto. |
| `07-canal-y-cuenta.md`, 2.5 | Plantilla con `#shorts #robloxstory #animation`. | `#shorts` no hace falta (oficial) y solo lo usa de forma constante 1 de 9 canales. Se propone `#roblox #robloxstory` y uno del tema. |
| `06-plan-de-accion.md`, cadencia | "Llegar a un video diario". | Ningún canal grande del formato publica menos de 2,5 al día (sección 2.9). Uno diario es el piso. |

## Lo que quedó sin verificar

- El peso real de cada señal (deslizadas, repeticiones, compartidos,
  comentarios, suscripciones) en la recomendación de Shorts.
- Si YouTube vuelve a empujar un Short en momentos fijos, y el supuesto límite
  de 30 días.
- Si los Shorts de 1 a 3 minutos se recomiendan distinto de los más cortos.
- Si un canal nuevo y sin verificar recibe doblaje automático desde el primer
  video, y si tiene acceso a las series de Shorts.
- Qué nivel de acceso exige hoy fijar comentarios (confirmar en la tabla
  oficial).
- Las citas marcadas "oficial vía prensa": no se abrieron los videos de Creator
  Insider ni las publicaciones del foro de ayuda; se tomaron de medios que las
  transcriben.
- Cuántos espectadores pasan de un Short a su video relacionado.
- Los límites de duración de Reels y TikTok, y la regla de marcas de agua de
  TikTok.
