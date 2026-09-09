import SwiftUI
import AppKit
import Darwin

// MARK: - Model

struct PortInfo: Identifiable {
    var id: String { "\(port)-\(pid)" }
    let port: String
    let processName: String
    let pid: Int32
    let command: String
    let isDev: Bool
    let uptime: String
    let uptimeSeconds: Int
}

// 自動過期的時間選項（分鐘），0 代表「停用自動過期」
let expireOptions: [(label: String, minutes: Int)] = [
    ("30 分鐘", 30),
    ("1 小時", 60),
    ("2 小時（預設）", 120),
    ("4 小時", 240),
    ("停用自動過期", 0)
]

let launchLogPath = "/tmp/smartlaunch-latest.log"

// 讀 launch log 的最後一行非空文字，讓使用者看到「目前實際在跑什麼」而不只是秒數
func lastLogLine() -> String {
    guard let data = FileManager.default.contents(atPath: launchLogPath),
          let text = String(data: data, encoding: .utf8) else { return "" }
    let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
    guard let last = lines.last else { return "" }
    let trimmed = last.trimmingCharacters(in: .whitespaces)
    return trimmed.count > 70 ? String(trimmed.suffix(70)) : trimmed
}

// smart-launch.sh 每次啟動都會把偵測到的 LABEL 寫進這個檔案；
// 用它判斷這次是不是「原生 App / Xcode 專案」——這種沒有網頁 port，等再久也不會有，直接跳過輪詢。
let lastLabelPath = "/tmp/smartlaunch-last-label.txt"
let nonWebLabelHints = ["macOS App", "Xcode 專案", "Swift Package", "Flutter", "Chrome 擴充功能"]

func isLikelyNonWebLaunch() -> Bool {
    guard let label = try? String(contentsOfFile: lastLabelPath, encoding: .utf8) else { return false }
    return nonWebLabelHints.contains { label.contains($0) }
}

let devPatterns: Set<String> = [
    "node", "python", "python3", "ruby", "go", "php", "php-fpm", "deno", "bun",
    "java", "ngrok", "caddy", "nginx", "webpack", "vite", "next", "rails",
    "uvicorn", "gunicorn", "flask", "dotnet"
]

let scriptPath = NSHomeDirectory() + "/bin/smartlaunch/smart-launch.sh"

// 等待新服務出現的最長時間（秒）。Docker Desktop 冷啟動常常要 1 分鐘以上，所以給寬一點。
let pollMaxAttempts = 150

// MARK: - Shell helpers

@discardableResult
func runShell(_ launchPath: String, _ args: [String]) -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: launchPath)
    task.arguments = args
    let outPipe = Pipe()
    task.standardOutput = outPipe
    task.standardError = Pipe()
    do {
        try task.run()
    } catch {
        return ""
    }
    let data = outPipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    return String(data: data, encoding: .utf8) ?? ""
}

func launchProject(at path: String) {
    DispatchQueue.global(qos: .userInitiated).async {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [scriptPath, path]
        try? task.run()
    }
}

func fetchPorts() -> [PortInfo] {
    let output = runShell("/usr/sbin/lsof", ["-iTCP", "-sTCP:LISTEN", "-n", "-P"])
    var results: [PortInfo] = []
    var seen = Set<String>()

    let lines = output.split(separator: "\n").dropFirst()
    for line in lines {
        let cols = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard cols.count >= 9 else { continue }
        let cmdName = cols[0]
        guard let pid = Int32(cols[1]) else { continue }
        let addr = cols[8]
        guard let portPart = addr.split(separator: ":").last else { continue }
        let port = String(portPart)

        let key = "\(port)-\(pid)"
        if seen.contains(key) { continue }
        seen.insert(key)

        let fullCmd = runShell("/bin/ps", ["-p", "\(pid)", "-o", "command="])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let rawEtime = runShell("/bin/ps", ["-p", "\(pid)", "-o", "etime="])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let isDev = devPatterns.contains(cmdName.lowercased())
        let seconds = uptimeSeconds(fromEtime: rawEtime)
        results.append(PortInfo(
            port: port, processName: cmdName, pid: pid, command: fullCmd,
            isDev: isDev, uptime: friendlyUptime(seconds), uptimeSeconds: seconds
        ))
    }
    return results.sorted { (Int($0.port) ?? 0) < (Int($1.port) ?? 0) }
}

// ps etime= 格式為 [[dd-]hh:]mm:ss，轉成總秒數
func uptimeSeconds(fromEtime raw: String) -> Int {
    guard !raw.isEmpty else { return 0 }
    var days = 0
    var rest = raw
    if let dashRange = raw.range(of: "-") {
        days = Int(raw[raw.startIndex..<dashRange.lowerBound]) ?? 0
        rest = String(raw[dashRange.upperBound...])
    }
    let parts = rest.split(separator: ":").map { Int($0) ?? 0 }
    var hours = 0, minutes = 0, seconds = 0
    switch parts.count {
    case 3: hours = parts[0]; minutes = parts[1]; seconds = parts[2]
    case 2: minutes = parts[0]; seconds = parts[1]
    case 1: seconds = parts[0]
    default: break
    }
    return ((days * 24 + hours) * 60 + minutes) * 60 + seconds
}

func friendlyUptime(_ totalSeconds: Int) -> String {
    let days = totalSeconds / 86400
    let hours = (totalSeconds % 86400) / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    if days > 0 { return "已運行 \(days) 天 \(hours) 小時" }
    if hours > 0 { return "已運行 \(hours) 小時 \(minutes) 分" }
    if minutes > 0 { return "已運行 \(minutes) 分鐘" }
    return "已運行 \(seconds) 秒"
}

// MARK: - App

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hosting = NSHostingController(
            rootView: ContentView().frame(width: 460, height: 640)
        )
        let win = NSWindow(contentViewController: hosting)
        win.title = "Smart Launch"
        win.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        win.isRestorable = false
        win.setFrameAutosaveName("")
        win.isReleasedWhenClosed = false

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = NSSize(width: 460, height: 640)
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.midY - size.height / 2
        )
        win.setFrame(NSRect(origin: origin, size: size), display: true)

        window = win

        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // 拖到 Dock 圖示或用「打開檔案」開啟資料夾時觸發
    func application(_ application: NSApplication, open urls: [URL]) {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        for url in urls {
            launchProject(at: url.path)
        }
    }
}

let delegate = AppDelegate()
let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.delegate = delegate
app.run()

// MARK: - UI

struct ContentView: View {
    @State private var ports: [PortInfo] = []
    @State private var isTargeted = false
    @State private var lastLaunched: String = ""
    @State private var pendingKill: PortInfo?
    @State private var pendingKillAll = false
    @State private var autoExpiredNotice: String = ""
    @State private var showOtherServices = false
    @State private var isLaunching = false
    @State private var launchStatus: String = ""
    @State private var pollToken = UUID()

    // 記住哪些 port 設為「保持背景常駐」(跨重啟保留)，以及全域自動過期時間
    @AppStorage("smartlaunch.persistentPorts") private var persistentPortsRaw: String = ""
    @AppStorage("smartlaunch.expireMinutes") private var expireMinutes: Int = 120

    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var persistentPorts: Set<String> {
        Set(persistentPortsRaw.split(separator: ",").map(String.init))
    }

    var devPorts: [PortInfo] { ports.filter { $0.isDev } }
    var otherPorts: [PortInfo] { ports.filter { !$0.isDev } }

    var body: some View {
        VStack(spacing: 14) {
            Text("Smart Launch")
                .font(.title2).bold()

            dropZone

            Button("或選擇資料夾…") { chooseFolder() }
                .buttonStyle(.bordered)

            Divider()

            HStack {
                Text("自動過期時間").font(.subheadline)
                Spacer()
                Picker("", selection: $expireMinutes) {
                    ForEach(expireOptions, id: \.minutes) { opt in
                        Text(opt.label).tag(opt.minutes)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }
            Text("超過時間會自動關閉「開發伺服器」；單一服務可勾選「常駐」跳過過期。")
                .font(.caption2).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !autoExpiredNotice.isEmpty {
                Text(autoExpiredNotice)
                    .font(.caption).foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack {
                Text("目前運行的服務").font(.headline)
                Spacer()
                if !devPorts.isEmpty {
                    Button("全部關閉") { pendingKillAll = true }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.small)
                }
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }

            List {
                Section("開發伺服器（拖進來啟動的專案）") {
                    if devPorts.isEmpty {
                        Text("目前沒有偵測到").foregroundColor(.secondary).font(.caption)
                    } else {
                        ForEach(devPorts) { info in
                            devRow(info)
                        }
                    }
                }
                DisclosureGroup("其他系統服務（\(otherPorts.count)，唯讀）", isExpanded: $showOtherServices) {
                    ForEach(otherPorts) { info in
                        systemRow(info)
                    }
                }
            }
            .listStyle(.inset)

            footerCredit
        }
        .padding(16)
        .onAppear(perform: refresh)
        .onReceive(timer) { _ in refresh() }
        .alert(item: $pendingKill) { info in
            Alert(
                title: Text("關閉 localhost:\(info.port)？"),
                message: Text("\(info.processName) · PID \(info.pid)\n\(info.command)"),
                primaryButton: .destructive(Text("關閉")) { doKill(info) },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .alert("全部關閉？", isPresented: $pendingKillAll) {
            Button("全部關閉", role: .destructive) { killAll() }
            Button("取消", role: .cancel) {}
        } message: {
            Text(killAllMessage)
        }
    }

    var killAllMessage: String {
        let toKill = devPorts.filter { !isPersistent($0.port) }
        let skipped = devPorts.count - toKill.count
        var msg = "會關閉 \(toKill.count) 個開發伺服器（localhost:\(toKill.map { $0.port }.joined(separator: ", localhost:")))。"
        if skipped > 0 {
            msg += "\n有標記「常駐」的 \(skipped) 個服務不會被關閉。"
        }
        return msg
    }

    func killAll() {
        for info in devPorts where !isPersistent(info.port) {
            Darwin.kill(info.pid, SIGTERM)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            refresh()
        }
    }

    func isPersistent(_ port: String) -> Bool {
        persistentPorts.contains(port)
    }

    func togglePersistent(_ port: String) {
        var set = persistentPorts
        if set.contains(port) { set.remove(port) } else { set.insert(port) }
        persistentPortsRaw = set.sorted().joined(separator: ",")
    }

    var footerCredit: some View {
        VStack(spacing: 2) {
            Text("由小貓 與 claude寶寶 聯合製作 ⌯^⦁𖥦⦁^⌯")
            if let url = URL(string: "https://github.com/ST6AR1") {
                Link("GitHub @ST6AR1", destination: url)
                    .underline(false)
            }
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundColor(isTargeted ? .accentColor : .secondary.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTargeted ? Color.accentColor.opacity(0.12) : Color.gray.opacity(0.06))
                )
            VStack(spacing: 6) {
                if isLaunching {
                    ProgressView()
                        .controlSize(.small)
                    Text(launchStatus.isEmpty ? "正在啟動…" : launchStatus)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 12)
                    Button("先不等了") { cancelWaiting() }
                        .buttonStyle(.plain)
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                    Text("把專案資料夾拖到這裡")
                        .font(.subheadline)
                    if !lastLaunched.isEmpty {
                        Text("上次啟動：\(lastLaunched)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(height: isLaunching ? 150 : 130)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    func devRow(_ info: PortInfo) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("localhost:\(info.port)")
                    .font(.system(.body, design: .monospaced)).bold()
                    .foregroundColor(.accentColor)
                    .underline()
                    .onTapGesture { openBrowser(port: info.port) }
                    .help("點一下在瀏覽器打開")
                Text("\(info.processName) · PID \(info.pid) · \(info.uptime)")
                    .font(.caption).foregroundColor(.secondary)
                Text(info.command)
                    .font(.caption2).foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Toggle("常駐", isOn: Binding(
                get: { isPersistent(info.port) },
                set: { _ in togglePersistent(info.port) }
            ))
            .toggleStyle(.checkbox)
            .help("開啟後這個服務不會被自動過期關閉")

            Button("關閉") { pendingKill = info }
                .buttonStyle(.bordered)
                .tint(.red)
        }
        .padding(.vertical, 2)
    }

    func openBrowser(port: String) {
        if let url = URL(string: "http://localhost:\(port)") {
            NSWorkspace.shared.open(url)
        }
    }

    func systemRow(_ info: PortInfo) -> some View {
        HStack {
            Text("localhost:\(info.port)")
                .font(.system(.caption, design: .monospaced))
            Text(info.processName)
                .font(.caption).foregroundColor(.secondary)
            Spacer()
        }
    }

    // fetchPorts() 會跑 lsof/ps，屬於阻塞式呼叫，一律丟到背景執行緒，避免卡住 UI
    func refresh() {
        DispatchQueue.global(qos: .utility).async {
            let fetched = fetchPorts()
            DispatchQueue.main.async {
                self.ports = fetched
                self.checkExpiry(fetched)
            }
        }
    }

    func checkExpiry(_ fetched: [PortInfo]) {
        guard expireMinutes > 0 else { return }
        let limitSeconds = expireMinutes * 60
        for info in fetched where info.isDev {
            guard !isPersistent(info.port) else { continue }
            if info.uptimeSeconds >= limitSeconds {
                Darwin.kill(info.pid, SIGTERM)
                autoExpiredNotice = "已自動關閉 localhost:\(info.port)（運行超過 \(expireMinutes) 分鐘）"
            }
        }
    }

    func doKill(_ info: PortInfo) {
        Darwin.kill(info.pid, SIGTERM)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            refresh()
        }
    }

    func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            var url: URL?
            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else if let u = item as? URL {
                url = u
            }
            guard let folderURL = url else { return }
            DispatchQueue.main.async {
                lastLaunched = folderURL.lastPathComponent
                launchAndAutoOpen(path: folderURL.path)
            }
        }
        return true
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "選擇"
        if panel.runModal() == .OK, let url = panel.url {
            lastLaunched = url.lastPathComponent
            launchAndAutoOpen(path: url.path)
        }
    }

    // 記下啟動前已存在的 dev port，啟動後輪詢直到出現「新的」dev port，
    // 代表這次拖進來的專案已經真的跑起來了，就自動打開瀏覽器。
    // 全程在背景執行緒跑（lsof/ps 都是阻塞呼叫），只用 main.async 更新畫面狀態。
    func launchAndAutoOpen(path: String) {
        isLaunching = true
        launchStatus = "正在偵測專案類型…"
        let token = UUID()
        pollToken = token

        DispatchQueue.global(qos: .userInitiated).async {
            let before = Set(fetchPorts().filter { $0.isDev }.map { $0.port })
            launchProject(at: path)

            // 給 smart-launch.sh 一點時間把偵測結果寫進 label 檔，再判斷是不是原生 App
            Thread.sleep(forTimeInterval: 0.5)
            if isLikelyNonWebLaunch() {
                DispatchQueue.main.async {
                    guard self.pollToken == token else { return }
                    self.isLaunching = false
                    self.launchStatus = ""
                    self.lastLaunched += "（已開啟）"
                }
                return
            }

            DispatchQueue.main.async {
                if self.pollToken == token {
                    self.launchStatus = "已在 Terminal 啟動，等待服務就緒…"
                }
            }

            self.pollForNewServer(before: before, attemptsLeft: pollMaxAttempts, token: token)
        }
    }

    func cancelWaiting() {
        pollToken = UUID() // 換一個新 token，讓還在跑的輪詢自己發現「過期」而停止
        isLaunching = false
        launchStatus = ""
    }

    // 在背景執行緒遞迴輪詢；每次都先睡 1 秒再檢查。Docker Desktop 冷啟動可能要一分鐘以上，
    // 所以給足時間；即使這裡超時放棄，Terminal 裡的指令仍會繼續跑，不需要重新拖曳資料夾。
    // token 用來偵測使用者是否已按「先不等了」或另外拖了新專案進來，過期就直接停止。
    func pollForNewServer(before: Set<String>, attemptsLeft: Int, token: UUID) {
        guard attemptsLeft > 0 else {
            DispatchQueue.main.async {
                guard self.pollToken == token else { return }
                self.isLaunching = false
                self.launchStatus = ""
                self.autoExpiredNotice = "已啟動，但沒有偵測到新的網頁 port（可能是原生 App、純後端／資料庫服務，本來就不會有網頁；若還在等 Docker，可以到 Terminal 視窗確認進度，不需要重新拖曳）"
                self.refresh()
            }
            return
        }
        Thread.sleep(forTimeInterval: 1)
        guard pollToken == token else { return }

        let elapsed = pollMaxAttempts - attemptsLeft + 1
        let logLine = lastLogLine()
        DispatchQueue.main.async {
            guard self.pollToken == token else { return }
            if logLine.isEmpty {
                self.launchStatus = "等待服務就緒…（已等待 \(elapsed) 秒，隨時可以到 Terminal 查看）"
            } else {
                self.launchStatus = "\(logLine)\n（已等待 \(elapsed) 秒）"
            }
        }
        let current = fetchPorts().filter { $0.isDev }
        if let newOne = current.first(where: { !before.contains($0.port) }) {
            DispatchQueue.main.async {
                guard self.pollToken == token else { return }
                self.isLaunching = false
                self.launchStatus = ""
                self.refresh()
                self.openBrowser(port: newOne.port)
            }
        } else {
            pollForNewServer(before: before, attemptsLeft: attemptsLeft - 1, token: token)
        }
    }
}
