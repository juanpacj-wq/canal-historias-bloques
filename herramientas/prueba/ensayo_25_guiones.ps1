# Ensayo de la cadena voz -> ritmo -> tiempos -> planos -> subtitulos sobre TODOS los guiones,
# con la voz sintetica de Windows y tres trabajos a la vez (simula varios chats).
# No toca la carpeta videos/: todo queda en la carpeta de salida.
# Uso:  powershell -ExecutionPolicy Bypass -File herramientas\prueba\ensayo_25_guiones.ps1 -Salida C:\ruta\temporal
# Este archivo va sin tildes a proposito (PowerShell 5.1).

param(
    [Parameter(Mandatory = $true)][string]$Salida,
    [int]$Paralelo = 3,
    [string]$Modelo = 'small.en'
)

$ErrorActionPreference = 'Stop'
$herramientas = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$raiz = Split-Path -Parent $herramientas
$py = Join-Path $herramientas '.venv\Scripts\python.exe'
New-Item -ItemType Directory -Force $Salida | Out-Null

$guiones = Get-ChildItem (Join-Path $raiz 'guiones') -Filter '0*.md' | Sort-Object Name

$trabajo = {
    param($md, $py, $herramientas, $Salida, $Modelo)
    $ErrorActionPreference = 'Continue'
    $nombre = [IO.Path]::GetFileNameWithoutExtension($md)
    $txt = [IO.Path]::ChangeExtension($md, '.txt')
    $dir = Join-Path $Salida $nombre
    New-Item -ItemType Directory -Force $dir | Out-Null
    $registro = Join-Path $dir 'registro.txt'
    $estado = 'OK'
    try {
        Add-Type -AssemblyName System.Speech
        $s = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $v = $s.GetInstalledVoices() | Where-Object { $_.Enabled -and $_.VoiceInfo.Culture.Name -like 'en-*' } | Select-Object -First 1
        if ($v) { $s.SelectVoice($v.VoiceInfo.Name) }
        $s.SetOutputToWaveFile((Join-Path $dir 'voz_original.wav'))
        $s.Speak((Get-Content $txt -Raw -Encoding UTF8).ToLower())
        $s.Dispose()
        & $py (Join-Path $herramientas 'ritmo.py') (Join-Path $dir 'voz_original.wav') (Join-Path $dir 'voz.wav') --guion $txt --ppm 230 *>> $registro
        if ($LASTEXITCODE -ne 0) { throw 'ritmo.py fallo' }
        & $py (Join-Path $herramientas 'transcribir.py') (Join-Path $dir 'voz.wav') --guion $txt --modelo $Modelo --salida (Join-Path $dir 'palabras.json') *>> $registro
        if ($LASTEXITCODE -ne 0) { throw 'transcribir.py fallo' }
        & $py (Join-Path $herramientas 'planos_tiempos.py') --guion $md --palabras (Join-Path $dir 'palabras.json') --audio (Join-Path $dir 'voz.wav') --salida (Join-Path $dir 'planos.json') *>> $registro
        if ($LASTEXITCODE -ne 0) { throw 'planos_tiempos.py fallo' }
        & $py (Join-Path $herramientas 'subtitulos.py') --palabras (Join-Path $dir 'palabras.json') --salida (Join-Path $dir 'subtitulos.ass') *>> $registro
        if ($LASTEXITCODE -ne 0) { throw 'subtitulos.py fallo' }
    } catch {
        $estado = "FALLO: $($_.Exception.Message)"
    }
    $avisos = @(Select-String -Path $registro -Pattern 'AVISO' -ErrorAction SilentlyContinue).Count
    $dur = ''; $planos = ''
    $pj = Join-Path $dir 'planos.json'
    if (Test-Path $pj) { $j = Get-Content $pj -Raw -Encoding UTF8 | ConvertFrom-Json; $dur = $j.duracion; $planos = $j.planos.Count }
    [pscustomobject]@{ Guion = $nombre; Estado = $estado; Avisos = $avisos; Duracion = $dur; Planos = $planos }
}

$pendientes = New-Object System.Collections.Queue
$guiones | ForEach-Object { $pendientes.Enqueue($_.FullName) }
$activos = @(); $resultados = @()
while ($pendientes.Count -gt 0 -or $activos.Count -gt 0) {
    while ($pendientes.Count -gt 0 -and $activos.Count -lt $Paralelo) {
        $activos += Start-Job -ScriptBlock $trabajo -ArgumentList $pendientes.Dequeue(), $py, $herramientas, $Salida, $Modelo
    }
    $listo = Wait-Job -Job $activos -Any
    $resultados += Receive-Job $listo
    Remove-Job $listo
    $activos = @($activos | Where-Object { $_.Id -ne $listo.Id })
}
$resultados | Sort-Object Guion | Select-Object Guion, Estado, Avisos, Duracion, Planos | Format-Table -AutoSize | Out-String -Width 200 | Tee-Object (Join-Path $Salida 'resumen.txt')
