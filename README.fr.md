[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | Français | [Español](README.es.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt-BR.md)

<p align="center">
  <img src="icon/mole-poses/wordmark-logo.png" width="160" alt="mole logo">
</p>

<p align="center">Oubliez les commandes, passez au travail.<br>Skip the commands, get to work.</p>

<p align="center"><a href="https://st6ar1.github.io/mole/">st6ar1.github.io/mole</a></p>

<p align="center">
  <img src="docs/screenshots/app-icon.png" width="120" alt="mole app icon">
</p>

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="Fenêtre principale de mole : déposez un dossier de projet, il le détecte et le lance automatiquement">
</p>

Un petit utilitaire macOS : déposez un dossier de projet, et mole détermine de quel type de projet il s'agit, le lance en arrière-plan, et ouvre votre navigateur — sans empiler une pile de fenêtres Terminal. Vous pouvez aussi voir exactement quels services localhost tournent en ce moment, et les arrêter d'un clic.

## Pourquoi j'ai créé cette app

<p align="center">
  <img src="docs/screenshots/story.png" width="280" alt="Pourquoi j'ai créé cette app">
</p>

Je ne suis pas développeur de métier. À force de vibe coding, j'ai accumulé de plus en plus de projets, sans jamais retenir les commandes de lancement, et je perdais même le fil des ports localhost encore actifs.

Et je n'avais pas envie de redemander à une IA juste pour relancer un projet.

Alors j'ai créé mole. On dépose le dossier, et il s'occupe du reste.

## Fonctionnalités

- **Lancement par glisser-déposer** : déposez un dossier sur la fenêtre, ou utilisez « Choisir dossier » — mole détecte le type de projet et le lance automatiquement. Compatible avec Node.js (npm / pnpm / yarn / bun), sites statiques, Python, Ruby / Rails, Go, Rust, Docker Compose, Deno, PHP, Flutter, Java / Kotlin, .NET, extensions Chrome, apps macOS natives, et plus encore
- **Tourne entièrement en arrière-plan** : plus de fenêtres Terminal qui s'empilent — la sortie de la commande de lancement est toujours enregistrée, mais vous n'avez plus à la regarder
- **Liste des projets en cours** : chaque service récupère automatiquement le `<title>` ou le favicon du site pour distinguer vos projets en un coup d'œil ; les icônes « toujours actif » (⭐️) et « arrêter » (✕) sont visibles et cliquables directement, sans avoir à ouvrir un menu
- **Fermeture automatique** : ferme automatiquement les services inactifs après un délai configurable ; les projets épinglés (toujours actifs) ne sont jamais touchés
- **Interface en 9 langues** : English, 繁體中文, 简体中文, 日本語, 한국어, Français, Español, Deutsch, et Português (Brasil) — changez de langue instantanément dans les Réglages, sans redémarrage. La liste des langues apparaît toujours dans le même ordre fixe, chaque langue étant écrite dans son propre nom natif
- **Mise à jour automatique** : vérifie au lancement si une nouvelle version est disponible, avec téléchargement et installation en un clic

## Captures d'écran

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="Fenêtre principale de mole">
</p>

## Comment ça marche

Déposez un dossier sur mole, et il va :

1. Examiner le contenu du dossier (`package.json`, `Gemfile`, `go.mod`, `Dockerfile`, …) pour déterminer le type de projet
2. Construire la commande de lancement correspondante et l'exécuter en arrière-plan (la sortie va dans un fichier de log, aucune fenêtre Terminal ne s'ouvre)
3. Surveiller l'apparition d'un nouveau port localhost
4. Ouvrir automatiquement le navigateur dès qu'il est détecté — ou, s'il n'y a pas de port web à détecter (une app native, un service purement backend, etc.), marquer le lancement comme terminé immédiatement

## Installation

Nécessite macOS 12 ou supérieur.

### Option 1 : Télécharger l'app

1. Téléchargez le dernier `mole-x.x.x.dmg` depuis [Releases](https://github.com/ST6AR1/mole/releases/latest)
2. Ouvrez le DMG et glissez l'app dans `Applications`
3. Comme il n'y a pas de certificat Apple Developer payant, le premier lancement affichera un avertissement « développeur non identifié » — dans le Finder, **Control-clic sur l'app → Ouvrir**, ou autorisez-le dans **Réglages Système → Confidentialité et sécurité**. Cela n'arrive qu'une seule fois

### Option 2 : Compiler depuis les sources

```bash
xcode-select --install   # si ce n'est pas déjà fait
git clone https://github.com/ST6AR1/mole.git
cd mole
./build.sh
```

Cela produit `mole.app` dans le dossier du projet — glissez-le dans `Applications` pour l'utiliser.

## Plateformes prises en charge

macOS 12 (Monterey) et versions ultérieures uniquement, sur Apple Silicon comme sur Intel.

## Confidentialité

mole fonctionne entièrement sur votre propre machine. Il ne collecte ni ne transmet aucune donnée d'utilisation ni le contenu de vos projets ; les seuls appels réseau qu'il effectue sont la vérification d'une nouvelle version sur GitHub au lancement (un appel en lecture seule à l'API Releases — aucune information sur votre appareil n'est envoyée), et l'ouverture d'une page GitHub Issue pré-remplie lorsque vous cliquez vous-même sur « Signaler un problème ».

## Questions fréquentes

**Q : Ça reste bloqué sur « Waiting for localhost », que faire ?**
R : S'il s'agit d'un service purement backend, d'une base de données ou d'une app native, il n'y a tout simplement pas de port web à trouver, et le lancement se marquera automatiquement comme terminé après un moment. Si `npm install` est encore en cours d'exécution, qu'une image Docker est en train d'être téléchargée, ou toute autre étape de configuration, consultez le log ou le Terminal pour voir la progression réelle plutôt que de redéposer le dossier.

**Q : J'ai choisi la mauvaise langue et je n'arrive plus à lire l'interface, que faire ?**
R : Dans le menu déroulant des langues des Réglages, chaque langue est affichée dans son propre nom natif (par ex. « Français », « 日本語 ») et apparaît toujours dans le même ordre fixe, pour que vous puissiez retrouver celle que vous comprenez sans avoir à déchiffrer quoi que ce soit d'autre au préalable.

**Q : Quels types de projets sont pris en charge ?**
R : Node.js (npm / pnpm / yarn / bun), sites statiques, Python, Ruby / Rails, Go, Rust, Docker Compose, Deno, PHP, Flutter, Java / Kotlin, .NET, extensions Chrome, apps macOS natives, et plus encore — la détection continue de s'étendre au fil du temps.

## Licence

Licence MIT — voir [LICENSE](LICENSE). Gratuit et open source : utilisez-le, forkez-le, distribuez votre propre build.

## Développement

- `App/main.swift` : le code source de toute l'app (AppKit pur, pas de SwiftUI)
- `App/Localization/` : les fichiers de traduction pour les 9 langues (`Strings.*.swift`) et la logique de changement de langue
- `bin/smart-launch.sh` : le script shell qui détecte les types de projet et construit les commandes de lancement
- `build.sh` : compile et package le `.app`
- `make-dmg.sh` : packages un `.dmg` distribuable

Publier une nouvelle version :

```bash
./make-dmg.sh
gh release create vX.Y.Z mole-X.Y.Z.dmg --title "vX.Y.Z" --notes "Ce qui a changé cette fois"
```

## Credits

Made by Wen and Claude, together ⌯^⦁𖥦⦁^⌯
