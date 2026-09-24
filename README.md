# workbuddy-web-checkin

> ✅ **已上架 WorkBuddy 官方技能库**（2026-09-24 过审）——在 WorkBuddy 内搜索「**WorkBuddy 网页版自动签到**」即可一键安装。

WorkBuddy **网页版**每日积分自动签到 Skill —— 无需桌面端、无后端、凭据不落盘。

> 每天自动领取 WorkBuddy「今日礼包」的 100 积分（连续第 7 天 1000 积分），再也不怕断连。

## 与现有方案的对比

| | 本项目 | [Coco-katarina/workbuddy-checkin](https://github.com/Coco-katarina/workbuddy-checkin) | [SIMON-WORLD/workbuddy-daily-credit](https://github.com/SIMON-WORLD/workbuddy-daily-credit) |
|---|---|---|---|
| 桌面端依赖 | **无需** | 需要（读本地登录态文件） | 需要（Windows 侧重） |
| 凭据获取 | 浏览器 cookie 会话（扫码一次） | 读明文 JSON / Electron 解密 vscdb | 读 `%LOCALAPPDATA%` 登录态文件 |
| 调用方式 | 同源代理接口（cookie 认证） | Bearer token 直调官方接口 | Bearer token 直调官方接口 |
| token 落盘 | **无**（token 不经手） | 内存中转，不落盘 | 内存中转，不落盘 |
| 幂等 | 三态判定 + 当天短路 | code=10001 兜底 | 查状态→可领才领→领完复核 |
| 拟人化 | 随机延迟 0-240s + 正常 UA | — | — |
| 熔断 | 连续失败≥3 自动停机 | — | — |
| 适用平台 | Linux / macOS（沙箱、容器、桌面均可；需有 Chrome/Chromium） | macOS / Linux / Windows | Windows / macOS |

三个项目互为补充：装了桌面端选他们，**只用网页版选我们**。

## 快速开始

```bash
npm i -g @playwright/cli        # 一次性
bash scripts/first-login.sh     # 扫码登录（唯一人工步骤）
bash scripts/web-checkin.sh     # 签到（幂等，可重复跑）
```

详见 [SKILL.md](SKILL.md)。

## 在 WorkBuddy 内使用

**推荐用法：在对话里直接用。** 脚本设计为在**当前运行环境**内自举——只要环境有 Chrome/Chromium 和 `playwright-cli`（WorkBuddy 沙箱默认具备），无需任何手工配置，首次运行会自动生成浏览器配置。

```bash
bash scripts/first-login.sh     # 扫码登录（唯一人工步骤，登录态持久化在浏览器 profile）
bash scripts/web-checkin.sh     # 签到（幂等，当天重复跑自动短路）
```

在对话中直接说「帮我签到」即可触达本 skill。

**关于定时自动化**：本 skill 需要浏览器登录态持久化，因此**云端一次性沙箱任务不适用**（每次全新容器、无持久 profile，已实测验证）。若需定时，请在有持久化环境的机器上用本地 crontab：

```bash
# 本地 crontab 示例：每天 9 点签到
0 9 * * * bash /path/to/workbuddy-web-checkin/scripts/web-checkin.sh >> /tmp/wb-checkin.out 2>&1
```

若你的 WorkBuddy 环境支持本地任务执行，可使用 `references/automation-prompt.md` 中的模板提示词。

## 常见问题

**Q：浏览器起不来 / 报 daemon 错误？**
A：脚本内置自检与脏锁自愈（v1.1.0 起）。若仍失败，手动清理：杀掉残留的 playwright/chrome 进程，删除 `~/.cache/ms-playwright/daemon` 下的 `Singleton*` 文件后重试。

**Q：提示 NEED_RELOGIN？**
A：重跑 `bash scripts/first-login.sh` 扫码即可（登录态一般可维持一年）。

**Q：积分没到账？**
A：接口返回与个人中心显示有延迟，以 [个人中心用量页](https://www.workbuddy.cn/profile/plans-usage) 为准。

## 安全与合规（第一性原理）

- **仅限本人账号**：扫码登录即本人授权，不支持也不会协助多账号
- **凭据最小攻击面**：不读取、不存储、不传输任何 token；会话 cookie 仅存在于本机浏览器 profile
- **官方接口白名单**：仅 `workbuddy.cn` / `cloud.tencent.com`，无任何第三方上报
- **频率等同人类**：每天至多 1 次真实调用 + 随机延迟拟人化
- **异常熔断**：连续失败自动停机，绝不硬刚风控
- **日志脱敏**：只记积分/天数/HTTP 状态，无任何凭据

详细威胁模型见 [SECURITY.md](SECURITY.md)。

## 不做什么

- ❌ 不做多账号 / 批量注册 / 刷分
- ❌ 不破解、不模拟 GUI 大规模点击
- ❌ 不绕过任何官方限制
- ⚠️ 若腾讯官方明确禁止此类自动化，请立即停用本工具

## License

[MIT](LICENSE)
