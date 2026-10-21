# 一键执行全部 curl 接口测试
# 用法：pwsh -File tests/api/run-all.ps1 [-BaseUrl http://localhost:8080]
# 退出码：0 = 全部通过；1 = 存在失败用例

param(
    [string]$BaseUrl = 'http://localhost:8080'
)

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot

. (Join-Path $here 'common.ps1')
. (Join-Path $here 'doctors.ps1')
. (Join-Path $here 'auth.ps1')

Set-ApiBase $BaseUrl

Write-Host ("API 测试开始，目标: {0}" -f $script:ApiBase)
Write-Host ('-' * 60)

Invoke-DoctorsTests
Invoke-AuthTests

Write-Host ('-' * 60)
$total = @($script:Results).Count
$passed = @($script:Results | Where-Object { $_.Pass }).Count
$failed = $total - $passed
Write-Host ("总计 {0} 条，通过 {1} 条，失败 {2} 条" -f $total, $passed, $failed) -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })

if ($failed -gt 0) {
    Write-Host '失败详情:'
    $script:Results | Where-Object { -not $_.Pass } | ForEach-Object {
        Write-Host ("  {0} {1} -> {2}" -f $_.Id, $_.Name, $_.Detail)
    }
    exit 1
}
exit 0
