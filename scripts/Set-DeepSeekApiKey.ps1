param(
    [string]$DshHome = 'D:\chatgpt\DeepSeekHarness\home'
)

$ErrorActionPreference = 'Stop'
$nl = [Environment]::NewLine

$credentialPath = Join-Path $DshHome '.credentials.yaml'
New-Item -ItemType Directory -Force -Path $DshHome | Out-Null

$secure = Read-Host 'DeepSeek API Key (input hidden)' -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)

try {
    $key = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)

    if ([string]::IsNullOrWhiteSpace($key)) {
        throw 'API Key cannot be empty.'
    }

    if (Test-Path -LiteralPath $credentialPath) {
        $content = [IO.File]::ReadAllText($credentialPath, [Text.Encoding]::UTF8)
    } else {
        $content = 'version: 1' + $nl
    }

    $escaped = $key.Replace("'", "''")
    $line = "  DEEPSEEK_API_KEY: '$escaped'"

    if ($content -match '(?m)^refs:\s*$') {
        if ($content -match '(?m)^\s{2}DEEPSEEK_API_KEY\s*:') {
            $content = [regex]::Replace(
                $content,
                '(?m)^\s{2}DEEPSEEK_API_KEY\s*:.*$',
                [Text.RegularExpressions.MatchEvaluator]{ param($m) $line },
                1
            )
        } else {
            $content = [regex]::Replace(
                $content,
                '(?m)^refs:\s*$',
                ('refs:' + $nl + $line),
                1
            )
        }
    } elseif ($content -match '(?m)^records:\s*$') {
        $content = [regex]::Replace(
            $content,
            '(?m)^records:\s*$',
            ('refs:' + $nl + $line + $nl + 'records:'),
            1
        )
    } else {
        if (-not $content.EndsWith($nl)) {
            $content += $nl
        }
        $content += 'refs:' + $nl + $line + $nl
    }

    $tmp = "$credentialPath.tmp"
    [IO.File]::WriteAllText(
        $tmp,
        $content,
        [Text.UTF8Encoding]::new($false)
    )
    Move-Item -Force -LiteralPath $tmp -Destination $credentialPath

    Write-Host 'Saved DEEPSEEK_API_KEY to DSH credential store.'
    Write-Host "Path: $credentialPath"
    Write-Host 'The key value was not printed.'
}
finally {
    if ($ptr -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
    $key = $null
}
