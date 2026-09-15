import { test } from "node:test";
import assert from "node:assert/strict";
import { isDevProcessName } from "../src/devPatterns.ts";

test("recognizes Windows image names by stripping .exe and lowercasing", () => {
  assert.equal(isDevProcessName("node.exe"), true);
  assert.equal(isDevProcessName("Python.exe"), true);
  assert.equal(isDevProcessName("DOTNET.EXE"), true);
});

test("recognizes bare macOS/Linux process names too", () => {
  assert.equal(isDevProcessName("node"), true);
  assert.equal(isDevProcessName("ruby"), true);
});

test("rejects names not in the dev-server allowlist", () => {
  assert.equal(isDevProcessName("svchost.exe"), false);
  assert.equal(isDevProcessName("Explorer.EXE"), false);
  assert.equal(isDevProcessName(""), false);
});
