// Centralizes the base-path prefix so switching from GitHub Pages
// (base: "/mole") to a custom domain (base: "/") later is a one-line change
// in astro.config.mjs — no component needs to change.
export function withBase(path: string): string {
  const base = import.meta.env.BASE_URL.replace(/\/$/, "");
  const clean = path.startsWith("/") ? path : `/${path}`;
  return `${base}${clean}`;
}

export const REPO_URL = "https://github.com/ST6AR1/mole";
export const RELEASES_URL = `${REPO_URL}/releases/latest`;
export const LICENSE_URL = `${REPO_URL}/blob/main/LICENSE`;
export const ISSUES_URL = `${REPO_URL}/issues`;
