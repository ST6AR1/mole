import SwiftUI
import AppKit
import Darwin

// MARK: - Version check

// 用一個真正 Equatable 的 struct 而不是 tuple 放進 @State——tuple 不是 Equatable，
// 曾經造成 SwiftUI 在比較新舊狀態時內部崩潰（AttributeGraph / BodyAccessor 相關的 crash）。
struct UpdateInfo: Equatable {
    let version: String
    let releasePageURL: URL
    let dmgURL: URL?
}

let currentVersion = "1.0.9"
let releasesAPI = "https://api.github.com/repos/ST6AR1/smart-launch/releases/latest"

// 比較兩個「1.2.3」格式的版本字串，回傳 a 是否比 b 新
func isVersion(_ a: String, newerThan b: String) -> Bool {
    let pa = a.split(separator: ".").map { Int($0) ?? 0 }
    let pb = b.split(separator: ".").map { Int($0) ?? 0 }
    for i in 0..<max(pa.count, pb.count) {
        let x = i < pa.count ? pa[i] : 0
        let y = i < pb.count ? pb[i] : 0
        if x != y { return x > y }
    }
    return false
}

// 開啟時問一次 GitHub「最新 release 是哪版」，有更新才回呼；離線或失敗就悄悄放棄，不打擾使用者
func checkForUpdate(completion: @escaping (UpdateInfo) -> Void) {
    guard let url = URL(string: releasesAPI) else { return }
    var request = URLRequest(url: url)
    request.timeoutInterval = 5
    URLSession.shared.dataTask(with: request) { data, _, _ in
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              let htmlURLString = json["html_url"] as? String,
              let releaseURL = URL(string: htmlURLString)
        else { return }
        let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        guard isVersion(latest, newerThan: currentVersion) else { return }

        var dmgURL: URL?
        if let assets = json["assets"] as? [[String: Any]] {
            for asset in assets {
                if let name = asset["name"] as? String, name.hasSuffix(".dmg"),
                   let downloadURLString = asset["browser_download_url"] as? String,
                   let downloadURL = URL(string: downloadURLString) {
                    dmgURL = downloadURL
                    break
                }
            }
        }
        completion(UpdateInfo(version: latest, releasePageURL: releaseURL, dmgURL: dmgURL))
    }.resume()
}

// MARK: - Model

struct PortInfo: Identifiable, Equatable {
    var id: String { "\(port)-\(pid)" }
    let port: String
    let processName: String
    let pid: Int32
    let command: String
    let isDev: Bool
    let uptime: String
    let uptimeSeconds: Int
}

// tuple 陣列在 ForEach 裡被 SwiftUI/AttributeGraph 比較新舊值時，在這個 macOS 版本上
// 會直接崩潰（EXC_BAD_ACCESS in Array<A>.==）。跟 UpdateInfo 那次是同一類問題，
// 這次影響範圍更大：Auto Close 這個選單在 App 一開啟就會渲染，所以是「一開就閃退」。
struct ExpireOption: Equatable {
    let label: String
    let minutes: Int
}

// 自動過期的時間選項（分鐘），0 代表「停用自動過期」
let expireOptions: [ExpireOption] = [
    ExpireOption(label: "30 分鐘", minutes: 30),
    ExpireOption(label: "1 小時", minutes: 60),
    ExpireOption(label: "2 小時（預設）", minutes: 120),
    ExpireOption(label: "4 小時", minutes: 240),
    ExpireOption(label: "停用自動過期", minutes: 0)
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

// 優先用 app bundle 內附的腳本（DMG 拖進 /Applications 就能直接用，不需要另外跑 install.sh）；
// 找不到才退回 ~/bin/smartlaunch/（給用 install.sh 裝、想要同時有 `ports` 指令的人）。
let scriptPath: String = {
    if let bundled = Bundle.main.path(forResource: "smart-launch", ofType: "sh") {
        return bundled
    }
    return NSHomeDirectory() + "/bin/smartlaunch/smart-launch.sh"
}()

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

// 曾經每個 port 各別呼叫兩次 /bin/ps（20 幾個系統服務就等於一次刷新開 40+ 個子程序）。
// 這造成一個很難追的間歇性崩潰：大量、快速地透過 Process() 開子程序，疑似觸發某種
// 資源競爭／記憶體毀損，症狀卻在完全不相關的 SwiftUI 渲染程式碼裡冒出來
// （記憶體毀損類 bug 很常見的特徵：當掉的地方不是真正出問題的地方）。
// 已用「拿掉這些額外的 ps 呼叫」連續跑 5 分鐘完全不會崩潰來驗證。
// 修法：所有 port 只共用「一次」ps 呼叫，一次把全部 pid 的資訊撈回來，
// 不管有幾個服務在跑，子程序數量固定是 lsof + ps 兩個。
func fetchPorts() -> [PortInfo] {
    let lsofOutput = runShell("/usr/sbin/lsof", ["-iTCP", "-sTCP:LISTEN", "-n", "-P"])

    struct RawEntry { let cmdName: String; let pid: Int32; let port: String }
    var entries: [RawEntry] = []
    var seenKeys = Set<String>()

    for line in lsofOutput.split(separator: "\n").dropFirst() {
        let cols = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard cols.count >= 9 else { continue }
        let cmdName = cols[0]
        guard let pid = Int32(cols[1]) else { continue }
        let addr = cols[8]
        guard let portPart = addr.split(separator: ":").last else { continue }
        let port = String(portPart)

        let key = "\(port)-\(pid)"
        if seenKeys.contains(key) { continue }
        seenKeys.insert(key)
        entries.append(RawEntry(cmdName: cmdName, pid: pid, port: port))
    }

    guard !entries.isEmpty else { return [] }

    // 一次把所有 pid 的 etime/command 撈回來，取代逐一呼叫 ps
    let uniquePids = Array(Set(entries.map { $0.pid })).map(String.init)
    let psOutput = runShell("/bin/ps", ["-o", "pid=,etime=,command=", "-p", uniquePids.joined(separator: ",")])

    var infoByPid: [Int32: (etime: String, command: String)] = [:]
    for line in psOutput.split(separator: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard parts.count >= 2, let pid = Int32(parts[0]) else { continue }
        let etime = String(parts[1])
        let command = parts.count >= 3 ? String(parts[2]) : ""
        infoByPid[pid] = (etime, command)
    }

    let results = entries.map { entry -> PortInfo in
        let info = infoByPid[entry.pid]
        let seconds = uptimeSeconds(fromEtime: info?.etime ?? "")
        let isDev = devPatterns.contains(entry.cmdName.lowercased())
        return PortInfo(
            port: entry.port, processName: entry.cmdName, pid: entry.pid,
            command: info?.command ?? "", isDev: isDev,
            uptime: friendlyUptime(seconds), uptimeSeconds: seconds
        )
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

    // 徹底關掉 macOS 的「上次意外退出，要不要重新打開視窗」對話框。
    // 光設定 NSWindow.isRestorable = false 不夠：只要應用程式曾經異常結束過一次，
    // 系統下次啟動還是會在我們自己的視窗出現「之前」，先跳出這個對話框——
    // 而且如果使用者點了「Reopen」，還原舊狀態的過程本身又可能再次觸發問題，變成無限循環。
    // 這個 delegate method 是比 isRestorable 更上層、更權威的開關，直接讓系統不要再問。
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hosting = NSHostingController(rootView: ContentView())
        let win = NSWindow(contentViewController: hosting)
        win.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isRestorable = false
        win.setFrameAutosaveName("")
        win.isReleasedWhenClosed = false
        win.minSize = NSSize(width: 480, height: 620)

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = NSSize(width: 480, height: 680)
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

// MARK: - Design tokens

enum Palette {
    static let windowBg = Color(red: 0.953, green: 0.949, blue: 0.937)      // #F3F2EF
    static let heroBg = Color(red: 0.992, green: 0.992, blue: 0.984)        // #FDFDFB
    static let rowBg = Color(red: 0.973, green: 0.969, blue: 0.953)         // #F8F7F3
    static let rowBgMuted = Color(red: 0.961, green: 0.957, blue: 0.941)    // #F5F4F0
    static let textPrimary = Color(red: 0.110, green: 0.110, blue: 0.118)   // #1C1C1E
    static let textSecondary = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93
    static let textTertiary = Color(red: 0.690, green: 0.686, blue: 0.675)  // #B0AFAC
    static let danger = Color(red: 0.753, green: 0.224, blue: 0.169)        // #C0392B
    static let localhostText = Color(red: 0.227, green: 0.227, blue: 0.235) // #3A3A3C
    static let updateBg = Color(red: 0.933, green: 0.945, blue: 0.965)      // #EEF1F6
    static let updateText = Color(red: 0.227, green: 0.353, blue: 0.549)    // #3A5A8C
    static let primaryButtonBg = Color(red: 0.941, green: 0.937, blue: 0.925) // #F0EFEC
}

// 拖曳懸浮時的柔和漸層描邊，全 App 唯一使用玻璃感效果的地方
let dragGradient = LinearGradient(
    colors: [Color.blue.opacity(0.45), Color.green.opacity(0.35)],
    startPoint: .topLeading, endPoint: .bottomTrailing
)

// 「選擇資料夾」這種主要操作用的 soft filled button
struct SoftFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Palette.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Palette.primaryButtonBg)
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.02 : 0.06), radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

// MARK: - UI

struct ContentView: View {
    @State private var ports: [PortInfo] = []
    @State private var isRefreshing = false
    @State private var isTargeted = false
    @State private var lastLaunched: String = ""
    @State private var pendingKill: PortInfo?
    @State private var pendingKillAll = false
    @State private var autoExpiredNotice: String = ""
    @State private var showOtherServices = false
    @State private var isLaunching = false
    @State private var launchStatus: String = ""
    @State private var pollToken = UUID()
    @State private var updateAvailable: UpdateInfo?
    @State private var isUpdating = false
    @State private var updateStatus = ""

    // 記住哪些 port 設為「保持背景常駐」(跨重啟保留)，以及全域自動過期時間
    @AppStorage("smartlaunch.persistentPorts") private var persistentPortsRaw: String = ""
    @AppStorage("smartlaunch.expireMinutes") private var expireMinutes: Int = 120

    // 拉長刷新間隔（2 秒 → 8 秒）：懷疑是 SwiftUI AttributeGraph 在這台機器的 macOS
    // 版本上累積夠多次畫面更新後會不穩定，降低更新頻率能拉長「炸掉之前」的時間，
    // 對正常「開 App、拖資料夾、看它跑起來」這種短時間使用情境影響不大。
    let timer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()

    var persistentPorts: Set<String> {
        Set(persistentPortsRaw.split(separator: ",").map(String.init))
    }

    var devPorts: [PortInfo] { ports.filter { $0.isDev } }
    var otherPorts: [PortInfo] { ports.filter { !$0.isDev } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if let update = updateAvailable {
                updateBanner(update)
            }

            heroCard
            autoCloseRow
            runningProjectsHeader

            // 改版後這裡本來是手刻的 ScrollView + VStack + ForEach，換回原生 List——
            // List 是 SwiftUI 從一開始就有、經過大量實戰測試的元件，處理會動態增減的
            // 內容遠比自己手刻的捲動容器成熟穩定，用來取代不確定成因的背景閒置崩潰。
            List {
                if devPorts.isEmpty {
                    Text("目前沒有專案在跑")
                        .font(.system(size: 12))
                        .foregroundColor(Palette.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                } else {
                    ForEach(devPorts) { info in
                        projectRow(info)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    }
                }
                if !otherPorts.isEmpty {
                    otherServicesDisclosure
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Palette.windowBg)
            .frame(maxHeight: .infinity)

            footerCredit
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.windowBg)
        .onAppear(perform: refresh)
        .onAppear {
            checkForUpdate { info in
                DispatchQueue.main.async {
                    updateAvailable = info
                }
            }
        }
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

    // MARK: Header

    var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Smart Launch")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                Text("讓本機專案重新啟動變簡單")
                    .font(.system(size: 12))
                    .foregroundColor(Palette.textSecondary)
            }
            Spacer()
            if let url = URL(string: "https://github.com/ST6AR1/smart-launch") {
                Link(destination: url) {
                    githubIcon
                        .frame(width: 14, height: 14)
                        .foregroundColor(Palette.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.black.opacity(0.04)))
                }
                .buttonStyle(.plain)
                .help("在 GitHub 上查看這個專案")
            }
        }
    }

    // 從 app bundle 讀真正的 GitHub 圖示（灰階 template，可跟著 foregroundColor 上色）
    var githubIcon: some View {
        Group {
            if let path = Bundle.main.path(forResource: "github-mark", ofType: "png"),
               let nsImage = NSImage(contentsOfFile: path) {
                Image(nsImage: nsImage)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }

    func updateBanner(_ update: UpdateInfo) -> some View {
        HStack {
            if isUpdating {
                ProgressView().controlSize(.small)
                Text(updateStatus.isEmpty ? "正在更新…" : updateStatus)
                    .font(.system(size: 12))
                    .foregroundColor(Palette.textPrimary)
            } else {
                Text("🎉 有新版本 v\(update.version) 可下載")
                    .font(.system(size: 12))
                    .foregroundColor(Palette.textPrimary)
                Spacer()
                if update.dmgURL != nil {
                    Button("立即更新") { performUpdate(update) }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Palette.updateText)
                } else {
                    Link("前往查看", destination: update.releasePageURL)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Palette.updateText)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.updateBg))
    }

    // 下載新版 DMG → 掛載 → 複製到自己現在的路徑蓋過舊版 → 卸載 → 重開新版、結束自己。
    // 全程在背景執行緒跑；任何一步失敗都優雅降級，改請使用者自己去 Release 頁面下載。
    func performUpdate(_ update: UpdateInfo) {
        guard let dmgURL = update.dmgURL else { return }
        isUpdating = true
        updateStatus = "正在下載更新…"

        DispatchQueue.global(qos: .userInitiated).async {
            func fail(_ message: String) {
                DispatchQueue.main.async {
                    self.isUpdating = false
                    self.updateStatus = ""
                    self.autoExpiredNotice = message
                }
            }

            let tmpDir = FileManager.default.temporaryDirectory
            let dmgPath = tmpDir.appendingPathComponent("SmartLaunch-update-\(UUID().uuidString).dmg")

            let semaphore = DispatchSemaphore(value: 0)
            var downloadError: String?
            URLSession.shared.downloadTask(with: dmgURL) { location, _, error in
                defer { semaphore.signal() }
                if let error = error {
                    downloadError = error.localizedDescription
                    return
                }
                guard let location = location else {
                    downloadError = "下載失敗"
                    return
                }
                do {
                    try FileManager.default.moveItem(at: location, to: dmgPath)
                } catch {
                    downloadError = error.localizedDescription
                }
            }.resume()
            semaphore.wait()

            if let err = downloadError {
                fail("更新下載失敗：\(err)")
                return
            }

            DispatchQueue.main.async { self.updateStatus = "正在安裝…" }

            let mountPoint = tmpDir.appendingPathComponent("SmartLaunchMount-\(UUID().uuidString)").path
            try? FileManager.default.createDirectory(atPath: mountPoint, withIntermediateDirectories: true)

            let attach = Process()
            attach.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            attach.arguments = ["attach", dmgPath.path, "-nobrowse", "-mountpoint", mountPoint]
            attach.standardOutput = Pipe()
            attach.standardError = Pipe()
            do {
                try attach.run()
                attach.waitUntilExit()
            } catch {
                fail("掛載更新檔失敗")
                return
            }

            func detachDMG() {
                let detach = Process()
                detach.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
                detach.arguments = ["detach", mountPoint, "-quiet"]
                detach.standardOutput = Pipe()
                detach.standardError = Pipe()
                try? detach.run()
                detach.waitUntilExit()
            }

            let newAppPath = mountPoint + "/SmartLaunch.app"
            guard FileManager.default.fileExists(atPath: newAppPath) else {
                detachDMG()
                fail("更新檔裡找不到 SmartLaunch.app")
                return
            }

            DispatchQueue.main.async { self.updateStatus = "正在替換舊版本…" }

            let stagingPath = tmpDir.appendingPathComponent("SmartLaunch-new-\(UUID().uuidString).app").path
            do {
                try FileManager.default.copyItem(atPath: newAppPath, toPath: stagingPath)
            } catch {
                detachDMG()
                fail("複製新版本失敗：\(error.localizedDescription)")
                return
            }
            detachDMG()

            let xattrClear = Process()
            xattrClear.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
            xattrClear.arguments = ["-cr", stagingPath]
            xattrClear.standardOutput = Pipe()
            xattrClear.standardError = Pipe()
            try? xattrClear.run()
            xattrClear.waitUntilExit()

            let currentAppPath = Bundle.main.bundlePath
            do {
                try FileManager.default.removeItem(atPath: currentAppPath)
                try FileManager.default.copyItem(atPath: stagingPath, toPath: currentAppPath)
            } catch {
                fail("安裝新版本失敗（可能沒有寫入權限），請自己到 Release 頁面下載安裝：\(error.localizedDescription)")
                return
            }

            DispatchQueue.main.async { self.updateStatus = "更新完成，重新啟動中…" }

            let openTask = Process()
            openTask.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            openTask.arguments = [currentAppPath]
            try? openTask.run()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                NSApp.terminate(nil)
            }
        }
    }

    // MARK: Hero — Launch Project

    var heroCard: some View {
        VStack(spacing: 10) {
            if isLaunching {
                ProgressView()
                    .controlSize(.small)
                Text(launchStatus.isEmpty ? "正在啟動…" : launchStatus)
                    .font(.system(size: 12))
                    .foregroundColor(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                Button("先不等了") { cancelWaiting() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(Palette.textSecondary)
            } else {
                Image(systemName: "folder")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(Palette.textSecondary)
                Text("把專案資料夾拖到這裡")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Palette.textPrimary)
                Text("自動判斷並啟動 localhost")
                    .font(.system(size: 12))
                    .foregroundColor(Palette.textSecondary)
                Button("選擇資料夾") { chooseFolder() }
                    .buttonStyle(SoftFilledButtonStyle())
                    .padding(.top, 4)
                if !lastLaunched.isEmpty {
                    Text("上次啟動：\(lastLaunched)")
                        .font(.system(size: 10))
                        .foregroundColor(Palette.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: isLaunching ? 160 : 170)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Palette.heroBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(dragGradient, lineWidth: 2)
                        .opacity(isTargeted ? 1 : 0)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 24, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    // MARK: Auto Close — inline row, no card

    // SwiftUI 的 Menu 在這台機器的 macOS 版本上會不定時讓 AttributeGraph 崩潰
    // （已用「拿掉 Menu 後連續跑 90 秒完全不會崩潰」證實），改用原生 NSPopUpButton
    // 包一層 NSViewRepresentable，完全不走 SwiftUI Menu 那條有問題的路徑。
    struct ExpireMenuPicker: NSViewRepresentable {
        @Binding var selection: Int
        let options: [ExpireOption]

        func makeNSView(context: Context) -> NSPopUpButton {
            let button = NSPopUpButton(frame: .zero, pullsDown: false)
            button.font = NSFont.systemFont(ofSize: 11, weight: .medium)
            button.bezelStyle = .rounded
            for opt in options {
                button.addItem(withTitle: opt.label)
            }
            button.target = context.coordinator
            button.action = #selector(Coordinator.selectionChanged(_:))
            context.coordinator.options = options
            if let idx = options.firstIndex(where: { $0.minutes == selection }) {
                button.selectItem(at: idx)
            }
            return button
        }

        func updateNSView(_ nsView: NSPopUpButton, context: Context) {
            context.coordinator.options = options
            if let idx = options.firstIndex(where: { $0.minutes == selection }),
               nsView.indexOfSelectedItem != idx {
                nsView.selectItem(at: idx)
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(selection: $selection)
        }

        class Coordinator: NSObject {
            var selectionBinding: Binding<Int>
            var options: [ExpireOption] = []
            init(selection: Binding<Int>) {
                self.selectionBinding = selection
            }
            @objc func selectionChanged(_ sender: NSPopUpButton) {
                let idx = sender.indexOfSelectedItem
                if idx >= 0 && idx < options.count {
                    selectionBinding.wrappedValue = options[idx].minutes
                }
            }
        }
    }

    var currentExpireLabel: String {
        expireOptions.first(where: { $0.minutes == expireMinutes })?.label
            .replacingOccurrences(of: "（預設）", with: "") ?? "\(expireMinutes) 分"
    }

    var autoCloseRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto Close")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Palette.textPrimary)
                    Text("閒置專案將自動關閉")
                        .font(.system(size: 11))
                        .foregroundColor(Palette.textSecondary)
                }
                Spacer()
                ExpireMenuPicker(selection: $expireMinutes, options: expireOptions)
                    .frame(width: 130)
            }
            if !autoExpiredNotice.isEmpty {
                Text(autoExpiredNotice)
                    .font(.system(size: 10))
                    .foregroundColor(Palette.textTertiary)
            }
        }
    }

    // MARK: Running Projects

    var runningProjectsHeader: some View {
        HStack {
            Text("Running Projects")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Palette.textPrimary)
            Spacer()
            if !devPorts.isEmpty {
                Button("全部關閉") { pendingKillAll = true }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Palette.danger)
            }
            Button(action: refresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    func shortUptime(_ totalSeconds: Int) -> String {
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        if days > 0 { return "\(days) d" }
        if hours > 0 { return "\(hours) hr" }
        if minutes > 0 { return "\(minutes) min" }
        return "< 1 min"
    }

    func projectRow(_ info: PortInfo) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text("localhost:\(info.port)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Palette.localhostText)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8))
                        .foregroundColor(Palette.textTertiary)
                }
                .onTapGesture { openBrowser(port: info.port) }
                .help("\(info.uptime)\n\(info.command)")

                Text("\(info.processName) · \(shortUptime(info.uptimeSeconds))")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.textSecondary)
            }
            Spacer()
            Button(action: { togglePersistent(info.port) }) {
                Image(systemName: isPersistent(info.port) ? "pin.fill" : "pin")
                    .font(.system(size: 12))
                    .foregroundColor(isPersistent(info.port) ? Palette.textPrimary : Palette.textTertiary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("常駐：不會被自動過期關閉")

            Button("Stop") { pendingKill = info }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Palette.danger)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Palette.rowBg))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.black.opacity(0.04), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 1)
    }

    var otherServicesDisclosure: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { showOtherServices.toggle() }) {
                HStack {
                    Text("System services (\(otherPorts.count))")
                        .font(.system(size: 11))
                        .foregroundColor(Palette.textTertiary)
                    Spacer()
                    Image(systemName: showOtherServices ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(Palette.textTertiary)
                }
            }
            .buttonStyle(.plain)

            if showOtherServices {
                VStack(spacing: 6) {
                    ForEach(otherPorts) { info in
                        HStack {
                            Text("localhost:\(info.port)")
                                .font(.system(size: 11))
                                .foregroundColor(Palette.textSecondary)
                            Text(info.processName)
                                .font(.system(size: 10))
                                .foregroundColor(Palette.textTertiary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.rowBgMuted))
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    func openBrowser(port: String) {
        if let url = URL(string: "http://localhost:\(port)") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: Footer

    var footerCredit: some View {
        VStack(spacing: 2) {
            Text("由溫Wen 與 claude寶寶 聯合製作 ⌯^⦁𖥦⦁^⌯")
            if let url = URL(string: "https://github.com/ST6AR1") {
                Link("GitHub @ST6AR1", destination: url)
                    .underline(false)
            }
            Text("v\(currentVersion)")
                .padding(.top, 2)
        }
        .font(.system(size: 10))
        .foregroundColor(Palette.textTertiary.opacity(0.7))
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // fetchPorts() 會跑 lsof + 每個 port 兩次 ps，屬於阻塞式呼叫，一律丟到背景執行緒避免卡住 UI。
    // 加上 isRefreshing 防止上一輪還沒跑完、下一次 2 秒計時器又觸發，兩輪背景工作同時把結果
    // 丟回主執行緒，導致短時間內疊加太多次狀態變更（曾經懷疑是這種 transaction 疊加讓
    // AttributeGraph 在某些 macOS 版本上不穩定，加這個guard 至少能排除這個可能性）。
    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        DispatchQueue.global(qos: .utility).async {
            let fetched = fetchPorts()
            DispatchQueue.main.async {
                self.ports = fetched
                self.checkExpiry(fetched)
                self.isRefreshing = false
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
        // loadObject(ofClass: URL.self) 是 Apple 建議的現代 API，比手動用 "public.file-url"
        // 字串比對更可靠，對雲端硬碟（Dropbox/iCloud 等 File Provider）掛載的資料夾支援也比較好。
        guard provider.canLoadObject(ofClass: URL.self) else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
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
        var stillCurrent = true
        DispatchQueue.main.sync { stillCurrent = (self.pollToken == token) }
        guard stillCurrent else { return }

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
