# ========================================================
#                  ..MANTENIMIENTO..
# Optimización de Kernel y Limpieza de Componentes
# Administración de Sistemas (ASIR) / ISO / Uso Libre
# ========================================================

# Configuración visual
$Host.UI.RawUI.WindowTitle = "MANTENIMIENTO"
Clear-Host

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "   EJECUTANDO PROTOCOLO DE LIMPIEZA Y OPTIMIZACION    " -ForegroundColor White -BackgroundColor Blue
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# 0. Verificación de privilegios
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] ERROR: Este script requiere privilegios de ADMINISTRADOR." -ForegroundColor Red
    Write-Host "Por favor, reinicia PowerShell como administrador."
    pause
    exit
}

# 1. Limpieza de Red (DNS)
Write-Host "[1/6] REFRESCANDO CACHE DNS..." -ForegroundColor Yellow
Clear-DnsClientCache
Write-Host "      Hecho." -ForegroundColor Gray

# 2. Actualización de aplicaciones
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "[2/6] ACTUALIZANDO SOFTWARE VIA CHOCOLATEY..." -ForegroundColor Yellow
    choco upgrade all -y
} else {
    Write-Host "[2/6] Chocolatey no detectado. Saltando paso..." -ForegroundColor DarkGray
}

# 3. Limpieza de Temporales (Uso de Remove-Item)
Write-Host "[3/6] ELIMINANDO MORRALLA TEMPORAL..." -ForegroundColor Yellow
$TempFolders = $env:TEMP, "C:\Windows\Temp"
foreach ($folder in $TempFolders) {
    Get-ChildItem -Path $folder -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "      Archivos temporales purgados." -ForegroundColor Gray

# 4. Vaciado de Papelera de Reciclaje
Write-Host "[4/6] VACIANDO PAPELERA DE RECICLAJE..." -ForegroundColor Yellow
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "      Papelera vaciada." -ForegroundColor Gray

# 5. Limpieza Profunda de Windows (DISM)
Write-Host "[5/6] LIMPIANDO ALMACEN DE COMPONENTES (DISM)..." -ForegroundColor Yellow
Write-Host "      (Esto puede tardar unos minutos, no cierres la ventana)" -ForegroundColor DarkGray
Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase /NoRestart

# 6. Verificación de Integridad (SFC)
Write-Host "[6/6] ESCANEANDO ARCHIVOS DE SISTEMA (SFC)..." -ForegroundColor Yellow
sfc /scannow

# Finalización
Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host "   MANTENIMIENTO FINALIZADO - SISTEMA OPTIMIZADO      " -ForegroundColor White -BackgroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan

# Alerta Visual y de Sonido
[System.Media.SystemSounds]::Asterisk.Play()
$wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("El mantenimiento de Cyber Guardian ha finalizado correctamente.", 0, "Mantenimiento Elite", 64)

pause