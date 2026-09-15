// Port of the two UserDefaults-backed properties in ../App/main.swift
// (`expireMinutes`, `persistentPortsRaw`) to a small JSON file, since
// Electron has no UserDefaults equivalent built in. Same defaults, same
// shape (a comma-joined string in Swift; an array here, since JSON has no
// reason to reproduce that particular encoding trick).

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";

export interface Settings {
  /** Minutes of idle uptime before a dev port auto-closes. 0 = never (matches "expire.never"). */
  expireMinutes: number;
  /** Ports pinned as "keep alive" — never auto-closed, shown with the pin badge. */
  persistentPorts: string[];
}

/** Matches `expireMinutes`'s fallback in main.swift: unset means 2 hours, not "never". */
export const DEFAULT_SETTINGS: Settings = { expireMinutes: 120, persistentPorts: [] };

export function loadSettings(filePath: string): Settings {
  try {
    const raw = JSON.parse(readFileSync(filePath, "utf8"));
    return {
      expireMinutes: typeof raw.expireMinutes === "number" ? raw.expireMinutes : DEFAULT_SETTINGS.expireMinutes,
      persistentPorts: Array.isArray(raw.persistentPorts) ? raw.persistentPorts.map(String) : [],
    };
  } catch {
    return { ...DEFAULT_SETTINGS };
  }
}

export function saveSettings(filePath: string, settings: Settings): void {
  mkdirSync(dirname(filePath), { recursive: true });
  writeFileSync(filePath, JSON.stringify(settings, null, 2), "utf8");
}

/** Mirrors togglePersistent(): add the port if absent, remove it if present. */
export function togglePersistentPort(settings: Settings, port: number): Settings {
  const key = String(port);
  const set = new Set(settings.persistentPorts);
  if (set.has(key)) set.delete(key);
  else set.add(key);
  return { ...settings, persistentPorts: [...set].sort() };
}

export function isPersistentPort(settings: Settings, port: number): boolean {
  return settings.persistentPorts.includes(String(port));
}
