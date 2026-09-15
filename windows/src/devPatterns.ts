// Ported verbatim from `devPatterns` in ../App/main.swift — the set of
// process names that mark a listening port as "a dev server", vs. some
// unrelated background service also happening to listen on a TCP port.
// Windows image names carry a `.exe` suffix (`node.exe`, not `node`), so
// isDevProcessName() strips that before comparing.
const DEV_PATTERNS = new Set([
  "node", "python", "python3", "ruby", "go", "php", "php-fpm", "deno", "bun",
  "java", "ngrok", "caddy", "nginx", "webpack", "vite", "next", "rails",
  "uvicorn", "gunicorn", "flask", "dotnet",
]);

export function isDevProcessName(name: string): boolean {
  const normalized = name.trim().toLowerCase().replace(/\.exe$/, "");
  return DEV_PATTERNS.has(normalized);
}
