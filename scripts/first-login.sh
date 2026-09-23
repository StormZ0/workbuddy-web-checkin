#!/bin/bash
# first-login.sh —— 首次登录引导：生成微信二维码，等待用户扫码
# 仅操作使用者本人账号；二维码本地截图展示，不经过任何第三方
set -u
source "$(dirname "$0")/common.sh"
ensure_runtime

playwright-cli open "$APP_URL" --persistent --config="$CONFIG" >/dev/null 2>&1 || true
sleep 3

LOC=$(playwright-cli eval "location.href" 2>/dev/null | grep -o 'https://[^"\\]*' | head -1)
if [[ "$LOC" != *"/login"* ]]; then
  echo "RESULT: ALREADY_LOGGED_IN | 已有有效登录态，无需扫码（如需换账号请清空浏览器 profile）"
  exit 0
fi

# 勾选协议 + 点同意（登录 UI 元素可能在可访问性树之外，用 DOM 直操作）
playwright-cli eval "(() => { const cb = document.querySelector('.t-checkbox__former, input[type=checkbox]'); if (cb && !cb.checked) cb.click(); return 'ok'; })()" >/dev/null 2>&1
sleep 1
playwright-cli eval "(() => { const b = document.querySelector('.agree-btn, button[class*=agree]'); if (b) b.click(); return 'ok'; })()" >/dev/null 2>&1
sleep 5

QR="$PWD/登录二维码.png"
playwright-cli screenshot --filename="$QR" >/dev/null 2>&1
[[ -f "$QR" ]] || QR="$PWD/qr.png" && playwright-cli screenshot --filename="$QR" >/dev/null 2>&1

echo "二维码已保存：$QR （请用微信扫码，与 WorkBuddy 相同的微信）"
echo "等待扫码确认，最长 5 分钟..."

for i in $(seq 1 60); do
  sleep 5
  LOC=$(playwright-cli eval "location.href" 2>/dev/null | grep -o 'https://[^"\\]*' | head -1)
  if [[ "$LOC" != *"/login"* ]]; then
    echo "RESULT: LOGIN_OK | 登录成功，会话已保存到本地浏览器 profile（约1年有效）"
    exit 0
  fi
  # 每 60 秒刷新一次二维码（微信码约2-3分钟过期）
  if (( i % 12 == 0 )); then
    playwright-cli eval "(() => { const b = document.querySelector('.agree-btn, button[class*=agree]'); if (b) b.click(); return 'ok'; })()" >/dev/null 2>&1
    sleep 5
    playwright-cli screenshot --filename="$QR" >/dev/null 2>&1
    echo "二维码可能已过期，已刷新：$QR"
  fi
done

echo "RESULT: TIMEOUT | 5分钟内未完成扫码，请重新运行本脚本"
exit 2
