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
    // English stays unprefixed at the base ("/mole/…"); Simplified Chinese
    // lives under "/mole/zh-cn/…". Locale *codes* (used in <html lang>,
    // hreflang, and src/i18n/*.ts filenames) stay "en" / "zh-CN" — only the
    // URL segment is lowercased. Keep in sync with src/i18n/config.ts.
    locales: ["en", { path: "zh-cn", codes: ["zh-CN"] }],
    routing: { prefixDefaultLocale: false },
  },
  integrations: [
    sitemap({
      i18n: {
        defaultLocale: "en",
        locales: { en: "en", "zh-cn": "zh-CN" },
      },
    }),
  ],
  compressHTML: true,
});
