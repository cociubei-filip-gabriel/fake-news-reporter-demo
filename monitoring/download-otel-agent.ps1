$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$agentPath = Join-Path $scriptDir "opentelemetry-javaagent.jar"
$url = "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar"

Write-Host "Downloading OpenTelemetry Java agent..."
Invoke-WebRequest -Uri $url -OutFile $agentPath
Write-Host "Saved agent to $agentPath"
