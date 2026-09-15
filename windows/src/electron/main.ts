// Electron main process — phase 3. Wires the window + IPC surface on top
// of the pure logic already built and tested in phase 1/2 (../detect.ts,
// ../run.ts, ../devPorts.ts, ../stop.ts, ../expiry.ts, ../settings.ts).
// This file itself has almost no logic of its own on purpose: every
// decision (what a folder is, when to stop it, when it's expired) already
// lives in a unit-tested module, so main.ts is just plumbing between those
// modules, the OS, and the renderer.
//
// Runs on whatever `process.platform` actually is rather than hardcoding
// "win32" — the target is Windows, but every module here already branches
// on platform, so running this on macOS during development exercises the
// exact same code paths (darwin lsof/ps instead of netstat/Get-Process),
// which is how this got smoke-tested without a Windows machine.

import { app, BrowserWindow, ipcMain, dialog, shell, type IpcMainInvokeEvent } from "electron";
import { join } from "node:path";
import { detectProject } from "../detect.ts";
import { runProject, type LaunchStage } from "../run.ts";
import { fetchDevPorts } from "../devPorts.ts";
import { stopPort, killAllDevPorts } from "../stop.ts";
import { findExpiredPorts } from "../expiry.ts";
import {
  loadSettings,
  saveSettings,
  togglePersistentPort,
  isPersistentPort,
  type Settings,
} from "../settings.ts";
import type { PortInfo, SupportedPlatform } from "../types.ts";

const platform = process.platform as SupportedPlatform;
const REFRESH_INTERVAL_MS = 8000; // matches refreshTimer in ../../App/main.swift

let mainWindow: BrowserWindow | null = null;
let settings: Settings;
let refreshTimer: ReturnType<typeof setInterval> | null = null;

function settingsPath(): string {
  return join(app.getPath("userData"), "settings.json");
}

function isPersistent(port: number): boolean {
  return isPersistentPort(settings, port);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function sendToRenderer(channel: string, ...args: unknown[]): void {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send(channel, ...args);
  }
}

/** One refresh tick: fetch ports, auto-close anything overdue, push the result to the renderer. */
function refreshPorts(): void {
  const ports = fetchDevPorts(platform);
  const expired = findExpiredPorts(ports, settings.expireMinutes, isPersistent);
  for (const info of expired) {
    stopPort(info.pid);
  }
  sendToRenderer("ports:update", ports, expired.map((p) => p.port));
}

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 620,
    height: 720,
    minWidth: 560,
    minHeight: 620,
    frame: false, // custom titlebar drawn in the renderer, matching the mac app's branded toolbar
    backgroundColor: "#f7f5f0", // --bg from site/src/styles/tokens.css, avoids a white flash on load
    webPreferences: {
      preload: join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  mainWindow.loadFile(join(__dirname, "renderer", "index.html"));
  mainWindow.on("closed", () => {
    mainWindow = null;
  });

  mainWindow.webContents.on("did-finish-load", () => {
    refreshPorts();
  });
}

function registerIpcHandlers(): void {
  ipcMain.handle("dialog:choose-folder", async () => {
    if (!mainWindow) return null;
    const result = await dialog.showOpenDialog(mainWindow, { properties: ["openDirectory"] });
    if (result.canceled || result.filePaths.length === 0) return null;
    return result.filePaths[0];
  });

  ipcMain.handle("project:detect", (_event: IpcMainInvokeEvent, dirPath: string) => {
    return detectProject(dirPath, platform);
  });

  ipcMain.handle("project:launch", async (_event: IpcMainInvokeEvent, dirPath: string) => {
    const onStage = (stage: LaunchStage) => sendToRenderer("project:stage", stage);
    const result = await runProject(dirPath, onStage, {
      platform,
      fetchDevPorts: () => fetchDevPorts(platform),
      sleep,
      onPortReady: () => refreshPorts(),
    });
    refreshPorts();
    return result;
  });

  ipcMain.handle("ports:refresh", (): PortInfo[] => fetchDevPorts(platform));

  ipcMain.handle("ports:stop", (_event: IpcMainInvokeEvent, pid: number) => {
    stopPort(pid);
    setTimeout(refreshPorts, 600); // matches doKill()'s 0.6s-later refresh in main.swift
  });

  ipcMain.handle("ports:kill-all", () => {
    const ports = fetchDevPorts(platform);
    killAllDevPorts(ports, isPersistent);
    setTimeout(refreshPorts, 600);
  });

  ipcMain.handle("ports:toggle-pin", (_event: IpcMainInvokeEvent, port: number) => {
    settings = togglePersistentPort(settings, port);
    saveSettings(settingsPath(), settings);
    refreshPorts();
    return settings;
  });

  ipcMain.handle("settings:get", (): Settings => settings);

  ipcMain.handle("settings:set-expire-minutes", (_event: IpcMainInvokeEvent, minutes: number) => {
    settings = { ...settings, expireMinutes: minutes };
    saveSettings(settingsPath(), settings);
    return settings;
  });

  ipcMain.handle("shell:open-external", (_event: IpcMainInvokeEvent, url: string) => {
    return shell.openExternal(url);
  });

  ipcMain.on("window:minimize", () => mainWindow?.minimize());
  ipcMain.on("window:toggle-maximize", () => {
    if (!mainWindow) return;
    if (mainWindow.isMaximized()) mainWindow.unmaximize();
    else mainWindow.maximize();
  });
  ipcMain.on("window:close", () => mainWindow?.close());
}

app.whenReady().then(() => {
  settings = loadSettings(settingsPath());
  registerIpcHandlers();
  createWindow();
  refreshTimer = setInterval(refreshPorts, REFRESH_INTERVAL_MS);

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on("window-all-closed", () => {
  if (refreshTimer) clearInterval(refreshTimer);
  if (process.platform !== "darwin") app.quit();
});
