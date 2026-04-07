# ========================================================
#          ..AUDITOR DE RED Y SEGURIDAD..
# Escaneo de puertos activos y detección de intrusos
# Administración de Sistemas (ASIR) / ISO / Uso Libre
# ========================================================

Function Ejecutar-Auditoria-Red {
    Clear-Host
    $HostName = $env:COMPUTERNAME
    
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "       AUDITORÍA DE SEGURIDAD ACTIVA: $HostName       " -ForegroundColor White -BackgroundColor DarkRed
    Write-Host "======================================================" -ForegroundColor Cyan

    # 1. CONEXIONES DE RED ACTIVAS (ESTILO NETSTAT PRO)
    Write-Host "`n[1] CONEXIONES TCP ESTABLECIDAS (Internet/LAN):" -ForegroundColor Yellow
    $Conexiones = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | 
                  Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess
    
    foreach ($c in $Conexiones) {
        $Proceso = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
        Write-Host "  > Proceso: $($Proceso.Name) (PID: $($c.OwningProcess))" -ForegroundColor Gray
        Write-Host "    Local: $($c.LocalAddress):$($c.LocalPort) <--> Remoto: $($c.RemoteAddress):$($c.RemotePort)" -ForegroundColor White
    }

    # 2. PUERTOS EN ESCUCHA (LISTENING) - Análisis de superficie de ataque
    Write-Host "`n[2] PUERTOS EN ESCUCHA (Posibles servicios abiertos):" -ForegroundColor Yellow
    Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | 
    Select-Object LocalAddress, LocalPort | Sort-Object LocalPort | ForEach-Object {
        Write-Host "  [*] Puerto Abierto: $($_.LocalPort) en $($_.LocalAddress)" -ForegroundColor Cyan
    }

    # 3. RECURSOS COMPARTIDOS (Análisis de vulnerabilidad lateral)
    Write-Host "`n[3] CARPETAS COMPARTIDAS EN RED (SMB):" -ForegroundColor Yellow
    $Shares = Get-SmbShare | Where-Object { $_.Name -notlike "*$" } # Ocultamos las administrativas C$, IPC$, etc.
    if ($Shares) {
        $Shares | ForEach-Object { Write-Host "  [!] Compartido: $($_.Name) -> $($_.Path)" -ForegroundColor Red }
    } else {
        Write-Host "  [OK] No hay recursos compartidos visibles (Hardenizado)." -ForegroundColor Green
    }

    # 4. DETECCIÓN DE INTRUSIÓN (Intentos fallidos de Login)
    # Buscamos el Evento ID 4625 en el Log de Seguridad
    Write-Host "`n[4] ÚLTIMOS INTENTOS DE ACCESO FALLIDOS (Posible Fuerza Bruta):" -ForegroundColor Yellow
    try {
        $LoginsFallidos = Get-WinEvent -FilterHashtable @{LogName='Security';ID=4625} -MaxEvents 5 -ErrorAction Stop
        $LoginsFallidos | ForEach-Object {
            Write-Host "  [ALERT] Intento fallido el: $($_.TimeCreated)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [OK] Sin intentos de intrusión registrados." -ForegroundColor Green
    }

    # 5. ESTADO DEL FIREWALL DE WINDOWS
    Write-Host "`n[5] ESTADO DEL CORTAFUEGOS (FIREWALL):" -ForegroundColor Yellow
    $Profiles = Get-NetFirewallProfile
    foreach ($p in $Profiles) {
        $Color = if($p.Enabled -eq "True") { "Green" } else { "Red" }
        Write-Host "  - Perfil $($p.Name): $(if($p.Enabled -eq 'True'){'ACTIVO'}else{'DESACTIVADO'})" -ForegroundColor $Color
    }

    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "                 REPORTE FINALIZADO                     " -ForegroundColor Gray
    Write-Host "======================================================" -ForegroundColor Cyan
}

# Ejecución
Ejecutar-Auditoria-Red