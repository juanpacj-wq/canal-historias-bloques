# Vuelve a descargar el material de referencia que se analizo en el primer equipo.
# No esta en el repositorio porque son videos y subtitulos de otros canales:
# se pueden estudiar, pero no republicar.
# Uso:  powershell -ExecutionPolicy Bypass -File investigacion\descargar-referencia.ps1
# Requiere yt-dlp, Node y ffmpeg. Este archivo va sin tildes a proposito.

$destino = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'referencia'
New-Item -ItemType Directory -Force $destino | Out-Null

# El short de referencia, con subtitulos automaticos
yt-dlp --js-runtimes node --write-auto-subs --sub-langs "en.*" -o "$destino\short.%(ext)s" "https://www.youtube.com/shorts/nn3_MOuxoho"

# Cortes de camara del short (umbral 0.3, el mismo de docs/01)
$video = Get-ChildItem $destino -Filter 'short.*' | Where-Object { $_.Extension -in '.webm', '.mp4', '.mkv' } | Select-Object -First 1
if ($video) {
    New-Item -ItemType Directory -Force "$destino\frames" | Out-Null
    ffmpeg -hide_banner -loglevel error -i $video.FullName -vf "select='gt(scene,0.3)',showinfo" -vsync vfr "$destino\frames\corte_%03d.png"
}

# Subtitulos de los tutoriales citados en docs/03 (solo texto, sin video)
foreach ($id in 'qGhhl_mp5Pk', 'gR6hWp8y09M') {
    yt-dlp --js-runtimes node --skip-download --write-auto-subs --sub-langs "en.*" -o "$destino\%(id)s.%(ext)s" "https://www.youtube.com/watch?v=$id"
}

Write-Host "Listo: $destino (esa carpeta esta en .gitignore)"
