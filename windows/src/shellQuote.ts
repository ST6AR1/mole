import type { Shell } from "./types.ts";

/**
 * Quote a path/argument for safe interpolation into a command string for
 * the given shell. Mirrors what smart-launch.sh does with `printf '%q'` for
 * bash, but for PowerShell (Windows) too.
 */
export function quoteForShell(value: string, shell: Shell): string {
  if (shell === "powershell") {
    // Single-quoted PowerShell strings are literal; only ' itself needs escaping (as '').
    return `'${value.replace(/'/g, "''")}'`;
  }
  // POSIX/bash: wrap in single quotes, escape any embedded single quote as '\''.
  return `'${value.replace(/'/g, "'\\''")}'`;
}
