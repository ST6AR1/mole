# Mole website

The official site, built with [Astro](https://astro.build) + TypeScript. Deploys to GitHub Pages at `st6ar1.github.io/mole` via `.github/workflows/deploy-site.yml` on every push to `main` that touches `site/`, on every published release (to refresh the version/star numbers), or manually.

## Develop

```bash
npm install
npm run dev
```

## Build

```bash
npm run build   # outputs to dist/
npm run preview # serve the built output locally
```

## Structure

- `src/i18n/` — copy dictionary. `en.ts` is the only complete locale; `config.ts` lists the other 8 languages the architecture supports, each marked `ready: false` until translated. To add one: copy `en.ts`, translate every field (TypeScript will flag anything missing against `types.ts`), register it in `i18n/index.ts`, and flip its `ready` flag in `config.ts`.
- `src/components/MoleArt.astro` — the **only** place mascot images are imported. Every pose used anywhere on the site goes through this component; add a new pose here rather than importing a PNG directly elsewhere.
- `src/components/Screenshot.astro` — swappable "app UI" slot. Currently renders a hand-built placeholder mock per `scene`. Once a real screenshot exists, pass it as `src` (see the component's own doc-comment) and the placeholder is replaced with zero changes to the page that uses it.
- `src/data/release.ts` — fetches the latest GitHub release (version, download URL, size) and star count at build time, with a hardcoded fallback if the API is unreachable or rate-limited.
- `src/assets/mole/` — the mascot art itself (currently the repo's existing low-res pose PNGs; see `mole-site-plan.md` at the repo root for the list of higher-resolution assets still needed).

## Known placeholders (v1)

- All "App UI" screenshots are CSS/HTML mocks, not real captures — see `Screenshot.astro`.
- Mascot art is the existing pose set at its original (mostly ~200px) resolution; several sections would benefit from higher-resolution or new illustrations, listed in `../mole-site-plan.md`.
- Star count / release list silently fall back to a hardcoded value if the GitHub API call fails at build time (rate limiting, no network) — by design, never breaks the build.
