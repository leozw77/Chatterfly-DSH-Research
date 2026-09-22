param(
    [string]$BaseUrl = 'http://127.0.0.1:3080'
)

$ErrorActionPreference = 'Stop'

$healthUrl = "$BaseUrl/chatterfly/v1/health"

try {
    $response = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 5
    $data = $response.Content | ConvertFrom-Json
} catch {
    Write-Error "Health check failed: $($_.Exception.Message)"
    exit 1
}

[pscustomobject]@{
    Ok            = $data.ok
    Plugin        = $data.plugin
    PluginVersion = $data.version
    Protocol      = $data.protocol
    DshVersion    = $data.dsh
    Workspace     = $data.workspace
    Subscribers   = $data.subscribers
    Running       = $data.running
    QueuedCount   = @($data.queued).Count
    SessionCount  = @($data.sessions).Count
} | Format-List

if ($data.ok -ne $true -or $data.plugin -ne 'chatterfly') {
    Write-Error 'Chatterfly DSH integration is not healthy.'
    exit 2
}

Write-Host 'Integration health check passed.'
