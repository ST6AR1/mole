// Locale roster for the site. Every entry here is fully translated and
// routed. To add a language: create src/i18n/<code>.ts implementing
// Dictionary, register it in i18n/index.ts, add it here, AND add it to
// astro.config.mjs's `i18n.locales` (that's what actually turns on routing
// for it — this file alone only drives the UI-facing switcher/labels).

export interface LocaleMeta {
  code: string; // matches Astro.currentLocale and the src/i18n/<code>.ts filename
  path: string; // URL segment used by astro.config.mjs's i18n.locales (lowercase)
  label: string; // shown in its own language, per the app's convention
  ready: boolean;
}

export const locales: LocaleMeta[] = [
  { code: "en", path: "en", label: "English", ready: true },
  { code: "zh-TW", path: "zh-tw", label: "繁體中文", ready: true },
  { code: "zh-CN", path: "zh-cn", label: "简体中文", ready: true },
  { code: "ja", path: "ja", label: "日本語", ready: true },
  { code: "ko", path: "ko", label: "한국어", ready: true },
  { code: "fr", path: "fr", label: "Français", ready: true },
  { code: "es", path: "es", label: "Español", ready: true },
  { code: "de", path: "de", label: "Deutsch", ready: true },
  { code: "pt-BR", path: "pt-br", label: "Português (Brasil)", ready: true },
];

export const defaultLocale = "en";

export const readyLocales = locales.filter((l) => l.ready);
