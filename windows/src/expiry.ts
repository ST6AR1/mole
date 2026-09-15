// Pure port of checkExpiry() in ../App/main.swift: which dev ports have
// been running long enough to auto-close. Kept separate from stop.ts so
// this decision — "which ports are overdue" — can be unit tested without
// touching a real process, the same way detect.ts's rules are tested
// without a real project on disk.

import type { PortInfo } from "./types.ts";

/**
 * Returns the dev ports that have exceeded `expireMinutes` of uptime and
 * aren't pinned. `expireMinutes <= 0` means auto-close is off (matches the
 * mac app's `ExpireOption(label: t("expire.never"), minutes: 0)`).
 */
export function findExpiredPorts(
  ports: PortInfo[],
  expireMinutes: number,
  isPersistent: (port: number) => boolean,
): PortInfo[] {
  if (expireMinutes <= 0) return [];
  const limitSeconds = expireMinutes * 60;
  return ports.filter((p) => p.isDev && !isPersistent(p.port) && p.uptimeSeconds >= limitSeconds);
}
