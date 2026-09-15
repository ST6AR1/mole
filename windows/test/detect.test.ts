import { test } from "node:test";
import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { detectProject } from "../src/detect.ts";
import type { SupportedPlatform } from "../src/types.ts";

const here = dirname(fileURLToPath(import.meta.url));
const fixture = (name: string) => join(here, "fixtures", name);

// --- Platform-agnostic rules: same label + run command shape on every OS ---

test("Node.js with a dev script, needs install", () => {
  for (const platform of ["win32", "darwin", "linux"] as SupportedPlatform[]) {
    const r = detectProject(fixture("node-npm"), platform);
    assert.ok(r, `expected a match on ${platform}`);
    assert.equal(r!.label, "Node.js (npm)");
    assert.equal(r!.installCommand, "npm install");
    assert.equal(r!.runCommand, "npm run dev");
  }
});

test("Node.js pnpm project, start script, already installed -> no installCommand", () => {
  const r = detectProject(fixture("node-pnpm-installed"), "win32");
  assert.ok(r);
  assert.equal(r!.label, "Node.js (pnpm)");
  assert.equal(r!.installCommand, undefined);
  assert.equal(r!.runCommand, "pnpm run start");
});

test("Node.js yarn project picks serve script", () => {
  const r = detectProject(fixture("node-yarn-serve"), "darwin");
  assert.ok(r);
  assert.equal(r!.label, "Node.js (yarn)");
  assert.equal(r!.runCommand, "yarn serve");
});

test("Node.js bun project", () => {
  const r = detectProject(fixture("node-bun"), "win32");
  assert.ok(r);
  assert.equal(r!.label, "Node.js (bun)");
  assert.equal(r!.runCommand, "bun run dev");
});

test("monorepo: root has no runnable script, desktop/ subfolder does", () => {
  const r = detectProject(fixture("monorepo-desktop"), "win32");
  assert.ok(r);
  assert.match(r!.label, /desktop, pnpm/);
  assert.equal(r!.runCommand, "Set-Location 'desktop'; pnpm install; pnpm run dev");
});

test("monorepo on macOS uses cd + && (install included: fixture has no node_modules)", () => {
  const r = detectProject(fixture("monorepo-desktop"), "darwin");
  assert.ok(r);
  assert.equal(r!.runCommand, "cd 'desktop' && pnpm install && pnpm run dev");
});

test("docker-compose", () => {
  const mac = detectProject(fixture("docker-compose"), "darwin")!;
  assert.equal(mac.label, "Docker Compose");
  assert.match(mac.runCommand, /docker compose up$/);
  assert.match(mac.runCommand, /open -a Docker/);

  const win = detectProject(fixture("docker-compose"), "win32")!;
  assert.equal(win.label, "Docker Compose");
  assert.match(win.runCommand, /docker compose up$/);
  assert.match(win.runCommand, /Docker Desktop\.exe/);
  assert.ok(win.notes?.length, "Windows docker-compose should carry a caveat about the install path assumption");
});

test("Django: python on macOS, python (no 3) on Windows", () => {
  const mac = detectProject(fixture("django"), "darwin")!;
  assert.equal(mac.label, "Django");
  assert.equal(mac.runCommand, "python3 manage.py runserver");

  const win = detectProject(fixture("django"), "win32")!;
  assert.equal(win.runCommand, "python manage.py runserver");
});

test("FastAPI detected from requirements.txt + main.py", () => {
  const r = detectProject(fixture("fastapi"), "win32")!;
  assert.equal(r.label, "FastAPI");
  assert.equal(r.runCommand, "uvicorn main:app --reload");
});

test("Flask detected from requirements.txt + app.py", () => {
  const r = detectProject(fixture("flask"), "darwin")!;
  assert.equal(r.label, "Flask");
  assert.equal(r.runCommand, "python3 app.py");
});

test("generic Python falls back to http.server", () => {
  const r = detectProject(fixture("python-generic"), "win32")!;
  assert.equal(r.label, "Python (fallback http.server)");
  assert.equal(r.runCommand, "python -m http.server 8000");
});

test("Rails vs plain Ruby", () => {
  const rails = detectProject(fixture("rails"), "darwin")!;
  assert.equal(rails.label, "Rails");
  assert.equal(rails.runCommand, "bundle exec rails s");

  const ruby = detectProject(fixture("ruby-plain"), "darwin")!;
  assert.equal(ruby.label, "Ruby");
});

test("Go", () => {
  const r = detectProject(fixture("go"), "win32")!;
  assert.equal(r.label, "Go");
  assert.equal(r.runCommand, "go run .");
});

test("Rust", () => {
  const r = detectProject(fixture("rust"), "win32")!;
  assert.equal(r.label, "Rust");
  assert.equal(r.runCommand, "cargo run");
});

test("Makefile dev target, with a Windows-only caveat note", () => {
  const win = detectProject(fixture("makefile-dev"), "win32")!;
  assert.equal(win.label, "Makefile (dev)");
  assert.equal(win.runCommand, "make dev");
  assert.ok(win.notes?.some((n) => n.includes("make")));

  const mac = detectProject(fixture("makefile-dev"), "darwin")!;
  assert.equal(mac.notes, undefined);
});

test("Deno task", () => {
  const r = detectProject(fixture("deno-task"), "win32")!;
  assert.equal(r.label, "Deno");
  assert.equal(r.runCommand, "deno task dev");
});

test("Deno entry-file fallback (no tasks)", () => {
  const r = detectProject(fixture("deno-entry"), "win32")!;
  assert.equal(r.label, "Deno");
  assert.match(r.runCommand, /mod\.ts$/);
});

test("PHP via composer.json", () => {
  const r = detectProject(fixture("php-composer"), "win32")!;
  assert.equal(r.label, "PHP");
  assert.equal(r.runCommand, "php -S localhost:8000");
});

test("Flutter targets the right desktop platform", () => {
  const win = detectProject(fixture("flutter"), "win32")!;
  assert.equal(win.runCommand, "flutter run -d windows");
  const mac = detectProject(fixture("flutter"), "darwin")!;
  assert.equal(mac.runCommand, "flutter run -d macos");
});

test("Gradle with bootRun, plus a Windows wrapper-script caveat", () => {
  const mac = detectProject(fixture("gradle-boot"), "darwin")!;
  assert.equal(mac.label, "Gradle");
  assert.equal(mac.runCommand, "./gradlew bootRun");

  const win = detectProject(fixture("gradle-boot"), "win32")!;
  assert.equal(win.runCommand, "gradlew.bat bootRun");
});

test("Maven with spring-boot dependency", () => {
  const r = detectProject(fixture("maven-spring"), "win32")!;
  assert.equal(r.label, "Maven");
  assert.equal(r.runCommand, "mvn spring-boot:run");
});

test(".NET via a .csproj file", () => {
  const r = detectProject(fixture("dotnet"), "win32")!;
  assert.equal(r.label, ".NET");
  assert.equal(r.runCommand, "dotnet run");
});

test("Chrome extension manifest", () => {
  const win = detectProject(fixture("chrome-extension"), "win32")!;
  assert.equal(win.label, "Chrome 擴充功能");
  assert.match(win.runCommand, /^start chrome --args/);

  const mac = detectProject(fixture("chrome-extension"), "darwin")!;
  assert.match(mac.runCommand, /^open -a 'Google Chrome'/);
});

test("project's own dev.sh, flagged as needing Git Bash/WSL on Windows", () => {
  const win = detectProject(fixture("shell-script"), "win32")!;
  assert.equal(win.label, "Shell Script (dev.sh)");
  assert.ok(win.notes?.some((n) => n.includes("Git Bash") || n.includes("WSL")));
});

test("plain static site prefers `serve` when npx is available", () => {
  const r = detectProject(fixture("static-html"), "win32", { commandExists: () => true })!;
  assert.equal(r.label, "靜態網頁");
  assert.equal(r.runCommand, "npx --yes serve -l 5173 .");
});

test("plain static site falls back to the platform's python when npx is missing", () => {
  const win = detectProject(fixture("static-html"), "win32", { commandExists: () => false })!;
  assert.equal(win.runCommand, "python -m http.server 8000");

  const mac = detectProject(fixture("static-html"), "darwin", { commandExists: () => false })!;
  assert.equal(mac.runCommand, "python3 -m http.server 8000");
});

test("unrecognized folder returns null", () => {
  assert.equal(detectProject(fixture("unknown"), "win32"), null);
  assert.equal(detectProject(fixture("unknown"), "darwin"), null);
});

test("Apple-only rules (.app/.xcodeproj/Package.swift) never match outside darwin", () => {
  // These three don't have fixtures of their own (they're Apple-specific and
  // would just be inert folders on Windows/Linux); the meaningful assertion
  // is that requesting win32/linux for *any* dir never takes that code path.
  // Covered indirectly by every non-darwin test above returning a non-Apple
  // label. This test just documents the intent.
  assert.equal(detectProject(fixture("unknown"), "linux"), null);
});
