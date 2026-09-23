# 排错手册

## 安装与运行

| 症状 | 原因 | 解法 |
|---|---|---|
| `playwright-cli 未安装` | 无浏览器自动化运行时 | `npm i -g @playwright/cli` |
| `未找到 Chrome/Chromium` | 系统无浏览器 | 安装 Chrome，或手动编辑 `config/browser.json` 的 `executablePath` |
| `Daemon process exited with code 1` + sandboxing failed | 以 root 运行且未禁沙箱 | 确认 `config/browser.json` 中 `chromiumSandbox: false`（common.sh 已自动生成） |
| 下载浏览器内核超时/被墙 | playwright 默认源不可达 | **无需下载内核**，本 skill 用系统 Chrome（`executablePath` 已指定） |

## 登录与会话

| 症状 | 原因 | 解法 |
|---|---|---|
| `NEED_RELOGIN` 频繁出现 | 会话被服务端提前失效 | 重跑 `first-login.sh`；检查是否有其他设备登出 |
| 扫码后无反应 | 二维码过期（约2-3分钟） | 脚本每 60s 自动刷新；或手动重跑 |
| 登录后要求短信验证码 | 账号开启了二次验证 | 在页面上完成验证（需用户在场，属正常安全机制） |
| 扫码完成但仍报未登录 | 跳转未完成 | 等待几秒重跑 `web-checkin.sh` |

## 签到结果

| 症状 | 原因 | 解法 |
|---|---|---|
| `FAILED` + HTTP 429/403 | 可能触发风控 | **立即熔断观察**，勿连续重试；检查 UA/延迟配置是否被改动 |
| `SUCCESS` 但积分未到账 | 接口与余额页同步延迟 | 以 WorkBuddy 个人中心用量页为准；持续不涨再反馈 issue |
| 连续签到归零 | 断签（某天所有触发点均未成功） | 检查触发时段设备是否开机；增加触发点数量 |
| `checkin-status` 显示未签但实际已签 | 该接口与签到数据不同步（已知现象，桌面端 skill 文档亦有记录） | 以 `daily-checkin` 返回为准，勿依赖 status 接口 |

## 安全事件响应

- 疑似凭据泄露：立即在 WorkBuddy 个人中心退出所有会话（会使浏览器 cookie 失效），再重新扫码
- 频繁 `FAILED` 且响应含异常字段：删除 `.state/.paused` 前先**连续观察 24h**，确认非风控信号
- 发现本 skill 被用于批量账号：向仓库提 issue，维护者将拒绝技术支持
