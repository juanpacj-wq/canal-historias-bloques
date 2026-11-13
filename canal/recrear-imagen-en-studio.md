# Recrear la imagen del canal con imágenes hechas en Roblox Studio

## Por qué

Las imágenes actuales de `canal/imagen/` (perfil, banner, marca de agua y
plantilla de miniatura) se dibujaron con código (Pillow), porque en el primer
equipo Roblox Studio no abría. Sirven para lanzar, pero no se parecen a lo que
se va a ver en los videos. La meta es rehacerlas con **capturas reales de
Studio**, usando los mismos personajes, escenarios y luz de los videos, para
que el canal y su contenido se vean como una sola cosa.

Esta tarea va **después** de validar la biblioteca
(`arranque/1-primera-prueba-en-studio.txt`) y **antes** de crear el canal en
YouTube, para subirlo ya con la imagen definitiva.

## Qué hay que entregar

| Pieza | Tamaño | Condiciones |
|---|---|---|
| Foto de perfil | 800 por 800 px, PNG | El personaje insignia de frente, cara grande y alegre, fondo plano de un color fuerte. Debe leerse a 48 px y caber en un recorte circular. |
| Banner | 2560 por 1440 px, PNG | Todo lo importante dentro de la zona segura central de 1546 por 423 px: nombre, la frase "In this world..." y dos o tres personajes con un objeto imposible. El resto es fondo del pueblo. |
| Marca de agua | 150 por 150 px, PNG con transparencia | Solo la cabeza del personaje insignia. |
| Plantilla de miniatura | 1280 por 720 px, PNG | Cara grande a un lado, espacio para tres palabras al otro. Para videos largos. |
| Portadas de prueba | 1080 por 1920 px | Dos o tres cuadros candidatos de los primeros videos, para elegir portada de Shorts. |

Todo se guarda en `canal/imagen/studio/`, sin borrar las versiones dibujadas
(quedan como respaldo en `canal/imagen/`).

## Reglas que no cambian

- Identidad: paleta, tipografía y rasgos del personaje insignia de
  `canal/identidad.md`. Si la versión de Studio obliga a cambiar algo (por
  ejemplo el tono de un color bajo la luz), se actualiza ese archivo.
- **Personajes propios**: el elenco de estilo "propio" de
  `studio/lib/Elenco.luau`, no el avatar clásico R6 o R15. Motivo:
  `docs/04-monetizacion-y-politicas.md`, sección "Derechos de Roblox".
- Sin el logo de Roblox, sin la palabra "Roblox" ni "Blox", sin recursos del
  catálogo con marcas, sin sugerir que el canal es oficial.
- Fuentes: Lilita One y Fredoka, que ya están en `canal/imagen/fuentes/` con su
  licencia.

## Método propuesto

Sin probar: nada de esto se ha hecho en Studio. Ajusta lo que haga falta y
deja anotado lo que cambiaste al final de este archivo.

1. **Lugar aparte.** Crea `canal/imagen/studio/imagen-canal.rbxl`, carga la
   biblioteca (`studio/README.md`) y marca el atributo
   `workspace:SetAttribute("VideoId", "canal")`.
2. **Personaje insignia.** Créalo con el elenco propio siguiendo la
   descripción de `canal/identidad.md` (cabeza menta, contorno azul noche,
   bloque coral flotando sobre la cabeza). Guárdalo como modelo con nombre
   `Insignia` para reutilizarlo en los videos.
3. **Una escena por pieza.**
   - Perfil: el personaje solo, pose de saludo, cara "feliz" o "sonrisa
     enorme", frente a una pared plana del color de fondo, luz suave de
     frente. Cámara cerca y de frente, campo de visión estrecho para que no
     deforme la cara.
   - Banner: el escenario "pueblo" de noche o al atardecer, tres personajes
     en el centro y la barra de batería de `Utileria.luau` flotando entre dos
     de ellos. Cámara general, horizontal.
   - Marca de agua: la cabeza sola sobre un fondo de un color que no exista
     en el personaje (por ejemplo magenta puro), para poder recortarlo.
   - Miniatura: el personaje a la derecha con una emoción fuerte (susto o
     llanto), fondo simple de un color, espacio libre a la izquierda.
4. **Captura a buena resolución.** La herramienta `screen_capture` devuelve
   la imagen al chat, pero no está comprobado que la guarde en disco ni a qué
   resolución. Opciones, en orden:
   - Si `screen_capture` entrega la imagen con resolución suficiente y se
     puede guardar, úsala.
   - Si no: el usuario pone Studio en pantalla completa, oculta la interfaz y
     toma la captura con la herramienta de recortes de Windows o con la
     captura de pantalla de OBS. Para el banner hace falta un monitor de al
     menos 2560 px de ancho, o tomar la captura más pequeña y ampliarla (se
     pierde nitidez; dilo si pasa).
   - El usuario deja los archivos en `canal/imagen/studio/capturas/`.
5. **Composición.** Los textos (nombre, lema, palabras de la miniatura) y los
   recortes se hacen con Pillow, igual que ahora. Amplía
   `canal/imagen/generar.py` con una opción para usar una captura como fondo
   o como personaje (por ejemplo `--captura-perfil`, `--captura-banner`,
   `--captura-miniatura`) en lugar de dibujarlos. Para la marca de agua,
   vuelve transparente el color de fondo elegido.
6. **Revisión.** Abre cada imagen y mírala. Reduce el perfil a 48 px y
   comprueba que se lee. Recorta la zona segura del banner y comprueba que
   nada importante queda fuera. Compara lado a lado con la versión dibujada y
   quédate con la mejor de cada pieza: no es obligatorio que gane la de
   Studio.
7. **Cierre.** Actualiza `canal/README.md` y `canal/identidad.md`, y avísale
   al usuario cuáles archivos subir a YouTube.

## Lo que decide el usuario

- Si le gusta más el personaje de Studio o el dibujado.
- El nombre definitivo del canal antes de componer el banner (recomendado:
  Almostville; alternativas en `canal/nombres.md`).

## Bitácora de esta tarea

(El chat que la haga anota aquí la fecha, qué método de captura funcionó y qué
cambió respecto a este plan.)
