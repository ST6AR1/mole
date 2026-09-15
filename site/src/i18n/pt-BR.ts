import type { Dictionary } from "./types";

// Terminology kept in sync with the app's own Strings.ptBR.swift where it
// overlaps (tagline, "Projetos em execução", "Fechamento automático", etc.).
export const ptBR: Dictionary = {
  meta: {
    title: "Mole — solte uma pasta, rode seu projeto local",
    description:
      "Mole é uma ferramenta gratuita e open source para macOS, feita para vibe coders. Solte uma pasta de projeto e ele descobre como rodar, inicia o localhost em segundo plano e abre seu navegador. Sem caminhos, sem comandos, sem Terminal.",
  },
  nav: {
    features: "Recursos",
    changelog: "Changelog",
    support: "Apoiar",
    github: "GitHub",
    download: "Baixar",
  },
  hero: {
    tagline: "Esqueça os comandos, vá direto ao trabalho.",
    h1Line1: "Seus projetos não sumiram,",
    h1Line2: "só foram parar debaixo da terra.",
    subhead:
      "Solte uma pasta de projeto no Mole. Ele descobre como rodar, inicia o localhost e abre seu navegador. Sem caminhos, sem comandos, sem Terminal.",
    ctaPrimary: "Baixar o Mole",
    ctaSecondary: "Ver no GitHub",
    versionLine: "Grátis · macOS 12+ · 4,8 MB",
  },
  problem: {
    line1: "Você fez isso com IA.",
    line2: "Depois fechou o Terminal.",
    line3: "Agora… como abrir de novo?",
    q1: "Qual pasta era mesmo?",
    q2: "Qual comando eu usei?",
    q3: "Qual porta do localhost era?",
  },
  solution: {
    eyebrow: "Como funciona",
    heading: "A parte chata, o Mole lembra por você.",
    steps: [
      {
        title: "Solte sua pasta",
        body: "Arraste até o Mole, ou escolha com «Escolher pasta». É toda a interface.",
      },
      {
        title: "O Mole descobre sozinho",
        body: "Ele olha o que tem dentro e descobre se é Vite, Next.js, Python, Rails, Docker Compose, ou outra coisa — e como iniciar.",
      },
      {
        title: "Rodar",
        body: "Roda em segundo plano e abre o localhost no seu navegador. Sem janela de Terminal, sem pilha de abas.",
      },
    ],
  },
  features: {
    eyebrow: "O que o Mole faz",
    heading: "Uma ferramenta pequena, com uma única função.",
    items: [
      {
        title: "Soltar e pronto",
        body: "Uma única zona de soltar. Arraste uma pasta, ou escolha manualmente — o Mole cuida do resto.",
      },
      {
        title: "Detecção inteligente",
        body: "Node (npm, pnpm, yarn, bun), sites estáticos, Python, Ruby on Rails, Go, Rust, Docker Compose, e mais. O Mole lê a pasta e escolhe o comando certo.",
      },
      {
        title: "Roda em segundo plano",
        body: "Sem janelas de Terminal se acumulando na sua área de trabalho. A saída continua indo para um log, caso você precise conferir.",
      },
      {
        title: "Veja o que está rodando",
        body: "Cada serviço no localhost, com nome e favicon. Mantenha ativo o que importa, pare o resto, ou deixe o fechamento automático organizar pra você.",
      },
    ],
  },
  moleMoment: {
    line1: "Seus projetos não desaparecem.",
    line2: "Eles só vão parar debaixo da terra.",
    line3: "O Mole sabe onde encontrá-los.",
  },
  vibeCoding: {
    eyebrow: "Feito para vibe coding",
    heading: "Para quem cria coisas antes de aprender o que significa npm run dev.",
    body: "Designers, criadores independentes, AI builders, e qualquer pessoa aprendendo a construir com IA. O Mole não tenta substituir o Terminal para engenheiros — é para quem prefere nem abrir um.",
    quote:
      "Eu não sou desenvolvedor profissional. Depois de muito vibe coding, fui acumulando cada vez mais projetos, não conseguia lembrar os comandos de inicialização e nem sabia mais quais portas do localhost ainda estavam rodando. Então eu criei o Mole — é só soltar a pasta que ele cuida do resto.",
    quoteAttribution: "— Wen, criador do Mole",
  },
  openSource: {
    eyebrow: "Código aberto",
    heading: "Gratuito. Código aberto. Livre para você inspecionar.",
    points: [
      "Código-fonte disponível no GitHub, licença MIT",
      "Issues e contribuições são bem-vindas",
      "Sem conta, sem assinatura, sem telemetria",
    ],
    ctaGithub: "Dar uma estrela no GitHub",
    support: "Apoiar o Mole ♡",
  },
  download: {
    heading: "Pronto para desenterrar seus projetos de novo?",
    ctaPrimary: "Baixar para macOS",
    ctaSecondary: "Ver no GitHub",
    version: "Mole",
    platform: "macOS 12 ou posterior",
    arch: "Apple Silicon e Intel (universal)",
    size: "≈ 4,8 MB",
    howToOpenSummary: "Primeira vez abrindo o Mole?",
    howToOpenBody:
      "O Mole ainda não passou pela notarização da Apple, então o macOS vai avisar que ele é de um desenvolvedor não identificado. No Finder, dê Control-clique em mole.app e escolha Abrir — só precisa fazer isso uma vez.",
    limitationsSummary: "Ainda não testado em todo tipo de ambiente",
    limitationsBody:
      "Por enquanto o Mole é só para macOS — a ideia é deixar essa versão estável antes de pensar em outras plataformas. A detecção de tipo de projeto foi testada em configurações comuns, mas não em todo framework, gerenciador de pacotes ou máquina. Se algo não funcionar no seu ambiente, abra uma issue no GitHub que será resolvido aos poucos.",
  },
  footer: {
    github: "GitHub",
    download: "Baixar",
    changelog: "Changelog",
    contact: "Contato",
    license: "Licença",
    privacy: "Privacidade",
    credit: "Feito por um designer independente cansado de decorar comandos de terminal.",
  },
  notFound: {
    heading: "Não tem nada aqui.",
    body: "O Mole deve ter cavado para outro lugar.",
    cta: "Voltar para o início",
  },
  support: {
    metaTitle: "Apoiar o Mole",
    metaDescription:
      "O Mole é gratuito e vai continuar sendo. Se quiser agradecer, aqui estão algumas formas opcionais de apoiar.",
    heading: "Apoiar o Mole",
    intro:
      "O Mole é gratuito e vai continuar sendo. Se ele te economizou um tempo e você quer agradecer, aqui estão as formas disponíveis agora — totalmente opcionais. Mais serão adicionadas com o tempo.",
    preparing: "Em preparação",
    footnote: "Sem pressão, sem assinatura, sem precisar de conta. O Mole funciona exatamente igual, use ou não essas opções.",
    backHome: "Voltar para o Mole",
    methodsHeading: "Formas de apoiar",
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
    contactBody: "Precisa de outra forma de apoiar? Entre em contato com o autor.",
    contactEmail: "st6ar1@gmail.com",
  },
  contact: {
    metaTitle: "Contato",
    metaDescription:
      "Dúvidas, feedback, ou um bug para reportar? Manda um e-mail — propostas de colaboração também são bem-vindas.",
    heading: "Fale comigo",
    body: "Dúvidas, feedback, um bug para reportar, ou só quer dar um oi? Manda um e-mail — propostas de colaboração também são bem-vindas.",
    email: "st6ar1@gmail.com",
    backHome: "Voltar para o Mole",
  },
  changelog: {
    metaTitle: "Changelog — Mole",
    metaDescription: "As novidades do Mole, versão por versão.",
    heading: "Changelog",
    intro: "Gerado a partir do",
    generatedFrom: "GitHub Releases",
    viewOnGithub: "Ver no GitHub",
  },
  privacyPage: {
    metaTitle: "Privacidade — Mole",
    metaDescription:
      "O Mole roda inteiramente na sua própria máquina. Aqui está exatamente o que ele envia e o que não envia pela rede.",
    heading: "Privacidade",
    intro: "O Mole roda inteiramente na sua própria máquina. Ele não coleta nem envia nenhum dado de uso ou conteúdo de projeto.",
    networkHeading: "As únicas chamadas de rede que o Mole faz",
    networkItem1:
      "Verificar no GitHub se há uma versão nova ao iniciar — uma chamada somente leitura para a API pública de Releases. Nenhuma informação do dispositivo é enviada.",
    networkItem2: "Abrir uma página de Issue do GitHub pré-preenchida, só quando você clica em «Reportar um problema».",
    websiteHeading: "Este site",
    websiteBody:
      "Este site não tem nenhuma ferramenta de análise, nenhum pixel de rastreamento, e nenhum cookie além dos que o próprio navegador define. Os números de versão e estrelas mostrados aqui vêm da API pública do GitHub no momento em que o site foi gerado.",
    questions: "Dúvidas? Abra uma issue no",
  },
};
