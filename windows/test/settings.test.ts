import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { loadSettings, saveSettings, togglePersistentPort, isPersistentPort, DEFAULT_SETTINGS } from "../src/settings.ts";

test("loadSettings returns the default (2h expire, no pins) when the file doesn't exist yet", () => {
  const dir = mkdtempSync(join(tmpdir(), "mole-settings-test-"));
  try {
    assert.deepEqual(loadSettings(join(dir, "settings.json")), DEFAULT_SETTINGS);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("saveSettings then loadSettings round-trips, creating parent directories as needed", () => {
  const dir = mkdtempSync(join(tmpdir(), "mole-settings-test-"));
  try {
    const filePath = join(dir, "nested", "settings.json");
    saveSettings(filePath, { expireMinutes: 30, persistentPorts: ["3000", "4000"] });
    assert.deepEqual(loadSettings(filePath), { expireMinutes: 30, persistentPorts: ["3000", "4000"] });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("loadSettings falls back to defaults on a corrupt file rather than throwing", () => {
  const dir = mkdtempSync(join(tmpdir(), "mole-settings-test-"));
  try {
    const filePath = join(dir, "settings.json");
    saveSettings(filePath, DEFAULT_SETTINGS); // ensures the dir exists
    writeFileSync(filePath, "not json");
    assert.deepEqual(loadSettings(filePath), DEFAULT_SETTINGS);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("togglePersistentPort adds an unpinned port and removes an already-pinned one", () => {
  const pinned = togglePersistentPort({ expireMinutes: 120, persistentPorts: [] }, 3000);
  assert.deepEqual(pinned.persistentPorts, ["3000"]);
  const unpinned = togglePersistentPort(pinned, 3000);
  assert.deepEqual(unpinned.persistentPorts, []);
});

test("isPersistentPort checks membership by string port", () => {
  const settings = { expireMinutes: 120, persistentPorts: ["3000"] };
  assert.equal(isPersistentPort(settings, 3000), true);
  assert.equal(isPersistentPort(settings, 4000), false);
});
