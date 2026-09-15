# Mole for Windows — phase 1: project detection

This is the first piece of Windows support, on its own before any UI work:
a cross-platform TypeScript port of [`../bin/smart-launch.sh`](../bin/smart-launch.sh)'s
project-type detection. It decides *what kind of project* a folder is and
*what command* would start it — it does not launch anything itself.

Recommended stack for the actual Windows app (see the planning discussion
in this session): **Electron**, sharing the same HTML/CSS/mascot-illustration
approach as [`../site/`](../site/) and reusing the exact art assets from
`../icon/mole-poses/`. This module has no Electron dependency and doesn't
need one — it's pure Node.js so it can be unit-tested here and imported
as-is once the app shell exists.

## Why detection came first

This is the highest-risk, most failure-prone part of the whole app if
ported carelessly — wrong path separators, wrong Python binary name, wrong
process-tree-kill semantics, etc. are the kind of bugs that only show up on
a real Windows machine, which isn't available in this environment. So this
piece was built with a test suite that runs everywhere, and its `darwin`
mode was diff-checked against the real `smart-launch.sh` running in
`SMART_LAUNCH_DRY_RUN=1` mode across all 24 fixtures — every label and
command matched exactly. That gives real confidence the *logic* is a
faithful port before a single line of Windows-only code (spawning,
port-polling, process-tree kill) gets written.

## What's ported, and what's platform-specific

Every rule from `smart-launch.sh`, in the same order, with these
adjustments where Windows genuinely differs from macOS:

| Concern | macOS | Windows |
|---|---|---|
| Shell | bash | PowerShell |
| Python binary | `python3` | `python` |
| Venv activation | `source venv/bin/activate` | `. .\venv\Scripts\Activate.ps1` |
| Chaining commands | `&&` | `;` (PowerShell doesn't gain much from `&&`-style short-circuiting the way bash does here) |
| Opening Docker Desktop | `open -a Docker` | `Start-Process` at the default install path (flagged with a `notes` caveat — this assumes the default path) |
| Flutter desktop target | `-d macos` | `-d windows` |
| Gradle wrapper | `./gradlew` | `gradlew.bat` (falls back to `gradlew` with a note if the `.bat` is missing) |
| `make` | assumed present | flagged with a note — not installed by default on Windows |
| Project's own `dev.sh`/`start.sh` | runs directly | flagged with a note — needs Git Bash or WSL |

Three rules are **not ported** because they're Apple-only concepts with no
Windows equivalent: a bundled `.app`, an `.xcodeproj`/`.xcworkspace`, and
`swift run` for a bare Swift Package. `detectProject` simply skips these
outside `platform === "darwin"`.

## Using it

```ts
import { detectProject } from "./src/detect.ts";

const result = detectProject("/path/to/some/project"); // platform defaults to process.platform
if (result) {
  console.log(result.label, result.runCommand, result.installCommand);
}
```

`detectProject(dir, platform?, deps?)` — `platform` can be overridden (used
throughout the test suite to exercise Windows-shaped output on any
machine); `deps` lets a test replace the one real side-effecting check
(`commandExists`, used only to decide whether `npx serve` is available)
without needing the actual binary on PATH.

## Running the tests

```bash
npm install
npm test        # node's built-in test runner, no extra test framework needed
npm run typecheck
```

24 fixture folders under `test/fixtures/`, one per detection rule, each
with a comment in `test/detect.test.ts` explaining what it's proving.

## What's next (not built yet)

This module deliberately stops at "here's the command." Phase 2 is the
launcher: actually spawning `installCommand`/`runCommand` detached on
Windows, redirecting output to a log, polling for a newly-opened TCP port
(Windows has no `lsof`; this needs `netstat -ano` parsing or a native
module), and killing a process **tree** on Stop (`taskkill /PID <pid> /T /F`,
since a plain kill of the parent PID often leaves child processes like a
dev server's file-watcher running). Phase 3 is the Electron UI itself,
reusing `../icon/mole-poses/*.png` and the design tokens already
established in `../site/src/styles/tokens.css`.
