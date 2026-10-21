# 公共函数：供 doctors.ps1 / auth.ps1 / run-all.ps1 使用（PowerShell 5.1 兼容）
# 仅依赖 curl.exe 与 PowerShell，不依赖 Node/Python/jq

$script:ApiBase = 'http://localhost:8080'
$script:Results = @()

function Set-ApiBase([string]$base) {
    $script:ApiBase = $base.TrimEnd('/')
}

function Invoke-Api {
    param(
        [string]$Method,
        [string]$Path,
        [string]$BodyPath,
        [string[]]$Headers
    )

    $outFile = [System.IO.Path]::GetTempFileName()
    $curlArgs = @('-s', '-o', $outFile, '-w', '%{http_code}', '-X', $Method, ($script:ApiBase + $Path))
    if ($BodyPath) {
        $curlArgs += @('-H', 'Content-Type: application/json', '--data-binary', ('@' + $BodyPath))
    }
    if ($Headers) {
        foreach ($h in $Headers) { $curlArgs += @('-H', $h) }
    }

    $statusText = & curl.exe @curlArgs
    $status = 0
    [void][int]::TryParse($statusText, [ref]$status)
    $text = ''
    if (Test-Path -LiteralPath $outFile) {
        $text = [System.IO.File]::ReadAllText($outFile, [System.Text.Encoding]::UTF8)
    }
    Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue

    $json = $null
    try { $json = $text | ConvertFrom-Json } catch { $json = $null }

    return [pscustomobject]@{
        Status = $status
        Text   = $text
        Json   = $json
    }
}

function New-JsonFile {
    param(
        [string]$Dir,
        [string]$Name,
        $Object
    )
    $path = Join-Path $Dir $Name
    $json = $Object | ConvertTo-Json -Compress -Depth 10
    [System.IO.File]::WriteAllText($path, $json, (New-Object System.Text.UTF8Encoding($false)))
    return $path
}

function Write-TestResult {
    param(
        [string]$Id,
        [string]$Name,
        [bool]$Pass,
        [string]$Detail
    )
    $script:Results += [pscustomobject]@{
        Id     = $Id
        Name   = $Name
        Pass   = $Pass
        Detail = $Detail
    }
    if ($Pass) {
        Write-Host ("[PASS] {0} {1}  {2}" -f $Id, $Name, $Detail)
    } else {
        Write-Host ("[FAIL] {0} {1}  {2}" -f $Id, $Name, $Detail) -ForegroundColor Red
    }
}
