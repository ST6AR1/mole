import { test } from "node:test";
import assert from "node:assert/strict";
import { getProcessInfoWindows, parseProcessInfoJson } from "../src/processInfo.ts";

test("parseProcessInfoJson normalizes the single-object shape ConvertTo-Json emits for one result", () => {
  const raw = `{"Id":14832,"ProcessName":"node","UptimeSeconds":42}`;
  assert.deepEqual(parseProcessInfoJson(raw), [{ pid: 14832, name: "node", uptimeSeconds: 42 }]);
});

test("parseProcessInfoJson handles the array shape for multiple results", () => {
  const raw = `[{"Id":14832,"ProcessName":"node","UptimeSeconds":42},{"Id":6120,"ProcessName":"python","UptimeSeconds":3600}]`;
  assert.deepEqual(parseProcessInfoJson(raw), [
    { pid: 14832, name: "node", uptimeSeconds: 42 },
    { pid: 6120, name: "python", uptimeSeconds: 3600 },
  ]);
});

test("parseProcessInfoJson returns [] for empty output (no pids matched)", () => {
  assert.deepEqual(parseProcessInfoJson(""), []);
  assert.deepEqual(parseProcessInfoJson("   \n  "), []);
});

test("parseProcessInfoJson returns [] rather than throwing on garbage input", () => {
  assert.deepEqual(parseProcessInfoJson("not json at all"), []);
});

test("parseProcessInfoJson drops entries missing a usable pid or name", () => {
  const raw = `[{"Id":14832,"ProcessName":"node","UptimeSeconds":42},{"Id":null,"ProcessName":"orphan","UptimeSeconds":1},{"Id":99,"ProcessName":"","UptimeSeconds":1}]`;
  assert.deepEqual(parseProcessInfoJson(raw), [{ pid: 14832, name: "node", uptimeSeconds: 42 }]);
});

test("getProcessInfoWindows builds a Get-Process call for the given pids and returns a pid-keyed map", () => {
  let capturedScript = "";
  const fakeExec = (cmd: string, args: string[]) => {
    assert.equal(cmd, "powershell.exe");
    capturedScript = args[args.length - 1];
    return `[{"Id":14832,"ProcessName":"node","UptimeSeconds":42},{"Id":6120,"ProcessName":"python","UptimeSeconds":10}]`;
  };

  const result = getProcessInfoWindows([14832, 6120], fakeExec);
  assert.match(capturedScript, /Get-Process -Id 14832,6120/);
  assert.equal(result.get(14832)?.name, "node");
  assert.equal(result.get(6120)?.uptimeSeconds, 10);
});

test("getProcessInfoWindows de-duplicates and ignores non-positive/non-integer pids", () => {
  let capturedScript = "";
  const fakeExec = (_cmd: string, args: string[]) => {
    capturedScript = args[args.length - 1];
    return "[]";
  };
  getProcessInfoWindows([14832, 14832, -1, 0, 1.5], fakeExec);
  assert.match(capturedScript, /Get-Process -Id 14832/);
  assert.doesNotMatch(capturedScript, /-1|1\.5/);
});

test("getProcessInfoWindows returns an empty map without shelling out when there are no pids", () => {
  const fakeExec = () => {
    throw new Error("should not be called");
  };
  assert.deepEqual(getProcessInfoWindows([], fakeExec), new Map());
});

test("getProcessInfoWindows returns an empty map rather than throwing when PowerShell fails", () => {
  const throwingExec = () => {
    throw new Error("powershell not found");
  };
  assert.deepEqual(getProcessInfoWindows([1234], throwingExec), new Map());
});
