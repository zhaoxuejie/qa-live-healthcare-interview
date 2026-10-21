# 演示视频脚本（VIDEO_SCRIPT.md）

> 目标：用一段 **约 5–6 分钟** 的录屏，完整展示三项需求的真实效果（改库即变、登录可用、测试可复现）。
> **范围说明**：按用户 2026-10-21 指示，**不包含 PR 链接与总结段**；视频结尾只做一句简短收束。
> 录制者：用户本人（AI 提供脚本与命令，不代替录制）。

---

## 1. 录制前准备

### 1.1 环境检查（录制前 1 分钟执行）

```powershell
cd D:\projectGithub\qa-live-healthcare-interview
git status --short
docker compose ps
curl.exe -s -w "`nHTTP %{http_code}`n" http://localhost:8080/actuator/health
```

期望：工作区干净；`qa-mysql` healthy；`{"status":"UP"}`。

```powershell
# 前端 / 后端未启动时（各自一个终端）
cd web\qa-web; npm run dev
cd server\qa-service-user; $env:JAVA_HOME='D:\dev\jdk17'; .\mvnw.cmd -s D:\dev\maven-settings.xml spring-boot:run
```

### 1.2 演示数据复位（保证视频里的数值可预期）

```powershell
# 医生：doc001 张伟医生、doc004 停诊（5 位医生，4 个开放诊室）
docker exec qa-mysql mysql -uroot -proot_pass_123 -D qa_healthcare --default-character-set=utf8mb4 -e "UPDATE doctor SET name='张伟医生' WHERE id='doc001'; UPDATE doctor SET is_active=0 WHERE id='doc004'; SELECT id,name,is_active FROM doctor ORDER BY id;"
```

患者账号：保留 `demo_patient / 123456`；如需全新演示，再注册一个 `demo_show_1021`。

### 1.3 画面设置

| 项 | 建议 |
|---|---|
| 分辨率 | 1920×1080，30fps |
| 浏览器 | Chrome/Edge，缩放 125%–150%（保证字可读） |
| 终端 | 字号 ≥ 18，深色主题，宽度足够显示 16 条用例 |
| 干扰 | 关闭微信/QQ/系统通知；隐藏无关窗口；录屏区域只保留浏览器 + 终端 |
| 鼠标 | 开启“点击高亮”（OBS/录屏工具自带），方便评委跟随 |
| 登录态 | 录制前在 DevTools 执行 `localStorage.removeItem('qa_patient_token')`，确保从登录页开始 |

---

## 2. 时间轴总览（目标 5:40）

| 时间段 | 内容 | 时长 |
|---|---|---|
| 0:00–0:40 | 开场：分支、目录结构、三项需求一句话 | 40s |
| 0:40–1:35 | 需求 1：首页中英切换 + 刷新保持 | 55s |
| 1:35–2:55 | 需求 2：phpMyAdmin 改库 → 页面刷新即变 → 改回 | 80s |
| 2:55–4:25 | 需求 3：患者注册 → 自动登录 → 刷新保持 → 登出 | 90s |
| 4:25–5:40 | 测试：curl 一键脚本 16/16 + 报告与证据 | 75s |
| 5:40 | 一句收束（**无 PR/总结段**） | 5s |

---

## 3. 分镜脚本

### 分镜 1：开场与代码结构（0:00–0:40）

**画面**：终端 + 资源管理器（或 VS Code 侧边栏）。

**操作**：

```powershell
git branch --show-current
git log --oneline -6
```

指向目录：`web/qa-web`（前端）、`server/qa-service-user`（后端）、`deploy/mysql/init`（建表/种子）、`tests/api`（测试）。

**口播词**：

> 这是 qa-live-healthcare-interview 的面试实现，分支 `feature-interview-1021`。
> 三项需求分别是：首页中英切换、医生数据改为 MySQL 读取、患者用户名密码登录。
> 代码分为前端 Vue、后端 Spring Boot、MySQL 初始化脚本和 curl 测试四部分，下面逐项演示真实效果。

**预期**：分支名正确；最近提交包含 T15–T19 的文档与测试。

---

### 分镜 2：首页中英切换（0:40–1:35）

**画面**：浏览器 `http://localhost:5173/`。

**操作**：

1. 指向 Header 导航与 Footer 文案（中文）。
2. 点右上角语言下拉 → English。
3. **刷新页面**（F5），再次展示 Header/Footer/首页正文均为英文。
4. 切回中文，指一下恢复。

**口播词**：

> 需求一：首页中英切换。语言开关在右上角，切换后 Header、Footer 和首页正文都会同步。
> 刷新后仍保持英文，因为语言存在 localStorage；切回中文同样即时生效。
> 按 README 范围，本期只覆盖外壳与首页，其他页面正文保持中文。

**预期**：出现 `Consult Now`、英文 Footer；刷新后仍英文；`<html lang="en">`（可在 DevTools 一闪而过，可选）。

---

### 分镜 3：医生数据来自 MySQL（1:35–2:55）

**画面**：左 phpMyAdmin，右 `/doctors` 页面。

**操作**：

1. 打开 `http://localhost:8082`，登录：用户 `root` / 密码 `root_pass_123`。
2. 选择库 `qa_healthcare` → 表 `doctor` → 编辑 `doc001` 的 `name` 为 `张伟医生(测试)` → 保存。
3. 切到浏览器 `/doctors` → **刷新**：第一张卡片显示“张伟医生(测试)”。
4. 回到 phpMyAdmin，把 `doc004` 的 `is_active` 改为 `1` → 保存。
5. 刷新首页 `/`：开放诊室从 **4** 变为 **5**。
6. 改回：`doc001.name=张伟医生`、`doc004.is_active=0`，刷新恢复原样。

**口播词**：

> 需求二：医生数据不再写在前端 JSON，而是来自 MySQL。
> 我在 phpMyAdmin 里把张伟医生的姓名改成“张伟医生(测试)”，回到页面刷新，立刻显示新值。
> 再把停诊的刘敏医生改为在诊，首页开放诊室从 4 个变成 5 个。
> 这说明页面数据确实来自数据库，而不是打包在前端。最后我改回原始数据。

**兜底（若 phpMyAdmin 不便操作）**：

```powershell
# 改
docker exec qa-mysql mysql -uroot -proot_pass_123 -D qa_healthcare --default-character-set=utf8mb4 -e "UPDATE doctor SET name='张伟医生(测试)' WHERE id='doc001';"
# 改回
docker exec qa-mysql mysql -uroot -proot_pass_123 -D qa_healthcare --default-character-set=utf8mb4 -e "UPDATE doctor SET name='张伟医生' WHERE id='doc001';"
```

> 注意：终端里中文需 UTF-8；若显示乱码，改用 phpMyAdmin 操作。录屏优先用 phpMyAdmin，画面更直观。

---

### 分镜 4：患者注册 / 登录 / 刷新保持 / 登出（2:55–4:25）

**画面**：浏览器 `/consultation`。

**操作**：

1. 打开 `/consultation`，展示「登录 / 注册」两个 Tab。
2. 切到「注册」，填写：
   - 用户名：`demo_show_1021`（若已存在则加时间后缀）
   - 密码：`123456`
   - 姓名：`演示患者`
3. 点「注册并登录」→ 进入「演示患者 的问诊」。
4. **刷新页面**：仍保持登录（不再显示登录表单）。
5. 点「切换用户」→ 回到登录表单。
6. 用 `demo_patient / 123456` 登录，展示「演示患者 的问诊」。
7. （可选，5 秒）打开 DevTools → Application → Local Storage，指出 `qa_patient_token` 存在；登出后消失。

**口播词**：

> 需求三：患者登录。原来用“姓名 + 生日”验证，任何人都能冒充；现在改成用户名密码。
> 我注册一个新账号，注册成功会自动登录；刷新页面仍然是登录态，因为前端用 token 调 `/me` 恢复会话。
> 点“切换用户”会同时让服务端 token 失效并清理本地状态，再回来就是登录表单。
> 密码在数据库里是 BCrypt 哈希，接口响应里不会返回任何密码字段。

**兜底**：登录失败先确认 `demo_patient` 存在（`03_seed_patient.sql`），或重新注册。

---

### 分镜 5：curl 测试与报告（4:25–5:40）

**画面**：终端（全屏），随后浏览器/编辑器打开报告。

**操作**：

```powershell
cd D:\projectGithub\qa-live-healthcare-interview
powershell -NoProfile -ExecutionPolicy Bypass -File tests\api\run-all.ps1
"EXIT CODE=$LASTEXITCODE"
```

等待输出 16 条 PASS 与汇总，指向：

```text
总计 16 条，通过 16 条，失败 0 条
EXIT CODE=0
```

再打开 `docs/TEST_REPORT.md`，快速滚动展示：被测接口清单、19 条用例结果、证据目录。

**口播词**：

> 测试用 curl 脚本覆盖医生列表和患者认证，包括正向、重复注册、弱密码、错误密码、伪造 token、登出失效等场景。
> 一键执行 16 条全部通过，退出码 0；更完整的 19 条用例和响应证据在 TEST_REPORT.md 里，每条都有实际状态码和关键响应。
> 测试账号会自动清理，数据库只保留演示账号。

**收束（5:40，一句话，无 PR/总结）**：

> 以上是三项需求的完整演示。

---

## 4. 口播词完整版（可打印提词）

```text
【0:00】这是 qa-live-healthcare-interview 的面试实现，分支 feature-interview-1021。
三项需求：首页中英切换、医生数据来自 MySQL、患者用户名密码登录。
代码分为前端 Vue、后端 Spring Boot、MySQL 初始化脚本和 curl 测试四部分。

【0:40】需求一：首页中英切换。语言开关在右上角，Header、Footer、首页正文同步切换；
刷新后仍保持英文；切回中文即时生效。按范围，其他页面正文保持中文。

【1:35】需求二：医生数据来自 MySQL。在 phpMyAdmin 把张伟医生改名，页面刷新立即显示新值；
把停诊医生改为在诊，首页开放诊室从 4 变 5；最后改回原始数据。
说明数据确实来自数据库，不是前端 JSON。

【2:55】需求三：患者登录。注册新账号会自动登录；刷新仍是登录态；
切换用户会让服务端 token 失效并清理本地状态；密码是 BCrypt 哈希，接口不返回密码。

【4:25】测试：curl 脚本覆盖医生列表与患者认证，16 条全部通过、退出码 0；
完整 19 条用例与证据在 TEST_REPORT.md；测试数据自动清理。

【5:40】以上是三项需求的完整演示。
```

---

## 5. 兜底与故障处理

| 现象 | 处理 |
|---|---|
| 页面 404 / 空白 | 确认 Vite 5173 在跑；刷新；看终端报错 |
| 医生列表加载失败 | 后端 8080 未起或 DB 未 healthy；先跑第 1.1 节检查 |
| 改库后页面没变 | 确认保存成功；强制刷新（Ctrl+F5）；确认 `doc001` 是当前卡片 |
| 登录 401 | `demo_patient` 不存在/密码被改；执行 `03_seed_patient.sql` 对应数据或重新注册 |
| 测试脚本报连接失败 | 8080 未启动；或端口被占用 |
| 中文乱码 | 终端 `[Console]::OutputEncoding=UTF8`；phpMyAdmin 用 utf8mb4 |
| 录制中弹出通知 | 开启勿扰模式，重新录该段（不要用剪辑掩盖失败） |

---

## 6. 录制后

1. 保存视频为 `demo-assets/recordings/demo-video.mp4`，或上传后把链接写入 `docs/`（二选一）。
2. 在 `docs/EXECUTION_PLAN.md` 的 T20 勾选验收项，并把文件/链接位置补到备注。
3. 若视频超过 7 分钟，优先压缩分镜 4 的注册步骤（可改用已有账号登录），不要删减“改库即变”和“测试全绿”。

## 7. 检查清单（录完自检）

- [ ] 分支名、目录结构清晰可见
- [ ] 首页中英切换含**刷新保持**
- [ ] 改库后页面数值变化有前后对比，且已改回
- [ ] 患者注册/登录/刷新/登出齐全
- [ ] curl 测试 16/16、退出码 0 可见
- [ ] 报告与证据文件出现
- [ ] 无 PR/总结段（按要求）
- [ ] 画面 1080p、字可读、无通知干扰
