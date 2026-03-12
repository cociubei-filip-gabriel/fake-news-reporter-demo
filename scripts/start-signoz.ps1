$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$composeCandidates = @(
    (Join-Path $repoRoot "signoz\deploy\docker\docker-compose.yaml"),
    (Join-Path $repoRoot "signoz\deploy\docker\clickhouse-setup\docker-compose.yaml")
)

$composeFile = $composeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $composeFile) {
    Write-Error "SigNoz compose file not found. Checked: $($composeCandidates -join ', '). Ensure the signoz repository is present in .\signoz."
}

$composeDir = Split-Path -Parent $composeFile

Write-Host "Starting SigNoz stack..."
Write-Host "Using compose file: $composeFile"
Push-Location $composeDir
try {
    docker compose -f $composeFile up -d
}
finally {
    Pop-Location
}

Write-Host "SigNoz should be available at http://localhost:3301"
