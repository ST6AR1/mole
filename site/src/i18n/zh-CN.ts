import type { Dictionary } from "./types";

// Terminology kept in sync with the app's own Strings.zhCN.swift and
// README.zh-CN.md where they overlap (tagline, "运行中的项目", "自动关闭",
// "选择文件夹", etc.) — the site and the app should sound like one product.
export const zhCN: Dictionary = {
  meta: {
    title: "Mole — 拖进文件夹，跑起你的本地项目",
    description:
      "Mole 是一个给 vibe coder 用的免费开源 macOS 工具。把项目文件夹拖进去，它会自动判断怎么运行、在后台启动 localhost，并打开浏览器。不用记路径，不用记指令，不用打开 Terminal。",
  },
  nav: {
    features: "功能",
    changelog: "更新日志",
    support: "支持",
    github: "GitHub",
    download: "下载",
  },
  hero: {
    tagline: "别管指令，直接开工。",
    h1Line1: "你的项目没有丢失，",
    h1Line2: "只是转入地下了。",
    subhead:
      "把项目文件夹拖进 Mole，它会判断怎么运行、启动 localhost，并打开浏览器。不用记路径，不用记指令，不用打开 Terminal。",
    ctaPrimary: "下载 Mole",
    ctaSecondary: "在 GitHub 上查看",
    versionLine: "免费 · macOS 12+ · 4.8 MB",
  },
  problem: {
    line1: "你用 AI 把它做出来了。",
    line2: "然后你关掉了 Terminal。",
    line3: "现在……要怎么再打开它？",
    q1: "是哪个文件夹来着？",
    q2: "我用的是什么指令？",
    q3: "是哪个 localhost 端口？",
  },
  solution: {
    eyebrow: "运作方式",
    heading: "无聊的部分，Mole 帮你记住。",
    steps: [
      {
        title: "把文件夹拖进来",
        body: "拖到 Mole 上，或用「选择文件夹」。就这么简单。",
      },
      {
        title: "Mole 会自己判断",
        body: "它会检查里面的内容，判断是 Vite、Next.js、Python、Rails、Docker Compose，还是别的——以及该怎么启动它。",
      },
      {
        title: "启动",
        body: "在后台运行，并在浏览器里打开 localhost。不会跳出 Terminal 窗口，也不会开一堆分页。",
      },
    ],
  },
  features: {
    eyebrow: "Mole 能做什么",
    heading: "一个只做一件事的小工具。",
    items: [
      {
        title: "拖进去就好",
        body: "一个拖放区。把文件夹拖进来，或手动选择——剩下的交给 Mole。",
      },
      {
        title: "智能判断",
        body: "Node（npm、pnpm、yarn、bun）、静态网站、Python、Ruby on Rails、Go、Rust、Docker Compose 等等。Mole 会读取文件夹内容，选出正确的启动指令。",
      },
      {
        title: "在后台运行",
        body: "不会有一堆 Terminal 窗口堆在桌面上。输出仍然会写进日志，需要时随时可以查看。",
      },
      {
        title: "看到正在运行的项目",
        body: "每个 localhost 服务都会显示名称和网站图标。把重要的设成常驻，其他的直接关闭，或让自动关闭帮你收拾。",
      },
    ],
  },
  moleMoment: {
    line1: "你的项目不会消失。",
    line2: "它们只是转入地下。",
    line3: "Mole 知道去哪里找到它们。",
  },
  vibeCoding: {
    eyebrow: "为 vibe coding 而生",
    heading: "献给那些在搞懂 npm run dev 是什么之前，就已经把东西做出来的人。",
    body: "设计师、独立开发者、AI builder，以及正在学习用 AI 做东西的所有人。Mole 不是要帮工程师取代 Terminal——而是给不想打开 Terminal 的人一个选择。",
    quote:
      "我不是专业开发者。Vibe coding 做久了，项目越来越多，启动指令记不住，连 localhost 开了哪些也常常搞不清楚。所以我做了 Mole——把文件夹丢进来，剩下交给它。",
    quoteAttribution: "——Wen，Mole 的作者",
  },
  openSource: {
    eyebrow: "开放源码",
    heading: "免费、开源，任何人都能检视代码。",
    points: [
      "源码公开在 GitHub 上，MIT 授权",
      "欢迎提出 Issue 或贡献代码",
      "不需要账号、不需要订阅、不收集任何数据",
    ],
    ctaGithub: "在 GitHub 加星标",
    support: "支持 Mole ♡",
  },
  download: {
    heading: "准备好重新挖出你的项目了吗？",
    ctaPrimary: "下载 macOS 版",
    ctaSecondary: "在 GitHub 上查看",
    version: "Mole",
    platform: "macOS 12 或更新版本",
    arch: "Apple Silicon 与 Intel 通用版",
    size: "约 4.8 MB",
    howToOpenSummary: "第一次打开 Mole？",
    howToOpenBody:
      "Mole 还没有经过 Apple 公证，macOS 会提示「无法确认开发者身份」。在 Finder 里按住 Control 点击 mole.app，选择「打开」即可，只需要做一次。",
    limitationsSummary: "还有些情况尚未测试",
    limitationsBody:
      "Mole 目前只支持 macOS——先把这个版本做稳，之后再考虑其他平台。项目类型检测已经针对常见情境测试过，但不是每一种框架、包管理器或机器环境都测过。如果在你的环境里出了问题，欢迎到 GitHub 提出 Issue，会逐步处理。",
  },
  footer: {
    github: "GitHub",
    download: "下载",
    changelog: "更新日志",
    contact: "联系方式",
    license: "授权条款",
    privacy: "隐私权",
    credit: "由一位受够了记不住 Terminal 指令的独立设计师制作。",
  },
  notFound: {
    heading: "这里什么都没有。",
    body: "Mole 大概挖去别的地方了。",
    cta: "回到首页",
  },
  support: {
    metaTitle: "支持 Mole",
    metaDescription:
      "Mole 免费，而且会一直免费。如果你想表达感谢，这里有几种可选的支持方式。",
    heading: "支持 Mole",
    intro:
      "Mole 免费，而且会一直免费。如果它帮你省下了一些时间，想表示感谢的话，这里是目前可用的方式——完全自愿，之后还会陆续增加。",
    preparing: "准备中",
    footnote:
      "没有压力，不用订阅，不需要账号。不管你用不用这些方式，Mole 都完全一样好用。",
    backHome: "回到 Mole",
    methodsHeading: "支持方式",
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
        label: "微信赞赏码",
        ready: true,
        qr: true,
        qrCaption: "微信支付 · 扫码支持",
      },
      { key: "linepay", label: "LINE Pay Money", ready: false },
      { key: "jkopay", label: "街口支付", ready: false },
      { key: "opay", label: "欧付宝", ready: false },
      { key: "ghsponsors", label: "GitHub Sponsors", ready: false },
      { key: "opencollective", label: "Open Collective", ready: false },
      { key: "paypalme", label: "PayPal.me", ready: false },
    ],
    contactBody: "还有其他想用的支持方式？欢迎联系作者。",
    contactEmail: "st6ar1@gmail.com",
  },
  contact: {
    metaTitle: "联系方式",
    metaDescription: "有问题、想给点反馈，或想报告一个 bug？欢迎写信——也欢迎聊合作。",
    heading: "联系我",
    body: "有问题、想给点反馈、想报告一个 bug，或只是想打个招呼？欢迎写信——也欢迎聊合作。",
    email: "st6ar1@gmail.com",
    backHome: "回到 Mole",
  },
  changelog: {
    metaTitle: "更新日志 — Mole",
    metaDescription: "Mole 每个版本的更新内容。",
    heading: "更新日志",
    intro: "内容来自",
    generatedFrom: "GitHub Releases",
    viewOnGithub: "在 GitHub 上查看",
  },
  privacyPage: {
    metaTitle: "隐私权 — Mole",
    metaDescription: "Mole 完全在你自己的电脑上运行。这里说明它会和不会传送哪些数据。",
    heading: "隐私权",
    intro: "Mole 完全在你自己的电脑上运行，不会收集或上传任何使用数据或项目内容。",
    networkHeading: "Mole 唯一会发出的网络请求",
    networkItem1:
      "启动时向 GitHub 查询是否有新版本——只是一次只读的 Releases API 请求，不会传送任何设备信息。",
    networkItem2: "只有在你自己点击「反馈问题」时，才会打开一个预先填好内容的 GitHub Issue 页面。",
    websiteHeading: "关于这个网站",
    websiteBody:
      "这个网站没有任何分析工具、没有追踪像素，也没有除了浏览器自身设置以外的 Cookie。页面上显示的版本号和星标数，是在构建网站时从 GitHub 公开 API 取得的。",
    questions: "有疑问？欢迎到这里提出 Issue：",
  },
};
