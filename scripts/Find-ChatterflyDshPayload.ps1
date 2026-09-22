param(
    [string]$InstallRoot = 'C:\Program Files (x86)\Chatterfly'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $InstallRoot)) {
    throw "Chatterfly install root not found: $InstallRoot"
}

$candidates = Get-ChildItem -LiteralPath $InstallRoot -Directory -ErrorAction Stop |
    ForEach-Object {
        $dshIme = Join-Path $_.FullName 'dsh-ime'
        $manifest = Join-Path $dshIme 'manifest.json'
        if (Test-Path -LiteralPath $manifest) {
            [pscustomobject]@{
                VersionDir = $_.Name
                DshImeDir  = $dshIme
                Manifest   = $manifest
            }
        }
    }

if (-not $candidates) {
    throw "No Chatterfly dsh-ime payload found under $InstallRoot"
}

$chosen = $candidates |
    Sort-Object {
        try { [version]$_.VersionDir } catch { [version]'0.0.0.0' }
    } -Descending |
    Select-Object -First 1

$manifestData = Get-Content -LiteralPath $chosen.Manifest -Raw | ConvertFrom-Json

$result = [pscustomobject]@{
    ChatterflyVersion = $chosen.VersionDir
    DshImeVersion     = $manifestData.version
    Manifest          = $chosen.Manifest
    MainPlugin        = Join-Path $chosen.DshImeDir 'plugins\dsh-ime.tgz'
    WebPlugin         = Join-Path $chosen.DshImeDir 'plugins\dsh-chatterfly-web.tgz'
    InstallScript     = Join-Path $chosen.DshImeDir 'scripts\install-dsh-ime.mjs'
    CheckScript       = Join-Path $chosen.DshImeDir 'scripts\check-env.mjs'
}

$result | Format-List

foreach ($name in 'MainPlugin','WebPlugin','InstallScript','CheckScript') {
    $path = $result.$name
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Warning "$name missing: $path"
    }
}
