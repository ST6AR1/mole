import { test } from "node:test";
import assert from "node:assert/strict";
import { uptimeFromEtime, getProcessInfoPosix } from "../src/posixProcessInfo.ts";

test("uptimeFromEtime parses mm:ss", () => {
  assert.equal(uptimeFromEtime("05:12"), 5 * 60 + 12);
});

test("uptimeFromEtime parses hh:mm:ss", () => {
  assert.equal(uptimeFromEtime("01:02:03"), 1 * 3600 + 2 * 60 + 3);
});

test("uptimeFromEtime parses dd-hh:mm:ss", () => {
  assert.equal(uptimeFromEtime("3-04:05:06"), (3 * 24 + 4) * 3600 + 5 * 60 + 6);
});

test("uptimeFromEtime parses bare seconds", () => {
  assert.equal(uptimeFromEtime("42"), 42);
});

test("uptimeFromEtime returns 0 for empty input", () => {
  assert.equal(uptimeFromEtime(""), 0);
  assert.equal(uptimeFromEtime("   "), 0);
});

test("getProcessInfoPosix parses ps -o pid=,etime=,comm= output and takes the exe basename", () => {
  const raw = "14832   05:12 /usr/local/bin/node\n 6120 1-02:00:00 /usr/bin/python3\n";
  const fakeExec = (cmd: string, args: string[]) => {
    assert.equal(cmd, "/bin/ps");
    assert.deepEqual(args, ["-o", "pid=,etime=,comm=", "-p", "14832,6120"]);
    return raw;
  };
  const result = getProcessInfoPosix([14832, 6120], fakeExec);
  assert.deepEqual(result.get(14832), { pid: 14832, name: "node", uptimeSeconds: 312 });
  assert.deepEqual(result.get(6120), { pid: 6120, name: "python3", uptimeSeconds: 26 * 3600 });
});

test("getProcessInfoPosix returns an empty map without shelling out when there are no pids", () => {
  const fakeExec = () => {
    throw new Error("should not be called");
  };
  assert.deepEqual(getProcessInfoPosix([], fakeExec), new Map());
});

test("getProcessInfoPosix returns an empty map rather than throwing when ps fails", () => {
  assert.deepEqual(
    getProcessInfoPosix([1], () => {
      throw new Error("no such pid");
    }),
    new Map(),
  );
});
