import { en } from "./en";
import { zhCN } from "./zh-CN";
import type { Dictionary } from "./types";
import { defaultLocale, locales, readyLocales } from "./config";

const dictionaries: Partial<Record<string, Dictionary>> = {
  en,
  "zh-CN": zhCN,
};

// Resolves a locale code (e.g. Astro.currentLocale) to its dictionary,
// falling back to the default locale for any not-yet-translated language.
export function getDictionary(locale: string = defaultLocale): Dictionary {
  return dictionaries[locale] ?? dictionaries[defaultLocale]!;
}

export { locales, readyLocales, defaultLocale };
export type { Dictionary };
