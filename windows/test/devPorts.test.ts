import { test } from "node:test";
import assert from "node:assert/strict";
import { fetchDevPorts, fetchDevPortsWindows } from "../src/devPorts.ts";

const NETSTAT_SAMPLE = `
  TCP    0.0.0.0:5173           0.0.0.0:0              LISTENING       14832
  TCP    0.0.0.0:445            0.0.0.0:0              LISTENING       4
`;

test("joins netstat's port/pid with process name+uptime and tags isDev", () => {
  const fakeExec = (cmd: string) => {
    if (cmd === "netstat.exe") return NETSTAT_SAMPLE;
    // The second call is the batched Get-Process lookup.
    return `[{"Id":14832,"ProcessName":"node","UptimeSeconds":90},{"Id":4,"ProcessName":"System","UptimeSeconds":500000}]`;
  };

  const result = fetchDevPortsWindows({ execRaw: fakeExec });

  assert.deepEqual(result, [
    { port: 445, pid: 4, processName: "System", isDev: false, uptimeSeconds: 500000 },
    { port: 5173, pid: 14832, processName: "node", isDev: true, uptimeSeconds: 90 },
  ]);
});

test("sorts by port ascending regardless of netstat's own ordering", () => {
  const fakeExec = (cmd: string) => {
    if (cmd === "netstat.exe") {
      return `
  TCP    0.0.0.0:9000  0.0.0.0:0  LISTENING  100
  TCP    0.0.0.0:3000  0.0.0.0:0  LISTENING  200
`;
    }
    return `[{"Id":100,"ProcessName":"node","UptimeSeconds":1},{"Id":200,"ProcessName":"node","UptimeSeconds":1}]`;
  };

  const result = fetchDevPortsWindows({ execRaw: fakeExec });
  assert.deepEqual(result.map((p) => p.port), [3000, 9000]);
});

test("a port whose owning process already exited gets an empty name and isDev:false, not dropped", () => {
  const fakeExec = (cmd: string) => (cmd === "netstat.exe" ? NETSTAT_SAMPLE.split("\n")[1] : "[]");
  const result = fetchDevPortsWindows({ execRaw: fakeExec });
  assert.equal(result.length, 1);
  assert.equal(result[0].processName, "");
  assert.equal(result[0].isDev, false);
  assert.equal(result[0].uptimeSeconds, 0);
});

test("returns [] without calling Get-Process when nothing is listening", () => {
  let processInfoCalled = false;
  const fakeExec = (cmd: string) => {
    if (cmd === "netstat.exe") return "";
    processInfoCalled = true;
    return "[]";
  };
  assert.deepEqual(fetchDevPortsWindows({ execRaw: fakeExec }), []);
  assert.equal(processInfoCalled, false);
});

test("fetchDevPorts('darwin', ...) dispatches to lsof + ps instead of netstat + Get-Process", () => {
  const fakeExec = (cmd: string) => {
    if (cmd === "lsof") {
      return "COMMAND   PID   USER   FD   TYPE DEVICE SIZE/OFF NODE NAME\nnode    14832    wen   23u  IPv4 0x0      0t0  TCP *:5173 (LISTEN)\n";
    }
    if (cmd === "/bin/ps") return "14832 00:01:30 /usr/local/bin/node\n";
    throw new Error(`unexpected command ${cmd}`);
  };
  const result = fetchDevPorts("darwin", { execRaw: fakeExec });
  assert.deepEqual(result, [{ port: 5173, pid: 14832, processName: "node", isDev: true, uptimeSeconds: 90 }]);
});
