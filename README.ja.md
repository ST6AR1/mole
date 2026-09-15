[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | 日本語 | [한국어](README.ko.md) | [Français](README.fr.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt-BR.md)

<p align="center">
  <img src="icon/mole-poses/wordmark-logo.png" width="160" alt="mole logo">
</p>

<p align="center">コマンドはもういらない、すぐに開発を始めよう。<br>Skip the commands, get to work.</p>

<p align="center">
  <img src="docs/screenshots/app-icon.png" width="120" alt="mole app icon">
</p>

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="mole のメイン画面：プロジェクトフォルダをドロップすると自動で検出・起動">
</p>

macOS 用の小さなユーティリティです。プロジェクトフォルダをドロップするだけで、mole がプロジェクトの種類を判別し、バックグラウンドで起動して、ブラウザを自動で開いてくれます。Terminal ウィンドウが積み重なることもありません。現在動いている localhost サービスを一覧で確認し、ワンクリックで停止することもできます。

## 作った理由

<p align="center">
  <img src="docs/screenshots/story.png" width="280" alt="このアプリを作った理由">
</p>

私はプロの開発者ではありません。vibe coding を続けているうちにプロジェクトがどんどん増えて、起動コマンドを覚えられなくなり、どの localhost ポートが動いているかも分からなくなってしまいました。

それに、プロジェクトを起動するだけのために、また AI に聞き直すのも嫌でした。

そこで mole を作りました。フォルダを放り込めば、あとは全部任せられます。

## 機能

- **ドラッグ&ドロップ起動**: フォルダをウィンドウにドロップするか「フォルダを選択」を使うと、mole がプロジェクトの種類を自動検出して起動します。対応: Node.js（npm / pnpm / yarn / bun）、静的サイト、Python、Ruby / Rails、Go、Rust、Docker Compose、Deno、PHP、Flutter、Java / Kotlin、.NET、Chrome 拡張機能、ネイティブ macOS アプリなど
- **完全バックグラウンド実行**: Terminal ウィンドウが積み重なることはもうありません。起動コマンドの出力はログに記録されるので、見なくても大丈夫
- **実行中プロジェクト一覧**: 各サービスはサイトの `<title>` や favicon を自動で拾ってくれるので、どのプロジェクトか一目で分かります。常駐（⭐️）と停止（✕）はメニューを開かなくても見えて、クリックできるアイコンです
- **自動終了（Auto Close）**: 一定時間操作がないサービスを自動で終了できます。常駐指定（Keep Alive）したプロジェクトは対象外です
- **9 言語インターフェース**: English、繁體中文、简体中文、日本語、한국어、Français、Español、Deutsch、Português (Brasil)。Settings でその場で言語を切り替えられ、再起動は不要です。言語リストは常に同じ固定順で表示され、それぞれの言語がその言語自身のネイティブ表記で書かれています
- **自動アップデート**: 起動時に新しいバージョンがないかチェックし、ワンクリックでダウンロード・インストールできます

## スクリーンショット

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="mole のメイン画面">
</p>

## 動作の仕組み

フォルダを mole にドロップすると、次のことが行われます。

1. フォルダの中身（`package.json`、`Gemfile`、`go.mod`、`Dockerfile` など）を調べてプロジェクトの種類を判別
2. 対応する起動コマンドを組み立て、バックグラウンドで実行（出力はログファイルに書き込まれ、Terminal ウィンドウは開きません）
3. 新しい localhost ポートが立ち上がっていないかポーリング
4. 検出できたら自動でブラウザを開く。検出できるポートがない場合（ネイティブアプリやバックエンドのみのサービスなど）は、その場で起動完了として扱う

## インストール

macOS 12 以降が必要です。

### 方法 1: アプリをダウンロード

1. [Releases](https://github.com/ST6AR1/mole/releases/latest) から最新の `mole-x.x.x.dmg` をダウンロード
2. DMG を開いて、アプリを `Applications` にドラッグ
3. 有料の Apple Developer 証明書を使っていないため、初回起動時に「開発元が未確認」という警告が表示されます。Finder で **アプリを Control キーを押しながらクリック → 「開く」** を選ぶか、**システム設定 → プライバシーとセキュリティ** から許可してください。これは最初の一度だけです

### 方法 2: ソースからビルド

```bash
xcode-select --install   # 未インストールの場合
git clone https://github.com/ST6AR1/mole.git
cd mole
./build.sh
```

プロジェクトフォルダ内に `mole.app` が生成されるので、`Applications` にドラッグすれば使えます。

## 対応プラットフォーム

macOS 12 (Monterey) 以降のみ対応。Apple Silicon と Intel の両方で動作します。

## プライバシー

mole はすべてあなた自身の Mac 上で動作します。使用データやプロジェクトの内容を収集・アップロードすることはありません。ネットワーク通信が発生するのは、起動時に GitHub 上の新しいバージョンをチェックする場合（Releases API への読み取り専用アクセスで、デバイス情報は一切送信されません）と、「問題を報告」をクリックしたときに内容が入力済みの GitHub Issue ページを開く場合のみです。

## よくある質問

**Q: 「Waiting for localhost」のまま止まってしまいます。どうすればいいですか？**
A: バックエンドのみのサービス、データベース、ネイティブアプリの場合はそもそも Web ポートが存在しないため、しばらくすると自動的に完了扱いになります。まだ `npm install` を実行中だったり、Docker イメージを取得中だったりする場合は、フォルダを再度ドロップするのではなく、ログや Terminal で実際の進行状況を確認してください。

**Q: 言語を間違えて選んでしまい、UI が読めなくなりました。どうすればいいですか？**
A: Settings の言語ドロップダウンでは、各言語がそれぞれのネイティブ表記（例:「Français」「日本語」）で表示され、常に同じ固定順に並んでいます。他の表示を読み解く必要なく、自分が読める言語をそのまま見つけられます。

**Q: どのプロジェクトタイプに対応していますか？**
A: Node.js（npm / pnpm / yarn / bun）、静的サイト、Python、Ruby / Rails、Go、Rust、Docker Compose、Deno、PHP、Flutter、Java / Kotlin、.NET、Chrome 拡張機能、ネイティブ macOS アプリなど。検出範囲は今後も拡大していきます。

## ライセンス

MIT ライセンス — 詳細は [LICENSE](LICENSE) をご覧ください。無料・オープンソースです。自由に使用、フォーク、独自ビルドの配布ができます。

## 開発

- `App/main.swift`: アプリ全体のソースコード（純粋な AppKit、SwiftUI は不使用）
- `App/Localization/`: 9 言語分の翻訳ファイル（`Strings.*.swift`）と言語切り替えロジック
- `bin/smart-launch.sh`: プロジェクトタイプを検出し、起動コマンドを組み立てる shell script
- `build.sh`: `.app` をコンパイル・パッケージ化
- `make-dmg.sh`: 配布用の `.dmg` をパッケージ化

リリースの手順:

```bash
./make-dmg.sh
gh release create vX.Y.Z mole-X.Y.Z.dmg --title "vX.Y.Z" --notes "今回の変更内容"
```

## Credits

Made by Wen and Claude, together ⌯^⦁𖥦⦁^⌯
