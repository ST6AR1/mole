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

## What's next (not built yet)

Everything here is pure Node.js with no UI. **Phase 3 is the Electron app
itself**: a window, a drag-and-drop target, the running-ports list, the
Story/General/About tabs, and Settings — reusing `../icon/mole-poses/*.png`
and the design tokens in `../site/src/styles/tokens.css`, with `src/run.ts`
and the other modules here as its entire backend. Two things also
explicitly need a real Windows machine before shipping, since neither can
be authentically produced in this sandbox: confirming `netstat -ano`'s
column layout matches what's parsed here on a real install, and confirming
`taskkill /PID <pid>` (no `/F`) actually stops common dev servers
(Node/Vite, Python, etc.) as gracefully as `SIGTERM` does on macOS rather
than needing a forced fallback.
