// contextBridge surface exposed to the renderer. Kept deliberately thin —
// one function per IPC channel in main.ts, no logic of its own — so the
// renderer never gets direct Node/Electron access (contextIsolation +
// sandbox stay on).

import { contextBridge, ipcRenderer, webUtils, type IpcRendererEvent } from "electron";

const moleAPI = {
  chooseFolder: (): Promise<string | null> => ipcRenderer.invoke("dialog:choose-folder"),
  launchProject: (dirPath: string) => ipcRenderer.invoke("project:launch", dirPath),
  refreshPorts: () => ipcRenderer.invoke("ports:refresh"),
  stopPort: (pid: number) => ipcRenderer.invoke("ports:stop", pid),
  killAllPorts: () => ipcRenderer.invoke("ports:kill-all"),
  togglePin: (port: number) => ipcRenderer.invoke("ports:toggle-pin", port),
  getSettings: () => ipcRenderer.invoke("settings:get"),
  setExpireMinutes: (minutes: number) => ipcRenderer.invoke("settings:set-expire-minutes", minutes),
  openExternal: (url: string) => ipcRenderer.invoke("shell:open-external", url),

  /** Renderer-side drag-and-drop hands over a browser File; this is the only way to get its real path back (contextIsolation blocks the old `file.path`). */
  getPathForFile: (file: File): string => webUtils.getPathForFile(file),

  onStage: (callback: (stage: unknown) => void) => {
    const listener = (_event: IpcRendererEvent, stage: unknown) => callback(stage);
    ipcRenderer.on("project:stage", listener);
    return () => ipcRenderer.removeListener("project:stage", listener);
  },
  onPortsUpdate: (callback: (ports: unknown[], expiredPorts: number[]) => void) => {
    const listener = (_event: IpcRendererEvent, ports: unknown[], expiredPorts: number[]) =>
      callback(ports, expiredPorts);
    ipcRenderer.on("ports:update", listener);
    return () => ipcRenderer.removeListener("ports:update", listener);
  },

  minimizeWindow: () => ipcRenderer.send("window:minimize"),
  toggleMaximizeWindow: () => ipcRenderer.send("window:toggle-maximize"),
  closeWindow: () => ipcRenderer.send("window:close"),
};

contextBridge.exposeInMainWorld("mole", moleAPI);

export type MoleAPI = typeof moleAPI;
