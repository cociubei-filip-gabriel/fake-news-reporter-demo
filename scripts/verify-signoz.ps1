param(
    [string]$BaseUrl = "http://localhost:8085",
    [int]$Requests = 10,
    [int]$DelayMs = 300
)

$ErrorActionPreference = "Stop"

$endpoints = @("/", "/reports", "/report")

Write-Host "Sending $Requests synthetic requests to $BaseUrl to generate logs..."
for ($i = 1; $i -le $Requests; $i++) {
    $endpoint = $endpoints[($i - 1) % $endpoints.Count]
    $uri = "$BaseUrl$endpoint"

    try {
        $response = Invoke-WebRequest -Uri $uri -Method GET -UseBasicParsing
        Write-Host "[$i/$Requests] GET $endpoint -> $($response.StatusCode)"
    }
    catch {
        Write-Warning "[$i/$Requests] GET $endpoint failed: $($_.Exception.Message)"
    }

    Start-Sleep -Milliseconds $DelayMs
}

Write-Host "Done. Check SigNoz Logs for service.name=fake-news-reporter"
