# API 测试报告

> 依据：[docs/API_TEST.md](API_TEST.md)（19 条用例）
> 测试脚本：[tests/api/run-all.ps1](../tests/api/run-all.ps1)
> 证据目录：[docs/test-evidence](test-evidence/)

---

## 1. 基本信息

| 项 | 内容 |
|---|---|
| 执行日期 | 2026-10-21 12:13（Asia/Shanghai） |
| 被测分支 | `feature-interview-1021` |
| 被测提交 | `5256b2d` |
| 执行人 | AI Coding（自动化执行） |
| 执行方式 | 一键 PowerShell 脚本 + 手工/证据采集复核 |
| 结论 | **通过**（19/19） |

### 1.1 环境

| 组件 | 版本 |
|---|---|
| 操作系统 | Windows 10 专业版 10.0.19045 |
| JDK | Temurin OpenJDK 17.0.20.1 |
| Node.js | v22.23.0 |
| MySQL | 8.0.46（Docker 容器 `qa-mysql`，healthy） |
| Spring Boot | 3.5.7 |
| Maven Wrapper | 3.9.11 |
| 前端构建 | Vite 5.4.8（仅记录，不参与本报告） |

### 1.2 服务状态（执行前）

```text
qa-mysql        Up (healthy)
qa-phpmyadmin   Up
/api/doctors    HTTP 200
/actuator/health UP（db: UP）
```

### 1.3 被测接口清单

Base URL：`http://localhost:8080`

| # | 方法 | 路径 | 用途 | 鉴权 | 对应用例 | 覆盖场景 |
|---|---|---|---|---|---|---|
| 1 | GET | `/api/doctors` | 医生列表（全量 / 仅在诊） | 无 | DOC-01~05 | 200 且 5 条；`active=true` 4 条；无 `password`；400 非法参数；中文正确 |
| 2 | POST | `/api/auth/patient/register` | 患者注册 | 无 | AUTH-01~04 | 201 + token；409 重复用户名；400 弱密码；400 缺字段 |
| 3 | POST | `/api/auth/patient/login` | 患者登录 | 无 | AUTH-05~09 | 200 + token（43 位）；401 密码错误；401 不存在用户；失败文案一致防枚举 |
| 4 | GET | `/api/auth/patient/me` | 获取当前患者 | `Authorization: Bearer <token>` | AUTH-10、11、12、14 | 200 返回患者；401 无 token / 伪造 token / 登出后 token |
| 5 | POST | `/api/auth/patient/logout` | 患者登出 | `Authorization: Bearer <token>` | AUTH-13 | 204 空响应 |
| 6 | GET | `/actuator/health` | 服务健康检查 | 无 | 前置检查（不计入 19 条） | 200，`status=UP`，`db=UP` |

说明：

- 共 **5 个业务接口** + 1 个健康检查端点，全部列入上表。
- 医生登录 `POST /api/doctors/login` **不在本报告范围**：它在 T14 前端回归中以 UI 方式验证（`dr-zhang-wei/123456` 登录并进入诊室）。
- 问题提交/查询为前端内存逻辑，无后端接口，因此无对应用例。

---

## 2. 执行结果汇总

| 指标 | 数值 |
|---|---|
| 一键脚本用例数 | 16 |
| 一键脚本通过 | 16 |
| 一键脚本失败 | 0 |
| 脚本退出码 | 0 |
| 手工复核用例（含脚本未单列的断言） | 19（全部通过） |
| 阻塞/严重缺陷 | 0 |

一键脚本末行输出：

```text
总计 16 条，通过 16 条，失败 0 条
EXIT CODE=0
```

完整日志：`docs/test-evidence/api-run-20261021-121309.log`。

---

## 3. 用例明细（19 条）

> 状态码为本次真实执行值；响应片段来自 `docs/test-evidence/*.json`（token 已脱敏）。
> `—` 表示该用例为对已有响应的断言，不单独发请求。

| ID | 目的 | 期望码 | 实际码 | 实际 code | 关键响应片段 | 结果 |
|---|---|---|---|---|---|---|
| DOC-01 | 医生全量列表 | 200 | **200** | 0 | `{"code":0,...,"data":[{"id":"doc001","name":"张伟医生",...}`（5 条） | PASS |
| DOC-02 | 响应不含密码 | — | — | — | 全量响应中无 `"password"` 字段 | PASS |
| DOC-03 | 仅在诊过滤 | 200 | **200** | 0 | `data` 长度 4（`doc004` 停诊被过滤） | PASS |
| DOC-04 | 非法参数 | 400 | **400** | 40000 | `{"code":40000,"message":"参数格式不正确: active","data":null}` | PASS |
| DOC-05 | 中文编码 | — | — | — | 响应文本含 `张伟医生`、`心内科` | PASS |
| AUTH-01 | 注册成功 | 201 | **201** | 0 | `{"code":0,...,"token":"<redacted>","patient":{"id":9,"username":"report_patient_2026...","name":"报告测试患者"...}}` | PASS |
| AUTH-02 | 重复用户名 | 409 | **409** | 40900 | `{"code":40900,"message":"用户名已存在","data":null}` | PASS |
| AUTH-03 | 弱密码 | 400 | **400** | 40000 | `{"code":40000,"message":"密码长度需为 6-64 位","data":null}` | PASS |
| AUTH-04 | 缺少姓名 | 400 | **400** | 40000 | `{"code":40000,"message":"姓名不能为空且不超过 64 字","data":null}` | PASS |
| AUTH-05 | 登录成功 | 200 | **200** | 0 | `{"code":0,...,"patient":{"id":1,"username":"demo_patient","name":"演示患者"...}}` | PASS |
| AUTH-06 | token 强度 | — | — | — | token 长度 **43**（≥32） | PASS |
| AUTH-07 | 密码错误 | 401 | **401** | 40100 | `{"code":40100,"message":"用户名或密码错误","data":null}` | PASS |
| AUTH-08 | 不存在用户 | 401 | **401** | 40100 | `{"code":40100,"message":"用户名或密码错误","data":null}` | PASS |
| AUTH-09 | 防枚举文案一致 | — | — | — | AUTH-07 与 AUTH-08 的 `message` 完全相同 | PASS |
| AUTH-10 | 有效 token 取用户 | 200 | **200** | 0 | `{"code":0,"data":{"id":9,"username":"report_patient_2026...","name":"报告测试患者"...}}` | PASS |
| AUTH-11 | 无 token | 401 | **401** | 40100 | `{"code":40100,"message":"未登录","data":null}` | PASS |
| AUTH-12 | 伪造 token | 401 | **401** | 40100 | `{"code":40100,"message":"登录已失效，请重新登录","data":null}` | PASS |
| AUTH-13 | 登出 | 204 | **204** | — | 响应体为空（`AUTH-13.json` 0 字节） | PASS |
| AUTH-14 | 登出后 token 失效 | 401 | **401** | 40100 | `{"code":40100,"message":"登录已失效，请重新登录","data":null}` | PASS |

---

## 4. 证据清单

| 文件 | 说明 |
|---|---|
| `docs/test-evidence/api-run-20261021-121309.log` | 一键脚本完整输出（16 条 PASS + 汇总） |
| `docs/test-evidence/status-20261021-121309.txt` | 19 条用例状态汇总 |
| `docs/test-evidence/DOC-01.json` | 医生全量响应（5 条，中文） |
| `docs/test-evidence/DOC-03.json` | 在线医生响应（4 条） |
| `docs/test-evidence/DOC-04.json` | 非法参数错误体 |
| `docs/test-evidence/AUTH-01.json` | 注册成功（token 已脱敏） |
| `docs/test-evidence/AUTH-02.json` / `AUTH-03.json` / `AUTH-04.json` | 409 / 400 / 400 |
| `docs/test-evidence/AUTH-05.json` | 登录成功（token 已脱敏） |
| `docs/test-evidence/AUTH-07.json` / `AUTH-08.json` | 401 两种失败（文案一致） |
| `docs/test-evidence/AUTH-10.json` | `/me` 成功 |
| `docs/test-evidence/AUTH-11.json` / `AUTH-12.json` / `AUTH-14.json` | 401 三种失效场景 |
| `docs/test-evidence/AUTH-13.json` | 204 空响应 |

> 脱敏说明：所有响应中的 `token` 值已替换为 `<redacted>`；未保存任何密码哈希。

---

## 5. 失败与缺陷

- 失败用例：**无**。
- 阻塞缺陷：**无**。
- 执行过程中发现并已修复的环境问题（非产品缺陷）：
  1. PowerShell 5.1 按 ANSI 读取无 BOM 的 UTF-8 脚本导致语法错误 → 脚本已改为 UTF-8 BOM。
  2. Windows `curl.exe` 内联 JSON 会丢引号 → 测试统一改用 `--data-binary @file`。

---

## 6. 风险与未覆盖

| 项 | 说明 |
|---|---|
| token 存 localStorage | XSS 可窃取（PRD R1），本期按计划接受 |
| 无登录失败限流/验证码 | 不在本期范围，存在暴力尝试风险 |
| 未做并发/性能压测 | 仅单请求功能验证 |
| 问题数据仍在前端内存 | 刷新丢失，属既有范围约定 |
| 前端 UI | 由 T13/T14 的 CDP 回归覆盖，不在本报告 |

---

## 7. 复现步骤

```powershell
# 1) 环境检查
docker compose ps
curl.exe -s -w "`nHTTP %{http_code}`n" http://localhost:8080/actuator/health

# 2) 一键测试（期望退出码 0，16/16）
powershell -NoProfile -ExecutionPolicy Bypass -File tests\api\run-all.ps1
"EXIT CODE=$LASTEXITCODE"

# 3) 清理测试账号（保留 demo_patient）
docker exec qa-mysql mysql -uroot -proot_pass_123 -D qa_healthcare -e "DELETE FROM patient WHERE username LIKE 'api_test_%' OR username LIKE 'api_sh_%' OR username LIKE 'api_manual_%' OR username LIKE 'report_%';"
```

测试后数据库状态：`patient` 仅剩 `demo_patient`；`doctor` 仍为 5 条（`doc004` 停诊），未被测试修改。
