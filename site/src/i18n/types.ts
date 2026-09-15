// Shape every locale dictionary must satisfy. Keep this the single source of
// truth for what copy the site needs — when a new language file is added,
// TypeScript will flag any missing key against this interface.

export interface Dictionary {
  meta: {
    title: string;
    description: string;
  };
  nav: {
    features: string;
    changelog: string;
    support: string;
    github: string;
    download: string;
  };
  hero: {
    tagline: string;
    h1Line1: string;
    h1Line2: string;
    subhead: string;
    ctaPrimary: string;
    ctaSecondary: string;
    versionLine: string;
  };
  problem: {
    line1: string;
    line2: string;
    line3: string;
    q1: string;
    q2: string;
    q3: string;
  };
  solution: {
    eyebrow: string;
    heading: string;
    steps: { title: string; body: string }[];
  };
  features: {
    eyebrow: string;
    heading: string;
    items: { title: string; body: string }[];
  };
  moleMoment: {
    line1: string;
    line2: string;
    line3: string;
  };
  vibeCoding: {
    eyebrow: string;
    heading: string;
    body: string;
    quote: string;
    quoteAttribution: string;
  };
  openSource: {
    eyebrow: string;
    heading: string;
    points: string[];
    ctaGithub: string;
    support: string;
  };
  download: {
    heading: string;
    ctaPrimary: string;
    ctaSecondary: string;
    version: string;
    platform: string;
    arch: string;
    size: string;
    howToOpenSummary: string;
    howToOpenBody: string;
    limitationsSummary: string;
    limitationsBody: string;
  };
  footer: {
    github: string;
    download: string;
    changelog: string;
    license: string;
    privacy: string;
    credit: string;
  };
  notFound: {
    heading: string;
    body: string;
    cta: string;
  };
  support: {
    metaTitle: string;
    metaDescription: string;
    heading: string;
    intro: string;
    comingSoon: string;
    footnote: string;
    backHome: string;
    regions: {
      key: string;
      title: string;
      note: string;
      ready: boolean;
      methods: { label: string; href?: string }[];
      qrCaption?: string;
      contactNote?: string;
    }[];
  };
}
