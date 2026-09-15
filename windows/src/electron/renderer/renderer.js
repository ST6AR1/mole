// Renderer-side glue: pure DOM + the `window.mole` API exposed by
// preload.ts. No build step — plain browser JS loaded as a classic
// <script>, since contextIsolation means this can't `require()` anything.
"use strict";

const DIG_FRAMES = [
  "assets/dig-anim-0.png",
  "assets/dig-anim-1.png",
  "assets/dig-anim-2.png",
  "assets/dig-anim-3.png",
  "assets/dig-anim-4.png",
  "assets/dig-anim-5.png",
];

let settings = { expireMinutes: 120, persistentPorts: [] };
let digFrameIndex = 0;
let digTimer = null;
let lastLaunchedName = "";

// --- titlebar ---

document.getElementById("btn-minimize").addEventListener("click", () => window.mole.minimizeWindow());
document.getElementById("btn-maximize").addEventListener("click", () => window.mole.toggleMaximizeWindow());
document.getElementById("btn-close").addEventListener("click", () => window.mole.closeWindow());

// --- friendly formatting (ported from main.swift's friendlyUptime/uptimeSeconds) ---

function friendlyUptime(totalSeconds) {
  const days = Math.floor(totalSeconds / 86400);
  const hours = Math.floor((totalSeconds % 86400) / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = Math.floor(totalSeconds % 60);
  if (days > 0) return `已運行 ${days} 天 ${hours} 小時`;
  if (hours > 0) return `已運行 ${hours} 小時 ${minutes} 分`;
  if (minutes > 0) return `已運行 ${minutes} 分鐘`;
  return `已運行 ${seconds} 秒`;
}

// --- drop zone / choose folder ---

const dropZone = document.getElementById("drop-zone");
const lastLaunchedEl = document.getElementById("last-launched");

document.getElementById("btn-choose-folder").addEventListener("click", async () => {
  const dir = await window.mole.chooseFolder();
  if (dir) launchProject(dir);
});

["dragenter", "dragover"].forEach((evt) =>
  dropZone.addEventListener(evt, (e) => {
    e.preventDefault();
    dropZone.classList.add("drag-over");
  }),
);
["dragleave", "drop"].forEach((evt) =>
  dropZone.addEventListener(evt, (e) => {
    e.preventDefault();
    dropZone.classList.remove("drag-over");
  }),
);
dropZone.addEventListener("drop", (e) => {
  const file = e.dataTransfer.files[0];
  if (!file) return;
  const dirPath = window.mole.getPathForFile(file);
  if (dirPath) launchProject(dirPath);
});

function folderNameOf(path) {
  return path.replace(/[/\\]+$/, "").split(/[/\\]/).pop() || path;
}

// --- launch flow ---

const launchStatusSection = document.getElementById("launch-status");
const launchStatusText = document.getElementById("launch-status-text");
const launchMascot = document.getElementById("launch-mascot");
const btnCancelLaunch = document.getElementById("btn-cancel-launch");

function startDigAnimation() {
  digFrameIndex = 0;
  digTimer = setInterval(() => {
    digFrameIndex = (digFrameIndex + 1) % DIG_FRAMES.length;
    launchMascot.src = DIG_FRAMES[digFrameIndex];
  }, 180); // matches the 0.18s frame interval in main.swift's dig animation
}

function stopDigAnimation() {
  if (digTimer) clearInterval(digTimer);
  digTimer = null;
}

function showLaunchStatus(text) {
  launchStatusText.textContent = text;
  launchStatusSection.hidden = false;
}

function hideLaunchStatus() {
  launchStatusSection.hidden = true;
  stopDigAnimation();
}

function stageToText(stage) {
  switch (stage.stage) {
    case "detecting":
      return "正在辨識專案…";
    case "unrecognized":
      return "看不出這是什麼類型的專案，暫時無法自動啟動。";
    case "preparing":
      return "正在準備環境…";
    case "starting-server":
      return "正在啟動開發伺服器…";
    case "opened-non-web":
      return "已啟動（原生應用程式，沒有網頁 port）";
    case "waiting-localhost": {
      const suffix = `（已等待 ${stage.elapsedSeconds} 秒）`;
      return stage.lastLogLine ? `${stage.lastLogLine}\n${suffix}` : `正在等待 localhost…${suffix}`;
    }
    case "no-port-found":
      return "已啟動，但沒有偵測到新的網頁 port（可能是原生 App 或純後端服務，本來就不會有網頁）";
    case "ready":
      return "專案已準備完成。";
    default:
      return "";
  }
}

let launchToken = 0;

async function launchProject(dirPath) {
  const token = ++launchToken;
  lastLaunchedName = folderNameOf(dirPath);
  showLaunchStatus("正在辨識專案…");
  startDigAnimation();

  const unsubscribe = window.mole.onStage((stage) => {
    if (token !== launchToken) return;
    showLaunchStatus(stageToText(stage));
    if (stage.stage === "ready") {
      setTimeout(() => {
        if (token === launchToken) hideLaunchStatus();
      }, 900);
    }
  });

  try {
    const result = await window.mole.launchProject(dirPath);
    if (token !== launchToken) return; // a newer launch superseded this one
    lastLaunchedEl.hidden = false;
    lastLaunchedEl.textContent = result.ok
      ? `上次啟動：${lastLaunchedName}（已開啟）`
      : `上次啟動：${lastLaunchedName}（${result.reason === "unrecognized" ? "無法辨識" : "沒有偵測到 port"}）`;
    if (result.ok && result.port == null) {
      // Non-web launch: nothing more to wait for, and the "ready" stage never fires.
      hideLaunchStatus();
    }
  } finally {
    unsubscribe();
  }
}

btnCancelLaunch.addEventListener("click", () => {
  launchToken++; // orphans any in-flight onStage callbacks; the IPC call itself still finishes in main
  hideLaunchStatus();
});

// --- running ports list ---

const portsListEl = document.getElementById("ports-list");
const emptyStateEl = document.getElementById("empty-state");
const expireSelect = document.getElementById("expire-select");
const btnKillAll = document.getElementById("btn-kill-all");
const autocloseNotice = document.getElementById("autoclose-notice");

function isPinned(port) {
  return settings.persistentPorts.includes(String(port));
}

function renderPorts(ports) {
  const devPorts = ports.filter((p) => p.isDev);
  btnKillAll.disabled = devPorts.length === 0;

  if (devPorts.length === 0) {
    emptyStateEl.hidden = false;
    portsListEl.hidden = true;
    portsListEl.textContent = "";
    return;
  }

  emptyStateEl.hidden = true;
  portsListEl.hidden = false;
  portsListEl.textContent = "";

  for (const info of devPorts) {
    const li = document.createElement("li");
    li.className = "port-row";

    const main = document.createElement("div");
    main.className = "port-row-main";

    const title = document.createElement("div");
    title.className = "port-row-title";
    const portSpan = document.createElement("span");
    portSpan.className = "port-number";
    portSpan.textContent = `localhost:${info.port}`;
    title.appendChild(portSpan);
    if (isPinned(info.port)) {
      const badge = document.createElement("span");
      badge.className = "pin-badge";
      badge.textContent = "常駐中";
      title.appendChild(badge);
    }
    main.appendChild(title);

    const meta = document.createElement("div");
    meta.className = "port-row-meta";
    meta.textContent = `${info.processName || "unknown"} · PID ${info.pid} · ${friendlyUptime(info.uptimeSeconds)}`;
    main.appendChild(meta);

    const actions = document.createElement("div");
    actions.className = "port-row-actions";

    const pinBtn = document.createElement("button");
    pinBtn.className = "icon-btn" + (isPinned(info.port) ? " pinned" : "");
    pinBtn.title = "常駐：不會被自動過期關閉";
    pinBtn.textContent = "📌";
    pinBtn.addEventListener("click", async () => {
      settings = await window.mole.togglePin(info.port);
      refreshPorts();
    });
    actions.appendChild(pinBtn);

    const stopBtn = document.createElement("button");
    stopBtn.className = "btn-stop";
    stopBtn.textContent = "關閉";
    stopBtn.addEventListener("click", () => {
      if (!window.confirm(`關閉 localhost:${info.port}？`)) return;
      window.mole.stopPort(info.pid).then(refreshPorts);
    });
    actions.appendChild(stopBtn);

    li.appendChild(main);
    li.appendChild(actions);
    portsListEl.appendChild(li);
  }
}

async function refreshPorts() {
  const ports = await window.mole.refreshPorts();
  renderPorts(ports);
}

window.mole.onPortsUpdate((ports, expiredPorts) => {
  renderPorts(ports);
  if (expiredPorts && expiredPorts.length > 0) {
    autocloseNotice.textContent = `已自動關閉 localhost:${expiredPorts.join(", localhost:")}（閒置過久）`;
    autocloseNotice.hidden = false;
    setTimeout(() => {
      autocloseNotice.hidden = true;
    }, 6000);
  }
});

btnKillAll.addEventListener("click", async () => {
  if (!window.confirm("確定要全部關閉嗎？（已標記「常駐」的服務不會被關閉）")) return;
  await window.mole.killAllPorts();
  refreshPorts();
});

expireSelect.addEventListener("change", async () => {
  settings = await window.mole.setExpireMinutes(Number(expireSelect.value));
});

// --- init ---

(async function init() {
  settings = await window.mole.getSettings();
  expireSelect.value = String(settings.expireMinutes);
  await refreshPorts();
})();
