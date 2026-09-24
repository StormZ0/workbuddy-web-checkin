---
name: workbuddy-web-checkin
display_name: WorkBuddy 网页版自动签到
display_name_en: WorkBuddy Web Check-in
description: WorkBuddy 网页版每日积分自动签到。无需桌面端，浏览器登录一次后每天自动领取签到积分（100/天，连续第7天1000）。幂等安全：当天短路、随机延迟、异常熔断、凭据不落盘。触发词：WorkBuddy 签到、自动签到、领积分、每日积分。
description_zh: WorkBuddy 网页版每日积分自动签到。无需桌面端，浏览器登录一次后每天自动领取签到积分（100/天，连续第7天1000）。幂等安全：当天短路、随机延迟、异常熔断、凭据不落盘。
description_en: Daily WorkBuddy web check-in automation. Claims daily credits (100/day, 1000 on day 7) via the same-origin official API after one QR-code login. No desktop client required; idempotent, rate-safe, credentials never stored.
version: "1.0.0"
license: MIT
author: StormZ0
---

# WorkBuddy 网页版每日自动签到

为**只用 WorkBuddy 网页版（或不愿安装桌面端）的用户**提供每日签到自动化。核心发现：WorkBuddy 网页版登录后，可携带 Keycloak 会话 cookie 直接调用**同源官方签到接口**，无需获取或存储任何 token。

## 红线（先读这个）

本 skill 只做以下事，且**永远不越界**：

- ✅ 仅操作**使用者本人**的账号（扫码登录即本人授权）
- ✅ 仅访问腾讯官方域名：`workbuddy.cn`、`cloud.tencent.com`
- ✅ 每天**至多 1 次**真实接口调用（等同人类正常签到频率）
- ❌ 不做多账号 / 批量注册 / 接口爆破 / 任何放大滥用
- ❌ 不上传任何凭据给第三方；token 全程留在浏览器内存
- ❌ 日志只记结果（积分/天数/成败），绝不记 cookie 或 token
- ⚠️ 若官方明确禁止此类自动化，应立即停用本 skill

## 依赖

| 依赖 | 用途 | 缺失时 |
|---|---|---|
| playwright-cli（`npm i -g @playwright/cli`） | 浏览器自动化 | 脚本会报错并提示安装 |
| Chrome/Chromium（系统自带即可） | 持久化会话浏览器 | 用 `--browser` 指定或安装 |
| Node.js ≥ 20 | playwright-cli 运行时 | 安装 nodejs |

## 使用流程

### 首次使用：扫码登录（唯一需要人工的一步）

```bash
bash scripts/first-login.sh
```

脚本会打开 WorkBuddy 登录页、自动勾选协议并点击同意、截取微信二维码保存到当前目录（`登录二维码.png`），把二维码展示给用户，等待扫码完成（脚本轮询 URL 直到跳回 `/app`，超时 5 分钟自动刷新二维码）。

### 日常签到（幂等，可重复执行）

```bash
bash scripts/web-checkin.sh
```

输出四种结果之一：

| 输出 | 含义 | 后续动作 |
|---|---|---|
| `SUCCESS credit=+X streak=N` | 签到成功 | 汇报「领取 X 积分，连续 N 天」 |
| `ALREADY_CHECKED` / `DONE_TODAY` | 今日已签 | 一句话汇报，勿展开 |
| `NEED_RELOGIN` | 登录态过期（约1年后） | 重新跑 `first-login.sh` |
| `CIRCUIT_BREAKER` | 连续失败已熔断 | 排查后删除 skill 目录下 `.paused` 解除 |

### 定时自动化

脚本幂等 + 当天短路，可放心设多个触发点（推荐 `FREQ=DAILY;BYHOUR=9,12,15,18,21;BYMINUTE=0;BYSECOND=0`）。在 WorkBuddy 内用自动化任务触发本脚本时，Prompt 参见 @references/automation-prompt.md。

## 工作原理

```
触发（自动化任务/手动）
 → [熔断检测] 连续失败≥3 → 停机待人工
 → [当天短路] 本地标记文件命中 → 0 接口调用，直接退出
 → [随机延迟] 0~240s 打散整点指纹
 → [会话检测] 打开 workbuddy.cn/app，跳到 /login 即登录态失效
 → [官方接口] POST /billing/meter/daily-checkin（同源 cookie 认证）
 → [三态判定] code=0 成功 / "已签到"视为成功 / 其他记失败
```

关键点：腾讯网页版对 `www.workbuddy.cn/billing/meter/*` 提供同源代理，浏览器 cookie 直接认证，因此**无需逆向或存储 accessToken**——凭据攻击面比读桌面端登录态文件的方案更小。

## 排错

见 @references/troubleshooting.md。常见：无浏览器环境（装 playwright-cli）、UA 指纹警告（保持脚本自带配置勿改）、积分未到账（以个人中心用量页为准，接口返回有延迟）。

## 致谢与谱系

- [Coco-katarina/workbuddy-checkin](https://github.com/Coco-katarina/workbuddy-checkin)：桌面端路线先驱，本 skill 的幂等三态与「不做什么」清单格式沿用其设计
- [SIMON-WORLD/workbuddy-daily-credit](https://github.com/SIMON-WORLD/workbuddy-daily-credit)：三段式校验（查状态→可领才领→领完复核）与 `checkin-activity-status` 接口线索
- 本 skill 差异化：**网页版零桌面依赖**，凭据攻击面最小化（cookie 会话 vs 明文/解密读取令牌文件）
