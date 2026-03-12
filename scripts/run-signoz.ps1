param(
    [string]$Profile = "local",
    [string]$ServiceName = "fake-news-reporter",
    [string]$OtlpEndpoint = "http://localhost:4317",
    [string]$OtlpProtocol = "grpc"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$agentPath = Join-Path $repoRoot "monitoring\opentelemetry-javaagent.jar"
$localMavenPath = Join-Path $repoRoot ".tools\apache-maven-3.9.11\bin\mvn.cmd"
$m2Dir = Join-Path $repoRoot ".m2"
$m2Repo = Join-Path $m2Dir "repository"
$m2Settings = Join-Path $m2Dir "settings-local.xml"

if (-not (Test-Path $agentPath)) {
    Write-Error "OpenTelemetry Java agent not found at '$agentPath'. Run '.\monitoring\download-otel-agent.ps1' first."
}

$mavenCmd = $null
if (Get-Command mvn -ErrorAction SilentlyContinue) {
    $mavenCmd = "mvn"
} elseif (Test-Path $localMavenPath) {
    $mavenCmd = (Resolve-Path $localMavenPath).Path
} else {
    Write-Error "Maven was not found in PATH and no local Maven exists at '$localMavenPath'."
}

New-Item -ItemType Directory -Path $m2Repo -Force | Out-Null
@"
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <localRepository>$($m2Repo.Replace('\', '/'))</localRepository>
</settings>
"@ | Set-Content -Path $m2Settings -Encoding ASCII

$resolvedAgentPath = (Resolve-Path $agentPath).Path
$otelOptions = @(
    "-javaagent:`"$resolvedAgentPath`"",
    "-Dotel.service.name=$ServiceName",
    "-Dotel.logs.exporter=otlp",
    "-Dotel.metrics.exporter=otlp",
    "-Dotel.traces.exporter=otlp",
    "-Dotel.exporter.otlp.endpoint=$OtlpEndpoint",
    "-Dotel.exporter.otlp.protocol=$OtlpProtocol",
    "-Dotel.resource.attributes=deployment.environment=$Profile"
)

if ($env:SIGNOZ_INGESTION_KEY) {
    $otelOptions += "-Dotel.exporter.otlp.headers=signoz-ingestion-key=$($env:SIGNOZ_INGESTION_KEY)"
}

$env:MAVEN_OPTS = ($otelOptions -join " ")

Write-Host "Starting app with SigNoz OTLP export (logs, metrics, traces)..."
Write-Host "Profile: $Profile"
Write-Host "Service name: $ServiceName"
Write-Host "OTLP endpoint: $OtlpEndpoint"
Write-Host "Maven command: $mavenCmd"

& $mavenCmd "-s" $m2Settings "spring-boot:run" "-Dspring-boot.run.profiles=$Profile"
