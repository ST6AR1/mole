// Locale roster for the site. v1 ships "en" + "zh-CN" — every other entry is
// a placeholder so the routing/switcher structure exists before translations
// do. To add a language: create src/i18n/<code>.ts implementing Dictionary,
// register it in i18n/index.ts, flip its `ready` flag here, AND add it to
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
  { code: "zh-CN", path: "zh-cn", label: "简体中文", ready: true },
  { code: "zh-TW", path: "zh-tw", label: "繁體中文", ready: false },
  { code: "ja", path: "ja", label: "日本語", ready: false },
  { code: "ko", path: "ko", label: "한국어", ready: false },
  { code: "fr", path: "fr", label: "Français", ready: false },
  { code: "es", path: "es", label: "Español", ready: false },
  { code: "de", path: "de", label: "Deutsch", ready: false },
  { code: "pt-BR", path: "pt-br", label: "Português (Brasil)", ready: false },
];

export const defaultLocale = "en";

export const readyLocales = locales.filter((l) => l.ready);
