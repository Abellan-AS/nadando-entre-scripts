# ========================================================
#                ..MONITOR SCRIPT..
# Monitorización de Hardware y OS
# Administración de Sistemas (ASIR) / ISO / Uso Libre
# ========================================================

Function Get-SystemStatus {
    Clear-Host
    # Carga de variables de entorno
    $HostName = $env:COMPUTERNAME
    $User = $env:USERNAME
    $OS = Get-CimInstance Win32_OperatingSystem
    $Uptime = (Get-Date) - $OS.LastBootUpTime
    
    # Verificación de nivel de privilegios
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # CABECERA ESTÁNDAR
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "  MONITOR DEL SISTEMA" -ForegroundColor White
    Write-Host "  $($HostName) | $($User)" -ForegroundColor Gray
    Write-Host "  NIVEL ACCESO: $(if($IsAdmin){'ADMINISTRATOR'}else{'STANDARD USER'})" -ForegroundColor $(if($IsAdmin){'Green'}else{'Yellow'})
    Write-Host "  $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Gray
    Write-Host "======================================================" -ForegroundColor Cyan

    # 1. ESTADO DEL SISTEMA Y UPTIME
    Write-Host " [+] OS: $($OS.Caption) (v$($OS.Version))" -ForegroundColor WHITE
    Write-Host " [+] Tiempo de Actividad: $($Uptime.Days)d $($Uptime.Hours)h $($Uptime.Minutes)m" -ForegroundColor White

    # 2. PROCESADOR (CPU)
    $cpu = Get-CimInstance Win32_Processor
    Write-Host " [CPU] > $($cpu.Name.Trim())" -ForegroundColor Yellow
    Write-Host "       Carga: $($cpu.LoadPercentage)% | Frecuencia: $($cpu.CurrentClockSpeed)MHz" -ForegroundColor White

    # 3. MEMORIA FÍSICA (RAM)
    $totalRam = [Math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
    $freeRam = [Math]::Round($OS.FreePhysicalMemory / 1MB, 2)
    $usedRam = $totalRam - $freeRam
    $perc = [Math]::Round(($usedRam / $totalRam) * 100, 1)
    Write-Host " [RAM] > $usedRam GB / $totalRam GB ($perc% en uso)" -ForegroundColor Green

    # 4. CONTROLADOR GRÁFICO (GPU)
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    Write-Host " [GPU] > $($gpu.Name)" -ForegroundColor Magenta

    # 5. UNIDADES DE DISCO (STORAGE)
    Write-Host " [HDD] > Unidades Lógicas Detectadas:" -ForegroundColor green
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        $size = [Math]::Round($_.Size / 1GB, 2)
        $free = [Math]::Round($_.FreeSpace / 1GB, 2)
        Write-Host "        - Volumen $($_.DeviceID) -> $free GB libres de $size GB" -ForegroundColor WHITE
    }

    # 6. MOTHERBOARD (HW BASE)
    $board = Get-CimInstance Win32_BaseBoard
    Write-Host " [MB]  > $($board.Manufacturer) $($board.Product)" -ForegroundColor Cyan

    # 7. CONFIGURACIÓN DE RED (IPv4)
    $net = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127*" } | Select-Object -First 1
    Write-Host " [NET] > IPv4 Actual: $($net.IPAddress) | Interface: $($net.InterfaceAlias)" -ForegroundColor green

    # 8. FIRMWARE (BIOS/UEFI)
    $bios = Get-CimInstance Win32_BIOS
    Write-Host " [BIOS]> Versión: $($bios.SMBIOSBIOSVersion) | Fabricante: $($bios.Manufacturer)" -ForegroundColor yellow

    # 9. CARGA DE TRABAJO (TOP 3 PROCESSES)
    Write-Host " [TOP] > Procesos con mayor consumo de RAM:" -ForegroundColor Red
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 3 | ForEach-Object {
        Write-Host "        * $($_.Name): $([Math]::Round($_.WorkingSet64 / 1MB, 0)) MB" -ForegroundColor Gray
    }

    # 10. SEGURIDAD (ENDPOINT STATUS)
    try {
        $av = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction Stop
        Write-Host " [SEC] > Antivirus: $($av.displayName) (Activo)" -ForegroundColor Green
    } catch {
        Write-Host " [SEC] > Estado de Seguridad: No se pudo consultar WMI." -ForegroundColor Red
    }

    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "  EJECUTANDO MONITOR CADA 10 SEGUNDOS" -ForegroundColor DarkGray
    Write-Host "  PRESIONA CTRL+C PARA TERMINAR" -ForegroundColor DarkGray
}

# Inicio del bucle infinito para monitorización en tiempo real
while($true) {
    Get-SystemStatus
    Start-Sleep -Seconds 10
}