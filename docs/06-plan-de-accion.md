# 06. Plan de acción

Plan para pasar de cero a un canal monetizado. Las fechas parten del 12 de
noviembre de 2026. Los plazos y metas son estimaciones propias, no garantías.

## La estrategia en cinco decisiones

| Decisión | Recomendación | Por qué |
|---|---|---|
| Formato | Micro-ficción de "una regla fantástica" con personajes de bloques, de 90 a 160 segundos | Es el formato de la ola actual; los líderes pasaron de 30 a 60 s a más de dos minutos. |
| Idioma | Empezar en inglés; abrir el canal en español en la fase 3 con las mismas escenas | El inglés paga de 5 a 10 veces más por vista; el español tiene menos competencia y los líderes ya trabajan con un canal por idioma. Si vas a narrar con tu voz, invertir el orden. |
| Cadencia | Llegar a un video diario | Los líderes publican de 3 a 8 al día; el canal de referencia, con uno cada 1 a 3 días, es el más pequeño del grupo. |
| Velocidad | Arrancar ya | La ola empezó a mediados de octubre y los tutoriales de "hazlo con Claude" salieron en noviembre: cada semana hay más competencia. |
| Modelo de ingresos | Shorts para crecer, videos largos para cobrar | Desde febrero de 2027 los Shorts solos exigen 20 millones de vistas en 90 días; un video largo rinde unas 10 veces más por vista. |
| Producción | Claude dirige (guion, lista de planos, escenas por MCP, montaje por comandos) y tú revisas y grabas | Es lo que hace viable publicar varias veces por semana siendo una sola persona. |
| Diferenciador | Universo propio (un pueblo y un elenco recurrentes), finales variados y una línea de leyendas latinoamericanas | Protege frente a la política de contenido no auténtico y frente a los imitadores. |

## Fase 0. Preparación (semana del 16 de noviembre)

Meta: tener todo instalado y las cuentas listas. El 13 de noviembre quedó
armado el kit completo; lo que sigue son los pasos que dependen de ti.

Ya hecho:

- [x] Definir el primer equipo: el equipo de casa (en el de trabajo
      Studio no abre; detalle en `03`).
- [x] 25 guiones, herramientas de posproducción probadas, biblioteca de
      Studio, identidad del canal y guías (`README.md`, "El kit de
      producción").
- [x] Leer las pautas de nombre y logo de Roblox. Resultado: el plan usa un
      elenco de personajes propio (`04`, "Derechos de Roblox").

Se puede hacer ya, sin el equipo de casa:

- [ ] Crear la cuenta de Google del canal y el canal, siguiendo
      `07-canal-y-cuenta.md` de principio a fin. Nombre recomendado:
      Almostville (`canal/nombres.md`). Audiencia: "No, no es contenido hecho
      para niños".
- [ ] Pedir desde el primer día el acceso a **funciones avanzadas**
      (verificación con documento o video): sin eso no hay video relacionado
      en Shorts, ni comentarios fijados, ni solicitud de monetización (`07`).
- [ ] Activar la verificación en dos pasos de la cuenta.
- [ ] Decidir la voz con `09-audio-voz-musica-efectos.md`: propia (gratis y
      la más segura) o ElevenLabs (Starter para el piloto, Creator para
      publicar a diario). No usar las voces predeterminadas de ElevenLabs:
      expiran el 31 de diciembre de 2026.
- [ ] Elegir de 5 a 8 pistas de música de la lista de `09` y descargarlas a
      `audio/musica/` con su registro de licencia.
- [ ] Darle una pasada al gancho y al remate de los primeros 5 guiones del
      orden de producción (`guiones/INDICE.md`).

En el equipo de casa:

- [ ] Copiar el proyecto y correr `preparar-equipo.ps1`.
- [ ] Crear o usar una cuenta de Roblox, iniciar sesión en Studio y activar
      el servidor MCP.
- [ ] Seguir `10-produccion-en-paralelo.md`, sección "Primer día en el
      equipo de casa".

## Fase 1. Piloto técnico (del 23 de noviembre al 6 de diciembre)

Meta: producir **un video completo** con el guion
`guiones/001-friendships-have-a-battery.md` y medir cuánto tarda cada paso. El
piloto no es para publicar con prisa: es para saber si el flujo funciona.

Hay dos rutas de producción (detalle en `03-produccion-y-herramientas.md`): la
A, con Roblox Studio y el MCP, y la B, todo en código sin Studio. El kit está
armado para la A. La B queda como respaldo si el piloto la descarta.

El paso a paso del piloto está en `10-produccion-en-paralelo.md`, pasos A y B.
Qué se valida, en orden:

0. Conexión: Claude pone un bloque rojo en el centro del mapa y toma una
   captura.
1. La biblioteca de `studio/` carga y crea un personaje del elenco propio,
   con poses y caras.
2. Un escenario en versión gris y en versión detallada, con luz.
3. El script director reproduce los primeros 8 planos con cámara y caras
   sincronizadas a los tiempos de `planos.json`.
4. La grabación queda vertical a buena resolución (probar la cámara girada 90
   grados, y la herramienta `video_capture` si existe).
5. El montaje con `herramientas/` sobre esa grabación real. Esta parte ya
   pasó su prueba con un video falso.
6. El video completo.

Criterios para seguir:

| Resultado del piloto | Decisión |
|---|---|
| El flujo funciona y el video se ve comparable al de referencia | Pasar a la fase 2. |
| Claude arma las escenas pero la cámara o el movimiento quedan pobres | Comprar Moon Animator 2 y animar a mano los planos clave; Claude sigue armando escenarios y montaje. |
| El MCP no da la talla para escenas, o no hay equipo donde correr Studio | Pasar a la ruta B (todo en código) como ruta principal. |
| El video toma más de 20 horas y no se ve camino para bajarlo | Replantear: historias más cortas (30 a 45 s, como la etapa 3 del canal de referencia) con 15 a 20 planos. |

## Fase 2. Lanzamiento (del 7 de diciembre al 10 de enero)

Meta: **12 a 15 videos publicados** y la biblioteca base armada.

- Cadencia: 3 videos por semana al comienzo, subiendo a 5 al final de la fase.
- Mezcla de temas: la mitad de amor y amistad (lo que más rinde en el canal de
  referencia), el resto repartido entre colegio, familia, comedia y terror
  suave, para descubrir qué pega en este canal.
- Dos familias de títulos: "In This World/Town, ..." y títulos cortos ("The
  Echo").
- Cada video se publica también en TikTok e Instagram Reels (solo por alcance).
- Bitácora por video: origen de la premisa, versiones del guion, archivo de
  Studio.
- Cada video pasa la lista de calidad antes de publicarse.
- Revisión semanal y mensual según la sección "Ritmo de revisión".

Meta de la fase: al menos un video por encima de 100 mil vistas. Si un video
pega fuerte, hacer de inmediato dos más de la misma familia.

## Fase 3. Tracción (del 11 de enero a finales de marzo)

Meta: **500 suscriptores y 3 millones de vistas de Shorts en 90 días** (nivel de
financiación de fans) y el primer video largo.

- Subir la cadencia a un video diario, apoyándose en la biblioteca.
- Abrir el canal en el segundo idioma con las mejores historias adaptadas.
- Duplicar lo que funcione: más videos de las premisas y temas ganadores.
- **Primer video largo en febrero**: una historia de 8 a 12 minutos en el mismo
  universo, o una antología de 4 a 5 historias unidas por una historia marco con
  escenas nuevas. No una simple unión de Shorts ya publicados. Título y
  miniatura según la sección "Títulos y miniaturas" de
  `05-guiones-y-fuentes.md`.
- A partir de ahí, un video largo cada dos semanas.
- Si se llega a 1.000 suscriptores y 10 millones de vistas en 90 días antes del
  1 de febrero de 2027, solicitar el ingreso al programa de inmediato para
  quedar con las reglas actuales.

## Fase 4. Monetización (de abril a noviembre de 2027)

Meta: entrar al Programa de Socios por la ruta que llegue primero.

| Ruta | Requisito | Cómo se llega |
|---|---|---|
| Shorts | 1.000 suscriptores y 20 millones de vistas en 90 días | Unos 6,7 millones al mes. Con la distribución del canal de referencia, equivale a uno o dos videos grandes al mes más el resto. |
| Videos largos | 1.000 suscriptores y 8.000 horas en 365 días | Son 480.000 minutos vistos. Por ejemplo, 12 videos largos de 10 minutos con 10 mil vistas cada uno y 4 minutos vistos en promedio. En vistas es la ruta más alcanzable. |

Después de entrar:

- Mantener los 10 millones de vistas de Shorts cada 90 días para no pausar ese
  ingreso.
- Activar membresías y probar patrocinios de juegos de Roblox.
- Evaluar una pista de audio en español.
- Enviar el formulario W-8BEN **el mismo día en que se apruebe AdSense**, no
  después: sin información fiscal Google retiene hasta el 24 % de todos los
  ingresos (`07-canal-y-cuenta.md`). Consultar la parte tributaria con un
  contador.

## Rutina de producción por video (cuando el flujo esté aceitado)

| Paso | Tiempo estimado | Responsable |
|---|---|---|
| Elegir premisa y generar 3 versiones del guion | 20 min | Claude |
| Editar el guion (gancho, remate, ritmo) | 30 min | Tú |
| Voz y tiempos por palabra | 10 min | Automático |
| Lista de planos | 15 min | Claude, con tu revisión |
| Escenas en Studio (reutilizando biblioteca) | 60 a 120 min | Claude por MCP, con tu revisión |
| Revisión plano por plano y ajustes | 45 a 90 min | Tú |
| Grabación | 15 min | Tú |
| Montaje automático y revisión final | 20 min | Automático y tú |
| Lista de calidad antes de publicar (ver abajo) | 5 min | Tú |
| Título, descripción, subida a las tres plataformas | 15 min | Tú |
| **Total** | **4 a 6 horas** | |

## Lista de calidad antes de publicar

Es la puerta de salida de cada video. Si un punto falla, el video no se publica
hasta corregirlo. Cada punto sale de un hallazgo documentado, no de gusto
personal.

Guion (`05-guiones-y-fuentes.md`):

- [ ] La regla está en la primera frase y se entiende sin contexto.
- [ ] La regla tiene un costo o un límite, y aparece antes de la mitad.
- [ ] El final depende de la regla: si se quita la regla, el final no funciona.
- [ ] El detalle sembrado al principio se cosecha al final.
- [ ] No hay nada después del remate (ni despedida ni "suscríbete").
- [ ] La premisa no repite el tipo de final de los dos videos anteriores.
- [ ] Se buscó el título en YouTube y no existe un video con la misma idea.

Imagen (`01-formato-de-referencia.md` y `03-produccion-y-herramientas.md`):

- [ ] La regla se ve en pantalla: quien mire sin sonido entiende de qué trata.
- [ ] Ningún plano dura más de 3 segundos y la cámara se mueve en casi todos.
- [ ] Se revisó la hoja de contactos (un cuadro por plano): ninguna cámara
      dentro de una pared, ningún personaje tapado, ninguna cara equivocada.
- [ ] No aparecen botones ni interfaz de Roblox Studio.
- [ ] Los subtítulos no tapan las caras y las palabras clave van en mayúsculas.

Audio:

- [ ] La voz va a ritmo del género (220 a 240 palabras por minuto), sin
      silencios largos.
- [ ] La música queda claramente por debajo de la voz (unos 12 dB).
- [ ] La música es de la Biblioteca de audio de YouTube o tiene licencia clara.

Políticas (`04-monetizacion-y-politicas.md`):

- [ ] Audiencia marcada como "no es contenido hecho para niños".
- [ ] Título y descripción sin "kids", "para niños" ni el logo de Roblox.
- [ ] Sin marcas reales, groserías, violencia gráfica ni personas reales.
- [ ] La bitácora del video está guardada: origen de la premisa, versiones del
      guion y archivo del proyecto.

Solo para videos largos:

- [ ] Miniatura hecha según `05-guiones-y-fuentes.md` y legible en tamaño de
      celular.
- [ ] Dos o tres miniaturas cargadas en la prueba de comparación de YouTube.
- [ ] El video trae material nuevo, no solo Shorts ya publicados pegados.

## Presupuesto

| Concepto | Mínimo | Recomendado |
|---|---|---|
| Voz (ElevenLabs) | 0 USD (voz propia) | 6 a 22 USD al mes |
| Moon Animator 2 (solo si el piloto lo pide) | 0 USD | unos 30 USD una vez |
| Música | 0 USD | 0 USD |
| Edición | 0 USD | 0 USD |
| **Total primer mes** | **0 USD** | **6 a 52 USD** |

No incluye la suscripción a Claude, que ya tienes.

## Indicadores a seguir

| Indicador | Dónde se ve | Referencia |
|---|---|---|
| Vieron en vez de deslizar | YouTube Studio | Buscar 70 % o más (cifra de blogs, no oficial) |
| Porcentaje promedio visto | YouTube Studio | Buscar 60 % o más en videos de más de 60 s |
| Vistas a 48 horas y a 7 días | YouTube Studio | Comparar contra los propios |
| Me gusta sobre vistas | YouTube Studio | El de referencia tiene 1,8 % |
| Vistas de Shorts en 90 días | YouTube Studio, pestaña de monetización | 3, 10 y 20 millones |
| Horas de videos largos en 365 días | YouTube Studio | 8.000 |
| Suscriptores ganados por cada 1.000 vistas | YouTube Studio, por video | Comparar contra los propios. Importa porque los 1.000 suscriptores son requisito en las dos rutas de monetización. |
| Fuentes de tráfico | YouTube Studio, pestaña Alcance | En Shorts debe dominar el feed de Shorts. En videos largos, mirar cuánto llega desde los Shorts propios, desde sugeridos y desde la página de inicio. |
| Clic en la miniatura (CTR), solo videos largos | YouTube Studio, pestaña Alcance | Comparar contra los propios y entre las miniaturas de la prueba de comparación. |
| Horas de trabajo por video | Registro propio | Bajar de 20 a 6 o menos |

## Ritmo de revisión

Los indicadores no sirven si no hay un momento fijo para mirarlos y decidir
algo con ellos.

### Revisión semanal (30 minutos, el mismo día cada semana)

Mira los videos publicados en la semana y responde por escrito, en una nota
dentro del repositorio:

1. ¿Cuál fue el mejor y cuál el peor video, por vistas a 48 horas y por
   porcentaje visto?
2. En el mejor, ¿qué tenía distinto? Tema, tipo de regla, primera frase,
   duración, tipo de final.
3. En el peor, ¿en qué segundo se cae la curva de retención y qué pasa en el
   guion en ese punto?
4. ¿Qué video trajo más suscriptores por cada 1.000 vistas?
5. ¿Cuántas horas tomó cada video y cuál paso fue el más lento?

Salida obligatoria: **una sola decisión** para la semana siguiente (por
ejemplo, "dos videos más de reglas sobre amistad" o "acortar el bloque de
ejemplos del mundo"). Una decisión por semana permite saber qué cambio produjo
qué resultado.

### Revisión mensual (una hora, el primer fin de semana del mes)

1. **Avance hacia los umbrales**: vistas de Shorts en los últimos 90 días,
   suscriptores y horas de videos largos, contra las metas de la fase.
2. **Qué familias de historias funcionan**: agrupar los videos del mes por tema
   y por tipo de título, y comparar medianas de vistas. Con pocos videos por
   grupo es una señal, no una prueba.
3. **Fuentes de tráfico**: si los videos largos reciben vistas desde los
   Shorts. Si no, reforzar el puente (comentario fijado y video relacionado en
   cada Short).
4. **Competencia**: repetir la medición de `02-casos-de-exito.md` sobre cinco
   canales de referencia (duración, cadencia, títulos y medianas). El formato
   cambió de 30 segundos a más de dos minutos en pocas semanas; hay que detectar
   el siguiente cambio a tiempo.
5. **Costos y tiempo**: horas por video y gasto del mes.
6. **Reglas para decidir**: aplicar las de la sección siguiente y actualizar
   este plan si cambia la fase o la estrategia.

Claude puede hacer buena parte de las dos revisiones: se exportan los datos de
YouTube Studio a un archivo, se guardan en el repositorio y se le pide el
análisis con estas mismas preguntas. La medición de la competencia se repite con
`yt-dlp`, como se hizo en la investigación inicial.

## Reglas para decidir

- **Tras 15 videos** sin ninguno por encima de 50 mil vistas: revisar ganchos y
  calidad visual contra el canal de referencia antes de seguir produciendo.
- **Tras 40 videos o cuatro meses** sin llegar a 3 millones de vistas en 90
  días: cambiar de subformato (historias más cortas, otro tema dominante) o
  detener.
- **Si un video supera 1 millón**: serie inmediata con la misma familia de
  premisa y fijar un comentario que invite a proponer reglas.
- **Si YouTube rechaza la monetización por contenido no auténtico**: apelar con
  la bitácora y los archivos de Studio, y aumentar la variación y la edición
  humana antes de volver a solicitar.

## Decisiones que quedan en tus manos

1. **Estética de Roblox o elenco propio.** Las pautas de Roblox de noviembre
   de 2026 restringen el avatar clásico en contenido comercial. El kit usa
   personajes de bloques propios por defecto; puedes volver al R6 clásico
   aceptando ese riesgo (`04`, "Derechos de Roblox").
2. **Voz propia o sintética.** La propia es gratis y la más segura para
   monetizar; la sintética es más rápida (`09`).
3. **Tiempo semanal disponible.** El plan asume entre 15 y 25 horas por semana
   en las fases 2 y 3.
4. **Nombre del canal.** Recomendado: Almostville. Alternativas: Rulefolk y
   OneOddRule (`canal/nombres.md`).
5. **Duración de los videos.** Los guiones dan de 90 a 125 segundos; los
   líderes van de 126 a 158 de mediana y la medición no muestra que más largo
   rinda más (`08`). Empieza con los guiones como están y decide con tu
   propia retención.
