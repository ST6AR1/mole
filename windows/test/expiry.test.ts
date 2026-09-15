import { test } from "node:test";
import assert from "node:assert/strict";
import { findExpiredPorts } from "../src/expiry.ts";
import type { PortInfo } from "../src/types.ts";

function port(overrides: Partial<PortInfo>): PortInfo {
  return { port: 3000, pid: 1, processName: "node", isDev: true, uptimeSeconds: 0, ...overrides };
}

test("expireMinutes <= 0 means auto-close is off, even for very old ports", () => {
  const ports = [port({ uptimeSeconds: 999_999 })];
  assert.deepEqual(findExpiredPorts(ports, 0, () => false), []);
  assert.deepEqual(findExpiredPorts(ports, -5, () => false), []);
});

test("flags ports at or past the limit, not ones still under it", () => {
  const ports = [
    port({ port: 3000, uptimeSeconds: 30 * 60 - 1 }),
    port({ port: 4000, uptimeSeconds: 30 * 60 }),
    port({ port: 5000, uptimeSeconds: 30 * 60 + 1 }),
  ];
  const expired = findExpiredPorts(ports, 30, () => false).map((p) => p.port);
  assert.deepEqual(expired, [4000, 5000]);
});

test("pinned (persistent) ports never expire regardless of uptime", () => {
  const ports = [port({ port: 3000, uptimeSeconds: 10_000 })];
  assert.deepEqual(findExpiredPorts(ports, 30, (p) => p === 3000), []);
});

test("non-dev ports are never candidates for auto-close", () => {
  const ports = [port({ port: 445, isDev: false, uptimeSeconds: 10_000 })];
  assert.deepEqual(findExpiredPorts(ports, 30, () => false), []);
});
