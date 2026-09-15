[English](README.md) | [繁體中文](README.zh-TW.md) | 简体中文 | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt-BR.md)

<p align="center">
  <img src="icon/mole-poses/wordmark-logo.png" width="160" alt="mole logo">
</p>

<p align="center">别管指令，直接开工。<br>Skip the commands, get to work.</p>

<p align="center"><a href="https://st6ar1.github.io/mole/">st6ar1.github.io/mole</a></p>

<p align="center">
  <img src="docs/screenshots/app-icon.png" width="120" alt="mole app icon">
</p>

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="mole 主界面：把项目文件夹拖进去，自动检测并启动">
</p>

一个 macOS 小工具：把项目文件夹拖进去，mole 会自动判断是什么类型的项目、在后台帮你跑起来、打开浏览器，全程不会弹出一堆 Terminal 窗口。也能随时看到目前有哪些 localhost 服务在跑，一键关闭。

## 为什么做这个

<p align="center">
  <img src="docs/screenshots/story.png" width="280" alt="为什么做这个 App">
</p>

我不是专业开发者。Vibe coding 做久了，项目越来越多，启动指令记不住，连 localhost 开了哪些也常常搞不清楚。

我又不想每次只是为了重新把项目跑起来，就再问一次 AI。

所以做了 mole。把文件夹丢进来，剩下交给它。

## 功能

- **拖拽启动**：把文件夹拖进窗口，或用「选择文件夹」，自动检测项目类型并启动——支持 Node.js（npm / pnpm / yarn / bun）、静态网页、Python、Ruby / Rails、Go、Rust、Docker Compose、Deno、PHP、Flutter、Java / Kotlin、.NET、Chrome 扩展、原生 macOS App 等等
- **完全在后台运行**：不会再弹出 Terminal 窗口——启动指令的输出还是有记录，只是不用再忍受窗口一直堆起来
- **运行中项目列表**：每个服务会自动抓取网站的 `<title>` 或 favicon，一眼看出是哪个项目；常驻（⭐️）和停止（✕）都是看得到、点得到的图标，不用打开菜单
- **自动关闭**：可设置多久没用就自动关闭闲置的服务，标记常驻的项目不受影响
- **9 语言界面**：English、繁體中文、简体中文、日本語、한국어、Français、Español、Deutsch、Português (Brasil)，设置里可以实时切换语言，不用重启 App；语言列表永远按固定顺序排列，每个语言都用自己的原生名称标注
- **自动更新**：打开时会检查最新版本，有更新可以一键下载安装

## 截图

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="mole 主界面">
</p>

## 运作方式

把文件夹拖进 mole，它会：

1. 读取文件夹内容（`package.json`、`Gemfile`、`go.mod`、`Dockerfile`……）判断项目类型
2. 组出对应的启动指令，在后台执行（输出写进日志，不弹出 Terminal 窗口）
3. 轮询是否有新的 localhost 端口打开
4. 检测到就自动打开浏览器；检测不到（原生 App、纯后端服务等）就直接标记完成

## 安装

需要 macOS 12+。

### 方式一：直接下载

1. 到 [Releases](https://github.com/ST6AR1/mole/releases/latest) 下载最新的 `mole-x.x.x.dmg`
2. 打开 DMG，把 App 拖到 `Applications`
3. 因为没有付费的 Apple 开发者证书，第一次打开会弹出「无法验证开发者」的警告——在 Finder 里**按住 Control 点两下 App → 选「打开」**，或到「系统设置 → 隐私与安全性」允许。之后就不会再弹出来了

### 方式二：从源码构建

```bash
xcode-select --install   # 如果还没装过
git clone https://github.com/ST6AR1/mole.git
cd mole
./build.sh
```

会在项目文件夹里生成 `mole.app`，拖到 `Applications` 就能用。

## 支持平台

仅支持 macOS 12 (Monterey) 以上，Apple Silicon 与 Intel 都可以。

## 隐私

mole 完全在你自己的电脑上运行。它不会收集、上传任何使用数据或项目内容；唯一对外连接的地方是启动时检查 GitHub 上有没有新版本（只读 Releases API，不会回传任何设备信息），以及你自己点击「反馈问题」时，打开预先填好内容的 GitHub Issue 页面。

## 常见问题

**Q：拖进去之后一直卡在「等待 localhost」？**
A：如果是纯后端、数据库服务或原生 App，本来就不会有网页端口，等一下就会自动标记完成。如果是还在跑 `npm install`、拉取 Docker 镜像之类的初始化，可以到 Terminal／日志文件看实际进度，不需要重新拖入。

**Q：语言选错了、看不懂目前的界面怎么办？**
A：设置的语言下拉菜单里，每个语言都用自己的原生名称显示（例如「Français」「日本語」），并且永远按固定顺序排列，可以直接找到自己看得懂的那个。

**Q：支持哪些项目类型？**
A：Node.js（npm / pnpm / yarn / bun）、静态网页、Python、Ruby / Rails、Go、Rust、Docker Compose、Deno、PHP、Flutter、Java / Kotlin、.NET、Chrome 扩展、原生 macOS App 等等，检测逻辑还会持续扩充。

## 许可协议

MIT 许可协议，详见 [LICENSE](LICENSE)。免费且开源，欢迎使用、fork、打包成自己的版本。

## 开发

- `App/main.swift`：整个 App 的源码（纯 AppKit，没有用 SwiftUI）
- `App/Localization/`：9 语言翻译文件（`Strings.*.swift`）与语言切换逻辑
- `bin/smart-launch.sh`：检测项目类型、组出启动指令的 shell script
- `build.sh`：编译、打包成 `.app`
- `make-dmg.sh`：打包成可分发的 `.dmg`

发布新版本：

```bash
./make-dmg.sh
gh release create vX.Y.Z mole-X.Y.Z.dmg --title "vX.Y.Z" --notes "这次改了什么"
```

## Credits

由 温 Wen 和 Claude 协同制作 ⌯^⦁𖥦⦁^⌯
