import type { Dictionary } from "./types";

// Terminology kept in sync with the app's own Strings.es.swift where it
// overlaps (tagline, "Proyectos en ejecución", "Cierre automático", etc.).
export const es: Dictionary = {
  meta: {
    title: "Mole — suelta una carpeta, ejecuta tu proyecto local",
    description:
      "Mole es una herramienta gratuita y de código abierto para macOS, pensada para vibe coders. Suelta una carpeta de proyecto y detecta cómo ejecutarla, inicia localhost en segundo plano y abre tu navegador. Sin rutas, sin comandos, sin Terminal.",
  },
  nav: {
    features: "Funciones",
    changelog: "Registro de cambios",
    support: "Apoyar",
    github: "GitHub",
    download: "Descargar",
  },
  hero: {
    tagline: "Olvídate de los comandos, ponte a trabajar.",
    h1Line1: "Tus proyectos no se han perdido,",
    h1Line2: "solo se han ido bajo tierra.",
    subhead:
      "Suelta una carpeta de proyecto en Mole. Averigua cómo ejecutarla, inicia localhost y abre tu navegador. Sin rutas, sin comandos, sin Terminal.",
    ctaPrimary: "Descargar Mole",
    ctaSecondary: "Ver en GitHub",
    versionLine: "Gratis · macOS 12+ · 4,8 MB",
  },
  problem: {
    line1: "Lo creaste con IA.",
    line2: "Luego cerraste Terminal.",
    line3: "Ahora… ¿cómo lo vuelves a abrir?",
    q1: "¿Cuál carpeta era?",
    q2: "¿Qué comando usé?",
    q3: "¿Cuál puerto de localhost era?",
  },
  solution: {
    eyebrow: "Cómo funciona",
    heading: "Mole recuerda la parte aburrida.",
    steps: [
      {
        title: "Suelta tu carpeta",
        body: "Arrástrala hasta Mole, o elígela con «Elegir carpeta». Esa es toda la interfaz.",
      },
      {
        title: "Mole lo descubre solo",
        body: "Revisa lo que hay dentro y determina si es Vite, Next.js, Python, Rails, Docker Compose, o algo más — y cómo iniciarlo.",
      },
      {
        title: "Inicio",
        body: "Se ejecuta en segundo plano y abre localhost en tu navegador. Sin ventana de Terminal, sin montón de pestañas.",
      },
    ],
  },
  features: {
    eyebrow: "Qué hace Mole",
    heading: "Una herramienta pequeña, un solo trabajo.",
    items: [
      {
        title: "Suelta y listo",
        body: "Una sola zona de arrastre. Suelta una carpeta, o elígela manualmente — Mole se encarga del resto.",
      },
      {
        title: "Detección inteligente",
        body: "Node (npm, pnpm, yarn, bun), sitios estáticos, Python, Ruby on Rails, Go, Rust, Docker Compose, y más. Mole lee la carpeta y elige el comando correcto.",
      },
      {
        title: "Se ejecuta en segundo plano",
        body: "Sin ventanas de Terminal acumulándose en tu escritorio. La salida sigue registrándose en un log, por si alguna vez necesitas revisarla.",
      },
      {
        title: "Ve qué está corriendo",
        body: "Cada servicio de localhost, con su nombre y favicon. Mantén activo lo importante, detén el resto, o deja que el cierre automático ordene por ti.",
      },
    ],
  },
  moleMoment: {
    line1: "Tus proyectos no desaparecen.",
    line2: "Solo se van bajo tierra.",
    line3: "Mole sabe dónde encontrarlos.",
  },
  vibeCoding: {
    eyebrow: "Hecho para el vibe coding",
    heading: "Para quienes construyen cosas antes de aprender qué significa npm run dev.",
    body: "Diseñadores, makers independientes, AI builders, y cualquiera que esté aprendiendo a construir con IA. Mole no intenta reemplazar Terminal para ingenieros — es para todos los que preferirían no abrir uno.",
    quote:
      "No soy un desarrollador profesional. Después de mucho vibe coding, terminé con cada vez más proyectos, sin poder recordar los comandos de inicio, y sin saber muy bien qué puertos de localhost seguían activos. Así que hice Mole — sueltas la carpeta y él se encarga del resto.",
    quoteAttribution: "— Wen, creador de Mole",
  },
  openSource: {
    eyebrow: "Código abierto",
    heading: "Gratis. Código abierto. Libre para que lo inspecciones.",
    points: [
      "Código fuente disponible en GitHub, licencia MIT",
      "Issues y contribuciones bienvenidas",
      "Sin cuenta, sin suscripción, sin telemetría",
    ],
    ctaGithub: "Dale una estrella en GitHub",
    support: "Apoyar a Mole ♡",
  },
  download: {
    heading: "¿Listo para desenterrar tus proyectos?",
    ctaPrimary: "Descargar para macOS",
    ctaSecondary: "Ver en GitHub",
    version: "Mole",
    platform: "macOS 12 o posterior",
    arch: "Apple Silicon e Intel (universal)",
    size: "≈ 4,8 MB",
    howToOpenSummary: "¿Es la primera vez que abres Mole?",
    howToOpenBody:
      "Mole aún no está notarizado por Apple, así que macOS advertirá que viene de un desarrollador no identificado. En Finder, haz Control-clic en mole.app y elige Abrir — solo necesitas hacerlo una vez.",
    limitationsSummary: "Todavía no se ha probado en todos los entornos",
    limitationsBody:
      "Por ahora Mole es solo para macOS — primero queremos dejar esta versión sólida antes de mirar otras plataformas. La detección del tipo de proyecto está probada en configuraciones comunes, pero no en todos los frameworks, gestores de paquetes o entornos. Si algo no funciona en el tuyo, abre un issue en GitHub y se irá resolviendo.",
  },
  footer: {
    github: "GitHub",
    download: "Descargar",
    changelog: "Registro de cambios",
    contact: "Contacto",
    license: "Licencia",
    privacy: "Privacidad",
    credit: "Hecho por un diseñador independiente cansado de recordar comandos de terminal.",
  },
  notFound: {
    heading: "Aquí no hay nada.",
    body: "Mole debe haber cavado hacia otro lado.",
    cta: "Volver al inicio",
  },
  support: {
    metaTitle: "Apoyar a Mole",
    metaDescription:
      "Mole es gratis y lo seguirá siendo. Si quieres dar las gracias, aquí tienes algunas formas opcionales de hacerlo.",
    heading: "Apoyar a Mole",
    intro:
      "Mole es gratis y lo seguirá siendo. Si te ahorró algo de tiempo y quieres dar las gracias, estas son las formas disponibles ahora mismo — totalmente opcionales. Se irán añadiendo más con el tiempo.",
    preparing: "En preparación",
    footnote: "Sin presión, sin suscripción, sin necesidad de cuenta. Mole funciona exactamente igual, uses o no estas opciones.",
    backHome: "Volver a Mole",
    methodsHeading: "Formas de apoyar",
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
    contactBody: "¿Necesitas otra forma de apoyar? Contacta al autor.",
    contactEmail: "st6ar1@gmail.com",
  },
  contact: {
    metaTitle: "Contacto",
    metaDescription:
      "¿Preguntas, comentarios, o un error que reportar? Envía un correo — también son bienvenidas las propuestas de colaboración.",
    heading: "Ponte en contacto",
    body: "¿Preguntas, comentarios, un error que reportar, o solo quieres saludar? Envía un correo — también son bienvenidas las propuestas de colaboración.",
    email: "st6ar1@gmail.com",
    backHome: "Volver a Mole",
  },
  changelog: {
    metaTitle: "Registro de cambios — Mole",
    metaDescription: "Las novedades de Mole, versión por versión.",
    heading: "Registro de cambios",
    intro: "Generado desde",
    generatedFrom: "GitHub Releases",
    viewOnGithub: "Ver en GitHub",
  },
  privacyPage: {
    metaTitle: "Privacidad — Mole",
    metaDescription:
      "Mole funciona completamente en tu propia máquina. Aquí se explica exactamente qué envía y qué no envía por la red.",
    heading: "Privacidad",
    intro: "Mole funciona completamente en tu propia máquina. No recopila ni sube ningún dato de uso ni contenido de proyectos.",
    networkHeading: "Las únicas llamadas de red que hace Mole",
    networkItem1:
      "Consultar a GitHub si hay una versión nueva al iniciar — una simple llamada de solo lectura a la API pública de Releases. No se envía información del dispositivo.",
    networkItem2: "Abrir una página de GitHub Issue prellenada, solo cuando tú mismo haces clic en «Reportar un problema».",
    websiteHeading: "Este sitio web",
    websiteBody:
      "Este sitio no tiene analítica, ni píxeles de seguimiento, ni más cookies que las que tu propio navegador configure. Los números de versión y estrellas que se muestran aquí se obtienen de la API pública de GitHub cuando se construye el sitio.",
    questions: "¿Preguntas? Abre un issue en",
  },
};
