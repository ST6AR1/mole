// Cross-platform port of ../../bin/smart-launch.sh's project-type detection.
//
// This is detection ONLY — it decides *what* a folder is and *what command*
// would start it. It does not spawn anything. That's the next module
// (launcher.ts, not built yet): it will take a DetectionResult and actually
// run installCommand/runCommand, track the child process, poll for a new
// port, etc. Keeping detection pure and side-effect-free (besides reading
// files) makes it trivially testable, which is the whole point of doing
// this piece first — see test/detect.test.ts.
//
// Ported rule-by-rule from smart-launch.sh, in the same order (numbered
// comments below match that file's section numbers), with platform-aware
// adjustments called out inline. Three of the original rules are Apple-only
// concepts with no Windows/Linux equivalent and are simply skipped outside
// darwin: a bundled .app, an Xcode project, and `swift run` for a raw
// Swift Package.

import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { execFileSync } from "node:child_process";
import type { DetectionResult, Shell, SupportedPlatform } from "./types.ts";
import { quoteForShell } from "./shellQuote.ts";

function shellFor(platform: SupportedPlatform): Shell {
  return platform === "win32" ? "powershell" : "bash";
}

function pythonBin(platform: SupportedPlatform): string {
  // Windows' official python.org installer and the Microsoft Store package
  // both put "python" on PATH, not "python3" (that alias is a WSL/Homebrew
  // convention). Using the wrong one is a very common first-run failure.
  return platform === "win32" ? "python" : "python3";
}

function has(dir: string, name: string): boolean {
  return existsSync(join(dir, name));
}

function isDir(dir: string, name: string): boolean {
  try {
    return statSync(join(dir, name)).isDirectory();
  } catch {
    return false;
  }
}

function readText(dir: string, name: string): string | null {
  try {
    return readFileSync(join(dir, name), "utf8");
  } catch {
    return null;
  }
}

function readJson<T = unknown>(dir: string, name: string): T | null {
  const text = readText(dir, name);
  if (text === null) return null;
  try {
    return JSON.parse(text) as T;
  } catch {
    return null;
  }
}

function containsAny(text: string | null, patterns: RegExp[]): boolean {
  if (text === null) return false;
  return patterns.some((p) => p.test(text));
}

function firstExisting(dir: string, names: string[]): string | null {
  for (const n of names) if (has(dir, n)) return n;
  return null;
}

function globExt(dir: string, ext: string): string | null {
  try {
    const match = readdirSync(dir).find((f) => f.toLowerCase().endsWith(ext));
    return match ?? null;
  } catch {
    return null;
  }
}

function commandExists(cmd: string, platform: SupportedPlatform): boolean {
  try {
    if (platform === "win32") {
      execFileSync("where", [cmd], { stdio: "ignore" });
    } else {
      execFileSync("which", [cmd], { stdio: "ignore" });
    }
    return true;
  } catch {
    return false;
  }
}

// --- Node.js package manager + scripts (used by rules 1 and 1b) -----------

type PkgManager = "pnpm" | "yarn" | "bun" | "npm";

function pkgManagerFor(dir: string): PkgManager {
  if (has(dir, "pnpm-lock.yaml")) return "pnpm";
  if (has(dir, "yarn.lock")) return "yarn";
  if (has(dir, "bun.lockb")) return "bun";
  return "npm";
}

function installCommandFor(pm: PkgManager): string {
  return { pnpm: "pnpm install", yarn: "yarn install", bun: "bun install", npm: "npm install" }[pm];
}

function runScriptCommand(pm: PkgManager, script: string): string {
  switch (pm) {
    case "pnpm":
      return `pnpm run ${script}`;
    case "yarn":
      return `yarn ${script}`;
    case "bun":
      return `bun run ${script}`;
    case "npm":
      return `npm run ${script}`;
  }
}

function pickScript(dir: string, candidates: string[]): string | null {
  const pkg = readJson<{ scripts?: Record<string, string> }>(dir, "package.json");
  const scripts = pkg?.scripts ?? {};
  for (const c of candidates) if (scripts[c]) return c;
  return null;
}

// --- Python venv activation (used by rules 3 and 4) ------------------------

function venvActivation(dir: string, platform: SupportedPlatform): string {
  const venvDir = has(dir, "venv") ? "venv" : has(dir, ".venv") ? ".venv" : null;
  if (!venvDir) return "";
  if (platform === "win32") {
    // Windows venvs put activation scripts in Scripts\, not bin/. PowerShell
    // needs the leading ".\" and, unlike cmd.exe, chains with ";" not "&&"
    // for "run this, then run that regardless" — but we specifically want
    // "only continue if activation succeeded", which in PowerShell is just
    // sequential statements (Activate.ps1 doesn't set $LASTEXITCode in a way
    // `&&`-chaining would check anyway), so a semicolon is the honest choice.
    return `. .\\${venvDir}\\Scripts\\Activate.ps1; `;
  }
  return `source ${venvDir}/bin/activate && `;
}

// --- The detector chain, in smart-launch.sh's exact order ------------------

export interface DetectDeps {
  /** Overridable for tests — the real implementation shells out to `where`/`which`,
   * which only reflects the machine actually running the process, not the
   * `platform` argument. Without this hook, a test can never exercise the
   * "npx is available" branch for a platform other than the one the test
   * runner itself is on. */
  commandExists: (cmd: string, platform: SupportedPlatform) => boolean;
}

const defaultDeps: DetectDeps = { commandExists };

export function detectProject(
  dir: string,
  platform: SupportedPlatform = process.platform as SupportedPlatform,
  deps: DetectDeps = defaultDeps,
): DetectionResult | null {
  const shell = shellFor(platform);
  const isWin = platform === "win32";
  const isMac = platform === "darwin";

  // 0 / 0b / 0c — bundled .app, Xcode project, raw Swift Package.
  // Apple-only concepts; nothing to detect on Windows or Linux.
  if (isMac) {
    const appBundle = (() => {
      try {
        return readdirSync(dir).find((f) => f.endsWith(".app")) ?? null;
      } catch {
        return null;
      }
    })();
    if (appBundle) {
      return {
        label: "macOS App（直接開啟）",
        runCommand: `open ${quoteForShell(join(dir, appBundle), shell)}`,
        shell,
      };
    }

    const xcodeProj = (() => {
      try {
        return (
          readdirSync(dir).find((f) => f.endsWith(".xcworkspace") || f.endsWith(".xcodeproj")) ?? null
        );
      } catch {
        return null;
      }
    })();
    if (xcodeProj) {
      return {
        label: "Xcode 專案",
        runCommand: `open ${quoteForShell(join(dir, xcodeProj), shell)}`,
        shell,
      };
    }

    if (has(dir, "Package.swift")) {
      const runScript = join(dir, "Scripts", "run.sh");
      const runCommand = existsSync(runScript)
        ? isExecutable(runScript)
          ? "./Scripts/run.sh"
          : "bash Scripts/run.sh"
        : "swift run";
      return { label: "Swift Package", runCommand, shell };
    }
  }

  // 1 — Node.js project.
  if (has(dir, "package.json")) {
    const pm = pkgManagerFor(dir);
    const needsInstall = !isDir(dir, "node_modules");
    const script = pickScript(dir, ["dev", "start", "serve"]);
    if (script) {
      return {
        label: `Node.js (${pm})`,
        installCommand: needsInstall ? installCommandFor(pm) : undefined,
        runCommand: runScriptCommand(pm, script),
        shell,
      };
    }
  }

  // 1b — Monorepo: root package.json has no usable dev/start/serve, but a
  // conventional subfolder does (Tauri/Electron-style: root = shared code,
  // desktop/ = the actual app).
  {
    const candidates = ["desktop", "app", "client", "frontend", "web", join("packages", "desktop"), join("packages", "app"), join("packages", "web")];
    for (const sub of candidates) {
      const subDir = join(dir, sub);
      if (!has(subDir, "package.json")) continue;
      const script = pickScript(subDir, ["dev", "start", "serve"]);
      if (!script) continue;

      const pm = pkgManagerFor(subDir);
      const needsInstall = !isDir(subDir, "node_modules");
      // cd needs its own quoting since `sub` can contain a path separator.
      const cd = isWin ? `Set-Location ${quoteForShell(sub, shell)}` : `cd ${quoteForShell(sub, shell)}`;
      const chain = isWin ? "; " : " && ";
      const run = runScriptCommand(pm, script);
      return {
        label: `Node.js 子專案 (${sub}, ${pm})`,
        runCommand: needsInstall
          ? `${cd}${chain}${installCommandFor(pm)}${chain}${run}`
          : `${cd}${chain}${run}`,
        shell,
      };
    }
  }

  // 2 — docker-compose.
  if (firstExisting(dir, ["docker-compose.yml", "compose.yaml", "compose.yml"])) {
    return {
      label: "Docker Compose",
      runCommand: dockerComposeCommand(platform, shell),
      shell,
      notes: isWin
        ? ["假設 Docker Desktop 已安裝在預設路徑；如果裝在別處，啟動 Docker 那段可能要調整。"]
        : undefined,
    };
  }

  // 3 — Python: Django.
  if (has(dir, "manage.py")) {
    return {
      label: "Django",
      runCommand: `${venvActivation(dir, platform)}${pythonBin(platform)} manage.py runserver`,
      shell,
    };
  }

  // 4 — Python: FastAPI / Flask / generic.
  if (has(dir, "requirements.txt") || has(dir, "pyproject.toml")) {
    const reqText = readText(dir, "requirements.txt");
    const pyprojectText = readText(dir, "pyproject.toml");
    const act = venvActivation(dir, platform);
    const py = pythonBin(platform);

    if (containsAny(reqText, [/fastapi|uvicorn/i]) || containsAny(pyprojectText, [/fastapi|uvicorn/i])) {
      const entryFile = firstExisting(dir, ["main.py", "app.py", join("src", "main.py")]);
      const entry = entryFile ? `${entryFile.replace(/\.py$/, "").replace(/[\\/]/g, ".")}:app` : "main:app";
      return { label: "FastAPI", runCommand: `${act}uvicorn ${entry} --reload`, shell };
    }
    if (containsAny(reqText, [/flask/i]) || containsAny(pyprojectText, [/flask/i])) {
      const entry = has(dir, "main.py") ? "main.py" : "app.py";
      return { label: "Flask", runCommand: `${act}${py} ${entry}`, shell };
    }
    if (has(dir, "app.py")) return { label: "Python (app.py)", runCommand: `${act}${py} app.py`, shell };
    if (has(dir, "main.py")) return { label: "Python (main.py)", runCommand: `${act}${py} main.py`, shell };
    return { label: "Python (fallback http.server)", runCommand: `${act}${py} -m http.server 8000`, shell };
  }

  // 5 — Ruby / Rails.
  if (has(dir, "Gemfile")) {
    if (has(dir, join("config", "application.rb"))) {
      return { label: "Rails", runCommand: "bundle exec rails s", shell };
    }
    return { label: "Ruby", runCommand: "bundle exec ruby app.rb", shell };
  }

  // 6 — Go.
  if (has(dir, "go.mod")) return { label: "Go", runCommand: "go run .", shell };

  // 7 — Rust.
  if (has(dir, "Cargo.toml")) return { label: "Rust", runCommand: "cargo run", shell };

  // 8 — Makefile with a dev/run/start target.
  {
    const makefile = readText(dir, "Makefile");
    if (makefile && /^(dev|run|start):/m.test(makefile)) {
      const target = /^dev:/m.test(makefile) ? "dev" : /^run:/m.test(makefile) ? "run" : "start";
      return {
        label: `Makefile (${target})`,
        runCommand: `make ${target}`,
        shell,
        notes: isWin
          ? ["Windows 沒有內建 make，需要另外安裝（例如透過 Chocolatey 或 MSYS2）才能執行這個指令。"]
          : undefined,
      };
    }
  }

  // 9 — Deno.
  {
    const denoFile = firstExisting(dir, ["deno.json", "deno.jsonc"]);
    if (denoFile) {
      const denoConfig = readText(dir, denoFile) ?? "";
      if (/"dev"|"start"/.test(denoConfig)) {
        const task = /"dev"/.test(denoConfig) ? "dev" : "start";
        return { label: "Deno", runCommand: `deno task ${task}`, shell };
      }
      const entry = firstExisting(dir, ["main.ts", "main.js", join("src", "main.ts"), "mod.ts"]) ?? "main.ts";
      return { label: "Deno", runCommand: `deno run --allow-net --allow-read --allow-env ${entry}`, shell };
    }
  }

  // 10 — PHP.
  if (has(dir, "composer.json") || has(dir, "index.php")) {
    return { label: "PHP", runCommand: "php -S localhost:8000", shell };
  }

  // 11 — Flutter.
  if (has(dir, "pubspec.yaml")) {
    return { label: "Flutter", runCommand: `flutter run -d ${isWin ? "windows" : "macos"}`, shell };
  }

  // 12 — Java / Kotlin (Gradle / Maven).
  if (has(dir, "gradlew")) {
    const buildFile = readText(dir, "build.gradle") ?? readText(dir, "build.gradle.kts") ?? "";
    const wrapper = isWin ? "gradlew.bat" : "./gradlew";
    return {
      label: "Gradle",
      runCommand: /bootRun/.test(buildFile) ? `${wrapper} bootRun` : `${wrapper} run`,
      shell,
      notes: isWin && !has(dir, "gradlew.bat")
        ? ["找到 gradlew 但沒有 gradlew.bat，Windows 上可能要改用 `gradle` 指令代替。"]
        : undefined,
    };
  }
  if (has(dir, "pom.xml")) {
    const pom = readText(dir, "pom.xml") ?? "";
    return {
      label: "Maven",
      runCommand: /spring-boot/.test(pom) ? "mvn spring-boot:run" : "mvn compile exec:java",
      shell,
    };
  }

  // 13 — .NET / C#.
  if (globExt(dir, ".csproj") || globExt(dir, ".sln")) {
    return { label: ".NET", runCommand: "dotnet run", shell };
  }

  // 14 — Chrome extension (manifest.json, not an npm project).
  {
    const manifest = readText(dir, "manifest.json");
    if (manifest && /manifest_version/.test(manifest)) {
      const chromeArg = `--load-extension=${dir}`;
      const runCommand = isWin
        ? `start chrome --args ${quoteForShell(chromeArg, shell)}`
        : `open -a 'Google Chrome' --args ${quoteForShell(chromeArg, shell)}`;
      return { label: "Chrome 擴充功能", runCommand, shell };
    }
  }

  // 15 — Project's own start.sh / run.sh / dev.sh, last resort before giving up.
  // On Windows these would need a bash-compatible shell (Git Bash/WSL) to run
  // at all — we still detect them so the UI can say so, rather than silently
  // skipping to the static-site fallback.
  {
    const script = firstExisting(dir, ["start.sh", "run.sh", "dev.sh"]);
    if (script) {
      return {
        label: `Shell Script (${script})`,
        runCommand: isWin ? `bash ${script}` : `bash ${script}`,
        shell,
        notes: isWin
          ? ["這是 shell script，Windows 上需要先安裝 Git Bash 或 WSL 才能執行。"]
          : undefined,
      };
    }
  }

  // 16 — Plain static site (index.html / any *.html, no build tooling).
  if (has(dir, "index.html") || globExt(dir, ".html")) {
    const hasNpx = deps.commandExists("npx", platform);
    return {
      label: "靜態網頁",
      runCommand: hasNpx ? "npx --yes serve -l 5173 ." : `${pythonBin(platform)} -m http.server 8000`,
      shell,
    };
  }

  return null;
}

function isExecutable(path: string): boolean {
  try {
    const stat = statSync(path);
    // POSIX-only check (Windows has no exec bit); fine since this branch
    // only runs under isMac above.
    return (stat.mode & 0o111) !== 0;
  } catch {
    return false;
  }
}

function dockerComposeCommand(platform: SupportedPlatform, shell: Shell): string {
  if (platform === "win32") {
    // PowerShell equivalent of the bash version's "wait for Docker Desktop
    // to wake up" loop. Assumes the default install path; see the `notes`
    // field this ships with.
    return [
      "if (-not (docker info *>$null; $?)) {",
      "  Write-Host '>> Docker 尚未啟動，正在打開 Docker Desktop...'; ",
      "  Start-Process 'C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe' -ErrorAction SilentlyContinue; ",
      "  $i = 0; ",
      "  while (-not (docker info *>$null; $?) -and $i -lt 60) { Start-Sleep -Seconds 1; $i++ }; ",
      "  if (docker info *>$null; $?) { Write-Host '>> Docker 已就緒' } else { Write-Host '>> 等待逾時，請確認已安裝並手動啟動 Docker Desktop' }",
      "}",
      "docker compose up",
    ].join("");
  }
  return "if ! docker info >/dev/null 2>&1; then echo '>> Docker 尚未啟動，正在打開 Docker Desktop...'; open -a Docker 2>/dev/null; printf '>> 等待 Docker 就緒'; i=0; until docker info >/dev/null 2>&1 || [ $i -ge 60 ]; do printf '.'; sleep 1; i=$((i+1)); done; echo; if docker info >/dev/null 2>&1; then echo '>> Docker 已就緒'; else echo '>> 等待逾時，請確認已安裝並手動啟動 Docker Desktop'; fi; fi; docker compose up";
}
