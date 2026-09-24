# Changelog

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
| macOS / Windows | 理论兼容（路径探测已抽象），欢迎 PR 补验证 |
