# Mole for Windows — phases 1 & 2: detection + the launcher/runtime layer

This is Windows support built before any UI work: a cross-platform
TypeScript port of both [`../bin/smart-launch.sh`](../bin/smart-launch.sh)
(project-type detection) and the process-management half of
[`../App/main.swift`](../App/main.swift) (launching, port-polling,
stopping, auto-close). Together they're everything the app *does* other
than draw a window — `runProject()` in [`src/run.ts`](src/run.ts) is the
one function an Electron main process needs to call per dropped folder.

Recommended stack for the actual Windows app (see the planning discussion
in this session): **Electron**, sharing the same HTML/CSS/mascot-illustration
approach as [`../site/`](../site/) and reusing the exact art assets from
`../icon/mole-poses/`. This module has no Electron dependency and doesn't
need one — it's pure Node.js so it can be unit-tested here and imported
as-is once the app shell exists (see [`src/index.ts`](src/index.ts) for the
intended import surface).

## Why detection came first, and how the launcher was ported without a Windows machine

This is the highest-risk, most failure-prone part of the whole app if
ported carelessly — wrong path separators, wrong Python binary name, wrong
kill semantics, etc. are the kind of bugs that only show up on a real
Windows machine, which isn't available in this environment. So detection
was built with a test suite that runs everywhere, and its `darwin` mode was
diff-checked against the real `smart-launch.sh` running in
`SMART_LAUNCH_DRY_RUN=1` mode across all 24 fixtures — every label and
command matched exactly.

The launcher/runtime layer (phase 2) was then ported by reading
`App/main.swift`'s actual implementation line by line rather than
guessing, which turned up a few things worth knowing before testing on a
real machine:

- **Stopping a port sends a single graceful signal to one pid — never a
  process-tree kill.** The mac app calls `Darwin.kill(pid, SIGTERM)`
  directly on whatever pid `lsof` says owns the listening socket (which is
  normally the real server process, not a shell wrapper) and never follows
  up with a force-kill. [`src/stop.ts`](src/stop.ts) mirrors this with a
  plain `taskkill.exe /PID <pid>` (no `/F`, no `/T`) — deliberately *not*
  the tree-kill this README used to say phase 2 would need, because the
  real app doesn't do that either. If a real dev server on Windows turns
  out to leave orphaned child processes where the mac equivalent doesn't,
  that's the one thing here that would need to grow a `/T`.
- **The launcher never tracks the pid it started.** `launchProject()` fires
  the run command detached and forgets about it; the *actual* server pid is
  only discovered afterwards, by diffing "ports listening now" against
  "ports listening right before launch" ([`src/poll.ts`](src/poll.ts)'s
  `waitForNewPort`, ported from `pollForNewServer`). This sidesteps ever
  needing to know what child processes a `npm run dev` / `pnpm install; ...`
  chain spawns.
- **Windows has no `lsof`.** [`src/ports.ts`](src/ports.ts) uses
  `netstat -ano -p TCP` instead, and [`src/processInfo.ts`](src/processInfo.ts)
  gets the owning process's name/uptime via one batched `Get-Process -Id
  ...` PowerShell call (mirroring the mac app's single shared `ps` call for
  all pids at once). Uptime is computed *inside* the PowerShell command
  rather than by parsing a returned timestamp in Node, specifically to
  dodge the fact that `ConvertTo-Json` serializes `DateTime` differently
  between Windows PowerShell 5.1 and PowerShell 7+ — a version-dependent
  bug that would be invisible until it hit a specific PowerShell version.
- **Non-web launches (Flutter, a Chrome extension) skip polling entirely**
  ([`isLikelyNonWebLaunch`](src/poll.ts)), same hint list as the mac app,
  so dropping a Flutter project doesn't sit there polling for 150 seconds
  for a port that will never open.

None of this can be *exercised* end-to-end without a real Windows box —
`netstat`'s exact column layout, `taskkill`'s exact exit behavior on a
process that ignores a graceful close, and PowerShell's JSON serialization
quirks are all things this environment can't produce authentically. What
can be verified here is that the *parsing and decision logic* is correct
against realistic captured output (see `test/ports.test.ts`,
`test/processInfo.test.ts`) and that the orchestration in `run.ts` calls
things in the right order with the right data (`test/run.test.ts`) — the
same "test everything that doesn't require the real OS" strategy that gave
confidence in phase 1.

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

Detection alone:

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

The full detect → launch → wait-for-port flow, as an Electron main process
would call it for a dropped folder:

```ts
import { runProject, fetchDevPortsWindows } from "./src/index.ts";

const result = await runProject(
  "/path/to/some/project",
  (stage) => console.log(stage), // { stage: "detecting" | "preparing" | "starting-server" | ... }
  {
    fetchDevPorts: fetchDevPortsWindows,
    sleep: (ms) => new Promise((r) => setTimeout(r, ms)),
    onPortReady: (port) => console.log(`open http://localhost:${port}`),
  },
);
```

Stopping a running dev server, and the auto-close ("expire after N
minutes") check, are separate small functions rather than bundled into
`runProject` — an Electron UI calls them directly off whatever `PortInfo[]`
its own polling timer last fetched:

```ts
import { fetchDevPortsWindows, stopPort, findExpiredPorts } from "./src/index.ts";

const ports = fetchDevPortsWindows(); // one snapshot of every listening dev port
stopPort(ports[0].pid); // single "Stop" button
findExpiredPorts(ports, 30, (port) => pinnedPorts.has(port)) // 30-minute auto-close
  .forEach((p) => stopPort(p.pid));
```

## Running the tests

```bash
npm install
npm test        # node's built-in test runner, no extra test framework needed
npm run typecheck
```

24 fixture folders under `test/fixtures/`, one per detection rule (see
`test/detect.test.ts`), plus unit tests per launcher/runtime module against
realistic captured `netstat`/PowerShell output and injected fakes for
spawning/timing (`test/ports.test.ts`, `test/processInfo.test.ts`,
`test/devPorts.test.ts`, `test/launcher.test.ts`, `test/poll.test.ts`,
`test/stop.test.ts`, `test/expiry.test.ts`, `test/run.test.ts`).

## Phase 3: the Electron app

`src/electron/` is a working Electron shell on top of everything above —
window, custom titlebar (frameless, matching the mac app's branded
toolbar instead of native chrome), drag-and-drop + a folder picker,
the running-ports list with Stop/pin/auto-close, and a Settings row for
the expire interval. It reuses the real mole art from `../icon/mole-poses/`
and the color/spacing tokens from `../site/src/styles/tokens.css` (copied
in by the build script, not hand-retyped, so it can't silently drift).

```bash
npm install
npm start   # builds (tsc + copies static assets) and launches Electron
```

`npm run build:electron` alone compiles `src/**/*.ts` to CommonJS in
`dist/` (via `scripts/build-electron.mjs`) and copies the renderer's
static HTML/CSS/JS plus the art assets and tokens.css alongside it — see
that script for the exact file list. `dist/` is gitignored; there is no
packaging/installer step here (no electron-builder, no release artifact)
since this is a dev-mode shell for testing the logic, not a distributable
build.

### What running it for real actually found

Every module up to this point had unit tests, but nothing had exercised
the *pieces those tests can't reach* — real IPC between the main process
and a real renderer, a real spawned child process, a real listening port.
Since `detectProject`/`fetchDevPorts`/`launchProject`/`stopPort` are all
already cross-platform (darwin/linux branches exist specifically so this
module can be developed without a Windows machine), the whole app could
actually be run and driven end-to-end on this Mac — launch a real Node
project, watch it appear in the running list, stop it, watch it disappear
— via Chrome DevTools Protocol (`electron --remote-debugging-port`,
scripted from the outside), plus screenshots to check the UI actually
rendered right. That surfaced three real bugs no unit test had caught,
now fixed:

1. **`launchProject` never set the spawned process's `cwd`.** `detectProject`
   writes every command (`"npm run dev"`, or `Set-Location 'sub'; ...` for
   a monorepo) as relative to the project directory, assuming the shell is
   already standing in it — but nothing was passing that directory through
   to `spawn()`. In practice this meant the dev server command ran wherever
   the *app's own* process happened to start from, not the dropped folder.
   `launchProject` now takes `dirPath` and sets it as `cwd` (`src/launcher.ts`).
2. **The bash branch used a login shell (`bash -lc`), which is fragile.**
   The intent (GUI apps don't inherit a Terminal's PATH, so tools like nvm
   or homebrew node need help) is real and is exactly what
   `bin/smart-launch.sh` already solves — by exporting a specific, minimal
   PATH prepend (`$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$HOME/.nvm/current/bin`),
   *not* by sourcing the user's full shell profile. `bash -lc` reproduces
   the profile-sourcing approach instead, and while smoke-testing this a
   real (if unrelated) broken Homebrew Node install on this machine caused
   the profile source to crash the launch outright — a class of failure a
   full login shell is exposed to that a fixed PATH prepend isn't. Fixed to
   `bash -c` plus the same explicit PATH prepend, ported as
   `posixPathWithCommonBinDirs`.
3. **A `hidden` attribute stopped working once its element also had a
   `display`-setting CSS class.** The launch-status card was visible on
   startup when it should have been hidden — `.launch-status { display:
   flex }` and the browser's built-in `[hidden] { display: none }` have
   equal specificity, and author CSS beats the user-agent default
   regardless, so the class silently won. Fixed with an explicit
   `[hidden] { display: none !important; }` rule in `styles.css`.

`stop.ts` also gained a real (non-shelled-out) POSIX branch — sending the
exact `SIGTERM` the mac app itself sends, via `process.kill`, rather than
only knowing how to run Windows's `taskkill.exe` — specifically so this
kind of live test could exercise Stop for real instead of trusting it
untested; the win32 branch (`taskkill /PID`, no `/F`) is unchanged and is
still what actually ships.

### What still can't be verified without a real Windows machine

- Whether `netstat -ano`'s column layout on a real Windows install matches
  what `ports.ts` parses (checked here only against a captured sample).
- Whether `taskkill /PID <pid>` (no `/F`) stops common dev servers
  (Node/Vite, Python, etc.) as gracefully as `SIGTERM` does on macOS, or
  whether some of them ignore it and need a forced fallback.
- The PowerShell `Get-Process`/`ConvertTo-Json` calls in `processInfo.ts`
  against a real Windows PowerShell 5.1 vs. PowerShell 7+ install (the
  uptime-as-plain-number trick was specifically chosen to sidestep a known
  serialization difference between them, but that's a documented risk, not
  a tested one).

### Known gaps in the phase-3 shell itself

- **Cancel doesn't actually cancel.** Clicking "先不等了" hides the status
  card in the renderer, but the `runProject` promise in the main process
  keeps running to completion in the background — there's no cancellation
  token wired through the IPC boundary yet (the mac app's `pollToken`
  UUID-swap approach doesn't cross a process boundary for free the way it
  does in-process). Low-impact (it just keeps polling harmlessly for up to
  150s) but not a faithful port of that behavior yet.
- No Story/General/About tabs or in-app Settings beyond the auto-close
  interval — this was scoped to the functional core (launch, running list,
  stop, pin, auto-close) rather than the full mac app's UI surface.
- No packaging/auto-update (electron-builder, electron-updater) — out of
  scope until there's a real Windows machine to test an installer on.
