$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $root "backend.pid"
$log = Join-Path $root "backend.err.log"
$py = Join-Path $root "venv\Scripts\python.exe"

if (-not (Test-Path $py)) {
    Write-Error "No se encontró el venv. Crea el entorno con: python -m venv venv"
    exit 1
}

# Idempotente: si ya había uno corriendo (lanzado por este mismo script), lo paramos primero.
if (Test-Path $pidFile) {
    $oldPid = Get-Content $pidFile -ErrorAction SilentlyContinue
    if ($oldPid) { Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue }
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}

if (Test-Path $log) { Remove-Item $log -Force }

# -PassThru da el objeto Process real: el PID exacto, sin adivinar por puerto ni cmdline.
$proc = Start-Process -FilePath $py `
    -ArgumentList "-m","uvicorn","main:app","--host","0.0.0.0","--port","8000" `
    -WorkingDirectory $root -RedirectStandardError $log -WindowStyle Hidden -PassThru

$proc.Id | Out-File -FilePath $pidFile -Encoding ascii -NoNewline
Start-Sleep -Seconds 3

if (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue) {
    Write-Output "Backend corriendo en http://localhost:8000 (PID $($proc.Id))"
} else {
    Write-Error "El backend murió al arrancar. Log:"
    Get-Content $log -ErrorAction SilentlyContinue
    exit 1
}