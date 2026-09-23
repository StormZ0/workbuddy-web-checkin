# WorkBuddy 自动化任务 · 签到触发 Prompt 模板

在 WorkBuddy 内创建 recurring 自动化任务时，将下方内容作为 Prompt（按实际路径替换 `/path/to/skill`）：

```text
执行 Bash 命令：bash /path/to/skill/scripts/web-checkin.sh

该脚本已内置安全机制（当天短路/随机延迟/熔断），重复运行无副作用。
根据退出码和输出汇报：
1) SUCCESS credit=+X streak=N → 「今日签到成功，领取X积分，已连续N天」
2) ALREADY_CHECKED 或 DONE_TODAY → 一句话「今日已签，跳过」，勿展开
3) NEED_RELOGIN → 「WorkBuddy 登录态过期，请运行 scripts/first-login.sh 重新扫码」
4) CIRCUIT_BREAKER → 「签到已自动熔断暂停（连续异常），请人工排查后
   删除 /path/to/skill/.state/.paused 解除」
5) FAILED → 「签到异常，HTTP 状态已记入日志，请关注是否触发风控」

任何情况下不要向用户展示接口响应原文或任何凭据信息。
```

## RRULE 建议

```
FREQ=DAILY;BYHOUR=9,12,15,18,21;BYMINUTE=0;BYSECOND=0
```

- 多时间点是**冗余保险**：脚本当天短路，一天至多 1 次真实接口调用
- 若设备全天开机，单个时间点（如 BYHOUR=10）即可
