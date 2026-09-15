import { en } from "./en";
import type { Dictionary } from "./types";
import { defaultLocale, locales } from "./config";

const dictionaries: Partial<Record<string, Dictionary>> = {
  en,
};

// v1 always resolves to English; once a locale's file lands, register it
// above and this starts serving it for real for that locale code.
export function getDictionary(locale: string = defaultLocale): Dictionary {
  return dictionaries[locale] ?? dictionaries[defaultLocale]!;
}

export { locales, defaultLocale };
export type { Dictionary };
