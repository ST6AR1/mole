import type { Dictionary } from "./types";

// Terminology kept in sync with the app's own Strings.ja.swift where it
// overlaps (tagline, "起動中のプロジェクト", "自動終了", etc.).
export const ja: Dictionary = {
  meta: {
    title: "Mole — フォルダをドロップして、ローカルプロジェクトを起動",
    description:
      "Mole は vibe coder のための無料オープンソース macOS アプリです。プロジェクトフォルダをドロップするだけで、起動方法を自動判定し、バックグラウンドで localhost を起動し、ブラウザを開きます。パスもコマンドも覚える必要はなく、Terminal を開く必要もありません。",
  },
  nav: {
    features: "機能",
    changelog: "更新履歴",
    support: "サポート",
    github: "GitHub",
    download: "ダウンロード",
  },
  hero: {
    tagline: "コマンドいらずで、すぐ作業へ。",
    h1Line1: "あなたのプロジェクトは失われていません。",
    h1Line2: "ただ地下に潜っているだけです。",
    subhead:
      "プロジェクトフォルダを Mole にドロップするだけ。起動方法を判断し、localhost を起動して、ブラウザを開きます。パスもコマンドも不要、Terminal を開く必要もありません。",
    ctaPrimary: "Mole をダウンロード",
    ctaSecondary: "GitHub で見る",
    versionLine: "無料 · macOS 12+ · 4.8 MB",
  },
  problem: {
    line1: "AI でそれを作った。",
    line2: "そして Terminal を閉じた。",
    line3: "さて……もう一度開くにはどうすればいい？",
    q1: "どのフォルダだったっけ？",
    q2: "どんなコマンドを使ったっけ？",
    q3: "どの localhost ポートだったっけ？",
  },
  solution: {
    eyebrow: "使い方",
    heading: "面倒な部分は、Mole が覚えています。",
    steps: [
      {
        title: "フォルダをドロップ",
        body: "Mole にドラッグするか、「フォルダを選択」で選ぶだけ。それがすべてです。",
      },
      {
        title: "Mole が自動判定",
        body: "中身を確認し、Vite なのか Next.js、Python、Rails、Docker Compose なのか、それとも別のものなのか——そしてどう起動すればいいかを判断します。",
      },
      {
        title: "起動",
        body: "バックグラウンドで実行し、ブラウザで localhost を開きます。Terminal ウィンドウも、タブの山もできません。",
      },
    ],
  },
  features: {
    eyebrow: "Mole でできること",
    heading: "一つのことだけをする、小さなツール。",
    items: [
      {
        title: "ドロップするだけ",
        body: "ドロップゾーンは一つだけ。フォルダをドラッグするか、手動で選択——あとは Mole が引き受けます。",
      },
      {
        title: "スマート判定",
        body: "Node（npm、pnpm、yarn、bun）、静的サイト、Python、Ruby on Rails、Go、Rust、Docker Compose など。Mole がフォルダを読み取り、正しいコマンドを選びます。",
      },
      {
        title: "バックグラウンドで実行",
        body: "デスクトップに Terminal ウィンドウが積み上がることはありません。出力はログに記録されるので、必要なときに確認できます。",
      },
      {
        title: "実行中の状態を確認",
        body: "すべての localhost サービスに名前と favicon が表示されます。大事なものは常駐に、それ以外は停止、または自動終了に任せましょう。",
      },
    ],
  },
  moleMoment: {
    line1: "あなたのプロジェクトは消えません。",
    line2: "ただ地下に潜るだけです。",
    line3: "Mole はどこにあるか知っています。",
  },
  vibeCoding: {
    eyebrow: "vibe coding のために",
    heading:
      "npm run dev が何なのか知る前に、もう何かを作り上げてしまった人たちへ。",
    body: "デザイナー、インディーメーカー、AI ビルダー、そして AI でものづくりを学んでいるすべての人へ。Mole はエンジニアの Terminal を置き換えるためのものではありません——そもそも Terminal を開きたくない人のためのものです。",
    quote:
      "私はプロの開発者ではありません。バイブコーディングを重ねるうちにプロジェクトがどんどん増え、起動コマンドを覚えられなくなり、どの localhost ポートが動いているのかも分からなくなっていました。だから mole を作りました。フォルダを入れるだけ、あとは全部おまかせです。",
    quoteAttribution: "——Wen、Mole の作者",
  },
  openSource: {
    eyebrow: "オープンソース",
    heading: "無料、オープンソース、誰でもコードを確認できます。",
    points: [
      "GitHub でソースを公開、MIT ライセンス",
      "Issue や貢献を歓迎します",
      "アカウント不要、サブスクリプション不要、テレメトリなし",
    ],
    ctaGithub: "GitHub でスターを付ける",
    support: "Mole をサポート ♡",
  },
  download: {
    heading: "またプロジェクトを掘り出す準備はできましたか？",
    ctaPrimary: "macOS 版をダウンロード",
    ctaSecondary: "GitHub で見る",
    version: "Mole",
    platform: "macOS 12 以降",
    arch: "Apple Silicon と Intel の両対応（Universal）",
    size: "約 4.8 MB",
    howToOpenSummary: "はじめて Mole を開きますか？",
    howToOpenBody:
      "Mole はまだ Apple の公証を受けていないため、macOS は「開発元が未確認」と警告を表示します。Finder で mole.app を Control キーを押しながらクリックし、「開く」を選んでください——これは最初の一回だけ必要です。",
    limitationsSummary: "まだすべての環境でテストされていません",
    limitationsBody:
      "Mole は今のところ macOS 専用です——まずこのバージョンを安定させてから、他のプラットフォームを検討します。プロジェクトタイプの判定は一般的な環境でテストしていますが、すべてのフレームワーク、パッケージマネージャー、マシン環境で確認できているわけではありません。うまく動かない場合は、GitHub で Issue を立ててください。順番に対応します。",
  },
  footer: {
    github: "GitHub",
    download: "ダウンロード",
    changelog: "更新履歴",
    contact: "お問い合わせ",
    license: "ライセンス",
    privacy: "プライバシー",
    credit: "Terminal のコマンドを覚えるのに疲れたインディーデザイナーが作りました。",
  },
  notFound: {
    heading: "ここには何もありません。",
    body: "Mole はどこか別の場所を掘っているようです。",
    cta: "ホームに戻る",
  },
  support: {
    metaTitle: "Mole をサポート",
    metaDescription:
      "Mole は無料で、これからも無料です。感謝を伝えたい方のために、いくつかの任意のサポート方法をご用意しています。",
    heading: "Mole をサポート",
    intro:
      "Mole は無料で、これからも無料です。時間の節約になり、感謝を伝えたいと思ったら、今すぐできる方法をご紹介します——完全に任意です。今後も少しずつ増えていきます。",
    preparing: "準備中",
    footnote:
      "プレッシャーもサブスクリプションもアカウントも不要です。これらを使っても使わなくても、Mole は変わらず同じように使えます。",
    backHome: "Mole に戻る",
    methodsHeading: "サポート方法",
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
    contactBody: "他のサポート方法をご希望ですか？作者にご連絡ください。",
    contactEmail: "st6ar1@gmail.com",
  },
  contact: {
    metaTitle: "お問い合わせ",
    metaDescription:
      "ご質問、ご意見、不具合の報告など、お気軽にメールをどうぞ——コラボのご相談も歓迎です。",
    heading: "お問い合わせ",
    body: "ご質問、ご意見、不具合の報告、あるいはただ挨拶したいだけでも構いません。メールをお送りください——コラボのご相談も歓迎です。",
    email: "st6ar1@gmail.com",
    backHome: "Mole に戻る",
  },
  changelog: {
    metaTitle: "更新履歴 — Mole",
    metaDescription: "Mole のリリースごとの更新内容。",
    heading: "更新履歴",
    intro: "情報の取得元：",
    generatedFrom: "GitHub Releases",
    viewOnGithub: "GitHub で見る",
  },
  privacyPage: {
    metaTitle: "プライバシー — Mole",
    metaDescription:
      "Mole はすべてあなた自身のマシン上で動作します。送信する情報・しない情報を正確に説明します。",
    heading: "プライバシー",
    intro:
      "Mole はすべてあなた自身のマシン上で動作します。使用状況やプロジェクトの内容を収集・送信することはありません。",
    networkHeading: "Mole が行う唯一のネットワーク通信",
    networkItem1:
      "起動時に GitHub へ新しいバージョンがないか確認します——公開 Releases API への読み取り専用のリクエストのみで、デバイス情報は送信されません。",
    networkItem2:
      "「問題を報告」をご自身でクリックしたときのみ、内容が入力済みの GitHub Issue ページを開きます。",
    websiteHeading: "このウェブサイトについて",
    websiteBody:
      "このサイトにはアナリティクスもトラッキングピクセルもなく、ブラウザ自体が設定する以外の Cookie もありません。ここに表示されているリリース情報やスター数は、サイトのビルド時に GitHub の公開 API から取得したものです。",
    questions: "ご質問があれば、こちらから Issue を立ててください：",
  },
};
