// Locale roster for the site. v1 ships "en" only — every other entry is a
// placeholder so the routing/switcher structure exists before translations do.
// To add a language: create src/i18n/<code>.ts implementing Dictionary, then
// flip its `ready` flag here.

export interface LocaleMeta {
  code: string;
  label: string; // shown in its own language, per the app's convention
  ready: boolean;
}

export const locales: LocaleMeta[] = [
  { code: "en", label: "English", ready: true },
  { code: "zh-TW", label: "繁體中文", ready: false },
  { code: "zh-CN", label: "简体中文", ready: false },
  { code: "ja", label: "日本語", ready: false },
  { code: "ko", label: "한국어", ready: false },
  { code: "fr", label: "Français", ready: false },
  { code: "es", label: "Español", ready: false },
  { code: "de", label: "Deutsch", ready: false },
  { code: "pt-BR", label: "Português (Brasil)", ready: false },
];

export const defaultLocale = "en";
