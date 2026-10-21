# API 测试指南（给 AI / 人照着执行）

> 适用项目：qa-live-healthcare-interview
> 被测版本：分支 `feature-interview-1021`（以 `git rev-parse --short HEAD` 为准）
> 配套脚本：`tests/api/run-all.ps1`（Windows）、`tests/api/run-all.sh`（Linux/Git Bash）
> 配套报告：执行完成后生成 `docs/TEST_REPORT.md`，证据放 `docs/test-evidence/`

---

## 0. 给 AI 的执行指令（可直接作为提示词）

```text
你是本项目的测试执行者。请严格按 docs/API_TEST.md 执行，不要跳步、不要修改断言来迁就结果：

1. 执行第 2 节全部环境检查；任一失败，停止并报告失败命令与输出。
2. 记录当前提交号（git rev-parse --short HEAD）与 JDK/Node/MySQL 版本。
3. 运行第 5 节的一键脚本，把完整输出保存到 docs/test-evidence/api-run-<时间戳>.log。
4. 按第 4 节用例表手工复核（至少覆盖每个接口的 1 条正向 + 1 条负向），保存关键响应片段。
5. 按第 6 节模板生成 docs/TEST_REPORT.md：每条用例写实际状态码、实际 code、关键响应、通过/失败。
6. 失败用例按第 7 节排查；若确认是产品缺陷，如实记录，不得伪造通过。
7. 完成后清理第 8 节列出的测试数据，并确认 demo_patient 仍可登录。

约束：只使用 curl + PowerShell/bash；不要把 Postman/Node/Python 作为前置依赖；所有结论必须有真实命令输出支撑。
```

---

## 1. 测试范围与前置条件

### 1.1 范围

| 接口 | 方法 | 覆盖 |
|---|---|---|
| `/api/doctors` | GET | 全量、`active=true`、字段安全、非法参数 |
| `/api/auth/patient/register` | POST | 成功、重复用户名、弱密码、缺字段 |
| `/api/auth/patient/login` | POST | 成功、错误密码、不存在用户（防枚举） |
| `/api/auth/patient/me` | GET | 有效 token、无 token、伪造 token、登出后失效 |
| `/api/auth/patient/logout` | POST | 204 幂等 |

不在本测试范围：前端 UI（由 T13/T14 的 CDP 回归覆盖）、问题提交（前端内存）、性能压测。

### 1.2 前置条件

| 项 | 要求 | 检查命令 |
|---|---|---|
| 代码 | 已检出 `feature-interview-1021` | `git rev-parse --short HEAD` |
| JDK | 17+ | `java -version` |
| Node（仅文档记录） | 18+ | `node -v` |
| MySQL | 容器 `qa-mysql` healthy，库 `qa_healthcare` 已初始化 | 见 2.1 |
| 后端 | `qa-service-user` 监听 8080 | 见 2.2 |
| 演示账号 | `demo_patient / 123456` | 见 2.3 |
| 端口 | 8080（后端）、3306（MySQL） | 见 2.2 |
| 工具 | `curl.exe`（Windows 自带）、PowerShell 5.1 | `curl.exe --version` |

数据库初始化（仅首次或重置时执行，**会清空数据**）：

```powershell
docker compose down -v
docker compose up -d
```

---

## 2. 环境检查

### 2.1 容器与数据库

```powershell
docker compose ps
docker inspect --format '{{.State.Health.Status}}' qa-mysql
docker exec qa-mysql mysql -uroot -proot_pass_123 -D qa_healthcare --default-character-set=utf8mb4 -e "SELECT COUNT(*) AS doctor_count FROM doctor; SELECT COUNT(*) AS patient_count FROM patient;"
```

期望：`qa-mysql` 为 `healthy`；`doctor_count=5`；`patient_count>=1`。

### 2.2 后端健康与端口

```powershell
curl.exe -s -w "`nHTTP %{http_code}`n" http://localhost:8080/actuator/health
Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
```

期望：`{"status":"UP"}`，HTTP 200；8080 处于 Listen。

### 2.3 演示账号可用

```powershell
$BASE = 'http://localhost:8080'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$check = Join-Path $env:TEMP 'qa-login-check.json'
[System.IO.File]::WriteAllText($check, '{"username":"demo_patient","password":"123456"}', $utf8)
curl.exe -s -o "$env:TEMP\qa-login-check-out.json" -w "%{http_code}`n" -X POST -H "Content-Type: application/json" --data-binary "@$check" "$BASE/api/auth/patient/login"
```

期望：`200`。若为 401，先确认是否执行过 `down -v` 且 `03_seed_patient.sql` 已生效。

---

## 3. 变量与请求约定

### 3.1 变量

```powershell
$BASE = 'http://localhost:8080'
$TMP  = Join-Path $env:TEMP 'qa-api-manual'
New-Item -ItemType Directory -Path $TMP -Force | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
```

### 3.2 统一响应体

```json
{"code":0,"message":"ok","data":...}
```

| code | 含义 | HTTP |
|---|---|---|
| `0` | 成功 | 200/201 |
| `40000` | 参数/请求体错误 | 400 |
| `40100` | 未登录/登录失效/用户名或密码错误 | 401 |
| `40900` | 用户名已存在 | 409 |
| `50000` | 服务端内部错误 | 500 |

### 3.3 请求体文件（关键：Windows curl 会吞内联 JSON 的引号）

**必须用文件 + `--data-binary @file`**，并用无 BOM 的 UTF-8 写入：

```powershell
[System.IO.File]::WriteAllText((Join-Path $TMP 'register.json'), '{"username":"api_manual_001","password":"123456","name":"接口测试患者","birthday":"1995-05-20"}', $utf8)
[System.IO.File]::WriteAllText((Join-Path $TMP 'login.json'),    '{"username":"demo_patient","password":"123456"}', $utf8)
[System.IO.File]::WriteAllText((Join-Path $TMP 'wrong.json'),    '{"username":"demo_patient","password":"wrong"}', $utf8)
[System.IO.File]::WriteAllText((Join-Path $TMP 'unknown.json'),  '{"username":"no_such_user","password":"123456"}', $utf8)
[System.IO.File]::WriteAllText((Join-Path $TMP 'weak.json'),     '{"username":"api_manual_weak","password":"12345","name":"弱密码"}', $utf8)
[System.IO.File]::WriteAllText((Join-Path $TMP 'missing.json'),  '{"username":"api_manual_missing","password":"123456"}', $utf8)
```

bash 等价：

```bash
BASE=http://localhost:8080
TMP=$(mktemp -d)
cat > "$TMP/login.json" <<'EOF'
{"username":"demo_patient","password":"123456"}
EOF
```

### 3.4 响应保存约定

```powershell
curl.exe -s -o (Join-Path $TMP 'out.json') -w "%{http_code}`n" ...
```

`-w` 只输出状态码；响应体在 `out.json`，后续用 `Get-Content -Encoding UTF8` 或 `ConvertFrom-Json` 断言。

---

## 4. 用例表（19 条）

> 命令中的 `$TMP`、`$BASE` 见第 3 节；每个 POST 的响应体建议用 `-o` 落盘后再断言。

| ID | 目的 | 前置 | 精确 curl 命令（PowerShell） | 期望状态码 | 期望响应断言 |
|---|---|---|---|---|---|
| DOC-01 | 医生全量列表 | 无 | `curl.exe -s -o "$TMP\docs.json" -w "%{http_code}`n" "$BASE/api/doctors"` | 200 | `code=0`；`data` 长度 **5**；含 `张伟医生` |
| DOC-02 | 响应不含密码 | DOC-01 | 对 `docs.json` 断言：`Select-String -SimpleMatch '"password"'` 无匹配 | — | 无 `password` 字段 |
| DOC-03 | 仅在诊过滤 | 无 | `curl.exe -s -o "$TMP\active.json" -w "%{http_code}`n" "$BASE/api/doctors?active=true"` | 200 | `data` 长度 **4**；不含停诊的 `doc004` |
| DOC-04 | 非法参数 | 无 | `curl.exe -s -o "$TMP\bad.json" -w "%{http_code}`n" "$BASE/api/doctors?active=abc"` | 400 | `code=40000`；`message` 含 `active` |
| DOC-05 | 中文编码 | 无 | `[System.IO.File]::ReadAllText("$TMP\docs.json", [Text.Encoding]::UTF8)` | — | 文本含 `张伟医生`、`心内科` |
| AUTH-01 | 注册成功 | 用户名未注册 | `curl.exe -s -o "$TMP\reg.json" -w "%{http_code}`n" -X POST -H "Content-Type: application/json" --data-binary "@$TMP\register.json" "$BASE/api/auth/patient/register"` | 201 | `code=0`；`data.token` 非空；无 `password_hash` |
| AUTH-02 | 重复用户名 | AUTH-01 已注册 | 重放 AUTH-01 同一请求体 | 409 | `code=40900`；`message=用户名已存在` |
| AUTH-03 | 弱密码 | 用户名未注册 | 用 `weak.json` 重放注册 | 400 | `code=40000`；`message` 含 `6-64` |
| AUTH-04 | 缺少姓名 | 用户名未注册 | 用 `missing.json` 重放注册 | 400 | `code=40000`；`message` 含 `姓名` |
| AUTH-05 | 登录成功 | 演示账号 | `curl.exe -s -o "$TMP\login-out.json" -w "%{http_code}`n" -X POST -H "Content-Type: application/json" --data-binary "@$TMP\login.json" "$BASE/api/auth/patient/login"` | 200 | `code=0`；`data.patient.username=demo_patient` |
| AUTH-06 | token 强度 | AUTH-05 | 解析 `login-out.json` 的 `data.token` | — | 长度 **≥ 32**（实际 43） |
| AUTH-07 | 密码错误 | 演示账号 | 用 `wrong.json` 重放登录 | 401 | `code=40100`；`message=用户名或密码错误` |
| AUTH-08 | 不存在用户 | 无 | 用 `unknown.json` 重放登录 | 401 | `code=40100`；`message` 与 AUTH-07 **完全一致** |
| AUTH-09 | 防枚举文案 | AUTH-07/08 | 比较两份响应 `message` | — | 字符串相等 |
| AUTH-10 | 有效 token 取用户 | AUTH-05 的 token | `curl.exe -s -o "$TMP\me.json" -w "%{http_code}`n" -H "Authorization: Bearer $TOKEN" "$BASE/api/auth/patient/me"` | 200 | `data.username=demo_patient` |
| AUTH-11 | 无 token | 无 | `curl.exe -s -o "$TMP\me-no.json" -w "%{http_code}`n" "$BASE/api/auth/patient/me"` | 401 | `code=40100` |
| AUTH-12 | 伪造 token | 无 | `curl.exe -s -o "$TMP\me-forged.json" -w "%{http_code}`n" -H "Authorization: Bearer forged-token" "$BASE/api/auth/patient/me"` | 401 | `code=40100` |
| AUTH-13 | 登出 | AUTH-05 的 token | `curl.exe -s -o "$TMP\logout.json" -w "%{http_code}`n" -X POST -H "Authorization: Bearer $TOKEN" "$BASE/api/auth/patient/logout"` | 204 | 响应体为空 |
| AUTH-14 | 登出后失效 | AUTH-13 后 | 用同一 token 重放 AUTH-10 | 401 | `code=40100` |

### 4.1 取 token 的写法（PowerShell 5.1）

```powershell
$login = Get-Content -LiteralPath (Join-Path $TMP 'login-out.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$TOKEN = $login.data.token
$TOKEN.Length
```

### 4.2 断言写法（示例）

```powershell
$r = Get-Content -LiteralPath (Join-Path $TMP 'reg.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($r.code -ne 0 -or [string]::IsNullOrEmpty($r.data.token)) { throw 'AUTH-01 失败' }
```

---

## 5. 执行方式

### 5.1 一键（推荐，Windows）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\api\run-all.ps1
```

期望输出末行：

```
总计 16 条，通过 16 条，失败 0 条
```

退出码 `0`。

### 5.2 一键（Linux / macOS / Git Bash）

```bash
API_BASE=http://localhost:8080 bash tests/api/run-all.sh
```

期望：`总计 19 条，通过 19 条，失败 0 条`，退出码 `0`。

> 本机若无 bash，可用容器复现（Docker Desktop）：
> ```powershell
> docker run --rm -v "$((Get-Location).Path)\tests\api:/tests:ro" -e API_BASE=http://host.docker.internal:8080 mysql:8.0 bash /tests/run-all.sh
> ```

### 5.3 手工逐条

1. 执行第 2 节环境检查。
2. 执行第 3.1 + 3.3 节，准备好变量与请求体文件。
3. 按第 4 节从上到下执行；每条记录：实际状态码、响应体、断言结果。
4. 对 POST 用例，先 `Get-Content ... | ConvertFrom-Json` 再断言。
5. 全部完成后进入第 6 节填写报告。

---

## 6. 结果记录模板（供 TEST_REPORT.md 使用）

```markdown
# API 测试报告

- 执行日期：YYYY-MM-DD HH:mm
- 被测提交：<git rev-parse --short HEAD>
- 环境：Windows <版本> / JDK <版本> / Node <版本> / MySQL <版本> / Spring Boot 3.5.7
- 执行方式：一键脚本 + 手工复核

## 结果汇总

| 指标 | 数值 |
|---|---|
| 用例总数 | 16 |
| 通过 | 16 |
| 失败 | 0 |
| 结论 | 通过 |

## 明细

| ID | 目的 | 期望状态码 | 实际状态码 | 实际 code | 关键响应片段 | 结果 |
|---|---|---|---|---|---|---|
| DOC-01 | 医生全量列表 | 200 | 200 | 0 | `"data":[...5 条]` | PASS |
| ... | ... | ... | ... | ... | ... | ... |

## 证据

- `docs/test-evidence/api-run-<时间戳>.log`：一键脚本完整输出
- `docs/test-evidence/<CASE-ID>.json`：关键响应体（脱敏后）
- 截图（可选）：`docs/test-evidence/*.png`

## 失败与风险

- 失败用例：无 / 列出 ID + 现象 + 初步原因
- 遗留风险：token 存 localStorage 的 XSS 风险（见 PRD R1）
```

---

## 7. 失败排查

| 现象 | 可能原因 | 排查/修复 |
|---|---|---|
| `curl: (7) Failed to connect` / HTTP 000 | 后端未启动或端口不对 | 检查 8080 Listen；重启 `mvnw spring-boot:run` |
| `/actuator/health` 非 UP，`db` DOWN | MySQL 未启动/密码错 | `docker compose ps`；看 `application.properties` |
| 登录 demo 返回 401 | 库被重建但种子未执行 | 确认 `03_seed_patient.sql` 在 init 目录；`down -v` 后重建 |
| 注册返回 400 "请求体格式不正确" | 内联 JSON 被 Windows shell 吞引号 | 改用 `--data-binary @file`（第 3.3 节） |
| 注册返回 400 "用户名需为..." | 用户名不满足 4-32 位规则 | 换合法用户名（字母/数字/`_`/`-`） |
| 重复用户名返回 409 | 用例复用旧用户名 | 用时间戳生成新用户名，或先清理（第 8 节） |
| 500 + `服务端内部错误` | DB 连接失败/服务异常 | 看后端日志；恢复 DB 后重试 |
| 500 + `数据库访问失败` | SQL 执行失败 | 检查表结构（`patient`/`patient_token`）与字符集 |
| 中文显示 `????`/乱码 | 客户端未按 UTF-8 读取 | 用 `Get-Content -Encoding UTF8` / `--default-character-set=utf8mb4` |
| PowerShell 脚本语法错误（`Unexpected token '{'`） | `.ps1` 被按 ANSI 读取 | 确保文件为 UTF-8 **BOM**（本仓库脚本已带 BOM） |
| CORS 报错（浏览器） | 前端 origin 未放行 | 检查 `WebConfig` 允许的 origins（5173） |
| 一键脚本退出码 1 | 有用例失败 | 看末尾"失败详情"，按本表逐项排查 |

---

## 8. 清理与复位

```powershell
# 1) 清理脚本/手工测试产生的账号（保留 demo_patient）
docker exec qa-mysql mysql -uroot -proot_pass_123 -D qa_healthcare -e "DELETE FROM patient WHERE username LIKE 'api_test_%' OR username LIKE 'api_sh_%' OR username LIKE 'api_manual_%';"

# 2) 确认仅剩演示账号
docker exec qa-mysql mysql -uroot -proot_pass_123 -D qa_healthcare --default-character-set=utf8mb4 -e "SELECT id, username, name FROM patient;"

# 3) 确认医生数据未被测试修改（应为 5 条，doc004 停诊）
docker exec qa-mysql mysql -uroot -proot_pass_123 -D qa_healthcare --default-character-set=utf8mb4 -e "SELECT id, name, is_active FROM doctor ORDER BY id;"

# 4) 删除本次临时响应文件
Remove-Item -LiteralPath (Join-Path $env:TEMP 'qa-api-manual') -Recurse -Force -ErrorAction SilentlyContinue
```

如需彻底重置数据库：`docker compose down -v; docker compose up -d`（会重新执行 `01~03` 初始化脚本）。

---

## 9. 证据规范

- 日志：`docs/test-evidence/api-run-YYYYMMDD-HHmmss.log`（一键盘完整 stdout/stderr）
- 响应：`docs/test-evidence/<CASE-ID>-response.json`（可截断，但保留 `code/message` 与关键 `data` 字段）
- 脱敏：不得写入真实密码哈希、完整 token；token 只保留前 8 位 + `...`
- 报告中每个结论必须能指回上述证据文件
