import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { EventEmitter } from "node:events";
import { launchProject, launchLogPath, lastNonEmptyLine, readLastLogLine } from "../src/launcher.ts";
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
    const { logPath } = launchProject(result, {
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
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("launchProject uses bash -lc for a bash DetectionResult", () => {
  const dir = mkdtempSync(join(tmpdir(), "mole-launcher-test-"));
  try {
    const calls: any[] = [];
    const result: DetectionResult = { label: "Go", runCommand: "go run .", shell: "bash" };
    launchProject(result, {
      tmpDir: () => dir,
      spawn: (command, args, options) => {
        calls.push({ command, args, options });
        return fakeChild();
      },
    });
    assert.equal(calls[0].command, "bash");
    assert.deepEqual(calls[0].args, ["-lc", "go run ."]);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
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
