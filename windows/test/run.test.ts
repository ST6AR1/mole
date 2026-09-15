import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runProject, type LaunchStage } from "../src/run.ts";
import type { PortInfo } from "../src/types.ts";

function port(overrides: Partial<PortInfo>): PortInfo {
  return { port: 3000, pid: 1, processName: "node", isDev: true, uptimeSeconds: 0, ...overrides };
}

function makeNodeProject(): string {
  const dir = mkdtempSync(join(tmpdir(), "mole-run-test-"));
  writeFileSync(join(dir, "package.json"), JSON.stringify({ scripts: { dev: "vite" } }));
  return dir;
}

test("returns unrecognized without launching anything for an empty folder", async () => {
  const dir = mkdtempSync(join(tmpdir(), "mole-run-test-"));
  try {
    const stages: LaunchStage[] = [];
    let launched = false;
    const result = await runProject(dir, (s) => stages.push(s), {
      platform: "win32",
      fetchDevPorts: () => [],
      sleep: () => Promise.resolve(),
      launchDeps: { tmpDir: () => dir, spawn: () => (launched = true) as any },
    });
    assert.deepEqual(result, { ok: false, reason: "unrecognized" });
    assert.deepEqual(stages, [{ stage: "detecting" }, { stage: "unrecognized" }]);
    assert.equal(launched, false);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("detects, launches, and resolves once a new dev port shows up", async () => {
  const projectDir = makeNodeProject();
  const logDir = mkdtempSync(join(tmpdir(), "mole-run-log-"));
  try {
    const stages: LaunchStage[] = [];
    let spawnCalls = 0;
    let fetchCalls = 0;
    const onPortReady: number[] = [];

    const result = await runProject(projectDir, (s) => stages.push(s), {
      platform: "win32",
      fetchDevPorts: () => {
        fetchCalls++;
        // First call ("preparing" snapshot) sees nothing; later polls see the new port.
        return fetchCalls === 1 ? [] : [port({ port: 5173 })];
      },
      sleep: () => Promise.resolve(),
      launchDeps: {
        tmpDir: () => logDir,
        spawn: (() => {
          spawnCalls++;
          return { unref: () => {} };
        }) as any,
      },
      onPortReady: (p) => onPortReady.push(p),
    });

    assert.deepEqual(result, {
      ok: true,
      result: { label: "Node.js (npm)", installCommand: "npm install", runCommand: "npm run dev", shell: "powershell" },
      port: 5173,
    });
    assert.equal(spawnCalls, 1);
    assert.deepEqual(onPortReady, [5173]);
    assert.deepEqual(
      stages.map((s) => s.stage),
      ["detecting", "preparing", "starting-server", "waiting-localhost", "waiting-localhost", "ready"],
    );
    assert.equal(stages.at(-1), stages.at(-1)); // ready stage carries the port
    assert.equal((stages.at(-1) as any).port, 5173);
  } finally {
    rmSync(projectDir, { recursive: true, force: true });
    rmSync(logDir, { recursive: true, force: true });
  }
});

test("skips waiting entirely for a non-web launch like Flutter", async () => {
  const dir = mkdtempSync(join(tmpdir(), "mole-run-flutter-"));
  const logDir = mkdtempSync(join(tmpdir(), "mole-run-log-"));
  try {
    writeFileSync(join(dir, "pubspec.yaml"), "name: demo\n");
    const stages: LaunchStage[] = [];
    let fetchCalls = 0;

    const result = await runProject(dir, (s) => stages.push(s), {
      platform: "win32",
      fetchDevPorts: () => {
        fetchCalls++;
        return [];
      },
      sleep: () => Promise.resolve(),
      launchDeps: { tmpDir: () => logDir, spawn: (() => ({ unref: () => {} })) as any },
    });

    assert.equal(result.ok, true);
    assert.equal((result as any).port, null);
    assert.deepEqual(
      stages.map((s) => s.stage),
      ["detecting", "preparing", "starting-server", "opened-non-web"],
    );
    // Only the "preparing" snapshot call — never enters the polling loop.
    assert.equal(fetchCalls, 1);
  } finally {
    rmSync(dir, { recursive: true, force: true });
    rmSync(logDir, { recursive: true, force: true });
  }
});

test("reports no-port-found after exhausting maxAttempts", async () => {
  const projectDir = makeNodeProject();
  const logDir = mkdtempSync(join(tmpdir(), "mole-run-log-"));
  try {
    const stages: LaunchStage[] = [];
    const result = await runProject(projectDir, (s) => stages.push(s), {
      platform: "win32",
      fetchDevPorts: () => [],
      sleep: () => Promise.resolve(),
      maxAttempts: 2,
      launchDeps: { tmpDir: () => logDir, spawn: (() => ({ unref: () => {} })) as any },
    });
    assert.equal(result.ok, false);
    assert.equal((result as any).reason, "no-port-found");
    assert.equal(stages.at(-1)?.stage, "no-port-found");
  } finally {
    rmSync(projectDir, { recursive: true, force: true });
    rmSync(logDir, { recursive: true, force: true });
  }
});
