import type { Dictionary } from "./types";

// Terminology kept in sync with the app's own Strings.ko.swift where it
// overlaps (tagline, "실행 중인 프로젝트", "자동 종료", etc.).
export const ko: Dictionary = {
  meta: {
    title: "Mole — 폴더를 놓으면, 로컬 프로젝트가 실행돼요",
    description:
      "Mole은 vibe coder를 위한 무료 오픈소스 macOS 도구예요. 프로젝트 폴더를 놓으면 실행 방법을 자동으로 판단하고, 백그라운드에서 localhost를 실행하고, 브라우저를 열어요. 경로도, 명령어도, Terminal도 필요 없어요.",
  },
  nav: {
    features: "기능",
    changelog: "업데이트 내역",
    support: "후원",
    github: "GitHub",
    download: "다운로드",
  },
  hero: {
    tagline: "명령어는 잊고, 바로 시작하세요.",
    h1Line1: "프로젝트는 사라진 게 아니에요,",
    h1Line2: "그냥 땅속으로 들어간 것뿐이에요.",
    subhead:
      "프로젝트 폴더를 Mole에 놓으세요. 실행 방법을 판단하고, localhost를 실행하고, 브라우저를 열어줘요. 경로도, 명령어도, Terminal도 필요 없어요.",
    ctaPrimary: "Mole 다운로드",
    ctaSecondary: "GitHub에서 보기",
    versionLine: "무료 · macOS 12+ · 4.8 MB",
  },
  problem: {
    line1: "AI로 만들었어요.",
    line2: "그리고 Terminal을 닫았죠.",
    line3: "그런데…… 다시 어떻게 열죠?",
    q1: "어느 폴더였더라?",
    q2: "무슨 명령어를 썼더라?",
    q3: "어느 localhost 포트였더라?",
  },
  solution: {
    eyebrow: "작동 방식",
    heading: "귀찮은 부분은 Mole이 기억해요.",
    steps: [
      {
        title: "폴더를 넣으세요",
        body: "Mole에 드래그하거나 '폴더 선택'으로 골라주세요. 그게 전부예요.",
      },
      {
        title: "Mole이 알아서 판단해요",
        body: "안에 뭐가 있는지 확인하고, Vite인지 Next.js, Python, Rails, Docker Compose인지, 아니면 다른 무엇인지——그리고 어떻게 실행할지 판단해요.",
      },
      {
        title: "실행",
        body: "백그라운드에서 실행되고, 브라우저에서 localhost를 열어줘요. Terminal 창도, 탭 더미도 생기지 않아요.",
      },
    ],
  },
  features: {
    eyebrow: "Mole이 하는 일",
    heading: "한 가지 일만 하는 작은 도구예요.",
    items: [
      {
        title: "놓기만 하면 끝",
        body: "드롭 존은 하나뿐이에요. 폴더를 드래그하거나 직접 선택하세요——나머지는 Mole이 알아서 해요.",
      },
      {
        title: "스마트 판단",
        body: "Node(npm, pnpm, yarn, bun), 정적 사이트, Python, Ruby on Rails, Go, Rust, Docker Compose 등등. Mole이 폴더를 읽고 알맞은 명령어를 골라요.",
      },
      {
        title: "백그라운드에서 실행",
        body: "데스크탑에 Terminal 창이 쌓이지 않아요. 출력은 로그에 계속 기록되니, 필요할 때 확인할 수 있어요.",
      },
      {
        title: "실행 상태 확인",
        body: "모든 localhost 서비스가 이름과 favicon과 함께 표시돼요. 중요한 프로젝트는 고정해두고, 나머지는 종료하거나 자동 종료에 맡기세요.",
      },
    ],
  },
  moleMoment: {
    line1: "프로젝트는 사라지지 않아요.",
    line2: "그냥 땅속으로 들어갈 뿐이에요.",
    line3: "Mole은 어디 있는지 알고 있어요.",
  },
  vibeCoding: {
    eyebrow: "vibe coding을 위해",
    heading: "npm run dev가 뭔지 알기도 전에 이미 뭔가를 만들어낸 사람들을 위해.",
    body: "디자이너, 인디 메이커, AI 빌더, 그리고 AI로 만드는 법을 배우고 있는 모든 사람을 위해. Mole은 엔지니어의 Terminal을 대체하려는 게 아니에요——애초에 Terminal을 열고 싶지 않은 사람들을 위한 거예요.",
    quote:
      "저는 전문 개발자가 아니에요. 바이브 코딩을 계속하다 보니 프로젝트가 점점 늘어났고, 실행 명령어를 다 외우지 못했고, 어떤 localhost 포트가 켜져 있는지도 헷갈리기 시작했어요. 그래서 mole을 만들었어요. 폴더만 넣으면 나머지는 알아서 처리해요.",
    quoteAttribution: "——Wen, Mole을 만든 사람",
  },
  openSource: {
    eyebrow: "오픈소스",
    heading: "무료, 오픈소스, 누구나 코드를 볼 수 있어요.",
    points: [
      "GitHub에 소스 공개, MIT 라이선스",
      "Issue와 기여를 환영해요",
      "계정도, 구독도, 텔레메트리도 없어요",
    ],
    ctaGithub: "GitHub에서 스타 누르기",
    support: "Mole 후원하기 ♡",
  },
  download: {
    heading: "다시 프로젝트를 파낼 준비 되셨나요?",
    ctaPrimary: "macOS용 다운로드",
    ctaSecondary: "GitHub에서 보기",
    version: "Mole",
    platform: "macOS 12 이상",
    arch: "Apple Silicon 및 Intel 통합 지원(universal)",
    size: "약 4.8 MB",
    howToOpenSummary: "Mole을 처음 여시나요?",
    howToOpenBody:
      "Mole은 아직 Apple 공증을 받지 않아서, macOS가 '확인되지 않은 개발자'라고 경고를 표시해요. Finder에서 Control 키를 누른 채 mole.app을 클릭하고 '열기'를 선택하세요——한 번만 하면 돼요.",
    limitationsSummary: "아직 모든 환경에서 테스트되지는 않았어요",
    limitationsBody:
      "Mole은 지금은 macOS 전용이에요——다른 플랫폼을 살펴보기 전에 이 버전부터 안정적으로 만들려고요. 프로젝트 유형 감지는 흔한 환경들로 테스트했지만, 모든 프레임워크나 패키지 매니저, 기기 환경까지 다 확인한 건 아니에요. 문제가 있다면 GitHub에 이슈를 남겨주세요, 차근차근 처리할게요.",
  },
  footer: {
    github: "GitHub",
    download: "다운로드",
    changelog: "업데이트 내역",
    contact: "문의하기",
    license: "라이선스",
    privacy: "개인정보",
    credit: "Terminal 명령어 외우는 데 지친 인디 디자이너가 만들었어요.",
  },
  notFound: {
    heading: "여기는 아무것도 없어요.",
    body: "Mole이 다른 곳을 파고 있나 봐요.",
    cta: "홈으로 돌아가기",
  },
  support: {
    metaTitle: "Mole 후원하기",
    metaDescription:
      "Mole은 무료이고, 앞으로도 무료예요. 감사를 표현하고 싶다면, 몇 가지 선택적인 후원 방법이 있어요.",
    heading: "Mole 후원하기",
    intro:
      "Mole은 무료이고, 앞으로도 무료예요. 시간을 아껴줬고 고마움을 표현하고 싶다면, 지금 가능한 방법들이에요——완전히 자율적으로요. 앞으로 계속 추가될 예정이에요.",
    preparing: "준비 중",
    footnote: "부담도, 구독도, 계정도 필요 없어요. 이 방법들을 쓰든 안 쓰든 Mole은 똑같이 잘 작동해요.",
    backHome: "Mole로 돌아가기",
    methodsHeading: "후원 방법",
    methods: [
      {
        key: "bmc",
        label: "Buy Me a Coffee",
        ready: false,
        href: "https://buymeacoffee.com/st6ar1",
      },
      {
        key: "kofi",
        label: "Ko-fi",
        ready: false,
        href: "https://ko-fi.com/wen",
      },
      {
        key: "wechat",
        label: "WeChat Reward Code (微信讚賞碼)",
        ready: true,
        qr: true,
        qrCaption: "微信支付 · 掃碼支持",
      },
      { key: "linepay", label: "LINE Pay Money", ready: false },
      { key: "jkopay", label: "JKoPay (街口支付)", ready: false },
      { key: "opay", label: "O'Pay (歐付寶)", ready: false },
      { key: "ghsponsors", label: "GitHub Sponsors", ready: false },
      { key: "opencollective", label: "Open Collective", ready: false },
      { key: "paypalme", label: "PayPal.me", ready: false },
    ],
    contactBody: "다른 후원 방법이 필요하신가요? 작성자에게 연락해주세요.",
    contactEmail: "st6ar1@gmail.com",
  },
  contact: {
    metaTitle: "문의하기",
    metaDescription:
      "질문이나 피드백, 버그 제보가 있으신가요? 이메일을 보내주세요——협업 제안도 환영해요.",
    heading: "연락하기",
    body: "질문이나 피드백, 버그 제보, 아니면 그냥 인사하고 싶으신가요? 이메일을 보내주세요——협업 제안도 환영해요.",
    email: "st6ar1@gmail.com",
    backHome: "Mole로 돌아가기",
  },
  changelog: {
    metaTitle: "업데이트 내역 — Mole",
    metaDescription: "Mole의 릴리스별 업데이트 내용이에요.",
    heading: "업데이트 내역",
    intro: "출처:",
    generatedFrom: "GitHub Releases",
    viewOnGithub: "GitHub에서 보기",
  },
  privacyPage: {
    metaTitle: "개인정보 — Mole",
    metaDescription:
      "Mole은 오직 사용자의 컴퓨터에서만 실행돼요. 무엇을 전송하고 전송하지 않는지 정확히 설명해요.",
    heading: "개인정보",
    intro: "Mole은 오직 사용자의 컴퓨터에서만 실행돼요. 사용 데이터나 프로젝트 내용을 수집하거나 업로드하지 않아요.",
    networkHeading: "Mole이 보내는 유일한 네트워크 요청",
    networkItem1:
      "실행할 때 GitHub에서 새 버전이 있는지 확인해요——공개 Releases API에 대한 읽기 전용 요청일 뿐, 기기 정보는 전송되지 않아요.",
    networkItem2: "직접 '문제 보고하기'를 클릭했을 때만, 내용이 미리 채워진 GitHub Issue 페이지를 열어요.",
    websiteHeading: "이 웹사이트에 대해",
    websiteBody:
      "이 사이트에는 분석 도구도, 추적 픽셀도 없고, 브라우저 자체가 설정하는 것 외에 쿠키도 없어요. 여기 표시된 릴리스와 스타 수는 사이트를 빌드할 때 GitHub 공개 API에서 가져온 거예요.",
    questions: "궁금한 점이 있으신가요? 여기에서 이슈를 남겨주세요:",
  },
};
