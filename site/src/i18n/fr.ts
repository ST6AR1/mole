import type { Dictionary } from "./types";

// Terminology kept in sync with the app's own Strings.fr.swift where it
// overlaps (tagline, "Projets en cours", "Fermeture automatique", etc.).
export const fr: Dictionary = {
  meta: {
    title: "Mole — déposez un dossier, lancez votre projet local",
    description:
      "Mole est un outil macOS gratuit et open source pour les vibe coders. Déposez un dossier de projet, et il détecte comment le lancer, démarre localhost en arrière-plan, et ouvre votre navigateur. Pas de chemins, pas de commandes, pas de Terminal.",
  },
  nav: {
    features: "Fonctionnalités",
    changelog: "Journal des modifications",
    support: "Soutenir",
    github: "GitHub",
    download: "Télécharger",
  },
  hero: {
    tagline: "Oubliez les commandes, passez au travail.",
    h1Line1: "Vos projets ne sont pas perdus,",
    h1Line2: "ils sont juste passés sous terre.",
    subhead:
      "Déposez un dossier de projet sur Mole. Il détermine comment le lancer, démarre localhost, et ouvre votre navigateur. Pas de chemins, pas de commandes, pas de Terminal.",
    ctaPrimary: "Télécharger Mole",
    ctaSecondary: "Voir sur GitHub",
    versionLine: "Gratuit · macOS 12+ · 4,8 Mo",
  },
  problem: {
    line1: "Vous l'avez créé avec l'IA.",
    line2: "Puis vous avez fermé Terminal.",
    line3: "Maintenant… comment le rouvrir ?",
    q1: "C'était quel dossier déjà ?",
    q2: "Quelle commande j'avais utilisée ?",
    q3: "C'était quel port localhost ?",
  },
  solution: {
    eyebrow: "Comment ça marche",
    heading: "Mole se souvient de la partie ennuyeuse.",
    steps: [
      {
        title: "Déposez votre dossier",
        body: "Glissez-le sur Mole, ou choisissez-le avec « Choisir dossier ». C'est toute l'interface.",
      },
      {
        title: "Mole comprend tout seul",
        body: "Il regarde ce qu'il y a dedans et détermine si c'est du Vite, du Next.js, du Python, du Rails, du Docker Compose, ou autre chose — et comment le démarrer.",
      },
      {
        title: "Lancement",
        body: "Il tourne en arrière-plan et ouvre localhost dans votre navigateur. Pas de fenêtre Terminal, pas de pile d'onglets.",
      },
    ],
  },
  features: {
    eyebrow: "Ce que fait Mole",
    heading: "Un petit outil, une seule mission.",
    items: [
      {
        title: "Déposer et c'est parti",
        body: "Une seule zone de dépôt. Glissez un dossier, ou choisissez-le manuellement — Mole s'occupe du reste.",
      },
      {
        title: "Détection intelligente",
        body: "Node (npm, pnpm, yarn, bun), sites statiques, Python, Ruby on Rails, Go, Rust, Docker Compose, et plus encore. Mole lit le dossier et choisit la bonne commande.",
      },
      {
        title: "Tourne en arrière-plan",
        body: "Plus de fenêtres Terminal qui s'accumulent sur votre bureau. La sortie continue d'aller dans un journal, au cas où vous auriez besoin de le consulter.",
      },
      {
        title: "Voir ce qui tourne",
        body: "Chaque service localhost, avec son nom et son favicon. Gardez actif ce qui compte, arrêtez le reste, ou laissez la fermeture automatique faire le ménage.",
      },
    ],
  },
  moleMoment: {
    line1: "Vos projets ne disparaissent pas.",
    line2: "Ils passent juste sous terre.",
    line3: "Mole sait où les retrouver.",
  },
  vibeCoding: {
    eyebrow: "Conçu pour le vibe coding",
    heading:
      "Pour ceux qui construisent des choses avant même de savoir ce que signifie npm run dev.",
    body: "Designers, makers indépendants, AI builders, et toute personne qui apprend à construire avec l'IA. Mole n'essaie pas de remplacer Terminal pour les ingénieurs — c'est pour tous ceux qui préféreraient ne jamais en ouvrir un.",
    quote:
      "Je ne suis pas développeur de métier. À force de vibe coding, j'ai accumulé de plus en plus de projets, sans jamais retenir les commandes de lancement, et je perdais même le fil des ports localhost encore actifs. Alors j'ai créé Mole — on dépose le dossier, et il s'occupe du reste.",
    quoteAttribution: "— Wen, créateur de Mole",
  },
  openSource: {
    eyebrow: "Open source",
    heading: "Gratuit. Open source. Libre à vous de l'inspecter.",
    points: [
      "Code source disponible sur GitHub, licence MIT",
      "Issues et contributions bienvenues",
      "Pas de compte, pas d'abonnement, pas de télémétrie",
    ],
    ctaGithub: "Star sur GitHub",
    support: "Soutenir Mole ♡",
  },
  download: {
    heading: "Prêt à redéterrer vos projets ?",
    ctaPrimary: "Télécharger pour macOS",
    ctaSecondary: "Voir sur GitHub",
    version: "Mole",
    platform: "macOS 12 ou version ultérieure",
    arch: "Apple Silicon et Intel (universel)",
    size: "≈ 4,8 Mo",
    howToOpenSummary: "Vous ouvrez Mole pour la première fois ?",
    howToOpenBody:
      "Mole n'est pas encore notarié par Apple, donc macOS va avertir qu'il provient d'un développeur non identifié. Dans le Finder, faites Control-clic sur mole.app et choisissez Ouvrir — à faire une seule fois.",
    limitationsSummary: "Toutes les configurations n'ont pas encore été testées",
    limitationsBody:
      "Mole est pour l'instant réservé à macOS — l'objectif est de stabiliser cette version avant d'envisager d'autres plateformes. La détection du type de projet est testée sur des configurations courantes, mais pas encore sur tous les frameworks, gestionnaires de paquets ou environnements. Si quelque chose ne fonctionne pas chez vous, ouvrez une issue sur GitHub, ce sera traité.",
  },
  footer: {
    github: "GitHub",
    download: "Télécharger",
    changelog: "Journal des modifications",
    contact: "Contact",
    license: "Licence",
    privacy: "Confidentialité",
    credit: "Créé par un designer indépendant fatigué de retenir des commandes de terminal.",
  },
  notFound: {
    heading: "Rien ici.",
    body: "Mole a dû creuser ailleurs.",
    cta: "Retour à l'accueil",
  },
  support: {
    metaTitle: "Soutenir Mole",
    metaDescription:
      "Mole est gratuit et le restera. Si vous voulez dire merci, voici quelques façons optionnelles de le faire.",
    heading: "Soutenir Mole",
    intro:
      "Mole est gratuit et le restera. Si l'app vous a fait gagner du temps et que vous voulez dire merci, voici les moyens disponibles dès maintenant — totalement optionnels. D'autres seront ajoutés avec le temps.",
    preparing: "En préparation",
    footnote:
      "Aucune pression, pas d'abonnement, pas de compte requis. Mole fonctionne exactement pareil, que vous utilisiez ces options ou non.",
    backHome: "Retour à Mole",
    methodsHeading: "Façons de soutenir",
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
    contactBody: "Besoin d'un autre moyen de soutenir le projet ? Contactez l'auteur.",
    contactEmail: "st6ar1@gmail.com",
  },
  contact: {
    metaTitle: "Contact",
    metaDescription:
      "Des questions, un retour, un bug à signaler ? Envoyez un e-mail — les propositions de collaboration sont aussi les bienvenues.",
    heading: "Contactez-moi",
    body: "Des questions, un retour, un bug à signaler, ou simplement envie de dire bonjour ? Envoyez un e-mail — les propositions de collaboration sont aussi les bienvenues.",
    email: "st6ar1@gmail.com",
    backHome: "Retour à Mole",
  },
  changelog: {
    metaTitle: "Journal des modifications — Mole",
    metaDescription: "Les nouveautés de Mole, version par version.",
    heading: "Journal des modifications",
    intro: "Généré depuis",
    generatedFrom: "GitHub Releases",
    viewOnGithub: "Voir sur GitHub",
  },
  privacyPage: {
    metaTitle: "Confidentialité — Mole",
    metaDescription:
      "Mole fonctionne entièrement sur votre propre machine. Voici exactement ce qu'il envoie, et ce qu'il n'envoie pas, sur le réseau.",
    heading: "Confidentialité",
    intro:
      "Mole fonctionne entièrement sur votre propre machine. Il ne collecte ni ne transmet aucune donnée d'utilisation ni contenu de projet.",
    networkHeading: "Les seuls appels réseau que fait Mole",
    networkItem1:
      "Vérifier auprès de GitHub s'il existe une nouvelle version au lancement — un simple appel en lecture seule à l'API publique des Releases. Aucune information sur l'appareil n'est envoyée.",
    networkItem2:
      "Ouvrir une page GitHub Issue pré-remplie, uniquement lorsque vous cliquez vous-même sur « Signaler un problème ».",
    websiteHeading: "Ce site web",
    websiteBody:
      "Ce site n'a aucun outil d'analyse, aucun pixel de suivi, et aucun cookie en dehors de ceux que votre navigateur définit lui-même. Les chiffres de version et d'étoiles affichés ici proviennent de l'API publique de GitHub au moment de la construction du site.",
    questions: "Des questions ? Ouvrez une issue sur",
  },
};
