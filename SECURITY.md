# 安全说明（威胁模型）

## 凭据生命周期

```
微信扫码授权（用户本人）
  → Keycloak 会话 cookie 写入本机浏览器 profile（~/.cache/ms-playwright/...）
      ↓ 每次签到
  浏览器带着 cookie 请求同源接口 www.workbuddy.cn/billing/meter/*
      → 腾讯服务端完成认证，全程无 token 经手
```

- cookie 由 Chrome profile 机制保管（与普通浏览器登录态同等安全级别）
- 本 skill 的任何脚本**不读取、不复制、不传输** cookie 内容
- 日志（`references` 外的 `.state/checkin.log`）仅含：时间、结果、积分、HTTP 状态码

## 信任边界

| 组件 | 信任级别 | 说明 |
|---|---|---|
| `scripts/*.sh` | 可审计 | 全部开源，无混淆，无网络出站（除官方域名） |
| `config/browser.json` | 自动生成 | 仅含浏览器路径与 UA 字符串，`chmod 600` |
| playwright-cli / Chrome | 第三方运行时 | 与官方 skill 同级依赖，建议用发行版渠道安装 |
| WorkBuddy 自动化任务 | 用户自建 | Prompt 模板见 references，汇报逻辑禁止输出凭据 |

## 已知限制与残余风险

1. 浏览器 profile 内的 cookie 对本机同用户进程可见（与普通浏览器一致的风险面）
2. 若账号开启短信二次验证，重新登录需用户在场（设计使然，非缺陷）
3. 官方接口路径/行为可能变更，脚本以失败熔断兜底，不会静默误操作

## 事件响应

- 会话疑似泄露：WorkBuddy 个人中心「退出所有设备」→ 重跑 `first-login.sh`
- 发现滥用 fork/二次分发：本仓库不支持、不背书任何批量账号用途
