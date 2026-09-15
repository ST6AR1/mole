import { test } from "node:test";
import assert from "node:assert/strict";
import { parseNetstatWindows, parseLsof, listListeningPorts } from "../src/ports.ts";

// Captured shape of `netstat -ano -p TCP` output on a real Windows box.
const NETSTAT_SAMPLE = `
Active Connections

  Proto  Local Address          Foreign Address        State           PID
  TCP    0.0.0.0:135            0.0.0.0:0              LISTENING       912
  TCP    0.0.0.0:5173           0.0.0.0:0              LISTENING       14832
  TCP    127.0.0.1:5432         0.0.0.0:0              LISTENING       6120
  TCP    192.168.1.5:49832      52.96.0.1:443          ESTABLISHED     4200
  TCP    [::]:8000              [::]:0                 LISTENING       14832
  TCP    [::1]:5000             [::]:0                 LISTENING       9981
`;

test("parseNetstatWindows only keeps LISTENING rows and reads the trailing pid", () => {
  const result = parseNetstatWindows(NETSTAT_SAMPLE);
  assert.deepEqual(result, [
    { port: 135, pid: 912 },
    { port: 5173, pid: 14832 },
    { port: 5432, pid: 6120 },
    { port: 8000, pid: 14832 },
    { port: 5000, pid: 9981 },
  ]);
});

test("parseNetstatWindows ignores non-LISTENING and malformed lines", () => {
  const result = parseNetstatWindows("garbage\n  TCP garbage line\nActive Connections\n");
  assert.deepEqual(result, []);
});

// Captured shape of `lsof -nP -iTCP -sTCP:LISTEN` output on macOS.
const LSOF_SAMPLE = `COMMAND   PID   USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
node    14832    wen   23u  IPv4 0x1234567890abcdef      0t0  TCP *:5173 (LISTEN)
Python   6120    wen    4u  IPv4 0xabcdef1234567890      0t0  TCP 127.0.0.1:5432 (LISTEN)
`;

test("parseLsof reads pid and port from the NAME column", () => {
  const result = parseLsof(LSOF_SAMPLE);
  assert.deepEqual(result, [
    { port: 5173, pid: 14832 },
    { port: 5432, pid: 6120 },
  ]);
});

test("listListeningPorts dispatches to netstat on win32 and lsof elsewhere", () => {
  const calls: Array<{ cmd: string; args: string[] }> = [];
  const fakeExec = (cmd: string, args: string[]) => {
    calls.push({ cmd, args });
    return cmd === "netstat.exe" ? NETSTAT_SAMPLE : LSOF_SAMPLE;
  };

  const win = listListeningPorts("win32", fakeExec);
  assert.equal(calls[0].cmd, "netstat.exe");
  assert.ok(win.some((p) => p.port === 5173));

  const mac = listListeningPorts("darwin", fakeExec);
  assert.equal(calls[1].cmd, "lsof");
  assert.ok(mac.some((p) => p.port === 5432));
});

test("listListeningPorts returns an empty list rather than throwing when the command fails", () => {
  const throwingExec = () => {
    throw new Error("command not found");
  };
  assert.deepEqual(listListeningPorts("win32", throwingExec), []);
  assert.deepEqual(listListeningPorts("darwin", throwingExec), []);
});
