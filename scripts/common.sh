#!/bin/bash
# common.sh —— 公共配置与环境探测（被 first-login.sh / web-checkin.sh source）
# 安全约定：本目录下所有文件均不含凭据；会话 cookie 由浏览器 profile 保管

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$SKILL_DIR/.state"
CONFIG_DIR="$SKILL_DIR/config"
CONFIG="$CONFIG_DIR/browser.json"
APP_URL="https://www.workbuddy.cn/app"

# 目录必须在使用前创建（否则首次运行 gen_config 写文件会失败）
mkdir -p "$STATE_DIR" "$CONFIG_DIR"

# 探测系统浏览器
detect_browser() {
  for b in /usr/bin/google-chrome /usr/bin/google-chrome-stable /usr/bin/chromium /usr/bin/chromium-browser /opt/google/chrome/chrome; do
    [[ -x "$b" ]] && { echo "$b"; return 0; }
  done
  command -v google-chrome || command -v chromium || command -v chromium-browser
}

gen_config() {
  local CHROME
  CHROME="$(detect_browser)"
  [[ -z "$CHROME" ]] && { echo "ERROR: 未找到 Chrome/Chromium，请安装后重试"; exit 1; }
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG" << EOF
{
  "browser": {
    "launchOptions": {
      "chromiumSandbox": false,
      "executablePath": "$CHROME",
      "userAgent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
    },
    "contextOptions": { "locale": "zh-CN", "timezoneId": "Asia/Shanghai" }
  },
  "outputMode": "stdout"
}
EOF
  chmod 600 "$CONFIG"
}

ensure_runtime() {
  command -v playwright-cli >/dev/null 2>&1 || { echo "ERROR: playwright-cli 未安装（npm i -g @playwright/cli）"; exit 1; }
  [[ -f "$CONFIG" ]] || gen_config
}

# 同源签到接口调用（无 token，仅 cookie）
# playwright-cli 输出形如：
#   ### Result
#   "200|{...}"
# 因此这里抽取形如 "数字|内容" 的结果行并去掉转义引号，供下游直接解析 HTTP 与 body。
api_checkin() {
  playwright-cli eval "(async () => { const r = await fetch('/billing/meter/daily-checkin', { method: 'POST', credentials: 'include' }); return r.status + '|' + (await r.text()); })()" 2>/dev/null \
    | sed 's/\\"/"/g' \
    | grep -E '^"?[0-9]{3}\|' | head -1
}

# ── 浏览器启停（含自检+自动恢复，2026-09-24 加固）──
# 背景：daemon 脏锁会导致 open 静默失败；不恢复就会一路滑到 FAILED http=
_start_browser() {
  local url="${1:-$APP_URL}"
  playwright-cli open "$url" --persistent --config="$CONFIG" >/dev/null 2>&1 || true
  sleep 3
  local probe
  probe=$(playwright-cli eval "1+1" 2>/dev/null | grep -c "2")
  [[ "$probe" -ge 1 ]]
}

# 清理 daemon 脏锁（仅在自检失败时调用，正常路径零开销）
# 注意：chrome 真实可执行文件通常是 /opt/google/chrome/chrome，不含 "google-chrome" 字样，
# 因此必须按 /google/chrome/ 路径特征匹配，否则会漏杀子进程导致 profile 仍被占用。
_recover_browser() {
  local self=$$ pids
  for pid in $(ps aux | grep -iE "playwright|/google/chrome/|google-chrome|chromium" | grep -v grep | awk '{print $2}'); do
    [[ "$pid" == "$self" ]] && continue
    kill -9 "$pid" 2>/dev/null || true
  done
  # 通用锁清理：适配 playwright 不同版本的缓存目录
  # 用 find 而非 glob，避免 zsh 在无匹配时报 "no matches found"
  find "$HOME/.cache/ms-playwright/daemon" -name "Singleton*" -delete 2>/dev/null || true
  find "$HOME/.cache/ms-playwright/daemon" -name "*.lock" -delete 2>/dev/null || true
  find "$HOME/.cache/ms-playwright/daemon" -path "*ud-default-chrome/Singleton*" -delete 2>/dev/null || true
  sleep 2
}

# 带自愈的浏览器启动：失败则清理脏锁重试一次
ensure_browser() {
  _start_browser "$@" && return 0
  echo "[$(date '+%F %T')] browser probe failed, attempting recovery" >> "${LOG:-/dev/null}"
  _recover_browser
  _start_browser "$@"
}
