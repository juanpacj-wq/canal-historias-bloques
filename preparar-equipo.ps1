# Prepara un equipo Windows nuevo para producir los videos.
# Uso, desde la raiz del proyecto, en PowerShell:
#   powershell -ExecutionPolicy Bypass -File .\preparar-equipo.ps1
# Opciones:
#   -SoloRevisar   No instala nada; solo informa que falta.
#   -SinPrueba     No corre la prueba de punta a punta de las herramientas.
# Este archivo va sin tildes a proposito, para que PowerShell 5.1 lo lea bien.

param(
    [switch]$SoloRevisar,
    [switch]$SinPrueba
)

$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $raiz

$resultados = New-Object System.Collections.Generic.List[object]
function Anotar($nombre, $ok, $detalle) {
    $resultados.Add([pscustomobject]@{ Paso = $nombre; Estado = $(if ($ok) { 'LISTO' } else { 'FALTA' }); Detalle = $detalle })
}
function Existe($comando) {
    return [bool](Get-Command $comando -ErrorAction SilentlyContinue)
}
function RefrescarPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

Write-Host ''
Write-Host '== 1. Avisos previos ==' -ForegroundColor Cyan
if ($env:USERPROFILE -match ' ') {
    Write-Host 'AVISO: la ruta de tu perfil de Windows tiene un espacio.' -ForegroundColor Yellow
    Write-Host '       El archivo mcp.bat de Roblox Studio falla en ese caso (reporte de la comunidad).'
    Write-Host '       Si la conexion MCP no funciona, crea un usuario de Windows sin espacios.'
    Anotar 'Perfil de Windows sin espacios' $false $env:USERPROFILE
} else {
    Anotar 'Perfil de Windows sin espacios' $true $env:USERPROFILE
}
$memGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$nota = if ($memGB -ge 30) { 'alcanza para 3 o 4 ventanas de Studio (estimacion)' } elseif ($memGB -ge 16) { 'alcanza para 2 ventanas de Studio (estimacion)' } else { 'usa el plan B: una sola ventana de Studio' }
Anotar 'Memoria' ($memGB -ge 16) "$memGB GB: $nota"
$gpu = (Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name) -join '; '
Anotar 'Tarjeta grafica' $true $gpu

Write-Host ''
Write-Host '== 2. Programas ==' -ForegroundColor Cyan
$paquetes = @(
    @{ Id = 'Git.Git';              Comando = 'git';    Nombre = 'Git' },
    @{ Id = 'Python.Python.3.13';   Comando = 'python'; Nombre = 'Python 3.13' },
    @{ Id = 'Gyan.FFmpeg';          Comando = 'ffmpeg'; Nombre = 'FFmpeg' },
    @{ Id = 'OpenJS.NodeJS.LTS';    Comando = 'node';   Nombre = 'Node.js' },
    @{ Id = 'Anthropic.ClaudeCode'; Comando = 'claude'; Nombre = 'Claude Code' },
    @{ Id = 'Roblox.RobloxStudio';  Comando = $null;    Nombre = 'Roblox Studio'; Ruta = "$env:LOCALAPPDATA\Roblox\Versions" }
)
function Instalado($p) {
    if ($p.Comando) { return (Existe $p.Comando) }
    if ($p.Nombre -eq 'Roblox Studio') {
        return [bool](Get-ChildItem $p.Ruta -Recurse -Filter RobloxStudioBeta.exe -ErrorAction SilentlyContinue | Select-Object -First 1)
    }
    return (Test-Path $p.Ruta)
}
if (-not (Existe 'winget')) {
    Write-Host 'No se encontro winget. Instala "App Installer" desde Microsoft Store y vuelve a correr este script.' -ForegroundColor Red
    Anotar 'winget' $false 'No esta instalado'
} else {
    foreach ($p in $paquetes) {
        if (Instalado $p) {
            Write-Host "$($p.Nombre): ya esta instalado."
        } elseif ($SoloRevisar) {
            Write-Host "$($p.Nombre): falta." -ForegroundColor Yellow
        } else {
            Write-Host "$($p.Nombre): instalando..." -ForegroundColor Yellow
            winget install --id $p.Id -e --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
            RefrescarPath
        }
        Anotar $p.Nombre (Instalado $p) $p.Id
    }
}

Write-Host ''
Write-Host '== 3. Entorno de Python de las herramientas ==' -ForegroundColor Cyan
$py = Join-Path $raiz 'herramientas\.venv\Scripts\python.exe'
if (-not (Test-Path $py) -and -not $SoloRevisar -and (Existe 'python')) {
    python -m venv (Join-Path $raiz 'herramientas\.venv')
}
if ((Test-Path $py) -and -not $SoloRevisar) {
    & $py -m pip install --quiet --upgrade pip
    & $py -m pip install --quiet -r (Join-Path $raiz 'herramientas\requirements.txt')
}
Anotar 'Entorno herramientas\.venv' (Test-Path $py) $py

Write-Host ''
Write-Host '== 4. Prueba de las herramientas ==' -ForegroundColor Cyan
if ($SoloRevisar -or $SinPrueba -or -not (Test-Path $py) -or -not (Existe 'ffmpeg')) {
    Write-Host 'Se omite la prueba.'
    Anotar 'Prueba de punta a punta' $false 'No se corrio'
} else {
    Write-Host 'Corriendo la prueba (tarda unos minutos; la primera vez descarga el modelo de transcripcion, unos 480 MB)...'
    & powershell -ExecutionPolicy Bypass -File (Join-Path $raiz 'herramientas\prueba\ejecutar_prueba.ps1') -SinExtras
    $okPrueba = ($LASTEXITCODE -eq 0)
    Anotar 'Prueba de punta a punta' $okPrueba 'herramientas\prueba\informe_revisar.txt'
}

Write-Host ''
Write-Host '== 5. Conexion de Claude Code con Roblox Studio ==' -ForegroundColor Cyan
$mcpBat = Join-Path $env:LOCALAPPDATA 'Roblox\mcp.bat'
$hayBat = Test-Path $mcpBat
Anotar 'mcp.bat de Studio' $hayBat $(if ($hayBat) { $mcpBat } else { 'Aparece despues de activar "Enable Studio as MCP server" dentro de Studio' })
$registrado = $false
if (Existe 'claude') {
    $lista = (& claude mcp list 2>$null | Out-String)
    $registrado = $lista -match 'Roblox_Studio'
    if (-not $registrado -and $hayBat -and -not $SoloRevisar) {
        & claude mcp add --transport stdio --scope user Roblox_Studio -- cmd.exe /c "%LOCALAPPDATA%\Roblox\mcp.bat"
        $lista = (& claude mcp list 2>$null | Out-String)
        $registrado = $lista -match 'Roblox_Studio'
    }
}
Anotar 'Servidor MCP registrado en Claude Code' $registrado 'claude mcp list'

Write-Host ''
Write-Host '== Resumen ==' -ForegroundColor Cyan
$resultados | Format-Table -AutoSize -Wrap

Write-Host 'Pasos que solo puedes hacer tu, en este orden:' -ForegroundColor Cyan
Write-Host ' 1. Abre Roblox Studio e inicia sesion con tu cuenta de Roblox.'
Write-Host ' 2. Crea un lugar con la plantilla Baseplate y guardalo como archivo (Archivo, Guardar en archivo como).'
Write-Host ' 3. Assistant, menu "...", Manage MCP Servers, activa "Enable Studio as MCP server".'
Write-Host '    Revisa el interruptor "Data access": apagado, si no quieres compartir tus prompts con Roblox.'
Write-Host ' 4. Vuelve a correr este script para que registre el servidor MCP en Claude Code.'
Write-Host ' 5. Abre "claude" en esta carpeta, escribe /mcp y confirma que Roblox_Studio aparece conectado.'
Write-Host ' 6. Sigue la guia docs\10-produccion-en-paralelo.md, seccion "Primer dia en el equipo de casa".'
