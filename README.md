English | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt-BR.md)

<p align="center">
  <img src="icon/mole-poses/wordmark-logo.png" width="160" alt="mole logo">
</p>

<p align="center">Skip the commands, get to work.<br>別管指令，直接開工。</p>

<p align="center"><a href="https://st6ar1.github.io/mole/">st6ar1.github.io/mole</a></p>

<p align="center">
  <img src="docs/screenshots/app-icon.png" width="120" alt="mole app icon">
</p>

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="mole's main window: drop a project folder in, it detects and launches automatically">
</p>

A tiny macOS utility: drop a project folder in, and mole figures out what kind of project it is, runs it in the background, and opens your browser — no pile of Terminal windows. You can also see exactly which localhost services are currently running, and stop them with one click.

## Why I made this

<p align="center">
  <img src="docs/screenshots/story.png" width="280" alt="Why I made this app">
</p>

I'm not a professional developer. After a lot of vibe coding, I ended up with more and more projects, couldn't remember the start commands, and kept losing track of which localhost ports were even running.

And I didn't want to ask an AI all over again just to get a project running.

So I made mole. Drop in the folder, and it takes care of the rest.

## Features

- **Drag-and-drop launch**: drop a folder onto the window, or use "Choose Folder" — mole detects the project type and launches it automatically. Supports Node.js (npm / pnpm / yarn / bun), static sites, Python, Ruby / Rails, Go, Rust, Docker Compose, Deno, PHP, Flutter, Java / Kotlin, .NET, Chrome extensions, native macOS apps, and more
- **Runs entirely in the background**: no more Terminal windows piling up — the launch command's output is still logged, you just don't have to look at it
- **Running Projects list**: each service automatically picks up the site's `<title>` or favicon so you can tell projects apart at a glance; Keep Alive (⭐️) and Stop (✕) are visible, clickable icons — no menu to dig through
- **Auto Close**: automatically close idle services after a configurable amount of time; pinned (Keep Alive) projects are never touched
- **9-language interface**: English, 繁體中文, 简体中文, 日本語, 한국어, Français, Español, Deutsch, and Português (Brasil) — switch languages instantly in Settings, no restart needed. The language list is always shown in the same fixed order, with each language written in its own native name
- **Auto-update**: checks for a newer version on launch, with a one-click download and install

## Screenshots

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="mole main window">
</p>

## How it works

Drop a folder onto mole, and it will:

1. Inspect the folder's contents (`package.json`, `Gemfile`, `go.mod`, `Dockerfile`, …) to figure out the project type
2. Build the matching launch command and run it in the background (output goes to a log file, no Terminal window pops up)
3. Poll for a new localhost port coming up
4. Open the browser automatically once it's detected — or, if there's no web port to detect (a native app, a backend-only service, etc.), mark the launch as done right away

## Installation

Requires macOS 12+.

### Option 1: Download the app

1. Download the latest `mole-x.x.x.dmg` from [Releases](https://github.com/ST6AR1/mole/releases/latest)
2. Open the DMG and drag the app into `Applications`
3. Since there's no paid Apple Developer certificate, the first launch will show an "unidentified developer" warning — in Finder, **Control-click the app → Open**, or allow it under **System Settings → Privacy & Security**. This only happens once

### Option 2: Build from source

```bash
xcode-select --install   # if you haven't already
git clone https://github.com/ST6AR1/mole.git
cd mole
./build.sh
```

This produces `mole.app` in the project folder — drag it into `Applications` to use it.

## Supported Platforms

macOS 12 (Monterey) and later only, on both Apple Silicon and Intel.

## Privacy

mole runs entirely on your own machine. It doesn't collect or upload any usage data or project content; the only network calls it makes are checking GitHub for a newer version on launch (a read-only call to the Releases API — no device info is sent back), and opening a pre-filled GitHub Issue page when you click "Report an Issue" yourself.

## FAQ

**Q: It's stuck on "Waiting for localhost" — what now?**
A: If it's a backend-only service, a database, or a native app, there's no web port to find in the first place, and it'll mark itself done automatically after a bit. If it's still running `npm install`, pulling a Docker image, or some other setup step, check the log/Terminal for real progress instead of dropping the folder in again.

**Q: I picked the wrong language and can't read the UI anymore — help?**
A: In the Settings language dropdown, every language is shown in its own native name (e.g. "Français", "日本語") and always appears in the same fixed order, so you can find the one you can read without needing to decode anything else first.

**Q: What project types are supported?**
A: Node.js (npm / pnpm / yarn / bun), static sites, Python, Ruby / Rails, Go, Rust, Docker Compose, Deno, PHP, Flutter, Java / Kotlin, .NET, Chrome extensions, native macOS apps, and more — detection keeps expanding over time.

## License

MIT — see [LICENSE](LICENSE). Free and open source; use it, fork it, ship your own build.

## Development

- `App/main.swift`: the entire app's source (pure AppKit, no SwiftUI)
- `App/Localization/`: the 9-language translation files (`Strings.*.swift`) and language-switching logic
- `bin/smart-launch.sh`: the shell script that detects project types and builds launch commands
- `build.sh`: compiles and packages the `.app`
- `make-dmg.sh`: packages a distributable `.dmg`
- `site/`: the official website ([Astro](https://astro.build)), deployed to GitHub Pages — see `site/README.md`

Cutting a release:

```bash
./make-dmg.sh
gh release create vX.Y.Z mole-X.Y.Z.dmg --title "vX.Y.Z" --notes "What changed this time"
```

## Credits

Made by Wen and Claude, together ⌯^⦁𖥦⦁^⌯
