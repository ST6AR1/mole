<p align="center">
  <img src="icon/mole-poses/wordmark-logo.png" width="160" alt="mole logo">
</p>

<p align="center">別管指令，直接開工。<br>Skip the commands, get to work.</p>

<p align="center">
  <img src="docs/screenshots/app-icon.png" width="120" alt="mole app icon">
</p>

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="mole 主畫面：把專案資料夾拖進去，自動偵測並啟動">
</p>

一個 macOS 小工具：把專案資料夾拖進去，mole 會自動判斷是什麼類型的專案、在背景幫你跑起來、打開瀏覽器，全程不會跳出一堆 Terminal 視窗。也能隨時看到目前有哪些 localhost 服務在跑，一鍵關閉。

## 為什麼做這個

<p align="center">
  <img src="docs/screenshots/story.png" width="280" alt="為什麼做這個 App">
</p>

我不是專業開發者。Vibe coding 做久了，專案越來越多，啟動指令記不住，連 localhost 開了哪些也常常搞不清楚。

我又不想每次只是為了重新把專案跑起來，就再問一次 AI。

所以做了 mole。把資料夾丟進來，剩下交給它。

## 功能

- **拖曳啟動**：把資料夾拖進視窗，或用「選擇資料夾」，自動偵測專案類型並啟動——支援 Node.js（npm / pnpm / yarn / bun）、靜態網頁、Python、Ruby / Rails、Go、Rust、Docker Compose、Deno、PHP、Flutter、Java / Kotlin、.NET、Chrome 擴充功能、原生 macOS App 等等
- **完全在背景執行**：不會再跳出 Terminal 視窗——啟動指令的輸出還是有記錄，只是不用再忍受視窗一直堆起來
- **Running Projects 清單**：每個服務會自動抓網站的 `<title>` 或 favicon，一眼看出是哪個專案；常駐（⭐️）跟 Stop（✕）都是看得到、按得到的圖示，不用點開選單
- **Auto Close**：可設定多久沒用就自動關閉閒置的服務，標記常駐的專案不受影響
- **中英雙語介面**：Settings 裡可以即時切換語言，不用重開 App
- **自動更新**：開啟時會檢查最新版本，有更新可以一鍵下載安裝

## 安裝

需要 macOS 12+。

### 方式一：直接下載

1. 到 [Releases](https://github.com/ST6AR1/mole/releases/latest) 下載最新的 `mole-x.x.x.dmg`
2. 打開 DMG，把 App 拖到 `Applications`
3. 因為沒有付費的 Apple 開發者憑證，第一次打開會跳出「無法驗證開發者」的警告——在 Finder 裡**按住 Control 點兩下 App → 選「打開」**，或到「系統設定 → 隱私權與安全性」允許。之後就不會再跳出來了

### 方式二：從原始碼建置

```bash
xcode-select --install   # 如果還沒裝過
git clone https://github.com/ST6AR1/mole.git
cd mole
./build.sh
```

會在專案資料夾裡產生 `mole.app`，拖到 `Applications` 就能用。

## 開發

- `App/main.swift`：整個 App 的原始碼（純 AppKit，沒有用 SwiftUI）
- `bin/smart-launch.sh`：偵測專案類型、組出啟動指令的 shell script
- `build.sh`：編譯、打包成 `.app`
- `make-dmg.sh`：打包成可散布的 `.dmg`

發新版本：

```bash
./make-dmg.sh
gh release create vX.Y.Z mole-X.Y.Z.dmg --title "vX.Y.Z" --notes "這次改了什麼"
```

---

由 溫 Wen 和 Claude 協同製作 ⌯^⦁𖥦⦁^⌯
