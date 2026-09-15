import { en } from "./en";
import { zhCN } from "./zh-CN";
import { zhTW } from "./zh-TW";
import { ja } from "./ja";
import { ko } from "./ko";
import { fr } from "./fr";
import { es } from "./es";
import { de } from "./de";
import { ptBR } from "./pt-BR";
import type { Dictionary } from "./types";
import { defaultLocale, locales, readyLocales } from "./config";

const dictionaries: Partial<Record<string, Dictionary>> = {
  en,
  "zh-CN": zhCN,
  "zh-TW": zhTW,
  ja,
  ko,
  fr,
  es,
  de,
  "pt-BR": ptBR,
};

// Resolves a locale code (e.g. Astro.currentLocale) to its dictionary,
// falling back to the default locale for any not-yet-translated language.
export function getDictionary(locale: string = defaultLocale): Dictionary {
  return dictionaries[locale] ?? dictionaries[defaultLocale]!;
}

export { locales, readyLocales, defaultLocale };
export type { Dictionary };
