# QA Live Healthcare 面试任务执行计划

> 依据：仓库根目录 [README.md](../README.md) 的「需求列表 / 测试要求 / 交付物要求 / 面试流程要求」
> 分支：`feature-interview-1021`（基于 `main` @ `4094c55`）
> 制定日期：2026-10-21
> 文档状态：待执行（本文件本身即任务看板，执行中同步勾选）

---

## 0. 如何使用本清单

1. **严格按编号顺序执行**：`T00 → T21`，前置任务未通过验收不得开始后继任务。
2. 每个任务执行前先读「目标 / 产出 / 依赖」，执行后逐条勾选「验收标准」；全部勾选才算完成。
3. 验收标准中的命令**必须真实执行**并把输出留痕（截图或粘贴到测试报告），不允许"看起来对"。
4. 每次任务完成后单独提交一次代码，提交信息格式：`<type>(<scope>): <summary>`，例如 `feat(web): add homepage i18n switcher`。
5. 任何需求歧义、环境阻塞、与验收标准冲突的情况，**先停下确认，不自行扩大范围**。
6. 全流程由 AI Coding 完成（README 硬性要求），每个阶段的提示词都要记录到 `docs/prompts.md`（见 T18）。

### 环境与端口约定（全程不变）

| 项 | 约定 |
|---|---|
| 前端 | `http://127.0.0.1:5173`（Vite） |
| 后端 user | `http://localhost:8080`（qa-service-user） |
| 后端 question | `http://localhost:8081`（qa-service-question，本次需求不扩展） |
| MySQL | `localhost:3306`，库 `qa_healthcare`，账号 `qa_user` / `qa_pass_123`（开发环境，仅本地） |
| phpMyAdmin | `http://localhost:8082` |
| JDK / Maven | JDK 17（`D:\dev\jdk17`）、项目自带 `mvnw`（Maven 3.9.11） |
| Maven 镜像 | `-s D:\dev\maven-settings.xml`（阿里云；不修改全局 `~/.m2/settings.xml`） |
| npm 源 | `https://registry.npmmirror.com/` |
| 远端 | `origin` = 你的 fork；GitHub 直连被阻断，推送依赖本机 `127.0.0.1:7890` 代理 |

### 范围边界（明确不做，避免范围蔓延）

- 需求 1 翻译**全站外壳（Header / Footer）+ 首页正文**；其他页面正文保持中文（README 原文只要求首页，Header/Footer 为 2026-10-21 用户追加要求）。语言下拉全站可见。
- 需求 2 只把**医生数据**迁到 MySQL；患者、问题数据仍保留前端 JSON/内存，不迁库。
- 需求 3 只做**患者用户名密码登录**；医生登录维持现状（本地 JSON 校验），不做医生账号体系。
- 不做权限角色体系、不做短信/邮箱验证、不做密码找回、不做分布式会话。

---

## 1. 总览与里程碑

| 阶段 | 任务 | 里程碑 | 对应 README |
|---|---|---|---|
| P0 准备 | T00–T01 | M0 基线就绪 | 面试流程要求（分支） |
| P1 首页中英文 | T02–T04 | **M1 需求 1 完成** | 需求列表 1 |
| P2 医生数据入 MySQL | T05–T09 | **M2 需求 2 完成** | 需求列表 2 |
| P3 患者账号登录 | T10–T14 | **M3 需求 3 完成** | 需求列表 3 |
| P4 接口测试与文档 | T15–T17 | **M4 测试完成** | 测试要求 1、2 |
| P5 交付 | T18–T21 | **M5 可交付** | 交付物 1、2、3 / 面试流程 |

**时间盒建议（README 要求 1 天内完成）**：P0 0.5h / P1 1h / P2 2.5h / P3 2h / P4 1.5h / P5 1.5h / 缓冲 1h。

---

## 2. 任务清单

### T00 建分支与基线确认（✅ 已完成，仅需复核）

- **目标**：确保所有工作在 `feature-interview-1021` 上进行，且起点与 `main` 一致。
- **产出**：无文件；git 状态。
- **步骤**：`git branch --show-current`；`git status --short`；`git rev-parse HEAD` 与 `main` 比对。
- **验收标准**
  - [x] 当前分支为 `feature-interview-1021`
  - [x] HEAD 与 `main` 同为 `4094c55`
  - [x] 工作区干净（无未提交改动）
  - [x] 远端 `origin` 不存在同名分支（首次推送不会冲突）
- **依赖**：无。

### T01 建立 docs 目录骨架与协作约定

- **目标**：先把文档落点、命名、API 响应格式约定下来，后续任务不再反复返工。
- **产出**
  - `docs/EXECUTION_PLAN.md`（本文件）
  - 目录：`docs/`（PRD、测试、报告、提示词均放这里，符合 README "交付物要求 2"）
  - 本文件第 0 节"环境与端口约定 / 范围边界"即为全项目约定
- **验收标准**
  - [x] `docs/EXECUTION_PLAN.md` 存在且编号完整（T00–T21）
  - [x] 全项目统一使用「统一响应体」约定：成功 `{"code":0,"message":"ok","data":...}`；失败 `{"code":<业务码>,"message":"<可读原因>"}`，HTTP 状态码同步（400/401/404/409/500）
  - [x] 任务看板（第 5 节）建立，状态列可用
- **依赖**：T00。

### T02 需求 1：引入 i18n 基础设施

- **目标**：安装并注册 `vue-i18n`，建立中英资源文件目录（README 指定 `web/qa-web/src/locales`）。
- **产出**
  - `web/qa-web/package.json` 新增 `vue-i18n`（建议 `^9` / `^11`，与本机 Vue 3.5 兼容）
  - `web/qa-web/src/locales/zh-CN.ts`、`web/qa-web/src/locales/en-US.ts`
  - `web/qa-web/src/i18n/index.ts`（`legacy:false`，默认 `zh-CN`，从 `localStorage.qa_locale` 恢复）
  - `web/qa-web/src/main.ts` 注册 i18n
- **步骤**：`npm install vue-i18n`（npmmirror）→ 建资源文件 → 建实例 → `app.use(i18n)`。
- **验收标准**
  - [x] `ls web/qa-web/src/locales` 至少包含 `zh-CN.ts`、`en-US.ts`
  - [x] `main.ts` 中 `app.use(i18n)` 生效，页面无控制台报错
  - [x] `npm run build` 通过（`vue-tsc` 严格模式无错）
  - [x] 刷新页面后语言取 `localStorage` 值；无值时默认中文
- **依赖**：T01。

### T03 需求 1：首页文案接入 + 右上角语言下拉

- **目标**：首页所有 UI 文案走 i18n；右上角提供「中文 / English」下拉，切换即时生效。
- **产出**
  - `web/qa-web/src/views/Home.vue`：模板文案替换为 `$t('home.*')`（hero 标题/副标题/三个特性/两个按钮/四个统计标签/开放诊室标题与副标题/进入诊室/在线）
  - `web/qa-web/src/components/AppHeader.vue`：右上角语言下拉，**全站可见**（2026-10-21 用户追加）；导航与登录按钮接入 `nav.*`
  - `web/qa-web/src/components/AppFooter.vue`：Footer 全部文案接入 `footer.*`（2026-10-21 用户追加）
  - 资源文件补齐 `home.*` / `nav.*` / `footer.*` 全部 key（中英一一对应）
- **范围控制**：Header/Footer 随语言切换；Doctors/Consultation/Login/Room 等**页面正文**仍不翻译（保持 README"只处理首页"的原范围）。
- **验收标准**
  - [x] 首页右上角可见语言下拉，选项为「中文 / English」
  - [x] 选择 English 后，首页全部 UI 文案变为英文，**无刷新、无残留中文**（医生姓名/科室等数据除外，数据不翻译）
  - [x] 切回中文一切复原
  - [x] 切换后刷新页面，语言保持（`localStorage.qa_locale`）
  - [x] 语言下拉全站可见；其他页面正文仍为中文（回归）
  - [x] `npm run build` 通过；浏览器控制台无 i18n 缺 key 警告
- **依赖**：T02。

### T04 需求 1 验收回归（M1 门禁）

- **目标**：确认需求 1 完成且未破坏既有功能。
- **验收标准**
  - [x] 首页中英切换 3 轮无异常
  - [x] 医生、问诊、关于、医生登录 4 个页面可正常打开，布局与文案无变化
  - [x] `npm run build` 成功，`dist/` 可产出
  - [x] 无新增运行时报错（Vite 终端 + 浏览器 Console）
  - [x] 提交记录存在，提交信息符合规范
- **依赖**：T03。

### T05 需求 2：docker-compose（MySQL + phpMyAdmin）

- **目标**：一条命令拉起数据库与管理界面，供开发联调与演示。
- **产出**：根目录 `docker-compose.yml`
  - `mysql:8.4`（或 8.0）：`MYSQL_DATABASE=qa_healthcare`、`MYSQL_USER=qa_user`、`MYSQL_PASSWORD=qa_pass_123`、`MYSQL_ROOT_PASSWORD=root_pass_123`、端口 `3306:3306`、`utf8mb4`、数据卷 `mysql_data`、healthcheck
  - `phpmyadmin`：`PMA_HOST=mysql`、端口 `8082:80`、依赖 mysql healthy
  - 挂载 `./deploy/mysql/init:/docker-entrypoint-initdb.d:ro`（供 T06 初始化）
- **前置**：本机 Docker Desktop 需启动（当前 daemon 未运行）；镜像拉取若失败，配置国内镜像加速后重试。
- **验收标准**
  - [x] `docker compose up -d` 成功，`docker compose ps` 中 mysql 为 `healthy`、phpmyadmin 为 `Up`
  - [x] `curl.exe -I http://localhost:8082/` 返回 200
  - [x] 宿主机可用 `mysql` 客户端或 `docker exec` 连入，`SELECT VERSION()` 返回 8.x
  - [x] `docker compose down` / `down -v` 可重复执行；`down -v && up -d` 后初始化脚本重新生效
  - [x] 端口不冲突（3306 / 8082；8080/8081 已被后端占用）
- **依赖**：T01。

### T06 需求 2：数据库 schema 与医生种子数据

- **目标**：建立与前端 `Doctor` 模型一致的表结构，并灌入现有 JSON 的 5 条医生数据。
- **产出**
  - `deploy/mysql/init/01_schema.sql`：`doctor`、`patient`、`patient_token` 三张表（patient 相关为 T12 预留，可同批建）
  - `deploy/mysql/init/02_seed_doctors.sql`：5 条医生（来自 `web/qa-web/src/data/doctor-user-list.json`）
  - `deploy/mysql/init/03_seed_patient.sql`：1 条演示患者（BCrypt 哈希，供 T14 演示）——**推迟到 T12 生成**（需先用后端 BCrypt 产出哈希）
- **表设计（验收依据）**
  - `doctor`：`id varchar(32) PK`、`username varchar(64) UNIQUE`、`password varchar(100)`、`name`、`title`、`department`、`avatar varchar(512)`、`experience`、`specialties JSON`、`is_active tinyint(1)`、`created_at`、`updated_at`
  - `patient`：`id bigint AUTO_INCREMENT PK`、`username varchar(64) UNIQUE`、`password_hash varchar(100)`、`name`、`birthday date`、`phone`、`gender`、`created_at`
  - `patient_token`：`token varchar(64) PK`、`patient_id bigint`、`expires_at datetime`、`created_at`
- **验收标准**
  - [x] 三张表存在，`SHOW CREATE TABLE doctor` 显示 `utf8mb4`
  - [x] `SELECT COUNT(*) FROM doctor` = 5；`username` 与 JSON 完全一致（`dr-zhang-wei` 等）
  - [x] `specialties` 为合法 JSON 数组（如 `["高血压","冠心病","心律失常"]`）
  - [x] `is_active` 与 JSON 一致（doc004 为 0，其余 4 条为 1）
  - [x] 脚本幂等可重复初始化（`docker compose down -v && up -d` 后数据一致）
- **依赖**：T05。

### T07 需求 2：qa-service-user 医生列表 API

- **目标**：在 `qa-service-user` 中提供医生列表接口，供前端医生页使用；**不返回密码**。
- **产出**
  - `pom.xml` 增加 `spring-boot-starter-data-jpa`、`mysql-connector-j`、`spring-security-crypto`（T12 复用）
  - `application.properties` 增加 datasource（`jdbc:mysql://localhost:3306/qa_healthcare?...`，`ddl-auto=none`：表结构由 init SQL 管理，避免 JSON 列类型校验误报）
  - 代码：`entity/Doctor.java`（`specialties` 用 JSON ↔ List 转换）、`repository/DoctorRepository.java`、`service/DoctorService.java`、`controller/DoctorController.java`、`dto/DoctorDto.java`、`common/ApiResponse.java`、`exception/GlobalExceptionHandler.java`
  - 接口：`GET /api/doctors`（全部）、`GET /api/doctors?active=true`（仅在线）
- **验收标准**
  - [x] `curl.exe -s http://localhost:8080/api/doctors` 返回 200 与统一响应体，`data` 长度 5
  - [x] 响应元素含 `id/username/name/title/department/avatar/experience/specialties/isActive`，**不含 `password`**
  - [x] `curl.exe -s "http://localhost:8080/api/doctors?active=true"` 返回 4 条
  - [x] 数据库不可用时返回 500 + 统一错误体，且不输出堆栈到响应
  - [x] `.\mvnw.cmd -s D:\dev\maven-settings.xml test` 通过；`/actuator/health` 仍为 UP
  - [x] 既有 CORS 配置对 `/api/**` 生效（浏览器 5173 可跨域调用）
- **依赖**：T06。

### T08 需求 2：前端医生数据改走 API（联调）

- **目标**：删除前端医生 JSON 数据源，改为调用后端；Doctors 与 Home 使用同一数据源。
- **产出**
  - `web/qa-web/src/api/http.ts`（fetch 封装、baseURL 取 `import.meta.env.VITE_API_BASE_URL`，默认 `http://localhost:8080`、统一错误处理）
  - `web/qa-web/src/api/doctors.ts`（`fetchDoctors(active?)`）
  - `web/qa-web/src/store/index.ts`：删除 `doctor-user-list.json` 导入；新增 `loadDoctors()` 与加载/错误状态
  - `web/qa-web/src/views/Doctors.vue` / `Home.vue`：改为使用 API 数据，含 loading 骨架与失败提示（可重试）
  - `web/qa-web/.env.development`（可选）：`VITE_API_BASE_URL=http://localhost:8080`
  - 医生登录改走 `POST /api/doctors/login`（删除 JSON 后避免医生登录回归；接口已实现）
- **验收标准**
  - [x] `rg "doctor-user-list" web/qa-web/src` 无引用（种子数据仅保留在 `deploy/mysql/init`）
  - [x] 打开 `/doctors` 显示 5 位医生，数据来自接口（Network 可见 `GET /api/doctors` 200）
  - [x] 首页统计（医生数 5、在线诊室 4）与首页开放诊室卡片=4 张，与 DB 一致
  - [x] 停掉后端刷新页面：显示明确错误提示与「重试」按钮，不白屏、不报未捕获异常
  - [x] 后端恢复后点重试可正常加载
  - [x] `npm run build` 通过
- **依赖**：T07。

### T09 需求 2 联调验收（M2 门禁）

- **目标**：用"改数据库 → 刷新页面"证明数据真的来自 MySQL（演示与验收关键证据）。
- **验收标准**
  - [x] 在 phpMyAdmin 把 `doc001.name` 改为「张伟医生(测试)」，刷新 `/doctors` 立即显示新值
  - [x] 把 `doc004.is_active` 改为 1，刷新后首页开放诊室变为 5、医生页 doc004 按钮可用
  - [x] 改回原值并刷新恢复
  - [x] 浏览器 5173 → 8080 跨域请求成功（无 CORS 报错）
  - [x] 提交记录存在
- **备注**：数据变更使用 `docker exec mysql` 执行等价 SQL（未走 phpMyAdmin UI），效果与在 phpMyAdmin 修改一致；验收后已核对 5 条医生数据与种子完全一致。
- **依赖**：T08。

### T10 需求 3：编写 PRD 文档模板

- **目标**：产出可复用的规范 PRD 模板（README 要求"规范的 PRD 文档模版"）。
- **产出**：`docs/PRD_TEMPLATE.md`
- **必须包含的章节**
  1. 文档信息（版本/日期/作者/状态/变更记录）
  2. 背景与目标（问题、目标、成功指标）
  3. 范围（In Scope / Out of Scope）
  4. 角色与场景
  5. 用户故事（US 编号）
  6. 功能需求（FR 编号，含优先级）
  7. 非功能需求（安全/性能/兼容性）
  8. 交互与状态（页面/流程/异常态）
  9. 接口与数据影响（可选，引用设计文档）
  10. 验收标准（Given/When/Then，逐条可测）
  11. 拆分步骤（任务编号、依赖、预计改动文件）
  12. 风险与待确认项
- **验收标准**
  - [ ] 模板章节齐全，每节有填写指引（示例占位）
  - [ ] 验收标准章节强制"可测量"，不允许"体验良好"这类描述
  - [ ] 模板本身不含具体业务内容（可被任意特性复用）
- **依赖**：T01。

### T11 需求 3：按模板编写患者登录 PRD

- **目标**：用 T10 模板产出本特性的 PRD，并给出开发拆分（README 明确要求拆分步骤）。
- **产出**：`docs/PRD-patient-login.md`
- **必须明确的决策点**
  - 注册字段：`username`（唯一，4–32 位）、`password`（≥6 位）、`name`、`birthday`、`phone?`
  - 密码存储：BCrypt（禁止明文/可逆加密）
  - 登录态：服务端下发不透明 token（有效期 7 天，存 `patient_token` 表），前端存 `localStorage.qa_patient_token`
  - 失败语义：用户名不存在/密码错误统一 401 且提示一致（防枚举）；重复注册 409
  - 旧逻辑替换：`Consultation.vue` 的"姓名+生日"验证方式移除
- **验收标准**
  - [ ] 符合 `docs/PRD_TEMPLATE.md` 全部章节
  - [ ] 每条 FR 至少对应 1 条 Given/When/Then 验收
  - [ ] 拆分步骤含：前端改造、后端接口、建表迁移、测试与文档，标注依赖顺序
  - [ ] 明确列出"不做"的范围（找回密码、验证码、第三方登录等）
- **依赖**：T10。

### T12 需求 3：后端患者账号与登录接口

- **目标**：实现注册、登录、当前用户、登出四个接口，密码 BCrypt 存储。
- **产出**
  - `entity/Patient.java`、`entity/PatientToken.java`、`repository/PatientRepository.java`、`repository/PatientTokenRepository.java`
  - `service/PatientAuthService.java`、`controller/PatientAuthController.java`、`dto/*`
  - 接口：
    - `POST /api/auth/patient/register` → 201
    - `POST /api/auth/patient/login` → 200 `{token, patient}`
    - `GET /api/auth/patient/me`（`Authorization: Bearer <token>`）→ 200
    - `POST /api/auth/patient/logout` → 204
- **验收标准**
  - [ ] 注册成功 201；重复用户名 409；密码 <6 位 400；缺字段 400
  - [ ] 登录成功 200 且返回 token；密码错误 401；用户不存在 401（提示与密码错误一致）
  - [ ] `/me` 带有效 token 返回患者信息；无 token / 过期 / 伪造 token 均 401
  - [ ] 登出后原 token 立即失效（`/me` 返回 401）
  - [ ] 数据库中 `password_hash` 以 `$2a$` 开头，全库无明文密码；所有响应不含密码字段
  - [ ] 参数校验失败返回统一错误体，不泄露堆栈
  - [ ] `.\mvnw.cmd test` 通过
- **依赖**：T06、T11。

### T13 需求 3：前端患者登录改造

- **目标**：把 `Consultation.vue` 的"姓名+生日"改为用户名密码登录/注册，并保持登录态。
- **产出**
  - `web/qa-web/src/api/auth.ts`（register/login/me/logout，自动带 Bearer）
  - `web/qa-web/src/views/Consultation.vue`：登录/注册切换、错误提示、登录后展示"xx 的问诊"
  - token 持久化与启动时 `/me` 恢复；登出清理 token
- **验收标准**
  - [ ] 未登录访问 `/consultation` 显示登录表单，含「登录 / 注册」切换
  - [ ] 注册成功自动登录，显示"<姓名> 的问诊"
  - [ ] 刷新页面仍保持登录（`/me` 校验通过）
  - [ ] 错误密码/重复用户名有明确中文提示，不白屏
  - [ ] 登出后回到登录表单，旧 token 清理
  - [ ] 页面中不再出现"姓名 + 生日"验证入口（`rg "生日" web/qa-web/src/views/Consultation.vue` 无结果）
  - [ ] 登录后提交问题功能正常（问题数据仍前端内存，符合范围约定）
  - [ ] `npm run build` 通过
- **依赖**：T12。

### T14 需求 3 验收回归（M3 门禁）

- **验收标准**
  - [ ] 完整走通：注册 → 登录 → 刷新保持 → 提交问题 → 登出 → 再登录
  - [ ] 用 2 个不同账号验证数据隔离（各自只看到自己的问题）
  - [ ] 医生登录/诊室页面不受影响（回归）
  - [ ] 首页中英切换仍正常（回归）
  - [ ] 提交记录存在
- **依赖**：T13。

### T15 测试要求 1：curl 接口测试脚本

- **目标**：用 curl 覆盖需求涉及的全部接口（医生列表、注册、登录、me、登出），含正向、负向与边界。
- **产出**
  - `tests/api/doctors.ps1`、`tests/api/auth.ps1`、`tests/api/run-all.ps1`（Windows 下调用 `curl.exe`；同时提供等价 `.sh` 供 Git Bash 复现）
  - 断言：HTTP 状态码、统一响应体 `code`、关键字段、`password` 字段不存在
  - 每次运行用时间戳生成唯一用户名，保证可重复执行
- **验收标准**
  - [ ] `pwsh -File tests/api/run-all.ps1` 退出码 0，输出 `PASS n / FAIL 0`
  - [ ] 覆盖用例 ≥ 12 条：医生列表 3（全量/在线/字段安全）、注册 3（成功/重复/弱密码）、登录 3（成功/错密码/不存在用户）、me 3（有效/无 token/伪造）
  - [ ] 任一用例失败时脚本退出码非 0，并打印请求与响应
  - [ ] 不依赖 Postman/Node/Python，仅 `curl.exe` + PowerShell
  - [ ] 测试数据不污染生产语义（仅本地库；用户名唯一化）
- **依赖**：T07、T12。

### T16 测试要求 2：编写 docs/API_TEST.md

- **目标**：写一份"给 AI 照着就能跑完测试并产出报告"的流程文档。
- **产出**：`docs/API_TEST.md`
- **必须包含**
  1. 测试范围与前置条件（服务、DB、账号、端口）
  2. 环境检查命令（健康检查、DB 连通）
  3. 用例表：ID / 目的 / 前置 / 精确 curl 命令 / 期望状态码 / 期望响应断言
  4. 执行方式（一键脚本 + 手工逐条）
  5. 结果记录模板（实际值、通过/失败、证据）
  6. 失败排查（常见 401/409/500/CORS/连接拒绝）
  7. 清理与复位
- **验收标准**
  - [ ] T15 中每条用例都能在文档里找到对应 curl 与期望结果
  - [ ] 文档可直接作为 AI 提示词输入（含"按本文档执行并生成 TEST_REPORT.md"的指令段）
  - [ ] 命令可直接复制运行（Windows PowerShell 下验证过）
- **依赖**：T15。

### T17 执行测试并生成 docs/TEST_REPORT.md

- **目标**：真实执行全部接口测试，产出可交付测试报告。
- **产出**：`docs/TEST_REPORT.md` + `docs/test-evidence/`（响应片段/截图/日志）
- **验收标准**
  - [ ] 报告含：日期、环境（JDK/Node/DB 版本）、被测提交号、用例总数/通过/失败
  - [ ] 每条用例有实际状态码与关键响应片段
  - [ ] 失败用例（如有）有根因与是否修复的结论
  - [ ] 报告与 `docs/API_TEST.md` 用例编号一一对应
  - [ ] 结论：0 失败（或明确记录未修复项及影响）
- **依赖**：T15、T16。

### T18 交付物 3：docs/prompts.md 提示词全记录

- **目标**：按时间顺序记录全流程使用的 AI 提示词（README 硬性交付物）。
- **产出**：`docs/prompts.md`
- **验收标准**
  - [ ] 覆盖至少：需求理解、计划制定、PRD 模板、PRD 编写、i18n 实现、DB/接口实现、前端联调、登录特性、测试脚本、测试报告、文档、视频脚本
  - [ ] 每条含：阶段、目的、提示词原文（或文件引用）、产出物
  - [ ] 包含本轮"制定执行计划"的提示词
  - [ ] 不遗漏关键决策类提问（如范围边界、端口约定）
- **依赖**：贯穿全程，最后汇总。

### T19 设计文档（建议交付）

- **目标**：让评审快速理解架构与关键决策。
- **产出**：`docs/DESIGN.md`
- **验收标准**
  - [ ] 架构图（前端 → API → MySQL 文本/mermaid）
  - [ ] 数据模型（ER + 字段说明）与数据库一致
  - [ ] 接口清单（方法/路径/入参/出参/错误码）
  - [ ] 登录时序（注册/登录/me/登出）
  - [ ] 关键决策记录：BCrypt、opaque token、specialties JSON、前端统一数据源、i18n 范围
  - [ ] 与代码实现一致（抽查 3 处）
- **依赖**：T07、T12、T13。

### T20 交付物 1：视频脚本与录制

- **目标**：录制完整展示三项需求的演示视频。
- **产出**：`docs/VIDEO_SCRIPT.md`（分镜/时间轴/演示步骤/口播词）+ 视频文件或链接
- **视频必须覆盖**
  1. 分支与代码结构（1 分钟）
  2. 首页中英切换（含刷新保持）（1 分钟）
  3. 医生列表来自 MySQL：phpMyAdmin 改一条数据 → 页面刷新变化（2 分钟）
  4. 患者注册/登录/刷新保持/登出（2 分钟）
  5. curl 测试执行与报告（1–2 分钟）
  6. PR 链接与总结（30 秒）
- **验收标准**
  - [ ] 视频时长 5–10 分钟，画面可读（1080p，字号可辨）
  - [ ] 六段内容齐全，无跳剪掩盖失败
  - [ ] 演示中的数值与 DB/接口实际一致
  - [ ] 视频链接或文件位置记录在 `docs/` 内
- **依赖**：T04、T09、T14、T17。

### T21 推送分支、创建 PR、交付

- **目标**：把分支推到自己的代码库并向 `main` 提 PR。
- **执行归属**：由用户本人执行；AI 不执行 push、不创建 PR（2026-10-21 用户指示）。
- **步骤**
  1. `git status` 确认干净；`git log --oneline main..HEAD` 复核提交
  2. `git push -u origin feature-interview-1021`（**推送前确认 7890 代理在线**）
  3. 在 GitHub 基于 `feature-interview-1021` 向 `main` 创建 PR，描述含：需求覆盖、测试结果、文档清单、演示视频链接
- **验收标准**
  - [ ] 远端存在 `feature-interview-1021`，本地分支跟踪 `origin/feature-interview-1021`
  - [ ] PR 已创建且目标分支为 `main`，无冲突
  - [ ] PR 描述链接到：`docs/PRD_TEMPLATE.md`、`docs/PRD-patient-login.md`、`docs/API_TEST.md`、`docs/TEST_REPORT.md`、`docs/prompts.md`、`docs/DESIGN.md`
  - [ ] 交付消息包含 PR 链接 + 视频链接
- **依赖**：T01–T20 全部完成。

---

## 3. 验收总表（门禁）

| 门禁 | 判定条件 | 通过标准 |
|---|---|---|
| G0 基线 | T00 | 分支正确、工作区干净、远端无同名分支 |
| G1 需求 1 | T02–T04 | 首页中英切换可用、刷新保持、构建通过、其他页面无回归 |
| G2 需求 2 | T05–T09 | 一条命令起 MySQL/phpMyAdmin；医生 API 200；前端不再读 JSON；改库即见变化 |
| G3 需求 3 | T10–T14 | PRD 模板+PRD 完成；注册/登录/me/登出全部通过；密码 BCrypt；前端可保持登录 |
| G4 测试 | T15–T17 | curl 用例 ≥12 全通过；API_TEST.md 可指导复跑；测试报告 0 失败 |
| G5 交付 | T18–T21 | 文档齐全；视频覆盖六段；分支已推送、PR 已创建 |

---

## 4. README 条款 → 任务 → 产出 对照

| README 条款 | 任务 | 产出物 | 验收方式 |
|---|---|---|---|
| 需求 1：首页中英切换 + locales 目录 | T02–T04 | `src/locales/*`、`src/i18n/*`、`Home.vue`、`AppHeader.vue` | 手工切换 + 刷新 + `npm run build` |
| 需求 2-a：docker-compose（mysql+phpmyadmin） | T05 | `docker-compose.yml`、`deploy/mysql/init/*` | `docker compose ps`、phpMyAdmin 可访问 |
| 需求 2-b：qa-service-user 医生列表 API | T06–T07 | 实体/仓储/服务/控制器 + schema/seed | `curl /api/doctors` 断言 |
| 需求 2-c：前后端联调 | T08–T09 | 前端 API 层、Doctors/Home 改造 | 改库→刷新可见；Network 断言 |
| 需求 3-a：规范 PRD 模板 | T10 | `docs/PRD_TEMPLATE.md` | 章节检查 |
| 需求 3-b：用模板写 PRD | T11 | `docs/PRD-patient-login.md` | 章节 + 拆分步骤检查 |
| 需求 3-c：按 PRD 开发 | T12–T14 | 后端认证接口、前端登录改造 | 全链路演示 + curl |
| 测试 1：curl 构建全部接口测试 | T15 | `tests/api/*.ps1`、`*.sh` | 一键脚本退出码 0 |
| 测试 2：API_TEST.md 指导 AI 测试并出报告 | T16–T17 | `docs/API_TEST.md`、`docs/TEST_REPORT.md` | 按文档复跑一致 |
| 交付 1：代码 + 视频 | T20 | 视频 + `docs/VIDEO_SCRIPT.md` | 六段内容检查 |
| 交付 2：docs 全套文档 | T10、T11、T16、T17、T19 | `docs/*` | 文件存在且内容完整 |
| 交付 3：prompts.md | T18 | `docs/prompts.md` | 覆盖全阶段 |
| 面试流程：特性分支 + PR | T00、T21 | 分支 + PR | 远端分支存在、PR 已建 |

---

## 5. 执行看板

> 状态：⬜ 未开始 / 🟨 进行中 / ✅ 已完成 / ⛔ 阻塞（需确认） / 👤 用户自执行

| 编号 | 任务 | 状态 | 完成时间 | 备注 |
|---|---|---|---|---|
| T00 | 建分支与基线确认 | ✅ | 2026-10-21 | `feature-interview-1021` @ 4094c55 |
| T01 | docs 骨架与约定 | ✅ | 2026-10-21 | 本文件（29 KB / 107 条验收） |
| T02 | i18n 基础设施 | ✅ | 2026-10-21 | vue-i18n 11.4.16；运行时已验证 localStorage 恢复与默认回退 |
| T03 | 首页文案 + 语言下拉 | ✅ | 2026-10-21 | CDP 验证无刷新切换；Header/Footer 已覆盖（用户追加）；下拉全站可见 |
| T04 | 需求 1 回归（M1） | ✅ | 2026-10-21 | 3 轮切换 + 4 页面回归通过；M1 完成 |
| T05 | docker-compose | ✅ | 2026-10-21 | MySQL 8.0.46（8.4 镜像源拉取停滞，按计划允许改用 8.0）+ phpMyAdmin 5；down -v 可复现 |
| T06 | schema + 医生种子 | ✅ | 2026-10-21 | 3 表 + 5 医生；doc004 停诊；utf8mb4；患者种子推迟到 T12 |
| T07 | 医生列表 API | ✅ | 2026-10-21 | `GET /api/doctors`(+active)；无 password；DB 挂→500；utf8mb4 乱码已修复 |
| T08 | 前端改 API | ✅ | 2026-10-21 | 删除医生 JSON；Doctors/Home 走 API；错误重试验证；医生登录改 DB |
| T09 | 联调验收（M2） | ✅ | 2026-10-21 | 改库→页面即变；改回已核对；M2 完成 |
| T10 | PRD 模板 | ⬜ | — | |
| T11 | 患者登录 PRD | ⬜ | — | |
| T12 | 后端认证接口 | ⬜ | — | |
| T13 | 前端登录改造 | ⬜ | — | |
| T14 | 需求 3 回归（M3） | ⬜ | — | |
| T15 | curl 测试脚本 | ⬜ | — | |
| T16 | API_TEST.md | ⬜ | — | |
| T17 | 测试报告 | ⬜ | — | |
| T18 | prompts.md | ⬜ | — | |
| T19 | 设计文档 | ⬜ | — | |
| T20 | 视频脚本与录制 | ⬜ | — | |
| T21 | 推送 + PR | 👤 用户自执行 | — | 按用户指示，AI 不推送；需 7890 代理在线 |

---

## 6. 风险与前置条件（执行前必读）

| 编号 | 风险 | 影响 | 应对 |
|---|---|---|---|
| R1 | Docker Desktop 未启动（当前 daemon 不可用） | T05–T09、T17 无法执行 | 先启动 Docker Desktop；`docker info` 验证 |
| R2 | Docker Hub 拉取镜像慢/失败 | T05 阻塞 | 配置国内镜像加速（阿里云/腾讯）；失败则记录并确认替代方案 |
| R3 | GitHub 直连被阻断，依赖 `127.0.0.1:7890` 代理 | T21 推送失败 | 推送前确认代理进程在监听；不改全局 git 配置 |
| R4 | 端口冲突（3306/8082/5173/8080/8081） | 服务起不来 | 启动前检查监听；冲突时改映射并同步文档 |
| R5 | i18n 范围歧义（下拉在共享 Header） | 需求理解偏差 | 已定策略：仅首页内容翻译、下拉仅首页显示，并在 PRD/README 记录 |
| R6 | 前端医生数据被 Home 与 Doctors 共用 | 改 API 时漏改导致双数据源 | T08 强制统一走 `store.loadDoctors()`，并验收 `rg` 无 JSON 引用 |
| R7 | 医生密码明文种子数据 | 安全质疑 | 仅用于演示且 API 不返回；患者密码强制 BCrypt |
| R8 | TypeScript 严格模式（`noUnusedLocals`） | 构建失败 | 每个任务结束跑 `npm run build` |
| R9 | 1 天时间盒 | 交付延期 | 按里程碑推进，P4/P5 可压缩但不可跳过测试与文档 |

---

## 7. 每个任务的 AI 执行提示词模板（同时写入 prompts.md）

```text
你现在在分支 feature-interview-1021 上执行 docs/EXECUTION_PLAN.md 的 <任务编号>。
先阅读：<相关文件列表>。
只做本任务范围内的改动，不扩展范围。
完成后逐条执行该任务的"验收标准"命令，把真实输出贴给我。
若验收不通过或遇到歧义，停止并说明，不要自行改需求。
```

---

## 8. 完成定义（Definition of Done）

- [ ] G0–G5 全部门禁通过
- [ ] `main..HEAD` 提交历史清晰（每任务至少 1 次提交）
- [ ] 工作区干净，`dist/`、`target/`、`node_modules/` 未入库
- [ ] `docs/` 交付物齐全：PRD_TEMPLATE、PRD、DESIGN、API_TEST、TEST_REPORT、prompts、VIDEO_SCRIPT、EXECUTION_PLAN
- [ ] 测试 0 失败；失败项已记录且不影响验收
- [ ] 视频链接与 PR 链接已提供
