#!/bin/bash
# common.sh —— 公共配置与环境探测（被 first-login.sh / web-checkin.sh source）
# 安全约定：本目录下所有文件均不含凭据；会话 cookie 由浏览器 profile 保管

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-$0}")/.." && pwd)"
STATE_DIR="$SKILL_DIR/.state"
mkdir -p "$STATE_DIR"

CONFIG="$SKILL_DIR/config/browser.json"
APP_URL="https://www.workbuddy.cn/app"

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
api_checkin() {
  playwright-cli eval "(async () => { const r = await fetch('/billing/meter/daily-checkin', { method: 'POST', credentials: 'include' }); return r.status + '|' + (await r.text()); })()" 2>/dev/null | sed 's/\\"/"/g'
}
