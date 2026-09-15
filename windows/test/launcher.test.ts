import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { EventEmitter } from "node:events";
import {
  launchProject,
  launchLogPath,
  lastNonEmptyLine,
  readLastLogLine,
  posixPathWithCommonBinDirs,
} from "../src/launcher.ts";
import type { DetectionResult } from "../src/types.ts";

function fakeChild() {
  const emitter = new EventEmitter() as any;
  emitter.unref = () => {};
  return emitter;
}

test("launchLogPath is fixed and lives under the given tmp dir", () => {
  const p = launchLogPath(() => "/some/tmp");
  assert.equal(p, join("/some/tmp", "mole-launch-latest.log"));
});

test("launchProject runs runCommand through powershell.exe for a powershell DetectionResult, detached", () => {
  const dir = mkdtempSync(join(tmpdir(), "mole-launcher-test-"));
  try {
    const calls: any[] = [];
    const result: DetectionResult = { label: "Node.js (npm)", runCommand: "npm run dev", shell: "powershell" };
    const { logPath } = launchProject(result, "/Users/wen/projects/my-app", {
      tmpDir: () => dir,
      spawn: (command, args, options) => {
        calls.push({ command, args, options });
        return fakeChild();
      },
    });

    assert.equal(logPath, join(dir, "mole-launch-latest.log"));
    assert.equal(calls.length, 1);
    assert.equal(calls[0].command, "powershell.exe");
    assert.deepEqual(calls[0].args, ["-NoProfile", "-Command", "npm run dev"]);
    assert.equal(calls[0].options.detached, true);
    assert.equal(calls[0].options.cwd, "/Users/wen/projects/my-app");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("launchProject uses a plain (non-login) bash -c for a bash DetectionResult", () => {
  const dir = mkdtempSync(join(tmpdir(), "mole-launcher-test-"));
  try {
    const calls: any[] = [];
    const result: DetectionResult = { label: "Go", runCommand: "go run .", shell: "bash" };
    launchProject(result, "/Users/wen/projects/go-app", {
      tmpDir: () => dir,
      spawn: (command, args, options) => {
        calls.push({ command, args, options });
        return fakeChild();
      },
    });
    assert.equal(calls[0].command, "bash");
    assert.deepEqual(calls[0].args, ["-c", "go run ."]);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("launchProject spawns with cwd set to the project directory (detect.ts writes every runCommand relative to it)", () => {
  const dir = mkdtempSync(join(tmpdir(), "mole-launcher-test-"));
  try {
    const calls: any[] = [];
    // A monorepo subfolder command like this only makes sense if the shell
    // starts out standing in the *parent* directory that was detected —
    // exactly what `cwd` needs to supply.
    launchProject(
      { label: "Node.js 子專案 (desktop, pnpm)", runCommand: "Set-Location 'desktop'; pnpm run dev", shell: "powershell" },
      "/Users/wen/projects/my-monorepo",
      { tmpDir: () => dir, spawn: (command, args, options) => (calls.push({ command, args, options }), fakeChild()) },
    );
    assert.equal(calls[0].options.cwd, "/Users/wen/projects/my-monorepo");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("launchProject prepends the common bin dirs to PATH for a bash DetectionResult, rather than sourcing a login shell profile", () => {
  const dir = mkdtempSync(join(tmpdir(), "mole-launcher-test-"));
  try {
    const calls: any[] = [];
    launchProject(
      { label: "Go", runCommand: "go run .", shell: "bash" },
      "/Users/wen/projects/go-app",
      {
        tmpDir: () => dir,
        spawn: (command, args, options) => {
          calls.push({ command, args, options });
          return fakeChild();
        },
      },
    );
    assert.match(calls[0].options.env.PATH, /\/opt\/homebrew\/bin/);
    assert.match(calls[0].options.env.PATH, /\.nvm\/current\/bin/);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("launchProject leaves the environment untouched for a powershell DetectionResult", () => {
  const dir = mkdtempSync(join(tmpdir(), "mole-launcher-test-"));
  try {
    const calls: any[] = [];
    launchProject(
      { label: "Node.js (npm)", runCommand: "npm run dev", shell: "powershell" },
      "/Users/wen/projects/my-app",
      {
        tmpDir: () => dir,
        spawn: (command, args, options) => {
          calls.push({ command, args, options });
          return fakeChild();
        },
      },
    );
    assert.equal(calls[0].options.env, undefined);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("posixPathWithCommonBinDirs prepends the fixed list ported from smart-launch.sh's own PATH fix-up", () => {
  const result = posixPathWithCommonBinDirs("/usr/bin:/bin", "/Users/wen");
  assert.equal(
    result,
    "/Users/wen/.local/bin:/opt/homebrew/bin:/usr/local/bin:/Users/wen/.nvm/current/bin:/usr/bin:/bin",
  );
});

test("posixPathWithCommonBinDirs still returns the prepend list when the current PATH is undefined", () => {
  const result = posixPathWithCommonBinDirs(undefined, "/Users/wen");
  assert.equal(result, "/Users/wen/.local/bin:/opt/homebrew/bin:/usr/local/bin:/Users/wen/.nvm/current/bin");
});

test("launchProject unrefs the child so it doesn't keep the app process alive", () => {
  const dir = mkdtempSync(join(tmpdir(), "mole-launcher-test-"));
  try {
    let unrefCalled = false;
    const child = fakeChild();
    child.unref = () => {
      unrefCalled = true;
    };
    launchProject(
      { label: "Go", runCommand: "go run .", shell: "bash" },
      "/Users/wen/projects/go-app",
      { tmpDir: () => dir, spawn: () => child },
    );
    assert.equal(unrefCalled, true);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("lastNonEmptyLine returns the last non-blank line, trimmed", () => {
  assert.equal(lastNonEmptyLine("first\nsecond\n\n   \n"), "second");
  assert.equal(lastNonEmptyLine(""), "");
  assert.equal(lastNonEmptyLine("\r\nonly\r\n"), "only");
});

test("lastNonEmptyLine truncates to the trailing N characters, matching the mac app's 70-char suffix", () => {
  const long = "x".repeat(100);
  const result = lastNonEmptyLine(long, 70);
  assert.equal(result.length, 70);
  assert.equal(result, long.slice(-70));
});

test("readLastLogLine returns '' when the log file doesn't exist yet", () => {
  assert.equal(readLastLogLine(join(tmpdir(), "definitely-does-not-exist-mole.log")), "");
});
