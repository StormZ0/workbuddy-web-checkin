#!/bin/bash
# web-checkin.sh —— WorkBuddy 网页版每日签到（幂等 · 自愈版 v2）
# 安全设计：当天短路（≤1次接口调用）| 随机延迟 | 异常熔断 | 日志无凭据
# 用法：bash scripts/web-checkin.sh
set -u
source "$(dirname "$0")/common.sh"
ensure_runtime

URL="$APP_URL"
MARK="$STATE_DIR/.done_$(date +%F)"     # 当天成功标记
FAILS="$STATE_DIR/.fail_streak"         # 连续失败计数
PAUSE="$STATE_DIR/.paused"              # 熔断标记
LOG="$STATE_DIR/checkin.log"

# 0) 熔断检测：连续失败≥3次后暂停，需人工删除 .paused 解除
if [[ -f "$PAUSE" ]]; then
  echo "RESULT: CIRCUIT_BREAKER | 连续失败过多已熔断，排查后删除 $PAUSE 解除"
  exit 3
fi

# 1) 当天已成功 → 短路，不产生任何接口流量
if [[ -f "$MARK" ]]; then
  echo "RESULT: DONE_TODAY | 今天已成功签到（本地标记），跳过"
  exit 0
fi

# 2) 随机延迟 0~240s，打散整点执行模式
DELAY=$((RANDOM % 240))
echo "[$(date '+%F %T')] random delay ${DELAY}s" >> "$LOG"
sleep "$DELAY"

# 3) 启动浏览器（自检 + 脏锁自愈），检测登录态
if ! ensure_browser; then
  echo "[$(date '+%F %T')] browser recovery failed" >> "$LOG"
fi

LOC=$(playwright-cli eval "location.href" 2>/dev/null | grep -o 'https://[^"\\]*' | head -1)
if [[ "$LOC" == *"/login"* ]]; then
  echo "$(date +%s)" >> "$FAILS"
  N=$(wc -l < "$FAILS" | tr -d ' ')
  [[ $N -ge 3 ]] && touch "$PAUSE" && echo "[$(date '+%F %T')] CIRCUIT_BREAKER trips=$N" >> "$LOG"
  echo "[$(date '+%F %T')] NEED_RELOGIN" >> "$LOG"
  echo "RESULT: NEED_RELOGIN | 登录态失效，需重新扫码（bash scripts/first-login.sh）"
  exit 2
fi

# 4) 调官方签到接口（同源 cookie 认证，无 token）
RES=$(api_checkin)
HTTP=$(echo "$RES" | tr -d '"' | head -1 | grep -o '^[0-9]*')
CREDIT=$(echo "$RES" | grep -o '"credit":[0-9]*' | head -1 | grep -o '[0-9]*$')
STREAK=$(echo "$RES" | grep -o '"streak_days":[0-9]*' | head -1 | grep -o '[0-9]*$')

# 5) 结果判定（三态幂等）+ 异常风控信号监测
if [[ "$RES" == *'"code":0'* && -n "$CREDIT" ]]; then
  date +%s > "$MARK"; > "$FAILS"
  echo "[$(date '+%F %T')] SUCCESS credit=+$CREDIT streak=$STREAK http=$HTTP" >> "$LOG"
  echo "RESULT: SUCCESS credit=+$CREDIT streak=$STREAK"
elif [[ "$RES" == *"已签到"* ]]; then
  date +%s > "$MARK"; > "$FAILS"
  echo "[$(date '+%F %T')] ALREADY_CHECKED http=$HTTP" >> "$LOG"
  echo "RESULT: ALREADY_CHECKED"
else
  echo "$(date +%s)" >> "$FAILS"
  N=$(wc -l < "$FAILS" | tr -d ' ')
  [[ $N -ge 3 ]] && touch "$PAUSE" && echo "[$(date '+%F %T')] CIRCUIT_BREAKER trips=$N" >> "$LOG"
  echo "[$(date '+%F %T')] FAILED http=$HTTP resp=${RES:0:200}" >> "$LOG"
  echo "RESULT: FAILED http=$HTTP"
  exit 1
fi
