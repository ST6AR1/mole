import type { Dictionary } from "./types";

export const en: Dictionary = {
  meta: {
    title: "Mole — drop a folder, run your local project",
    description:
      "Mole is a free, open-source macOS app for vibe coders. Drop a project folder in and it detects how to run it, starts localhost in the background, and opens your browser. No paths, no commands, no Terminal.",
  },
  nav: {
    features: "Features",
    changelog: "Changelog",
    support: "Support",
    github: "GitHub",
    download: "Download",
  },
  hero: {
    tagline: "Skip the commands, get to work.",
    h1Line1: "Your projects aren't lost.",
    h1Line2: "They're just underground.",
    subhead:
      "Drop a project folder on Mole. It figures out how to run it, starts localhost, and opens your browser. No paths, no commands, no Terminal.",
    ctaPrimary: "Download Mole",
    ctaSecondary: "View on GitHub",
    versionLine: "Free · macOS 12+ · 4.8 MB",
  },
  problem: {
    line1: "You made it with AI.",
    line2: "Then you closed Terminal.",
    line3: "Now… how do you open it again?",
    q1: "Which folder was it?",
    q2: "What command did I use?",
    q3: "Which localhost port was it?",
  },
  solution: {
    eyebrow: "How it works",
    heading: "Mole remembers the boring part.",
    steps: [
      {
        title: "Drop in your folder",
        body: "Drag it onto Mole, or pick it with Choose Folder. That's the whole interface.",
      },
      {
        title: "Mole figures it out",
        body: "It looks at what's inside and works out whether it's Vite, Next.js, Python, Rails, Docker Compose, or something else — and how to start it.",
      },
      {
        title: "Launch",
        body: "It runs in the background and opens localhost in your browser. No Terminal window, no pile of tabs.",
      },
    ],
  },
  features: {
    eyebrow: "What Mole does",
    heading: "A small tool with one job.",
    items: [
      {
        title: "Drop & go",
        body: "One drop zone. Drag a folder in, or choose it manually — either way, Mole takes it from there.",
      },
      {
        title: "Smart detection",
        body: "Node (npm, pnpm, yarn, bun), static sites, Python, Ruby on Rails, Go, Rust, Docker Compose, and more. Mole reads the folder and picks the right command.",
      },
      {
        title: "Runs in the background",
        body: "No Terminal windows piling up on your desktop. Output still goes to a log, in case you ever need to check it.",
      },
      {
        title: "See what's running",
        body: "Every localhost service, with its name and favicon. Keep Alive what matters, stop the rest, or let Auto Close tidy up after you.",
      },
    ],
  },
  moleMoment: {
    line1: "Your projects don't disappear.",
    line2: "They just go underground.",
    line3: "Mole knows where to find them.",
  },
  vibeCoding: {
    eyebrow: "Built for vibe coding",
    heading:
      "Built for people who build things before learning what npm run dev means.",
    body: "Designers, indie makers, AI builders, and anyone learning to build with AI. Mole isn't trying to replace Terminal for engineers — it's for everyone who'd rather not open one in the first place.",
    quote:
      "I'm not a professional developer. After a lot of vibe coding I couldn't remember the start commands, or which localhost ports were even running. So I made Mole — drop in the folder, and it takes care of the rest.",
    quoteAttribution: "— Wen, maker of Mole",
  },
  openSource: {
    eyebrow: "Open source",
    heading: "Free. Open source. Yours to inspect.",
    points: [
      "Source available on GitHub, MIT licensed",
      "Issues and contributions welcome",
      "No account, no subscription, no telemetry",
    ],
    ctaGithub: "Star on GitHub",
    support: "Support Mole ♡",
  },
  download: {
    heading: "Ready to dig back into your projects?",
    ctaPrimary: "Download for macOS",
    ctaSecondary: "View on GitHub",
    version: "Mole",
    platform: "macOS 12 or later",
    arch: "Apple Silicon & Intel (universal)",
    size: "≈ 4.8 MB",
    howToOpenSummary: "First time opening Mole?",
    howToOpenBody:
      "Mole isn't notarized by Apple yet, so macOS will warn that it's from an unidentified developer. In Finder, Control-click mole.app and choose Open — you only need to do this once.",
    limitationsSummary: "Not every setup is tested yet",
    limitationsBody:
      "Mole is macOS only for now — getting this version solid before looking at other platforms. Project-type detection is tested against common setups, but not every framework, package manager, or machine configuration yet. If something doesn't work on yours, open an issue on GitHub and it'll get worked through.",
  },
  footer: {
    github: "GitHub",
    download: "Download",
    changelog: "Changelog",
    license: "License",
    privacy: "Privacy",
    credit:
      "Made by an indie designer who got tired of remembering terminal commands.",
  },
  notFound: {
    heading: "Nothing here.",
    body: "Mole must have dug off somewhere else.",
    cta: "Back home",
  },
  support: {
    metaTitle: "Support Mole",
    metaDescription:
      "Mole is free and stays free. If you'd like to say thanks, here are a few optional ways to support it.",
    heading: "Support Mole",
    intro:
      "Mole is free and will stay free. If it saved you some time and you'd like to say thanks, here are a few ways — completely optional. This page fills in gradually as each region's options are set up.",
    comingSoon: "Coming soon",
    footnote:
      "No pressure, no subscription, no account required. Mole works exactly the same whether or not you use any of these.",
    backHome: "Back to Mole",
    regions: [
      {
        key: "taiwan",
        title: "Taiwan",
        note: "Local options are being set up.",
        ready: false,
        methods: [
          { label: "LINE Pay" },
          { label: "街口支付" },
          { label: "ATM 轉帳" },
        ],
      },
      {
        key: "global",
        title: "Global",
        note: "Pick whichever's easiest for you.",
        ready: true,
        methods: [
          { label: "Buy Me a Coffee", href: "https://buymeacoffee.com/st6ar1" },
          { label: "Ko-fi", href: "https://ko-fi.com/wen" },
        ],
      },
      {
        key: "china",
        title: "Mainland China",
        note: "微信讚賞碼，掃碼即可。",
        ready: true,
        methods: [],
        qrCaption: "微信支付 · 掃碼支持",
      },
    ],
  },
};
