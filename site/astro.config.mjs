import { defineConfig } from "astro/config";
import sitemap from "@astrojs/sitemap";

// First version ships on GitHub Pages under a /mole sub-path.
// When a custom domain is attached later, this becomes site: "https://molelaunch.app" (or similar) and base: "/".
export default defineConfig({
  site: "https://st6ar1.github.io",
  base: "/mole",
  trailingSlash: "ignore",
  i18n: {
    defaultLocale: "en",
    // English stays unprefixed at the base ("/mole/…"); every other locale
    // lives under "/mole/<path>/…". Locale *codes* (used in <html lang>,
    // hreflang, and src/i18n/*.ts filenames) keep their canonical casing —
    // only the URL segment is lowercased. Keep in sync with
    // src/i18n/config.ts (the UI-facing locale roster).
    locales: [
      "en",
      { path: "zh-cn", codes: ["zh-CN"] },
      { path: "zh-tw", codes: ["zh-TW"] },
      { path: "ja", codes: ["ja"] },
      { path: "ko", codes: ["ko"] },
      { path: "fr", codes: ["fr"] },
      { path: "es", codes: ["es"] },
      { path: "de", codes: ["de"] },
      { path: "pt-br", codes: ["pt-BR"] },
    ],
    routing: { prefixDefaultLocale: false },
  },
  integrations: [
    sitemap({
      i18n: {
        defaultLocale: "en",
        locales: {
          en: "en",
          "zh-cn": "zh-CN",
          "zh-tw": "zh-TW",
          ja: "ja",
          ko: "ko",
          fr: "fr",
          es: "es",
          de: "de",
          "pt-br": "pt-BR",
        },
      },
    }),
  ],
  compressHTML: true,
});
