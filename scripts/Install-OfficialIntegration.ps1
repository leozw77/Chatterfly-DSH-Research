param(
    [string]$Root = 'D:\chatgpt\DeepSeekHarness',
    [string]$InstallRoot = 'C:\Program Files (x86)\Chatterfly',
    [string]$Profile = 'web',
    [int]$Port = 3080,
    [string]$DshBin = 'dsh',
    [switch]$CheckOnly,
    [switch]$NoStart
)

$ErrorActionPreference = 'Stop'

function Resolve-CommandPath {
    param([string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $cmd) { return $null }
    return $cmd.Source
}

function Find-Payload {
    param([string]$RootPath)

    if (-not (Test-Path -LiteralPath $RootPath)) {
        throw "Chatterfly install root not found: $RootPath"
    }

    $candidates = Get-ChildItem -LiteralPath $RootPath -Directory |
        ForEach-Object {
            $manifest = Join-Path $_.FullName 'dsh-ime\manifest.json'
            if (Test-Path -LiteralPath $manifest) {
                [pscustomobject]@{
                    VersionDir = $_.Name
                    Base       = Join-Path $_.FullName 'dsh-ime'
                    Manifest   = $manifest
                }
            }
        }

    if (-not $candidates) {
        throw "No dsh-ime payload found under $RootPath"
    }

    $chosen = $candidates |
        Sort-Object {
            try { [version]$_.VersionDir } catch { [version]'0.0.0.0' }
        } -Descending |
        Select-Object -First 1

    $manifestData = Get-Content -LiteralPath $chosen.Manifest -Raw | ConvertFrom-Json

    return [pscustomobject]@{
        ChatterflyVersion = $chosen.VersionDir
        PluginVersion     = $manifestData.version
        MainPlugin        = Join-Path $chosen.Base 'plugins\dsh-ime.tgz'
        WebPlugin         = Join-Path $chosen.Base 'plugins\dsh-chatterfly-web.tgz'
        Installer         = Join-Path $chosen.Base 'scripts\install-dsh-ime.mjs'
        CheckEnv          = Join-Path $chosen.Base 'scripts\check-env.mjs'
    }
}

$node = Resolve-CommandPath 'node'
$pnpm = Resolve-CommandPath 'pnpm'
$dsh = Resolve-CommandPath $DshBin
$payload = Find-Payload -RootPath $InstallRoot

$summary = [pscustomobject]@{
    Root               = $Root
    Profile            = $Profile
    Port               = $Port
    Node               = $node
    Pnpm               = $pnpm
    Dsh                = $dsh
    ChatterflyVersion  = $payload.ChatterflyVersion
    PluginVersion      = $payload.PluginVersion
    MainPlugin         = $payload.MainPlugin
    WebPlugin          = $payload.WebPlugin
    Installer          = $payload.Installer
}

$summary | Format-List

if ($CheckOnly) {
    if (-not $node) { Write-Warning 'node not found in PATH' }
    if (-not $pnpm) { Write-Warning 'pnpm not found in PATH' }
    if (-not $dsh) { Write-Warning "dsh command not found: $DshBin" }
    return
}

if (-not $node) { throw 'node is required and was not found in PATH' }
if (-not $pnpm) { throw 'pnpm is required and was not found in PATH' }
if (-not $dsh) { throw "DeepSeek Harness command not found: $DshBin" }

foreach ($path in $payload.MainPlugin, $payload.WebPlugin, $payload.Installer) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required Chatterfly payload file missing: $path"
    }
}

$workspace = Join-Path $Root 'workspace\Chatterfly'
$dshHome = Join-Path $Root 'home'
$temp = Join-Path $Root 'tmp'

New-Item -ItemType Directory -Force -Path $Root, $workspace, $dshHome, $temp | Out-Null

$env:DSH_HOME = $dshHome
$env:TEMP = $temp
$env:TMP = $temp

$args = @(
    $payload.Installer,
    '--workspace', $workspace,
    '--profile', $Profile,
    '--port', [string]$Port,
    '--dsh-bin', $dsh,
    '--plugin-tgz', $payload.MainPlugin,
    '--web-tgz', $payload.WebPlugin
)

if ($NoStart) {
    $args += '--no-start'
}

Write-Host 'Running Tencent-shipped install-dsh-ime.mjs against the local DSH profile...'
& $node @args

if ($LASTEXITCODE -ne 0) {
    throw "Tencent installer exited with code $LASTEXITCODE"
}

Write-Host ''
Write-Host 'Install command completed.'
Write-Host "DSH_HOME: $dshHome"
Write-Host "Workspace: $workspace"
Write-Host "Health URL: http://127.0.0.1:$Port/chatterfly/v1/health"
