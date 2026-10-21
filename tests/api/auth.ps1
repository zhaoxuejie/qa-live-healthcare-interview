# 患者认证接口测试
# 依赖 common.ps1 提供的 Invoke-Api / New-JsonFile / Write-TestResult

function Invoke-AuthTests {
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ('qa-api-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    $stamp = Get-Date -Format 'HHmmss'
    $user = 'api_test_' + $stamp
    $weakUser = 'api_weak_' + $stamp
    $missingUser = 'api_missing_' + $stamp

    try {
        $registerBody = New-JsonFile $dir 'register.json' @{
            username = $user
            password = '123456'
            name     = '接口测试患者'
            birthday = '1995-05-20'
        }

        $reg = Invoke-Api -Method POST -Path '/api/auth/patient/register' -BodyPath $registerBody
        Write-TestResult 'AUTH-01' '注册成功返回 201 + token' (
            $reg.Status -eq 201 -and $reg.Json.code -eq 0 -and -not [string]::IsNullOrEmpty($reg.Json.data.token)
        ) ("HTTP {0}, tokenLen={1}" -f $reg.Status, ([string]$reg.Json.data.token).Length)

        $dup = Invoke-Api -Method POST -Path '/api/auth/patient/register' -BodyPath $registerBody
        Write-TestResult 'AUTH-02' '重复用户名返回 409' (
            $dup.Status -eq 409 -and $dup.Json.code -eq 40900
        ) ("HTTP {0}, body={1}" -f $dup.Status, $dup.Text)

        $weakBody = New-JsonFile $dir 'weak.json' @{
            username = $weakUser
            password = '12345'
            name     = '弱密码'
        }
        $weak = Invoke-Api -Method POST -Path '/api/auth/patient/register' -BodyPath $weakBody
        Write-TestResult 'AUTH-03' '密码不足 6 位返回 400' (
            $weak.Status -eq 400 -and $weak.Json.code -eq 40000
        ) ("HTTP {0}, body={1}" -f $weak.Status, $weak.Text)

        $missingBody = New-JsonFile $dir 'missing.json' @{
            username = $missingUser
            password = '123456'
        }
        $missing = Invoke-Api -Method POST -Path '/api/auth/patient/register' -BodyPath $missingBody
        Write-TestResult 'AUTH-04' '缺少姓名返回 400' (
            $missing.Status -eq 400 -and $missing.Json.code -eq 40000
        ) ("HTTP {0}, body={1}" -f $missing.Status, $missing.Text)

        $loginBody = New-JsonFile $dir 'login.json' @{
            username = $user
            password = '123456'
        }
        $login = Invoke-Api -Method POST -Path '/api/auth/patient/login' -BodyPath $loginBody
        $token = [string]$login.Json.data.token
        Write-TestResult 'AUTH-05' '登录成功返回 token' (
            $login.Status -eq 200 -and $login.Json.code -eq 0 -and $token.Length -ge 32
        ) ("HTTP {0}, tokenLen={1}" -f $login.Status, $token.Length)

        $wrongBody = New-JsonFile $dir 'wrong.json' @{
            username = $user
            password = 'wrong-password'
        }
        $wrong = Invoke-Api -Method POST -Path '/api/auth/patient/login' -BodyPath $wrongBody
        Write-TestResult 'AUTH-06' '密码错误返回 401' (
            $wrong.Status -eq 401 -and $wrong.Json.code -eq 40100 -and $wrong.Json.message -eq '用户名或密码错误'
        ) ("HTTP {0}, body={1}" -f $wrong.Status, $wrong.Text)

        $unknownBody = New-JsonFile $dir 'unknown.json' @{
            username = ('no_such_' + $stamp)
            password = '123456'
        }
        $unknown = Invoke-Api -Method POST -Path '/api/auth/patient/login' -BodyPath $unknownBody
        Write-TestResult 'AUTH-07' '不存在用户返回 401 且文案一致' (
            $unknown.Status -eq 401 -and $unknown.Json.message -eq '用户名或密码错误'
        ) ("HTTP {0}, body={1}" -f $unknown.Status, $unknown.Text)

        $authHeaders = @('Authorization: Bearer ' + $token)
        $me = Invoke-Api -Method GET -Path '/api/auth/patient/me' -Headers $authHeaders
        Write-TestResult 'AUTH-08' '有效 token 获取当前用户' (
            $me.Status -eq 200 -and $me.Json.code -eq 0 -and $me.Json.data.username -eq $user
        ) ("HTTP {0}, username={1}" -f $me.Status, $me.Json.data.username)

        $meNoToken = Invoke-Api -Method GET -Path '/api/auth/patient/me'
        Write-TestResult 'AUTH-09' '无 token 返回 401' (
            $meNoToken.Status -eq 401 -and $meNoToken.Json.code -eq 40100
        ) ("HTTP {0}" -f $meNoToken.Status)

        $meForged = Invoke-Api -Method GET -Path '/api/auth/patient/me' -Headers @('Authorization: Bearer forged-token')
        Write-TestResult 'AUTH-10' '伪造 token 返回 401' (
            $meForged.Status -eq 401 -and $meForged.Json.code -eq 40100
        ) ("HTTP {0}" -f $meForged.Status)

        $logout = Invoke-Api -Method POST -Path '/api/auth/patient/logout' -Headers $authHeaders
        Write-TestResult 'AUTH-11' '登出返回 204' (
            $logout.Status -eq 204
        ) ("HTTP {0}" -f $logout.Status)

        $meAfterLogout = Invoke-Api -Method GET -Path '/api/auth/patient/me' -Headers $authHeaders
        Write-TestResult 'AUTH-12' '登出后 token 失效返回 401' (
            $meAfterLogout.Status -eq 401
        ) ("HTTP {0}" -f $meAfterLogout.Status)
    }
    finally {
        Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
