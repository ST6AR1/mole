#!/bin/bash
# smart-launch.sh <folder>
# 偵測資料夾內是什麼類型的專案，並在新的 Terminal 視窗中執行對應的啟動指令。

set -u

# 用 AppleScript "do shell script" 啟動時 PATH 很精簡，補上常見的安裝位置
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$HOME/.nvm/current/bin:$PATH"

DIR="${1:-$(pwd)}"
DIR="$(cd "$DIR" 2>/dev/null && pwd)"

if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  osascript -e "display alert \"Smart Launch\" message \"找不到資料夾：$1\""
  exit 1
fi

cd "$DIR" || exit 1

CMD=""
LABEL=""

pkg_manager() {
  if [ -f pnpm-lock.yaml ]; then echo "pnpm"
  elif [ -f yarn.lock ]; then echo "yarn"
  elif [ -f bun.lockb ]; then echo "bun"
  else echo "npm"
  fi
}

has_script() {
  # $1 = script name, checks package.json "scripts" block
  if command -v node >/dev/null 2>&1; then
    node -e "
      try {
        const s = require('$DIR/package.json').scripts || {};
        process.exit(s['$1'] ? 0 : 1);
      } catch (e) { process.exit(1); }
    " 2>/dev/null
    return $?
  fi
  # node 不可用時，用 grep 抓 "scriptName": 這個 key（用純文字比對，夠用即可）
  grep -qE "\"$1\"[[:space:]]*:" "$DIR/package.json" 2>/dev/null
}

run_pkg_script() {
  local script="$1"
  local pm
  pm="$(pkg_manager)"
  case "$pm" in
    pnpm) echo "pnpm run $script" ;;
    yarn) echo "yarn $script" ;;
    bun) echo "bun run $script" ;;
    npm) echo "npm run $script" ;;
  esac
}

# 偵測順序：優先找「一鍵啟動整個專案」的方式（package.json 的 dev/start script，
# 常見於 monorepo，例如同時啟動 docker 依賴 + 前端 + API），
# 找不到才退回單獨啟動 docker-compose 或其他更底層的方式。

# 0. 已經打包好的原生 macOS App（資料夾裡有 .app）：直接開啟，不是網頁，不需要啟動 server
APP_BUNDLE="$(find . -maxdepth 1 -name "*.app" -print -quit 2>/dev/null)"
if [ -n "$APP_BUNDLE" ]; then
  CMD="open $(printf '%q' "$APP_BUNDLE")"
  LABEL="macOS App（直接開啟）"
fi

# 0b. Xcode 專案：用 Xcode 打開
if [ -z "$CMD" ]; then
  XC_PROJ="$(find . -maxdepth 1 \( -name "*.xcworkspace" -o -name "*.xcodeproj" \) -print -quit 2>/dev/null)"
  if [ -n "$XC_PROJ" ]; then
    CMD="open $(printf '%q' "$XC_PROJ")"
    LABEL="Xcode 專案"
  fi
fi

# 0c. Swift Package（原生 App 的原始碼，還沒打包成 .app）
if [ -z "$CMD" ] && [ -f Package.swift ]; then
  if [ -x Scripts/run.sh ]; then
    CMD="./Scripts/run.sh"
  elif [ -f Scripts/run.sh ]; then
    CMD="bash Scripts/run.sh"
  else
    CMD="swift run"
  fi
  LABEL="Swift Package"
fi

# 1. Node.js 專案（優先）
if [ -f package.json ]; then
  if [ ! -d node_modules ]; then
    pm="$(pkg_manager)"
    case "$pm" in
      pnpm) INSTALL="pnpm install" ;;
      yarn) INSTALL="yarn install" ;;
      bun) INSTALL="bun install" ;;
      npm) INSTALL="npm install" ;;
    esac
  else
    INSTALL=""
  fi

  if has_script dev; then
    RUN="$(run_pkg_script dev)"
  elif has_script start; then
    RUN="$(run_pkg_script start)"
  elif has_script serve; then
    RUN="$(run_pkg_script serve)"
  else
    RUN=""
  fi

  if [ -n "$RUN" ]; then
    if [ -n "$INSTALL" ]; then
      CMD="$INSTALL && $RUN"
    else
      CMD="$RUN"
    fi
    LABEL="Node.js ($(pkg_manager))"
  fi
fi

# 1b. Monorepo：根目錄的 package.json 沒有可執行的 dev/start/serve（例如只是個共用 library），
#     但常見的子資料夾自己有一份 package.json 而且可以跑，例如 Tauri/Electron 專案常見的
#     根目錄 = 共用程式碼、desktop/ = 桌面 App、web/ = 前端
if [ -z "$CMD" ]; then
  for sub in desktop app client frontend web packages/desktop packages/app packages/web; do
    SUBDIR="$DIR/$sub"
    [ -f "$SUBDIR/package.json" ] || continue

    SUB_SCRIPT=""
    for s in dev start serve; do
      if grep -qE "\"$s\"[[:space:]]*:" "$SUBDIR/package.json" 2>/dev/null; then
        SUB_SCRIPT="$s"
        break
      fi
    done
    [ -n "$SUB_SCRIPT" ] || continue

    if [ -f "$SUBDIR/pnpm-lock.yaml" ]; then
      SUB_PM="pnpm"; SUB_RUN="pnpm run $SUB_SCRIPT"; SUB_INSTALL="pnpm install"
    elif [ -f "$SUBDIR/yarn.lock" ]; then
      SUB_PM="yarn"; SUB_RUN="yarn $SUB_SCRIPT"; SUB_INSTALL="yarn install"
    elif [ -f "$SUBDIR/bun.lockb" ]; then
      SUB_PM="bun"; SUB_RUN="bun run $SUB_SCRIPT"; SUB_INSTALL="bun install"
    else
      SUB_PM="npm"; SUB_RUN="npm run $SUB_SCRIPT"; SUB_INSTALL="npm install"
    fi

    if [ -d "$SUBDIR/node_modules" ]; then
      CMD="cd $(printf '%q' "$sub") && $SUB_RUN"
    else
      CMD="cd $(printf '%q' "$sub") && $SUB_INSTALL && $SUB_RUN"
    fi
    LABEL="Node.js 子專案 ($sub, $SUB_PM)"
    break
  done
fi

# 2. docker-compose（package.json 沒有可用的 dev/start/serve 時，才單獨啟動 docker）
if [ -z "$CMD" ] && { [ -f docker-compose.yml ] || [ -f compose.yaml ] || [ -f compose.yml ]; }; then
  CMD="if ! docker info >/dev/null 2>&1; then echo '>> Docker 尚未啟動，正在打開 Docker Desktop...'; open -a Docker 2>/dev/null; printf '>> 等待 Docker 就緒'; i=0; until docker info >/dev/null 2>&1 || [ \$i -ge 60 ]; do printf '.'; sleep 1; i=\$((i+1)); done; echo; if docker info >/dev/null 2>&1; then echo '>> Docker 已就緒'; else echo '>> 等待逾時，請確認已安裝並手動啟動 Docker Desktop'; fi; fi; docker compose up"
  LABEL="Docker Compose"
fi

# 3. Python - Django
if [ -z "$CMD" ] && [ -f manage.py ]; then
  if [ -d venv ]; then ACT="source venv/bin/activate && "; elif [ -d .venv ]; then ACT="source .venv/bin/activate && "; else ACT=""; fi
  CMD="${ACT}python3 manage.py runserver"
  LABEL="Django"
fi

# 4. Python - FastAPI / Flask / 其他
if [ -z "$CMD" ] && { [ -f requirements.txt ] || [ -f pyproject.toml ]; }; then
  if [ -d venv ]; then ACT="source venv/bin/activate && "; elif [ -d .venv ]; then ACT="source .venv/bin/activate && "; else ACT=""; fi
  if grep -qiE "fastapi|uvicorn" requirements.txt pyproject.toml 2>/dev/null; then
    ENTRY="main:app"
    for f in main.py app.py src/main.py; do
      [ -f "$f" ] && ENTRY="$(basename "$f" .py):app" && break
    done
    CMD="${ACT}uvicorn $ENTRY --reload"
    LABEL="FastAPI"
  elif grep -qi "flask" requirements.txt pyproject.toml 2>/dev/null; then
    ENTRY="app.py"
    [ -f main.py ] && ENTRY="main.py"
    CMD="${ACT}python3 $ENTRY"
    LABEL="Flask"
  elif [ -f app.py ]; then
    CMD="${ACT}python3 app.py"
    LABEL="Python (app.py)"
  elif [ -f main.py ]; then
    CMD="${ACT}python3 main.py"
    LABEL="Python (main.py)"
  else
    CMD="${ACT}python3 -m http.server 8000"
    LABEL="Python (fallback http.server)"
  fi
fi

# 5. Ruby / Rails
if [ -z "$CMD" ] && [ -f Gemfile ]; then
  if [ -f config/application.rb ]; then
    CMD="bundle exec rails s"
    LABEL="Rails"
  else
    CMD="bundle exec ruby app.rb"
    LABEL="Ruby"
  fi
fi

# 6. Go
if [ -z "$CMD" ] && [ -f go.mod ]; then
  CMD="go run ."
  LABEL="Go"
fi

# 7. Rust
if [ -z "$CMD" ] && [ -f Cargo.toml ]; then
  CMD="cargo run"
  LABEL="Rust"
fi

# 8. Makefile 有 dev/run/start target
if [ -z "$CMD" ] && [ -f Makefile ] && grep -qE "^(dev|run|start):" Makefile; then
  TARGET="dev"
  grep -qE "^dev:" Makefile || TARGET="run"
  grep -qE "^(dev|run):" Makefile || TARGET="start"
  CMD="make $TARGET"
  LABEL="Makefile ($TARGET)"
fi

# 9. Deno
if [ -z "$CMD" ] && { [ -f deno.json ] || [ -f deno.jsonc ]; }; then
  if grep -qE '"(dev|start)"' deno.json deno.jsonc 2>/dev/null; then
    TASK="dev"
    grep -qE '"dev"' deno.json deno.jsonc 2>/dev/null || TASK="start"
    CMD="deno task $TASK"
  else
    ENTRY="main.ts"
    for f in main.ts main.js src/main.ts mod.ts; do
      [ -f "$f" ] && ENTRY="$f" && break
    done
    CMD="deno run --allow-net --allow-read --allow-env $ENTRY"
  fi
  LABEL="Deno"
fi

# 10. PHP
if [ -z "$CMD" ] && { [ -f composer.json ] || [ -f index.php ]; }; then
  CMD="php -S localhost:8000"
  LABEL="PHP"
fi

# 11. Flutter
if [ -z "$CMD" ] && [ -f pubspec.yaml ]; then
  CMD="flutter run -d macos"
  LABEL="Flutter"
fi

# 12. Java / Kotlin (Gradle / Maven)
if [ -z "$CMD" ] && [ -f gradlew ]; then
  if grep -qE "bootRun" build.gradle build.gradle.kts 2>/dev/null; then
    CMD="./gradlew bootRun"
  else
    CMD="./gradlew run"
  fi
  LABEL="Gradle"
elif [ -z "$CMD" ] && [ -f pom.xml ]; then
  if grep -q "spring-boot" pom.xml 2>/dev/null; then
    CMD="mvn spring-boot:run"
  else
    CMD="mvn compile exec:java"
  fi
  LABEL="Maven"
fi

# 13. .NET / C#
if [ -z "$CMD" ] && { ls ./*.csproj >/dev/null 2>&1 || ls ./*.sln >/dev/null 2>&1; }; then
  CMD="dotnet run"
  LABEL=".NET"
fi

# 14. Chrome 擴充功能 (manifest.json，不是 npm 專案)
if [ -z "$CMD" ] && [ -f manifest.json ] && grep -q "manifest_version" manifest.json 2>/dev/null; then
  CMD="open -a 'Google Chrome' --args --load-extension=$(printf '%q' "$DIR")"
  LABEL="Chrome 擴充功能"
fi

# 15. 專案自帶的啟動腳本 (start.sh / run.sh / dev.sh)，找不到其他明確線索時的救援方案
if [ -z "$CMD" ]; then
  for f in start.sh run.sh dev.sh; do
    if [ -f "$f" ]; then
      CMD="bash $f"
      LABEL="Shell Script ($f)"
      break
    fi
  done
fi

# 16. 純網頁 (index.html / 靜態網站，沒有任何 build 工具)
if [ -z "$CMD" ] && { [ -f index.html ] || ls ./*.html >/dev/null 2>&1; }; then
  if command -v npx >/dev/null 2>&1; then
    CMD="npx --yes serve -l 5173 ."
  else
    CMD="python3 -m http.server 8000"
  fi
  LABEL="靜態網頁"
fi

if [ -z "$CMD" ]; then
  if [ "${SMART_LAUNCH_DRY_RUN:-}" = "1" ]; then
    echo "偵測結果：找不到可辨識的專案類型"
    exit 1
  fi
  osascript -e "display alert \"Smart Launch\" message \"看不出來 $DIR 是什麼類型的專案，無法自動啟動。\" as warning"
  exit 1
fi

echo "$LABEL" > /tmp/smartlaunch-last-label.txt

if [ "${SMART_LAUNCH_DRY_RUN:-}" = "1" ]; then
  echo "偵測結果：$LABEL"
  echo "啟動指令：$CMD"
  exit 0
fi

# 用暫存腳本檔案來執行，避免 CMD 內容（可能含有單引號等）在字串拼接時破壞外層引號
# （曾經發生過 CMD 裡的 '>>' 被誤判成真的 shell redirect，在專案資料夾裡生出垃圾檔案）
TMP_SCRIPT="$(mktemp "${TMPDIR:-/tmp}/smartlaunch.XXXXXX")"

# 同時把實際輸出寫進一個固定的 log 檔，讓 GUI 可以即時讀最後一行顯示「目前在跑什麼」
# 固定用 /tmp（而非 $TMPDIR），因為這支腳本可能被不同的呼叫端（GUI App / shell）
# 用不同的環境變數啟動，只有 /tmp 這種絕對路徑能保證雙方看到同一個檔案
LOG_FILE="/tmp/smartlaunch-latest.log"
: > "$LOG_FILE"

{
  echo "#!/bin/bash"
  echo "cd $(printf '%q' "$DIR")"
  echo "echo '>> 偵測到：$LABEL'"
  echo "echo '>> 指令：請看下面'"
  echo "( $CMD ) 2>&1 | tee -a $(printf '%q' "$LOG_FILE")"
} > "$TMP_SCRIPT"
chmod +x "$TMP_SCRIPT"

osascript <<EOF
tell application "Terminal"
  activate
  do script "bash $(printf '%q' "$TMP_SCRIPT")"
end tell
EOF
