# 医生列表接口测试
# 依赖 common.ps1 提供的 Invoke-Api / Write-TestResult

function Invoke-DoctorsTests {
    $all = Invoke-Api -Method GET -Path '/api/doctors'
    $allCount = @($all.Json.data).Count
    Write-TestResult 'DOC-01' '医生列表返回 5 条' (
        $all.Status -eq 200 -and $all.Json.code -eq 0 -and $allCount -eq 5
    ) ("HTTP {0}, count={1}" -f $all.Status, $allCount)

    Write-TestResult 'DOC-02' '响应不含 password 字段' (
        $all.Status -eq 200 -and ($all.Text -notmatch '"password"')
    ) ("password 出现: {0}" -f [bool]($all.Text -match '"password"'))

    $active = Invoke-Api -Method GET -Path '/api/doctors?active=true'
    $activeCount = @($active.Json.data).Count
    Write-TestResult 'DOC-03' 'active=true 仅返回 4 条' (
        $active.Status -eq 200 -and $active.Json.code -eq 0 -and $activeCount -eq 4
    ) ("HTTP {0}, count={1}" -f $active.Status, $activeCount)

    $bad = Invoke-Api -Method GET -Path '/api/doctors?active=abc'
    Write-TestResult 'DOC-04' '非法参数返回 400 + 业务码' (
        $bad.Status -eq 400 -and $bad.Json.code -eq 40000 -and $bad.Json.message -like '*active*'
    ) ("HTTP {0}, body={1}" -f $bad.Status, $bad.Text)
}
