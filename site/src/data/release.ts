// Build-time fetch of the latest GitHub release, with a hardcoded fallback
// so a rate-limited or offline build never breaks. Re-runs on every build,
// including the scheduled/on-release CI trigger — see
// .github/workflows/deploy-site.yml.

export interface ReleaseInfo {
  version: string; // "1.0.4"
  tag: string; // "v1.0.4"
  htmlUrl: string;
  downloadUrl: string;
  sizeMB: string; // "4.8"
  publishedAt: string; // ISO date
}

const REPO = "ST6AR1/mole";

const FALLBACK: ReleaseInfo = {
  version: "1.0.4",
  tag: "v1.0.4",
  htmlUrl: `https://github.com/${REPO}/releases/latest`,
  downloadUrl: `https://github.com/${REPO}/releases/download/v1.0.4/mole-1.0.4.dmg`,
  sizeMB: "4.8",
  publishedAt: "2026-09-15T08:10:16Z",
};

export async function getLatestRelease(): Promise<ReleaseInfo> {
  try {
    const res = await fetch(
      `https://api.github.com/repos/${REPO}/releases/latest`,
      { headers: { Accept: "application/vnd.github+json" } },
    );
    if (!res.ok) throw new Error(`GitHub API ${res.status}`);
    const json = await res.json();
    const dmg = (json.assets ?? []).find((a: { name: string }) =>
      a.name.endsWith(".dmg"),
    );
    if (!dmg) throw new Error("No .dmg asset on latest release");
    const tag: string = json.tag_name;
    return {
      version: tag.replace(/^v/, ""),
      tag,
      htmlUrl: json.html_url,
      downloadUrl: dmg.browser_download_url,
      sizeMB: (dmg.size / 1_000_000).toFixed(1),
      publishedAt: json.published_at,
    };
  } catch {
    return FALLBACK;
  }
}

export async function getStarCount(): Promise<number | null> {
  try {
    const res = await fetch(`https://api.github.com/repos/${REPO}`, {
      headers: { Accept: "application/vnd.github+json" },
    });
    if (!res.ok) throw new Error(`GitHub API ${res.status}`);
    const json = await res.json();
    return typeof json.stargazers_count === "number"
      ? json.stargazers_count
      : null;
  } catch {
    return null;
  }
}

export interface ReleaseListItem {
  tag: string;
  name: string;
  htmlUrl: string;
  publishedAt: string;
  body: string;
}

export async function getAllReleases(): Promise<ReleaseListItem[]> {
  try {
    const res = await fetch(
      `https://api.github.com/repos/${REPO}/releases?per_page=30`,
      { headers: { Accept: "application/vnd.github+json" } },
    );
    if (!res.ok) throw new Error(`GitHub API ${res.status}`);
    const json = await res.json();
    return json.map((r: Record<string, string>) => ({
      tag: r.tag_name,
      name: r.name || r.tag_name,
      htmlUrl: r.html_url,
      publishedAt: r.published_at,
      body: r.body || "",
    }));
  } catch {
    return [
      {
        tag: FALLBACK.tag,
        name: FALLBACK.tag,
        htmlUrl: FALLBACK.htmlUrl,
        publishedAt: FALLBACK.publishedAt,
        body: "See the GitHub Releases page for details.",
      },
    ];
  }
}
