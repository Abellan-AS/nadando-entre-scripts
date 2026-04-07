# ========================================================
#                 ..MODO INVISIBLE..
# Eliminación de huellas y artefactos locales
# Administración de Sistemas (ASIR) / ISO / Uso Libre
# ========================================================

Function Activar-ModoInvisible {
    Clear-Host
    
    # 0. Verificación de Privilegios de Administrador
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "[!] ERROR: Se requieren permisos de Administrador para limpiar el Registro y los Logs." -ForegroundColor Red
        return
    }

    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "                      GHOSTMODE                       " -ForegroundColor White -BackgroundColor DarkMagenta
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ""

    # 1. Historial de comandos de la consola (PSReadline)
    $RutaHistorial = (Get-PSReadlineOption).HistorySavePath
    if (Test-Path $RutaHistorial) { 
        Clear-Content $RutaHistorial
        Write-Host "[+] Historial de PowerShell: ELIMINADO" -ForegroundColor Green
    }

    # 2. Archivos Recientes, JumpLists y Accesos Directos
    $RutasRecientes = @(
        "$env:APPDATA\Microsoft\Windows\Recent\*",
        "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*",
        "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations\*"
    )
    foreach ($ruta in $RutasRecientes) {
        Remove-Item -Path $ruta -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[+] Rastros de archivos recientes: LIMPIADOS" -ForegroundColor Green

    # 3. Historial del cuadro de diálogo 'Ejecutar' (MRU)
    $RutaRegistroMRU = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
    if (Test-Path $RutaRegistroMRU) {
        Remove-ItemProperty -Path $RutaRegistroMRU -Name "*" -ErrorAction SilentlyContinue
        Write-Host "[+] Historial de ventana 'Ejecutar': BORRADO" -ForegroundColor Green
    }

    # 4. Limpieza del Portapapeles (Clipboard)
    # Reiniciamos el servicio encargado del historial del portapapeles
    Get-Service -Name "cbdhsvc*" -ErrorAction SilentlyContinue | Restart-Service -Force -ErrorAction SilentlyContinue
    Write-Host "[+] Portapapeles del sistema: VACIADO" -ForegroundColor Green

    # 5. Directorio Prefetch (Programas ejecutados recientemente)
    Write-Host "[*] Vaciando carpeta Prefetch..." -ForegroundColor Yellow
    Remove-Item -Path "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
    Write-Host "[+] Registro de ejecución de apps: LIMPIADO" -ForegroundColor Green

    # 6. Registros de Eventos de Windows (Logs de Auditoría)
    Write-Host "[*] Eliminando registros del Visor de Eventos..." -ForegroundColor Yellow
    $Logs = Get-EventLog -List | Select-Object -ExpandProperty Log
    foreach ($L in $Logs) {
        Clear-EventLog -LogName $L -ErrorAction SilentlyContinue
    }
    Write-Host "[+] Todos los Event Logs: VACIADOS" -ForegroundColor Red

    # 7. Purga de la Papelera de Reciclaje
    Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "[+] Papelera de reciclaje: TOTALMENTE VACÍA" -ForegroundColor Green

    Write-Host "`n======================================================" -ForegroundColor Cyan
    Write-Host "   OPERACIÓN COMPLETADA: NO QUEDAN RASTROS LOCALES    " -ForegroundColor White -BackgroundColor DarkGreen
    Write-Host "======================================================" -ForegroundColor Cyan

    # Aviso sonoro de finalización
    [System.Media.SystemSounds]::Beep.Play()
}

# Ejecución de la función
Activar-ModoInvisible