# Prueba de punta a punta de la caja de herramientas, con el guion 001.
# Uso (desde cualquier carpeta):
#   powershell -ExecutionPolicy Bypass -File "herramientas\prueba\ejecutar_prueba.ps1"
# Opciones:
#   -SinExtras     omite las pruebas adicionales (--clips, --rotar, ElevenLabs simulado, reclamos)
#   -Modelo tiny.en   usa otro modelo de Whisper (por defecto small.en)

param(
    [switch]$SinExtras,
    [string]$Modelo = "small.en"
)

# Nota: este archivo va sin tildes a proposito, para que Windows PowerShell 5.1 lo lea
# bien sin importar la codificacion con la que se guarde.

$ErrorActionPreference = "Stop"
# Para que las tildes de los mensajes de Python se vean bien al capturar su salida.
$env:PYTHONIOENCODING = "utf-8"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$prueba = $PSScriptRoot
$herramientas = Split-Path -Parent $prueba
$raiz = Split-Path -Parent $herramientas
$guionTxt = Join-Path $raiz "guiones\001-friendships-have-a-battery.txt"
$guionMd = Join-Path $raiz "guiones\001-friendships-have-a-battery.md"

function Paso([string]$titulo) {
    Write-Host ""
    Write-Host "=== $titulo ===" -ForegroundColor Cyan
}

function Comprobar([string]$que) {
    if ($LASTEXITCODE -ne 0) { throw "Fallo: $que (codigo $LASTEXITCODE)" }
}

# Python: se usa el entorno virtual de herramientas\.venv; si no existe, se crea.
$py = Join-Path $herramientas ".venv\Scripts\python.exe"
if (-not (Test-Path $py)) {
    Paso "Creando el entorno virtual e instalando dependencias"
    python -m venv (Join-Path $herramientas ".venv"); Comprobar "crear el entorno virtual"
    & $py -m pip install --disable-pip-version-check -r (Join-Path $herramientas "requirements.txt"); Comprobar "instalar dependencias"
}

Paso "1. Voz de prueba con la sintesis de voz de Windows"
Add-Type -AssemblyName System.Speech
$sintetizador = New-Object System.Speech.Synthesis.SpeechSynthesizer
$vozIngles = $sintetizador.GetInstalledVoices() | Where-Object { $_.Enabled -and $_.VoiceInfo.Culture.Name -like "en-*" } | Select-Object -First 1
if ($vozIngles) {
    $sintetizador.SelectVoice($vozIngles.VoiceInfo.Name)
    Write-Host "Voz: $($vozIngles.VoiceInfo.Name)"
} else {
    Write-Host "AVISO: no hay voz en ingles instalada; se usa la voz por defecto."
}
$vozOriginal = Join-Path $prueba "voz_original.wav"
$sintetizador.SetOutputToWaveFile($vozOriginal)
$sintetizador.Speak((Get-Content $guionTxt -Raw -Encoding UTF8))
$sintetizador.Dispose()
Write-Host "Listo: $vozOriginal"

Paso "2. ritmo.py"
& $py (Join-Path $herramientas "ritmo.py") $vozOriginal (Join-Path $prueba "voz.wav") --guion $guionTxt --ppm 230
Comprobar "ritmo.py"

Paso "3. transcribir.py --guion"
& $py (Join-Path $herramientas "transcribir.py") (Join-Path $prueba "voz.wav") --guion $guionTxt --modelo $Modelo --salida (Join-Path $prueba "palabras.json") --crudo (Join-Path $prueba "palabras_crudo.json")
Comprobar "transcribir.py"

Paso "4. planos_tiempos.py"
& $py (Join-Path $herramientas "planos_tiempos.py") --guion $guionMd --palabras (Join-Path $prueba "palabras.json") --audio (Join-Path $prueba "voz.wav") --salida (Join-Path $prueba "planos.json")
Comprobar "planos_tiempos.py"

Paso "5. subtitulos.py"
& $py (Join-Path $herramientas "subtitulos.py") --palabras (Join-Path $prueba "palabras.json") --claves (Join-Path $prueba "claves.txt") --salida (Join-Path $prueba "subtitulos.ass")
Comprobar "subtitulos.py"

Paso "6. Video falso horizontal (un color y un numero por plano), musica y efecto de prueba"
& $py (Join-Path $prueba "video_falso.py") --planos (Join-Path $prueba "planos.json") --salida (Join-Path $prueba "video_falso.mp4") --clips (Join-Path $prueba "clips")
Comprobar "video_falso.py"
$acorde = "0.25*sin(2*PI*220*t)*(0.6+0.4*sin(2*PI*2*t))+0.2*sin(2*PI*277.18*t)+0.2*sin(2*PI*329.63*t)"
ffmpeg -hide_banner -nostdin -y -v error -f lavfi -i "aevalsrc='$acorde|$acorde':s=48000:d=30" -c:a libmp3lame -b:a 160k (Join-Path $prueba "musica_prueba.mp3")
Comprobar "musica de prueba"
ffmpeg -hide_banner -nostdin -y -v error -f lavfi -i "sine=frequency=1200:duration=0.25:sample_rate=48000" -af "afade=t=out:st=0.05:d=0.2" (Join-Path $prueba "efecto_prueba.wav")
Comprobar "efecto de prueba"
Set-Content -Path (Join-Path $prueba "efectos.json") -Encoding ascii -Value '[{"archivo": "efecto_prueba.wav", "tiempo": 20.0, "volumen_db": -8}]'

Paso "7. montar.py"
& $py (Join-Path $herramientas "montar.py") --video (Join-Path $prueba "video_falso.mp4") --voz (Join-Path $prueba "voz.wav") --subtitulos (Join-Path $prueba "subtitulos.ass") --musica (Join-Path $prueba "musica_prueba.mp3") --efectos (Join-Path $prueba "efectos.json") --salida (Join-Path $prueba "final.mp4")
Comprobar "montar.py"

Paso "8. hoja_contactos.py"
& $py (Join-Path $herramientas "hoja_contactos.py") --video (Join-Path $prueba "final.mp4") --planos (Join-Path $prueba "planos.json") --salida (Join-Path $prueba "hoja_contactos.png")
Comprobar "hoja_contactos.py"

Paso "9. Seis cuadros del resultado para mirarlos"
$cuadros = Join-Path $prueba "cuadros"
New-Item -ItemType Directory -Force $cuadros | Out-Null
Remove-Item (Join-Path $cuadros "*.png") -ErrorAction SilentlyContinue
$numero = 0
foreach ($t in "1.7", "12.0", "20.3", "33.0", "52.6", "66.2") {
    $numero++
    ffmpeg -hide_banner -nostdin -y -v error -ss $t -i (Join-Path $prueba "final.mp4") -frames:v 1 (Join-Path $cuadros ("cuadro_{0}_{1}s.png" -f $numero, $t))
    Comprobar "extraer cuadro en $t s"
}
Write-Host "Cuadros en: $cuadros"

Paso "10. revisar.py"
$informe = & $py(Join-Path $herramientas "revisar.py") --video (Join-Path $prueba "final.mp4") --palabras (Join-Path $prueba "palabras.json") --subtitulos (Join-Path $prueba "subtitulos.ass") --planos (Join-Path $prueba "planos.json")
$codigoRevisar = $LASTEXITCODE
$informe | Out-File -FilePath (Join-Path $prueba "informe_revisar.txt") -Encoding utf8
$informe | ForEach-Object { Write-Host $_ }

if (-not $SinExtras) {
    $extras = Join-Path $prueba "extras"
    New-Item -ItemType Directory -Force $extras | Out-Null

    Paso "Extra A. montar.py --clips (un clip por plano)"
    & $py (Join-Path $herramientas "montar.py") --clips (Join-Path $prueba "clips") --planos (Join-Path $prueba "planos.json") --voz (Join-Path $prueba "voz.wav") --subtitulos (Join-Path $prueba "subtitulos.ass") --preset ultrafast --salida (Join-Path $extras "final_clips.mp4")
    Comprobar "montar.py --clips"
    & $py (Join-Path $herramientas "revisar.py") --video (Join-Path $extras "final_clips.mp4") --planos (Join-Path $prueba "planos.json") --palabras (Join-Path $prueba "palabras.json")
    Write-Host "(codigo de revisar.py: $LASTEXITCODE)"

    Paso "Extra B. montar.py --rotar y --desfase (grabacion con la camara girada, 12 s)"
    # Se arma una grabacion vertical falsa, se acuesta 90 grados y se le agregan 0,5 s de sobra al comienzo.
    & $py (Join-Path $prueba "video_falso.py") --planos (Join-Path $prueba "planos.json") --tamano 1080x1920 --salida (Join-Path $extras "vertical.mp4")
    Comprobar "video falso vertical"
    ffmpeg -hide_banner -nostdin -y -v error -t 13 -i (Join-Path $extras "vertical.mp4") -vf "transpose=2,tpad=start_mode=clone:start_duration=0.5" -c:v libx264 -preset ultrafast -crf 18 -an (Join-Path $extras "girado.mp4")
    Comprobar "video girado"
    ffmpeg -hide_banner -nostdin -y -v error -t 12 -i (Join-Path $prueba "voz.wav") (Join-Path $extras "voz_12s.wav")
    Comprobar "voz corta"
    & $py (Join-Path $herramientas "montar.py") --video (Join-Path $extras "girado.mp4") --rotar horario --desfase 0.5 --voz (Join-Path $extras "voz_12s.wav") --subtitulos (Join-Path $prueba "subtitulos.ass") --preset ultrafast --salida (Join-Path $extras "final_rotado.mp4")
    Comprobar "montar.py --rotar"
    ffmpeg -hide_banner -nostdin -y -v error -ss 5.0 -i (Join-Path $extras "final_rotado.mp4") -frames:v 1 (Join-Path $extras "cuadro_rotado.png")
    ffmpeg -hide_banner -nostdin -y -v error -ss 5.0 -i (Join-Path $extras "girado.mp4") -frames:v 1 (Join-Path $extras "cuadro_girado_original.png")
    & $py (Join-Path $herramientas "revisar.py") --video (Join-Path $extras "final_rotado.mp4") --planos (Join-Path $prueba "planos.json") --tolerancia-corte 0.05
    Write-Host "(codigo de revisar.py: $LASTEXITCODE. Es normal que marque REVISAR en 'Cortes contra planos.json': este video solo tiene los primeros 12 s)"

    Paso "Extra C. voz_elevenlabs.py con respuesta simulada (no llama a la API real)"
    & $py (Join-Path $prueba "probar_voz_elevenlabs.py")
    Comprobar "probar_voz_elevenlabs.py"

    Paso "Extra D. Reclamos de nuevo_video.py con procesos simultaneos"
    & $py (Join-Path $prueba "probar_reclamos.py")
    Comprobar "probar_reclamos.py"
}

Paso "Resultado"
Write-Host "Video final:        $(Join-Path $prueba 'final.mp4')"
Write-Host "Hoja de contactos:  $(Join-Path $prueba 'hoja_contactos.png')"
Write-Host "Informe:            $(Join-Path $prueba 'informe_revisar.txt')"
if ($codigoRevisar -ne 0) {
    Write-Host "revisar.py dejo lineas por REVISAR en el video principal." -ForegroundColor Yellow
    exit 1
}
Write-Host "revisar.py: APROBADO" -ForegroundColor Green
exit 0
