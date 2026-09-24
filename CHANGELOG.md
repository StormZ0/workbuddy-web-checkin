# Changelog

## 1.2.0 (2026-09-24)

> **修复性发布** —— 1.1.0 及更早版本在**全新环境首次运行会直接失败**。强烈建议更新。

### 🔴 致命修复

- **`config/` 目录从未创建** → 干净环境首次运行 100% 失败（`config/browser.json: No such file or directory`）。
  此前在自己机器上"测试通过"是因为 `config/` 目录恰好早已存在，掩盖了该缺陷。
  现在在 `common.sh` 加载时即 `mkdir -p` 状态目录与配置目录，`gen_config` 内亦做兜底。

### 🔴 高危修复

- **`SKILL_DIR` 路径解析错位一层** → 原来用 `BASH_SOURCE[1]`，被 `source` 时为空并回退到 `$0`（`bash`），
  导致 `SKILL_DIR` 指向技能目录的**上一层**，配置与状态文件被写到技能目录之外（多技能互相污染）。
  改用 `BASH_SOURCE[0]`，始终稳定指向 `common.sh` 自身。
- **浏览器进程清理正则漏匹配** → 原正则 `google-chrome|chromium` 匹配不到真实可执行路径
  `/opt/google/chrome/chrome`，只能杀掉 3/11 个进程，子进程残留导致 profile 仍被占用、**自愈失效**。
  改为按 `/google/chrome/` 路径特征匹配，实测 10 → 0 个进程全部清理。
- **HTTP 状态码解析恒为空** → `playwright-cli` 输出带 `### Result` 前缀，原 `head -1` 取到的是该前缀而非数字，
  导致失败时只显示无信息量的 `FAILED http=`。现在 `api_checkin` 直接抽取结果行。
- **登录态失效静默滑过** → 补回 v1.1.0 重写时丢失的 `-z "$LOC"` 空值判定；新增 401/403 兜底，
  使登录失效时明确提示 `NEED_RELOGIN` 而非笼统的 `FAILED`。

### 🟡 其他

- 锁文件清理改用 `find -path`，避免 zsh 下 glob 无匹配时报 `no matches found`
- `_recover_browser` 增加 PID 自我保护，杜绝极端路径下的自杀风险
- README 平台声明据实修正：明确支持 **Linux / macOS**（需 Chrome/Chromium），不再声明 Windows
- README「在 WorkBuddy 内使用」重写：明确**推荐在对话中直接使用**，脚本在当前环境自举，零手工配置

### 验证矩阵（本次全部在隔离 HOME 环境下复测）

| 场景 | 结果 |
|---|---|
| 全新目录 + 无 `.state` + 无 `config`，首次运行 | ✅ 自动建配置并跑通 |
| 注入脏锁后运行 | ✅ 自愈触发，10 → 0 进程，锁清理干净 |
| 无登录态（隔离环境） | ✅ 正确报 `NEED_RELOGIN http=401` |
| 有登录态（真实环境） | ✅ `ALREADY_CHECKED`，HTTP 正常解析 |
| `SKILL_DIR` 路径解析 | ✅ 精确指向技能目录 |

## 1.1.0 (2026-09-24)

- ✅ **上架 WorkBuddy 官方技能库**（过审 2026-09-24）
- **浏览器自检 + 脏锁自愈**：启动后用探针验证会话活性，失败时自动清理 daemon 残留锁并重试一次（修复：daemon 脏锁导致 `open` 静默失败、签到哑火）
- **运行时可移植化**：移除全部硬编码绝对路径（`SKILL_DIR` 自动推导、`$HOME` 适配、浏览器路径探测），任意用户任意目录开箱即用
- **SKILL.md frontmatter 补全**至官方九件套规范（`display_name` / `description_zh` / `description_en` / `version` / `license` / `author`）
- README 增补：上架徽章、常见问题、云端自动化不可行的实测结论（云端任务为一次性隔离沙箱）
- 代码共享化：`ensure_browser` / `_recover_browser` 上移至 `common.sh`，消除运行时与发行版的重复实现

## 1.0.0 (2026-09-23)

- 首个开源版本
- 网页版同源接口签到（无需桌面端）
- 幂等三态判定 + 当天短路（每天 ≤1 次真实调用）
- 拟人化：随机延迟 0-240s、正常 Chrome UA、zh-CN 时区
- 异常熔断：连续失败 ≥3 自动停机待人工
- 首跑扫码引导 `first-login.sh`（二维码过期自动刷新）
- 排错手册与 WorkBuddy 自动化任务 Prompt 模板

### 验证矩阵

| 平台 | 状态 |
|---|---|
| Linux + Chrome（root，沙箱容器） | ✅ 实测通过（2026-09-23 credit=100 streak=1；2026-09-24 credit=+100 streak=2） |
| Linux 全新目录零配置安装 | ✅ 实测通过（2026-09-24，自动探测浏览器 + 自动生成配置） |
| macOS | 理论兼容（macOS Chrome 路径已纳入探测），欢迎 PR 补验证 |
| Windows | ❌ 当前不支持（脚本为 Bash + 类 Unix 路径探测）；如需请提 Issue |
