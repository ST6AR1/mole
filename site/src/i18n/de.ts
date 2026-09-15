import type { Dictionary } from "./types";

// Terminology kept in sync with the app's own Strings.de.swift where it
// overlaps (tagline, "Laufende Projekte", "Automatisches Schließen", etc.).
export const de: Dictionary = {
  meta: {
    title: "Mole — Ordner ablegen, lokales Projekt starten",
    description:
      "Mole ist ein kostenloses Open-Source-macOS-Tool für Vibe Coder. Projektordner ablegen, und Mole erkennt, wie er gestartet wird, startet localhost im Hintergrund und öffnet den Browser. Keine Pfade, keine Befehle, kein Terminal.",
  },
  nav: {
    features: "Funktionen",
    changelog: "Änderungsprotokoll",
    support: "Unterstützen",
    github: "GitHub",
    download: "Herunterladen",
  },
  hero: {
    tagline: "Keine Befehle, einfach loslegen.",
    h1Line1: "Deine Projekte sind nicht verloren,",
    h1Line2: "sie sind nur unter die Erde gegangen.",
    subhead:
      "Projektordner auf Mole ablegen. Es findet heraus, wie er gestartet wird, startet localhost und öffnet den Browser. Keine Pfade, keine Befehle, kein Terminal.",
    ctaPrimary: "Mole herunterladen",
    ctaSecondary: "Auf GitHub ansehen",
    versionLine: "Kostenlos · macOS 12+ · 4,8 MB",
  },
  problem: {
    line1: "Du hast es mit KI gebaut.",
    line2: "Dann hast du Terminal geschlossen.",
    line3: "Jetzt … wie öffnest du es wieder?",
    q1: "Welcher Ordner war das noch?",
    q2: "Welchen Befehl habe ich benutzt?",
    q3: "Welcher localhost-Port war das?",
  },
  solution: {
    eyebrow: "So funktioniert's",
    heading: "Den langweiligen Teil merkt sich Mole.",
    steps: [
      {
        title: "Ordner reinziehen",
        body: "Auf Mole ziehen, oder mit „Ordner wählen“ auswählen. Das ist schon die ganze Oberfläche.",
      },
      {
        title: "Mole findet es selbst heraus",
        body: "Es prüft den Inhalt und stellt fest, ob es Vite, Next.js, Python, Rails, Docker Compose oder etwas anderes ist — und wie man es startet.",
      },
      {
        title: "Start",
        body: "Läuft im Hintergrund und öffnet localhost im Browser. Kein Terminal-Fenster, kein Stapel von Tabs.",
      },
    ],
  },
  features: {
    eyebrow: "Was Mole macht",
    heading: "Ein kleines Werkzeug mit genau einer Aufgabe.",
    items: [
      {
        title: "Ablegen und los",
        body: "Nur eine Ablagefläche. Ordner reinziehen oder manuell auswählen — den Rest übernimmt Mole.",
      },
      {
        title: "Intelligente Erkennung",
        body: "Node (npm, pnpm, yarn, bun), statische Seiten, Python, Ruby on Rails, Go, Rust, Docker Compose und mehr. Mole liest den Ordner und wählt den richtigen Befehl.",
      },
      {
        title: "Läuft im Hintergrund",
        body: "Keine Terminal-Fenster, die sich auf dem Desktop stapeln. Die Ausgabe landet trotzdem in einem Log, falls du sie mal brauchst.",
      },
      {
        title: "Sehen, was läuft",
        body: "Jeder localhost-Dienst mit Name und Favicon. Wichtiges dauerhaft laufen lassen, den Rest stoppen, oder das automatische Schließen aufräumen lassen.",
      },
    ],
  },
  moleMoment: {
    line1: "Deine Projekte verschwinden nicht.",
    line2: "Sie gehen nur unter die Erde.",
    line3: "Mole weiß, wo es sie findet.",
  },
  vibeCoding: {
    eyebrow: "Gemacht für Vibe Coding",
    heading: "Für alle, die etwas bauen, bevor sie wissen, was npm run dev bedeutet.",
    body: "Designer, unabhängige Macher, AI Builder, und alle, die gerade lernen, mit KI zu bauen. Mole will Terminal nicht für Entwickler ersetzen — es ist für alle, die gar nicht erst eins öffnen wollen.",
    quote:
      "Ich bin kein professioneller Entwickler. Nach viel Vibe Coding hatte ich immer mehr Projekte, konnte mir die Start-Befehle nicht merken und wusste oft nicht mehr, welche localhost-Ports überhaupt noch liefen. Also habe ich Mole gebaut — Ordner reinziehen, den Rest erledigt es von selbst.",
    quoteAttribution: "— Wen, Erfinder von Mole",
  },
  openSource: {
    eyebrow: "Open Source",
    heading: "Kostenlos. Open Source. Frei einsehbar.",
    points: [
      "Quellcode auf GitHub verfügbar, MIT-Lizenz",
      "Issues und Beiträge willkommen",
      "Kein Konto, kein Abo, keine Telemetrie",
    ],
    ctaGithub: "Stern auf GitHub geben",
    support: "Mole unterstützen ♡",
  },
  download: {
    heading: "Bereit, deine Projekte wieder auszugraben?",
    ctaPrimary: "Für macOS herunterladen",
    ctaSecondary: "Auf GitHub ansehen",
    version: "Mole",
    platform: "macOS 12 oder neuer",
    arch: "Apple Silicon & Intel (universell)",
    size: "≈ 4,8 MB",
    howToOpenSummary: "Mole zum ersten Mal öffnen?",
    howToOpenBody:
      "Mole ist noch nicht von Apple notariell beglaubigt, daher warnt macOS vor einem nicht identifizierten Entwickler. Im Finder bei gedrückter Ctrl-Taste auf mole.app klicken und „Öffnen“ wählen — das ist nur einmal nötig.",
    limitationsSummary: "Noch nicht jede Konfiguration getestet",
    limitationsBody:
      "Mole gibt es vorerst nur für macOS — erst soll diese Version stabil laufen, bevor andere Plattformen infrage kommen. Die Projekttyp-Erkennung ist an gängigen Konfigurationen getestet, aber nicht an jedem Framework, Paketmanager oder jeder Maschine. Falls bei dir etwas nicht funktioniert, ein Issue auf GitHub eröffnen — wird nach und nach bearbeitet.",
  },
  footer: {
    github: "GitHub",
    download: "Herunterladen",
    changelog: "Änderungsprotokoll",
    contact: "Kontakt",
    license: "Lizenz",
    privacy: "Datenschutz",
    credit: "Gemacht von einem Indie-Designer, der es leid war, sich Terminal-Befehle zu merken.",
  },
  notFound: {
    heading: "Hier ist nichts.",
    body: "Mole muss woanders hingebuddelt haben.",
    cta: "Zurück zur Startseite",
  },
  support: {
    metaTitle: "Mole unterstützen",
    metaDescription:
      "Mole ist kostenlos und bleibt es. Wenn du dich bedanken möchtest, gibt es ein paar optionale Möglichkeiten dazu.",
    heading: "Mole unterstützen",
    intro:
      "Mole ist kostenlos und bleibt es. Wenn es dir Zeit gespart hat und du dich bedanken möchtest, hier die Wege, die gerade zur Verfügung stehen — völlig freiwillig. Es kommen mit der Zeit weitere dazu.",
    preparing: "In Vorbereitung",
    footnote: "Kein Druck, kein Abo, kein Konto nötig. Mole funktioniert genau gleich, egal ob du eine dieser Optionen nutzt oder nicht.",
    backHome: "Zurück zu Mole",
    methodsHeading: "Unterstützungsmöglichkeiten",
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
    contactBody: "Brauchst du eine andere Art zu unterstützen? Kontaktiere den Autor.",
    contactEmail: "st6ar1@gmail.com",
  },
  contact: {
    metaTitle: "Kontakt",
    metaDescription:
      "Fragen, Feedback oder ein Bug zum Melden? Schreib eine E-Mail — auch Kooperationsanfragen sind willkommen.",
    heading: "Kontakt aufnehmen",
    body: "Fragen, Feedback, ein Bug zum Melden, oder einfach nur Hallo sagen? Schreib eine E-Mail — auch Kooperationsanfragen sind willkommen.",
    email: "st6ar1@gmail.com",
    backHome: "Zurück zu Mole",
  },
  changelog: {
    metaTitle: "Änderungsprotokoll — Mole",
    metaDescription: "Was es Neues bei Mole gibt, Release für Release.",
    heading: "Änderungsprotokoll",
    intro: "Erstellt aus",
    generatedFrom: "GitHub Releases",
    viewOnGithub: "Auf GitHub ansehen",
  },
  privacyPage: {
    metaTitle: "Datenschutz — Mole",
    metaDescription:
      "Mole läuft vollständig auf deinem eigenen Rechner. Hier steht genau, was es sendet — und was nicht.",
    heading: "Datenschutz",
    intro: "Mole läuft vollständig auf deinem eigenen Rechner. Es sammelt oder überträgt keine Nutzungsdaten oder Projektinhalte.",
    networkHeading: "Die einzigen Netzwerkanfragen, die Mole stellt",
    networkItem1:
      "Beim Start bei GitHub nach einer neueren Version fragen — ein einfacher, rein lesender Aufruf der öffentlichen Releases-API. Es werden keine Geräteinformationen gesendet.",
    networkItem2: "Eine vorausgefüllte GitHub-Issue-Seite öffnen, aber nur, wenn du selbst auf „Problem melden“ klickst.",
    websiteHeading: "Diese Website",
    websiteBody:
      "Diese Seite hat keine Analytics, keine Tracking-Pixel und keine Cookies außer denen, die dein Browser selbst setzt. Die hier angezeigten Release- und Sterne-Zahlen stammen von der öffentlichen GitHub-API zum Zeitpunkt des Website-Builds.",
    questions: "Fragen? Eröffne ein Issue auf",
  },
};
