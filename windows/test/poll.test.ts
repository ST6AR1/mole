import { test } from "node:test";
import assert from "node:assert/strict";
import { waitForNewPort, isLikelyNonWebLaunch } from "../src/poll.ts";
import type { PortInfo } from "../src/types.ts";

function port(overrides: Partial<PortInfo>): PortInfo {
  return { port: 3000, pid: 1, processName: "node", isDev: true, uptimeSeconds: 0, ...overrides };
}

const noopSleep = () => Promise.resolve();

test("isLikelyNonWebLaunch flags Flutter and Chrome-extension launches", () => {
  assert.equal(isLikelyNonWebLaunch({ label: "Flutter" }), true);
  assert.equal(isLikelyNonWebLaunch({ label: "Chrome 擴充功能" }), true);
});

test("isLikelyNonWebLaunch is false for anything that actually opens a port", () => {
  assert.equal(isLikelyNonWebLaunch({ label: "Node.js (npm)" }), false);
  assert.equal(isLikelyNonWebLaunch({ label: "Django" }), false);
});

test("waitForNewPort resolves as soon as a port outside `before` shows up", async () => {
  let call = 0;
  const ticks: number[] = [];
  const result = await waitForNewPort(
    new Set([3000]),
    { maxAttempts: 5, onTick: (elapsed) => ticks.push(elapsed) },
    {
      sleep: noopSleep,
      fetchDevPorts: () => {
        call++;
        if (call < 3) return [port({ port: 3000 })];
        return [port({ port: 3000 }), port({ port: 4000, pid: 2 })];
      },
    },
  );
  assert.equal(result?.port, 4000);
  assert.deepEqual(ticks, [1, 2, 3]);
});

test("waitForNewPort ignores ports that aren't isDev", () => {
  return waitForNewPort(
    new Set(),
    { maxAttempts: 2 },
    { sleep: noopSleep, fetchDevPorts: () => [port({ port: 445, isDev: false })] },
  ).then((result) => assert.equal(result, null));
});

test("waitForNewPort gives up and returns null after maxAttempts", async () => {
  let calls = 0;
  const result = await waitForNewPort(
    new Set([3000]),
    { maxAttempts: 3 },
    {
      sleep: noopSleep,
      fetchDevPorts: () => {
        calls++;
        return [port({ port: 3000 })];
      },
    },
  );
  assert.equal(result, null);
  assert.equal(calls, 3);
});

test("waitForNewPort sleeps before each check, matching pollForNewServer's sleep-then-check order", async () => {
  const order: string[] = [];
  await waitForNewPort(
    new Set(),
    { maxAttempts: 1 },
    {
      sleep: () => {
        order.push("sleep");
        return Promise.resolve();
      },
      fetchDevPorts: () => {
        order.push("check");
        return [];
      },
    },
  );
  assert.deepEqual(order, ["sleep", "check"]);
});
