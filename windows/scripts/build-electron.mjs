// Builds the Electron app: compiles src/**/*.ts to CommonJS in dist/, then
// copies over everything tsc doesn't touch (the renderer's static
// HTML/CSS/JS, the mole art assets, and the site's design tokens).
//
// dist/ ends up CommonJS while windows/package.json says "type": "module"
// (needed for the node --experimental-strip-types test script) — so a
// dist/package.json override is written last to reclaim CommonJS for
// everything under dist/, the same way a nested package.json normally
// carves out an exception to a parent's "type" field.

import { execFileSync } from "node:child_process";
import { mkdirSync, cpSync, writeFileSync, readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const windowsDir = dirname(dirname(fileURLToPath(import.meta.url)));
const repoDir = dirname(windowsDir);
const distDir = join(windowsDir, "dist");

console.log("[build] tsc -p tsconfig.build.json");
execFileSync(process.execPath, [join(windowsDir, "node_modules", ".bin", "tsc"), "-p", "tsconfig.build.json"], {
  cwd: windowsDir,
  stdio: "inherit",
});

const rendererSrc = join(windowsDir, "src", "electron", "renderer");
const rendererDist = join(distDir, "electron", "renderer");
console.log("[build] copying renderer static files");
mkdirSync(rendererDist, { recursive: true });
for (const entry of readdirSync(rendererSrc)) {
  if (entry === "assets") continue; // copied separately, from the real art assets below
  cpSync(join(rendererSrc, entry), join(rendererDist, entry), { recursive: true });
}

const assetsDist = join(rendererDist, "assets");
mkdirSync(assetsDist, { recursive: true });
const molePosesDir = join(repoDir, "icon", "mole-poses");
const usedAssets = [
  "wordmark-logo.png",
  "hold-folder-idle.png",
  "carry-folder.png",
  "dig-anim-0.png",
  "dig-anim-1.png",
  "dig-anim-2.png",
  "dig-anim-3.png",
  "dig-anim-4.png",
  "dig-anim-5.png",
  "mound.png",
];
console.log("[build] copying mole art assets");
for (const name of usedAssets) {
  cpSync(join(molePosesDir, name), join(assetsDist, name));
}

console.log("[build] copying design tokens");
cpSync(join(repoDir, "site", "src", "styles", "tokens.css"), join(rendererDist, "tokens.css"));

writeFileSync(join(distDir, "package.json"), JSON.stringify({ type: "commonjs" }, null, 2) + "\n");

console.log("[build] done ->", distDir);
