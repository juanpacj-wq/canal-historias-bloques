# Caja de herramientas de posproducción

Scripts de Python para llevar un guion hasta un Short listo para subir: voz con
ritmo, tiempos por palabra, tiempos de cada plano, subtítulos, montaje, hoja de
contactos y control de calidad. Todo corre en Windows, en CPU, con ffmpeg.

## Requisitos

- Windows 10 u 11 con PowerShell.
- Python 3.10 o superior (probado con 3.13).
- ffmpeg y ffprobe en el PATH (o las variables de entorno `FFMPEG` y `FFPROBE`
  con la ruta a cada ejecutable).
- No hace falta GPU.

## Instalación

Las dependencias se instalan en un entorno virtual dentro de esta carpeta
(`herramientas\.venv`), para no tocar el Python del sistema. Desde la raíz del
proyecto:

```powershell
python -m venv herramientas\.venv
herramientas\.venv\Scripts\python.exe -m pip install -r herramientas\requirements.txt
```

Paquetes: `faster-whisper` (transcripción) y `Pillow` (hoja de contactos y
medición del ancho de los subtítulos). La primera vez que corras
`transcribir.py` se descarga el modelo `small.en` (unos 480 MB) a la caché de
Hugging Face de tu usuario.

En los ejemplos de abajo, `$py` es el Python del entorno virtual:

```powershell
$py = "herramientas\.venv\Scripts\python.exe"
```

Todos los scripts tienen ayuda: `& $py herramientas\montar.py --help`.

## Qué hace cada script

| Script | Para qué sirve |
|---|---|
| `nuevo_video.py` | Crea `videos/NNN-slug/` con subcarpetas y `estado.md`. También maneja los reclamos (`tomar`, `soltar`, `estado`) para que varios chats trabajen en paralelo. |
| `voz_elevenlabs.py` | Genera la narración con ElevenLabs y entrega `voz.mp3` y `palabras.json` de una vez. |
| `ritmo.py` | Recorta silencios y acelera la voz hasta el ritmo objetivo (230 palabras por minuto por defecto) sin cambiar el tono, y normaliza la sonoridad. |
| `transcribir.py` | Saca el tiempo de cada palabra de un audio (`palabras.json`). Con `--guion` deja las palabras escritas como en el guion. |
| `planos_tiempos.py` | Une la tabla "Lista de planos" del guion con `palabras.json` y produce `planos.json`: inicio y fin de cada plano. |
| `subtitulos.py` | Convierte `palabras.json` en `subtitulos.ass` con el estilo del formato. |
| `montar.py` | Arma el MP4 final: recorte a 9:16, voz, subtítulos quemados, música y efectos. |
| `hoja_contactos.py` | Un cuadro por plano en una sola imagen PNG numerada. |
| `revisar.py` | Control de calidad del MP4 final, con APROBADO o REVISAR por línea. |
| `comun.py` | Funciones compartidas. No se ejecuta directamente. |

## Orden de uso

1. `nuevo_video.py crear` y `nuevo_video.py tomar`.
2. Voz: `voz_elevenlabs.py`, o grabar tu propia voz.
3. `ritmo.py` sobre la voz.
4. `transcribir.py --guion` sobre la voz que salió de `ritmo.py`.
5. `planos_tiempos.py`. El `planos.json` que sale es el que lee el script
   director de Luau, así que este paso va antes de grabar.
6. Grabar en Roblox Studio (una sola toma continua, o un clip por plano).
7. `subtitulos.py`.
8. `montar.py`.
9. `hoja_contactos.py` y `revisar.py`.
10. `nuevo_video.py soltar`.

Importante: cada vez que cambies la voz (otro texto, otro ritmo) hay que
repetir desde el paso 4, porque todos los tiempos dependen de ese audio.

Si usas `voz_elevenlabs.py` y luego `ritmo.py`, el `palabras.json` de
ElevenLabs deja de servir (el audio cambió de duración): corre `transcribir.py`
sobre la voz ya ajustada. Si la voz de ElevenLabs ya sale al ritmo que quieres
(opción `--velocidad`), puedes saltarte `ritmo.py` y `transcribir.py`.

## Ejemplo completo en PowerShell

Desde la raíz del proyecto, para el video 001:

```powershell
$py = "herramientas\.venv\Scripts\python.exe"
$guionTxt = "guiones\001-friendships-have-a-battery.txt"
$guionMd  = "guiones\001-friendships-have-a-battery.md"
$v = "videos\001-friendships-have-a-battery"

# 1. Carpeta de trabajo y reclamo
& $py herramientas\nuevo_video.py crear 001
& $py herramientas\nuevo_video.py tomar 001 --chat chat-montaje

# 2. Voz con ElevenLabs (la clave va solo en la variable de entorno de esta sesión)
$env:ELEVENLABS_API_KEY = "tu_clave"
& $py herramientas\voz_elevenlabs.py --texto $guionTxt --voz ID_DE_LA_VOZ --carpeta "$v\voz"
#    Si grabas tu propia voz, guárdala como "$v\voz\voz.mp3" (o .wav) y sigue igual.

# 3. Ritmo: sin silencios, 230 palabras por minuto, sonoridad pareja
& $py herramientas\ritmo.py "$v\voz\voz.mp3" "$v\voz\voz_ritmo.wav" --guion $guionTxt --ppm 230

# 4. Tiempo de cada palabra, con la ortografía del guion
& $py herramientas\transcribir.py "$v\voz\voz_ritmo.wav" --guion $guionTxt --salida "$v\tiempos\palabras.json"

# 5. Tiempo de cada plano (lo usa el script director de Luau)
& $py herramientas\planos_tiempos.py --guion $guionMd --palabras "$v\tiempos\palabras.json" --audio "$v\voz\voz_ritmo.wav" --salida "$v\tiempos\planos.json"

# 6. (Grabas en Roblox Studio y guardas la toma en "$v\grabacion\toma.mp4")

# 7. Subtítulos
& $py herramientas\subtitulos.py --palabras "$v\tiempos\palabras.json" --salida "$v\tiempos\subtitulos.ass"

# 8. Montaje
& $py herramientas\montar.py --video "$v\grabacion\toma.mp4" --voz "$v\voz\voz_ritmo.wav" --subtitulos "$v\tiempos\subtitulos.ass" --musica "$v\montaje\musica.mp3" --salida "$v\montaje\final.mp4"

# 9. Revisión
& $py herramientas\hoja_contactos.py --video "$v\montaje\final.mp4" --planos "$v\tiempos\planos.json" --salida "$v\revision\hoja_contactos.png"
& $py herramientas\revisar.py --video "$v\montaje\final.mp4" --palabras "$v\tiempos\palabras.json" --subtitulos "$v\tiempos\subtitulos.ass" --planos "$v\tiempos\planos.json"

# 10. Soltar el reclamo
& $py herramientas\nuevo_video.py soltar 001
```

Variantes del montaje:

```powershell
# Grabación hecha con la cámara girada 90 grados (queda vertical a resolución completa)
& $py herramientas\montar.py --video toma.mp4 --rotar horario --voz voz.wav --subtitulos subtitulos.ass --salida final.mp4

# La grabación empezó 0,8 s antes que la acción
& $py herramientas\montar.py --video toma.mp4 --desfase 0.8 --voz voz.wav --salida final.mp4

# Un clip por plano (001.mp4, 002.mp4...) en vez de una toma continua
& $py herramientas\montar.py --clips "$v\grabacion\clips" --planos "$v\tiempos\planos.json" --voz voz.wav --subtitulos subtitulos.ass --salida final.mp4

# Con efectos de sonido y la música más baja
& $py herramientas\montar.py --video toma.mp4 --voz voz.wav --musica musica.mp3 --nivel-musica -15 --efectos efectos.json --salida final.mp4
```

## Formatos de archivo

`palabras.json` (lo escriben `transcribir.py` y `voz_elevenlabs.py`):

```json
[{"palabra": "In", "inicio": 0.0, "fin": 0.14}, {"palabra": "this", "inicio": 0.14, "fin": 0.3}]
```

`planos.json` (lo escribe `planos_tiempos.py`; lo lee el script director de
Luau, `montar.py --clips`, `hoja_contactos.py` y `revisar.py`). Tiempos en
segundos; el `fin` de un plano es el `inicio` del siguiente:

```json
{"video": "001-friendships-have-a-battery", "duracion": 75.51, "planos": [
  {"n": 1, "inicio": 0.0, "fin": 2.32, "texto": "In this world, every friendship...",
   "escenario": "Pueblo de día", "en_pantalla": "Dos amigos frente a frente, barra verde flotando entre ellos",
   "cara": "Felices", "camara": "M"}
]}
```

`efectos.json` (opcional, para `montar.py --efectos`). Las rutas relativas se
toman desde la carpeta donde está el JSON:

```json
[{"archivo": "efectos/pop.wav", "tiempo": 12.5, "volumen_db": -6}]
```

Palabras clave de los subtítulos: por defecto se resaltan las palabras que en
el guion ya van en MAYÚSCULAS. Si prefieres una lista aparte, pasa
`--claves claves.txt` con una o varias palabras por línea.

## Detalles que conviene saber

- **Fuente de los subtítulos.** Lilita One, con licencia SIL Open Font License
  1.1, descargada del repositorio oficial de Google Fonts
  (`github.com/google/fonts`, carpeta `ofl/lilitaone`). Está en `fuentes/` junto
  con su licencia (`OFL.txt`). ffmpeg la carga desde esa carpeta (`fontsdir`),
  así que no hay que instalarla en Windows. Si quieres otra, copia su `.ttf` a
  `fuentes/` y pasa `--fuente "Nombre de la familia"` y `--archivo-fuente` a
  `subtitulos.py`. `revisar.py` avisa si ffmpeg no encontró la fuente y la
  cambió por otra.
- **Anclaje de planos.** `planos_tiempos.py` busca la frase de cada plano en la
  voz, siempre hacia adelante. Si la frase de la tabla no coincide palabra por
  palabra con la narración, prueba con el comienzo de la frase y luego con un
  parecido aproximado. Avisa de los planos que duran menos de 0,6 s o más de
  3,5 s y de las frases que no encontró.
- **Sonoridad.** `ritmo.py` deja la voz en -16 LUFS. `montar.py` pone la música
  12 dB por debajo de la voz (midiendo las dos) y normaliza la mezcla final a
  -14 LUFS con pico real de -1,5 dBTP, en dos pasadas.
- **Zona segura de Shorts.** `revisar.py` dibuja los subtítulos solos y mide
  dónde caen. Los márgenes por defecto (250 px arriba, 384 px abajo, 60 px a los
  lados y una columna de 190 px a la derecha en la mitad inferior) son una
  estimación conservadora de lo que tapa la interfaz de Shorts; YouTube no
  publica medidas exactas. Se pueden cambiar con las opciones `--seguro-*`.
- **Detección de cortes.** `revisar.py` usa el detector de escena de ffmpeg con
  umbral 0,3, el mismo con el que se midió el video de referencia. Dos planos
  seguidos con el mismo encuadre y poca diferencia de imagen pueden contarse
  como uno solo.
- **Reclamos.** `nuevo_video.py tomar` crea `videos/NNN-slug/.tomado` con
  apertura exclusiva: si dos chats lo intentan al mismo tiempo, solo uno lo
  logra y el otro recibe un mensaje con quién lo tomó y cuándo. La etapa que
  muestra `estado` es la primera casilla sin marcar de `estado.md`.
- **Mayúsculas del guion.** Las palabras en MAYÚSCULAS de la narración son
  para resaltar en los subtítulos. `voz_elevenlabs.py` las envía en minúsculas
  para que la voz no las deletree ni las grite (`--conservar-mayusculas` lo
  evita). Los subtítulos recuperan las mayúsculas al correr
  `transcribir.py --guion`, así que con ElevenLabs sigue siempre el camino
  completo (voz, `ritmo.py`, `transcribir.py --guion`). Sin probar con la API
  real.
- **Claves.** `voz_elevenlabs.py` lee la clave solo de la variable de entorno
  `ELEVENLABS_API_KEY`. No la escribas en ningún archivo.

## Prueba de punta a punta

`prueba/ejecutar_prueba.ps1` repite toda la cadena con el guion 001: genera una
voz con la síntesis de Windows, la pasa por todos los scripts, arma una
grabación falsa (cada plano es un color con su número) y deja en `prueba/` el
video final, la hoja de contactos, seis cuadros y el informe de `revisar.py`.

```powershell
powershell -ExecutionPolicy Bypass -File "herramientas\prueba\ejecutar_prueba.ps1"
```

Con `-SinExtras` se salta las pruebas adicionales (`--clips`, `--rotar`,
ElevenLabs con respuesta simulada y reclamos simultáneos). La llamada real a la
API de ElevenLabs no forma parte de la prueba: necesita una clave.
