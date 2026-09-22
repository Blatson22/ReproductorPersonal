$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $root "backend.pid"

if (Test-Path $pidFile) {
    $procId = Get-Content $pidFile -ErrorAction SilentlyContinue
    if ($procId -and (Get-Process -Id $procId -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $procId -Force
        Write-Output "Backend (PID $procId) detenido."
    } else {
        Write-Output "El PID guardado ya no estaba vivo."
    }
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
} else {
    Write-Output "No hay backend.pid — ¿lo arrancaste con start.ps1?"
}