# ========================================================
#              ..GESTOR DE BACKUP..
# Backup de Documentos con verificación hash
# Administración de Sistemas (ASIR) / ISO / Uso Libre
# ========================================================

Function Ejecutar-Backup-hash {
    [CmdletBinding()]
    Param(
        # Usamos variables de entorno para que funcione en cualquier PC
        [string]$Origen = "$env:USERPROFILE\Documents", 
        [string]$Destino = "$env:USERPROFILE\Desktop\Mis_Backups"
    )

    Clear-Host
    $Fecha = Get-Date -Format "yyyy-MM-dd_HHmm"
    $NombreArchivo = "Respaldo_Documentos_$Fecha.zip"
    $RutaFinal = Join-Path $Destino $NombreArchivo

    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "      GESTOR DE COPIAS DE SEGURIDAD UNIVERSAL         " -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "======================================================" -ForegroundColor Cyan

    # 1. Validación y creación de rutas
    # Si el origen no existe (raro en Documentos), avisamos.
    if (!(Test-Path $Origen)) {
        Write-Host "[!] ERROR: No se encuentra la carpeta de origen: $Origen" -ForegroundColor Red
        return
    }

    # Si el destino no existe (Escritorio\Mis_Backups), lo creamos nosotros.
    if (!(Test-Path $Destino)) {
        New-Item -Path $Destino -ItemType Directory -Force | Out-Null
        Write-Host "[+] Carpeta de destino creada automáticamente en el Escritorio." -ForegroundColor Gray
    }

    # 2. Proceso de Compresión
    Write-Host "`n[*] Comprimiendo contenido de: $Origen" -ForegroundColor Yellow
    try {
        # Excluimos el propio destino si está dentro del origen para evitar bucles
        Compress-Archive -Path "$Origen\*" -DestinationPath $RutaFinal -Force -ErrorAction Stop
        Write-Host "[OK] Backup creado: $NombreArchivo" -ForegroundColor Green
    } catch {
        Write-Host "[!] FALLO: Asegúrate de que no haya archivos abiertos en Documentos." -ForegroundColor Red
        return
    }

    # 3. Integridad SHA-256
    Write-Host "[*] Generando firma digital de integridad..." -ForegroundColor Yellow
    $Hash = Get-FileHash -Path $RutaFinal -Algorithm SHA256
    $Hash.Hash | Out-File -FilePath "$RutaFinal.sha256"
    Write-Host "[+] Hash SHA-256 guardado junto al archivo." -ForegroundColor Cyan

    # 4. Política de Retención (Guardar solo los últimos 3)
    $Viejos = Get-ChildItem -Path $Destino -Filter "*.zip" | Sort-Object CreationTime -Descending | Select-Object -Skip 3
    if ($Viejos) { $Viejos | Remove-Item -Force }

    Write-Host "`n======================================================" -ForegroundColor Cyan
    Write-Host "  BACKUP FINALIZADO PARA EL USUARIO: $env:USERNAME" -ForegroundColor White
    Write-Host "======================================================" -ForegroundColor Cyan
}

Ejecutar-Backup-hash