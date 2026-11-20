---
name: producir-video
description: Produce un video del canal de punta a punta (voz, puesta en escena en Roblox Studio, rodaje cuadro a cuadro, montaje y revisión) con el método probado en el video 001. Úsala cuando el usuario pida hacer, producir, grabar, rodar o montar un video NNN, o retomar uno a medias.
---

# Producir un video del canal

Método probado el 2026-11-13 con el video 001. El porqué de cada regla está en
`docs/11-metodo-probado.md`; no hace falta leerlo para producir. No leas los
demás documentos ni los fuentes de la biblioteca salvo que un paso falle.

En todo lo que sigue, `$py` es `herramientas\.venv\Scripts\python.exe`, `$s` es
`herramientas\studio` y `NNN` es el número del video. Corre todo desde la raíz
del repositorio.

## Reglas que no se negocian

- Escribe y edita archivos con las herramientas de escritura y edición, o con
  un script de Python. Nunca con `Set-Content`, `Out-File` ni reemplazos de
  PowerShell.
- No lances el rodaje de la toma final sin haber mirado las hojas de la vista
  previa.
- La ventana de Studio del usuario llamada "Experiencia sin título" u otra que
  no sea la del video no se toca. Las herramientas solo usan la ventana cuyo
  nombre contiene `NNN-slug`.
- La toma final dura más de 10 minutos: lánzala en segundo plano y espera.
- No hagas commit ni publiques nada.

## Paso 1. Tomar el video y abrir su lugar (1 minuto)

```powershell
& $py herramientas\nuevo_video.py estado
& $py herramientas\nuevo_video.py tomar NNN --chat <nombre>
& $py $s\puente.py --video NNN abrir       # crea el lugar desde la plantilla si no existe
& $py $s\puente.py --video NNN instalar    # debe responder "Historias 1.0.0 instalada..."
```

Si `abrir` dice que no hay ventana, Studio no está corriendo con el servidor
MCP activo: pide al usuario que abra Studio, y en Assistant, menú "...",
Manage MCP Servers, active "Enable Studio as MCP server".

## Paso 2. Guion, voz y tiempos (6 minutos)

1. Lee `guiones/NNN-slug.md` una vez: narración y tabla de planos.
2. Corre la cadena completa:

```powershell
& $py herramientas\producir.py voz NNN                  # Kokoro af_heart
& $py herramientas\producir.py voz NNN --voz am_puck    # otra voz
& $py herramientas\producir.py voz NNN --audio RUTA     # voz propia o de ElevenLabs
```

3. Si `planos` avisa de planos de menos de 0,6 s, de más de 3,5 s o sin anclar,
   corrige la columna "Frase (inicio)" de la tabla en el `.md` (solo de tu
   video) y corre `producir.py tiempos NNN`. Comprueba además que cada fila
   empiece donde empieza la idea que el plano ilustra.
4. La voz la decide el usuario. Si no dijo nada, usa `af_heart`, dilo en el
   informe final y anótalo en `estado.md`.

## Paso 3. Escribir la puesta (el trabajo creativo)

Crea `videos/NNN-slug/escenas/hacer_puesta.py` copiando la estructura de
`videos/001-friendships-have-a-battery/escenas/hacer_puesta.py`. Las ayudas y
todas las reglas de encuadre están en el encabezado de `$s\puesta.py`: léelo
entero, es corto y evita rehacer tomas.

Para conocer un escenario antes de usarlo (anclas y aspecto):

```powershell
& $py $s\ver.py --video NNN --panorama sala videos\NNN-slug\escenas\capturas\pan_sala.png
```

Escenarios: pueblo, parque, cuarto, sala, cocina, salon, pasillo, cafeteria,
cancha, patio, bosque, calle_noche. Caras: neutra, feliz, risa, triste, llanto,
susto, rabia, confundido, decidido, enamorado, dormido, picaro, mareado, vacia,
sonrisa_enorme, angustia, risa_forzada, indiferente, orgulloso, incomodo.
Poses: de_pie, brazos_arriba, senalar, senalar_arriba, ofrecer, saludar,
mirar_arriba, negar, correr, caminar, sentado, acostado, saltar, encogerse,
gritar, celular, más las de `POSES` en `puesta.py`. Evita `cabeza_abajo`,
`derrotado`, `abrazo` y `de_espaldas` en planos frontales: esconden la cara o
se ven mal; usa `POSES["cabizbajo"]`.

Criterio visual que funcionó:

- Un plano por frase, con sujeto grande. Alterna dúo, primer plano de cara,
  objeto solo y plano general; no repitas el mismo encuadre dos planos seguidos.
- El objeto de la regla del mundo (la batería, en el 001) aparece en la mayoría
  de los planos y cambia de estado a la vista.
- Elenco con colores de camisa bien distintos; el protagonista con el color
  más vivo. Los mismos personajes de principio a fin.
- Cada plano con algo que se mueve: `anim`, `mover`, `cambios`, `claves` de la
  batería o un movimiento de cámara.
- Flashbacks con `efecto="recuerdo"`, clímax con un efecto de luz, y el último
  plano parecido al primero para que el video encadene al repetirse.

## Paso 4. Revisar los planos en edición (2 minutos por pasada)

```powershell
& $py videos\NNN-slug\escenas\hacer_puesta.py
& $py $s\puente.py --video NNN reconstruir      # "inexistentes" debe salir vacío
& $py $s\ver.py --video NNN videos\NNN-slug\escenas\capturas\p.png todos
```

Mira las hojas (10 planos por imagen). En cada plano comprueba: caras visibles,
nada importante entre las dos marcas rojas del borde izquierdo (franja de
subtítulos), nadie cortado por los bordes, el objeto se entiende. Corrige
`hacer_puesta.py`, regenera y vuelve a mirar solo los planos cambiados
(`ver.py ... 12 13 40`). Después de cambiar el elenco o la utilería corre
`reconstruir` otra vez.

## Paso 5. Vista previa en modo juego (4 minutos)

Prepara la ventana una sola vez (Studio lo recuerda): paneles cerrados, sin
selector de vista ni barra de comandos, pantalla completa. Los pasos están en
el encabezado de `$s\ui.py`. Avisa al usuario que no use el equipo.

```powershell
& $py $s\rodar.py --video NNN previa
```

Mira `escenas/capturas/hoja_N.png`: dos cuadros por plano, ya como se verá. La
luz, los resplandores y las partículas se ven distintos que en edición, así que
esta revisión manda. Si la orden avisa de "vista pequeña", arregla la ventana
antes de seguir. Para comprobar un arreglo puntual:
`rodar.py --video NNN tramo 40 46` (segundos).

## Paso 6. Toma final (21 minutos por cada 94 s de video)

```powershell
& $py $s\rodar.py --video NNN toma     # en segundo plano
```

Mientras rueda, escribe `montaje/hacer_efectos.py` (ejemplo: el del 001; guía
en el encabezado de `$s\efectos.py`), descarga la música a
`montaje/musica_<nombre>.mp3`, escribe `montaje/licencias.md` (copia la
estructura del 001) y ajusta `metadatos/publicacion.txt`, que ya viene escrito
en la carpeta de cada video: agrégale el crédito de la música y el cuadro de
portada (plantilla en `docs/08`, sección 3.1). Música:
lista por tono en `docs/09`, sección "Pistas recomendadas"; enlace directo
`https://incompetech.com/music/royalty-free/mp3-royaltyfree/Nombre.mp3`, con
crédito obligatorio en la descripción.

## Paso 7. Montaje y revisión (4 minutos)

```powershell
& $py herramientas\producir.py montar NNN
```

Mira `revision/hoja_contactos.png`. En el informe, la línea de "Cortes contra
planos.json" puede quedar en REVISAR cuando hay planos seguidos de color
parecido: confirma en la hoja que los planos están y sigue. Cualquier otra
línea en REVISAR se corrige.

## Paso 8. Cerrar

1. Marca las casillas y deja notas en `videos/NNN-slug/estado.md`.
2. `& $py herramientas\producir.py limpiar NNN`
3. `& $py $s\ui.py --video NNN tecla F11` para sacar a Studio de pantalla
   completa.
4. `& $py herramientas\nuevo_video.py soltar NNN`
5. Informe al usuario: ruta del MP4, qué no pudiste comprobar (no ves el video
   en movimiento ni lo escuchas), decisiones que tomaste por él y qué le toca.

## Si algo falla

| Síntoma | Causa y arreglo |
|---|---|
| "No hay una ventana de Studio con ..." | El lugar no está abierto: `puente.py --video NNN abrir` |
| "Failed to parse command code" | El archivo `.luau` tiene un carácter raro al inicio o un error de sintaxis; escríbelo de nuevo con la herramienta de escritura |
| "el cliente no quedó listo" | Mira la consola: `puente.py --video NNN call get_console_output -`. Casi siempre es un error de la puesta |
| "no encontré la pantalla de calibración" | La ventana de Studio no está al frente o está minimizada |
| Un personaje sale sin cara | Está de perfil: baja el `giro` a 40 o menos |
| Cambié la biblioteca y no se nota | `puente.py --video NNN instalar` y luego `reconstruir` |
| `grabacion.lock` existe | Otro chat está grabando; espera. Si es un resto de un rodaje tuyo que se cayó, bórralo |
