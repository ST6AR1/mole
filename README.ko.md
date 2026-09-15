[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | 한국어 | [Français](README.fr.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt-BR.md)

<p align="center">
  <img src="icon/mole-poses/wordmark-logo.png" width="160" alt="mole logo">
</p>

<p align="center">명령어는 필요 없어요, 바로 작업을 시작하세요.<br>Skip the commands, get to work.</p>

<p align="center">
  <img src="docs/screenshots/app-icon.png" width="120" alt="mole app icon">
</p>

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="mole 메인 화면: 프로젝트 폴더를 드롭하면 자동으로 감지하고 실행">
</p>

macOS용 작은 유틸리티예요. 프로젝트 폴더를 드롭하기만 하면 mole이 어떤 종류의 프로젝트인지 알아내고, 백그라운드에서 실행한 뒤 브라우저를 자동으로 열어줍니다. Terminal 창이 잔뜩 쌓일 일도 없어요. 현재 실행 중인 localhost 서비스도 한눈에 확인하고, 클릭 한 번으로 종료할 수 있습니다.

## 이 앱을 만든 이유

<p align="center">
  <img src="docs/screenshots/story.png" width="280" alt="이 앱을 만든 이유">
</p>

저는 전문 개발자가 아니에요. vibe coding을 계속하다 보니 프로젝트가 점점 늘어났고, 실행 명령어는 기억이 안 나고, 어떤 localhost 포트가 돌아가고 있는지도 계속 헷갈렸어요.

그리고 프로젝트 하나 다시 실행하겠다고 매번 AI한테 다시 물어보고 싶지도 않았고요.

그래서 mole을 만들었습니다. 폴더만 던져 놓으면 나머지는 알아서 해줍니다.

## 기능

- **드래그 앤 드롭 실행**: 폴더를 창에 드롭하거나 "폴더 선택"을 사용하면, mole이 프로젝트 유형을 자동으로 감지해서 실행합니다. 지원 대상: Node.js(npm / pnpm / yarn / bun), 정적 사이트, Python, Ruby / Rails, Go, Rust, Docker Compose, Deno, PHP, Flutter, Java / Kotlin, .NET, Chrome 확장 프로그램, 네이티브 macOS 앱 등
- **완전한 백그라운드 실행**: Terminal 창이 더 이상 쌓이지 않아요. 실행 명령어의 출력은 여전히 로그로 남지만, 굳이 들여다볼 필요는 없습니다
- **실행 중 프로젝트 목록**: 각 서비스는 사이트의 `<title>`이나 favicon을 자동으로 가져와서, 어떤 프로젝트인지 한눈에 구분할 수 있어요. 상시 유지(⭐️)와 중지(✕)는 메뉴를 열지 않아도 바로 보이고 클릭할 수 있는 아이콘입니다
- **자동 종료(Auto Close)**: 설정한 시간 동안 사용하지 않은 서비스를 자동으로 종료합니다. 상시 유지로 고정한 프로젝트는 건드리지 않아요
- **9개 언어 인터페이스**: English, 繁體中文, 简体中文, 日本語, 한국어, Français, Español, Deutsch, Português (Brasil). Settings에서 즉시 언어를 전환할 수 있고, 앱을 다시 시작할 필요도 없습니다. 언어 목록은 항상 같은 고정된 순서로 표시되며, 각 언어는 자신의 고유 표기로 쓰여 있습니다
- **자동 업데이트**: 실행할 때마다 새 버전이 있는지 확인하고, 클릭 한 번으로 다운로드 및 설치할 수 있습니다

## 스크린샷

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="mole 메인 화면">
</p>

## 작동 방식

폴더를 mole에 드롭하면 다음 순서로 진행됩니다.

1. 폴더 내용(`package.json`, `Gemfile`, `go.mod`, `Dockerfile` 등)을 확인해서 프로젝트 유형을 판단
2. 해당하는 실행 명령어를 구성하고 백그라운드에서 실행(출력은 로그 파일에 기록되고, Terminal 창은 뜨지 않음)
3. 새로운 localhost 포트가 열리는지 주기적으로 확인
4. 감지되면 자동으로 브라우저를 열고, 감지할 웹 포트가 없는 경우(네이티브 앱, 백엔드 전용 서비스 등)에는 바로 완료로 표시

## 설치

macOS 12 이상이 필요합니다.

### 방법 1: 앱 다운로드

1. [Releases](https://github.com/ST6AR1/mole/releases/latest)에서 최신 `mole-x.x.x.dmg`를 다운로드
2. DMG를 열고 앱을 `Applications`로 드래그
3. 유료 Apple 개발자 인증서를 사용하지 않기 때문에, 처음 실행할 때 "확인되지 않은 개발자" 경고가 표시됩니다. Finder에서 **Control 키를 누른 채 앱을 클릭 → 열기**를 선택하거나, **시스템 설정 → 개인정보 보호 및 보안**에서 허용해주세요. 이 과정은 처음 한 번만 필요합니다

### 방법 2: 소스에서 직접 빌드

```bash
xcode-select --install   # 아직 설치하지 않았다면
git clone https://github.com/ST6AR1/mole.git
cd mole
./build.sh
```

프로젝트 폴더 안에 `mole.app`이 생성됩니다. `Applications`로 드래그하면 사용할 수 있어요.

## 지원 플랫폼

macOS 12 (Monterey) 이상에서만 동작하며, Apple Silicon과 Intel을 모두 지원합니다.

## 개인정보 보호

mole은 전적으로 사용자의 컴퓨터에서 실행됩니다. 사용 데이터나 프로젝트 내용을 수집하거나 업로드하지 않아요. 유일하게 발생하는 네트워크 요청은 실행 시 GitHub에서 새 버전이 있는지 확인하는 것(Releases API에 대한 읽기 전용 호출로, 기기 정보는 전송되지 않음)과, 사용자가 직접 "문제 신고"를 클릭했을 때 미리 채워진 GitHub Issue 페이지를 여는 것뿐입니다.

## 자주 묻는 질문

**Q: "Waiting for localhost"에서 멈춰 있어요. 어떻게 해야 하나요?**
A: 백엔드 전용 서비스, 데이터베이스, 네이티브 앱이라면 애초에 찾을 웹 포트가 없기 때문에, 잠시 후 자동으로 완료 처리됩니다. 아직 `npm install`을 실행 중이거나 Docker 이미지를 받는 중이라면, 폴더를 다시 드롭하지 말고 로그나 Terminal에서 실제 진행 상황을 확인해주세요.

**Q: 언어를 잘못 선택해서 UI를 읽을 수 없게 됐어요. 어떻게 해야 하나요?**
A: Settings의 언어 드롭다운에서는 각 언어가 자신의 고유 표기(예: "Français", "日本語")로 표시되고, 항상 같은 고정된 순서로 나열됩니다. 다른 표시를 해석할 필요 없이 읽을 수 있는 언어를 바로 찾을 수 있어요.

**Q: 어떤 프로젝트 유형을 지원하나요?**
A: Node.js(npm / pnpm / yarn / bun), 정적 사이트, Python, Ruby / Rails, Go, Rust, Docker Compose, Deno, PHP, Flutter, Java / Kotlin, .NET, Chrome 확장 프로그램, 네이티브 macOS 앱 등이며, 감지 범위는 계속 확장되고 있습니다.

## 라이선스

MIT 라이선스 — 자세한 내용은 [LICENSE](LICENSE)를 참고하세요. 무료 오픈소스이며, 자유롭게 사용, 포크, 자체 빌드 배포가 가능합니다.

## 개발

- `App/main.swift`: 앱 전체의 소스 코드(순수 AppKit, SwiftUI 미사용)
- `App/Localization/`: 9개 언어 번역 파일(`Strings.*.swift`)과 언어 전환 로직
- `bin/smart-launch.sh`: 프로젝트 유형을 감지하고 실행 명령어를 구성하는 shell script
- `build.sh`: `.app`을 컴파일하고 패키징
- `make-dmg.sh`: 배포용 `.dmg`로 패키징

새 버전 배포하기:

```bash
./make-dmg.sh
gh release create vX.Y.Z mole-X.Y.Z.dmg --title "vX.Y.Z" --notes "이번에 바뀐 내용"
```

## Credits

Made by Wen and Claude, together ⌯^⦁𖥦⦁^⌯
