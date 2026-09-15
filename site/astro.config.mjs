import { defineConfig } from "astro/config";
import sitemap from "@astrojs/sitemap";

// First version ships on GitHub Pages under a /mole sub-path.
// When a custom domain is attached later, this becomes site: "https://molelaunch.app" (or similar) and base: "/".
export default defineConfig({
  site: "https://st6ar1.github.io",
  base: "/mole",
  trailingSlash: "ignore",
  integrations: [sitemap()],
  compressHTML: true,
});
