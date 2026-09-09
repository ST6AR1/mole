#!/bin/bash
# ports.sh [--watch]
# 顯示目前本機所有正在監聽 (LISTEN) 的 TCP port。
# 會把看起來像「開發伺服器」的 process（node/python/ruby/go/php/deno/bun/rails...）
# 挑出來放最上面，其他系統背景服務（WeChat/Dropbox/Spotify 等）收在下面。
# --watch: 每 2 秒自動刷新一次

DEV_PATTERN="^(node|python|python3|ruby|go|php|php-fpm|deno|bun|java|ngrok|caddy|nginx|webpack|vite|next|rails|uvicorn|gunicorn|flask)$"

show_ports() {
  local raw
  raw=$(lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | awk 'NR>1')

  if [ -z "$raw" ]; then
    echo "目前沒有偵測到任何 LISTEN 中的服務。"
    return
  fi

  local dev_rows=()
  local other_rows=()

  while IFS= read -r line; do
    local cmd_name pid addr port full_cmd row
    cmd_name=$(echo "$line" | awk '{print $1}')
    pid=$(echo "$line" | awk '{print $2}')
    addr=$(echo "$line" | awk '{print $9}')
    port=$(echo "$addr" | sed -E 's/.*:([0-9]+)$/\1/')
    full_cmd=$(ps -p "$pid" -o command= 2>/dev/null | cut -c1-50)
    row="$(printf "%-8s %-16s %-8s %-50s" "$port" "$cmd_name" "$pid" "$full_cmd")"

    if echo "$cmd_name" | grep -qiE "$DEV_PATTERN"; then
      dev_rows+=("$port|$row")
    else
      other_rows+=("$port|$row")
    fi
  done <<< "$raw"

  echo "開發伺服器 (可能是你自己跑的專案)："
  echo "--------------------------------------------------------------------"
  if [ "${#dev_rows[@]}" -eq 0 ]; then
    echo "  (目前沒有偵測到)"
  else
    printf "%-8s %-16s %-8s %-50s\n" "PORT" "程式" "PID" "指令"
    printf '%s\n' "${dev_rows[@]}" | sort -t'|' -k1,1n -u | cut -d'|' -f2-
  fi

  echo ""
  echo "其他系統背景服務："
  echo "--------------------------------------------------------------------"
  if [ "${#other_rows[@]}" -eq 0 ]; then
    echo "  (無)"
  else
    printf '%s\n' "${other_rows[@]}" | sort -t'|' -k1,1n -u | cut -d'|' -f2-
  fi

  echo "--------------------------------------------------------------------"
  echo "提示：瀏覽器打開 http://localhost:<PORT> 即可查看；結束對應 Terminal 分頁 (Ctrl+C) 即可關閉該服務。"
}

if [ "${1:-}" = "--watch" ]; then
  while true; do
    clear
    date "+%H:%M:%S"
    show_ports
    sleep 2
  done
else
  show_ports
fi
