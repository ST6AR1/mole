import type { Dictionary } from "./types";

// Terminology kept in sync with the app's own Strings.zhTW.swift and
// README.zh-TW.md where they overlap ("資料夾" not "文件夾", "專案" not
// "项目", "執行中的專案", "自動關閉", etc.) — the site and the app should
// sound like one product, and Taiwan Mandarin shouldn't just be zh-CN with
// characters swapped.
export const zhTW: Dictionary = {
  meta: {
    title: "Mole — 拖進資料夾，跑起你的本機專案",
    description:
      "Mole 是一個給 vibe coder 用的免費開源 macOS 工具。把專案資料夾拖進去，它會自動判斷怎麼執行、在背景啟動 localhost，並打開瀏覽器。不用記路徑，不用記指令，不用打開 Terminal。",
  },
  nav: {
    features: "功能",
    changelog: "更新日誌",
    support: "贊助",
    github: "GitHub",
    download: "下載",
  },
  hero: {
    tagline: "別管指令，直接開工。",
    h1Line1: "你的專案沒有遺失，",
    h1Line2: "只是轉入地下了。",
    subhead:
      "把專案資料夾拖進 Mole，它會判斷怎麼執行、啟動 localhost，並打開瀏覽器。不用記路徑，不用記指令，不用打開 Terminal。",
    ctaPrimary: "下載 Mole",
    ctaSecondary: "在 GitHub 上查看",
    versionLine: "免費 · macOS 12+ · 4.8 MB",
  },
  problem: {
    line1: "你用 AI 把它做出來了。",
    line2: "然後你關掉了 Terminal。",
    line3: "現在……要怎麼再打開它？",
    q1: "是哪個資料夾來著？",
    q2: "我用的是什麼指令？",
    q3: "是哪個 localhost port？",
  },
  solution: {
    eyebrow: "運作方式",
    heading: "無聊的部分，Mole 幫你記住。",
    steps: [
      {
        title: "把資料夾拖進來",
        body: "拖到 Mole 上，或用「選擇資料夾」。就這麼簡單。",
      },
      {
        title: "Mole 會自己判斷",
        body: "它會檢查裡面的內容，判斷是 Vite、Next.js、Python、Rails、Docker Compose，還是別的——以及該怎麼啟動它。",
      },
      {
        title: "啟動",
        body: "在背景執行，並在瀏覽器裡打開 localhost。不會跳出 Terminal 視窗，也不會開一堆分頁。",
      },
    ],
  },
  features: {
    eyebrow: "Mole 能做什麼",
    heading: "一個只做一件事的小工具。",
    items: [
      {
        title: "拖進去就好",
        body: "一個拖放區。把資料夾拖進來，或手動選擇——剩下的交給 Mole。",
      },
      {
        title: "智慧判斷",
        body: "Node（npm、pnpm、yarn、bun）、靜態網站、Python、Ruby on Rails、Go、Rust、Docker Compose 等等。Mole 會讀取資料夾內容，選出正確的啟動指令。",
      },
      {
        title: "在背景執行",
        body: "不會有一堆 Terminal 視窗堆在桌面上。輸出仍然會寫進日誌，需要時隨時可以查看。",
      },
      {
        title: "看到正在執行的專案",
        body: "每個 localhost 服務都會顯示名稱和網站圖示。把重要的設成常駐，其他的直接關閉，或讓自動關閉幫你收拾。",
      },
    ],
  },
  moleMoment: {
    line1: "你的專案不會消失。",
    line2: "它們只是轉入地下。",
    line3: "Mole 知道去哪裡找到它們。",
  },
  vibeCoding: {
    eyebrow: "為 vibe coding 而生",
    heading: "獻給那些在搞懂 npm run dev 是什麼之前，就已經把東西做出來的人。",
    body: "設計師、獨立開發者、AI builder，以及正在學習用 AI 做東西的所有人。Mole 不是要幫工程師取代 Terminal——而是給不想打開 Terminal 的人一個選擇。",
    quote:
      "我不是專業開發者。Vibe coding 做久了，專案越來越多，啟動指令記不住，連 localhost 開了哪些也常常搞不清楚。所以我做了 Mole——把資料夾丟進來，剩下交給它。",
    quoteAttribution: "——Wen，Mole 的作者",
  },
  openSource: {
    eyebrow: "開放原始碼",
    heading: "免費、開源，任何人都能檢視程式碼。",
    points: [
      "原始碼公開在 GitHub 上，MIT 授權",
      "歡迎提出 Issue 或貢獻程式碼",
      "不需要帳號、不需要訂閱、不收集任何資料",
    ],
    ctaGithub: "在 GitHub 加星號",
    support: "贊助 Mole ♡",
  },
  download: {
    heading: "準備好重新挖出你的專案了嗎？",
    ctaPrimary: "下載 macOS 版",
    ctaSecondary: "在 GitHub 上查看",
    version: "Mole",
    platform: "macOS 12 或更新版本",
    arch: "Apple Silicon 與 Intel 通用版",
    size: "約 4.8 MB",
    howToOpenSummary: "第一次打開 Mole？",
    howToOpenBody:
      "Mole 還沒有經過 Apple 公證，macOS 會提示「無法確認開發者身份」。在 Finder 裡按住 Control 點擊 mole.app，選擇「打開」即可，只需要做一次。",
    limitationsSummary: "還有些情況尚未測試",
    limitationsBody:
      "Mole 目前只支援 macOS——先把這個版本做穩，之後再考慮其他平台。專案類型偵測已經針對常見情境測試過，但不是每一種框架、套件管理器或機器環境都測過。如果在你的環境裡出了問題，歡迎到 GitHub 提出 Issue，會逐步處理。",
  },
  footer: {
    github: "GitHub",
    download: "下載",
    changelog: "更新日誌",
    contact: "聯絡方式",
    license: "授權條款",
    privacy: "隱私權",
    credit: "由一位受夠了記不住 Terminal 指令的獨立設計師製作。",
  },
  notFound: {
    heading: "這裡什麼都沒有。",
    body: "Mole 大概挖去別的地方了。",
    cta: "回到首頁",
  },
  support: {
    metaTitle: "贊助 Mole",
    metaDescription: "Mole 免費，而且會一直免費。如果你想表達感謝，這裡有幾種可選的贊助方式。",
    heading: "贊助 Mole",
    intro:
      "Mole 免費，而且會一直免費。如果它幫你省下了一些時間，想表示感謝的話，這裡是目前可用的方式——完全自願，之後還會陸續增加。",
    preparing: "準備中",
    footnote:
      "沒有壓力，不用訂閱，不需要帳號。不管你用不用這些方式，Mole 都完全一樣好用。",
    backHome: "回到 Mole",
    methodsHeading: "贊助方式",
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
        label: "微信讚賞碼",
        ready: true,
        qr: true,
        qrCaption: "微信支付 · 掃碼支持",
      },
      { key: "linepay", label: "LINE Pay Money", ready: false },
      { key: "jkopay", label: "街口支付", ready: false },
      { key: "opay", label: "歐付寶", ready: false },
      { key: "ghsponsors", label: "GitHub Sponsors", ready: false },
      { key: "opencollective", label: "Open Collective", ready: false },
      { key: "paypalme", label: "PayPal.me", ready: false },
    ],
    contactBody: "還有其他想用的贊助方式？歡迎聯繫作者。",
    contactEmail: "st6ar1@gmail.com",
  },
  contact: {
    metaTitle: "聯絡方式",
    metaDescription: "有問題、想給點回饋，或想回報一個 bug？歡迎寫信——也歡迎聊合作。",
    heading: "聯絡我",
    body: "有問題、想給點回饋、想回報一個 bug，或只是想打聲招呼？歡迎寫信——也歡迎聊合作。",
    email: "st6ar1@gmail.com",
    backHome: "回到 Mole",
  },
  changelog: {
    metaTitle: "更新日誌 — Mole",
    metaDescription: "Mole 每個版本的更新內容。",
    heading: "更新日誌",
    intro: "內容來自",
    generatedFrom: "GitHub Releases",
    viewOnGithub: "在 GitHub 上查看",
  },
  privacyPage: {
    metaTitle: "隱私權 — Mole",
    metaDescription: "Mole 完全在你自己的電腦上執行。這裡說明它會和不會傳送哪些資料。",
    heading: "隱私權",
    intro: "Mole 完全在你自己的電腦上執行，不會收集或上傳任何使用資料或專案內容。",
    networkHeading: "Mole 唯一會發出的網路請求",
    networkItem1:
      "啟動時向 GitHub 查詢是否有新版本——只是一次唯讀的 Releases API 請求，不會傳送任何裝置資訊。",
    networkItem2: "只有在你自己點擊「回報問題」時，才會打開一個預先填好內容的 GitHub Issue 頁面。",
    websiteHeading: "關於這個網站",
    websiteBody:
      "這個網站沒有任何分析工具、沒有追蹤像素，也沒有除了瀏覽器自身設定以外的 Cookie。頁面上顯示的版本號和星標數，是在建置網站時從 GitHub 公開 API 取得的。",
    questions: "有疑問？歡迎到這裡提出 Issue：",
  },
};
