import AppKit
import Darwin

// MARK: - Version check

struct UpdateInfo: Equatable {
    let version: String
    let releasePageURL: URL
    let dmgURL: URL?
}

let currentVersion = "1.0.10"
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

// 對「不是我們自己啟動」的服務，試著抓它自己網頁的 <title> 跟 favicon，
// 卡片才能顯示真正的網站名稱/圖示，而不是只有一個 process 名稱。
// 兩個請求都給很短的逾時時間——這只是錦上添花，不能讓它拖慢畫面刷新。
func fetchSiteInfo(port: String, completion: @escaping (String?, NSImage?) -> Void) {
    guard let pageURL = URL(string: "http://localhost:\(port)/") else {
        completion(nil, nil)
        return
    }
    var request = URLRequest(url: pageURL)
    request.timeoutInterval = 1.5
    URLSession.shared.dataTask(with: request) { data, _, _ in
        var title: String?
        if let data = data, let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) {
            if let range = html.range(of: "<title>", options: .caseInsensitive),
               let endRange = html.range(of: "</title>", options: .caseInsensitive, range: range.upperBound..<html.endIndex) {
                let raw = html[range.upperBound..<endRange.lowerBound]
                let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty && cleaned.count < 80 { title = cleaned }
            }
        }

        guard let faviconURL = URL(string: "http://localhost:\(port)/favicon.ico") else {
            completion(title, nil)
            return
        }
        var faviconRequest = URLRequest(url: faviconURL)
        faviconRequest.timeoutInterval = 1.5
        URLSession.shared.dataTask(with: faviconRequest) { favData, response, _ in
            var icon: NSImage?
            if let favData = favData, favData.count > 32,
               let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let image = NSImage(data: favData) {
                icon = image
            }
            DispatchQueue.main.async { completion(title, icon) }
        }.resume()
    }.resume()
}

// MARK: - Model

struct PortInfo: Equatable {
    var id: String { "\(port)-\(pid)" }
    let port: String
    let processName: String
    let pid: Int32
    let command: String
    let isDev: Bool
    let uptime: String
    let uptimeSeconds: Int
}

struct ExpireOption {
    let label: String
    let minutes: Int
}

// 自動過期的時間選項（分鐘），0 代表「停用自動過期」
// 用 func 而不是 let：內容要跟著語言切換即時變化，且 t() 依賴的字典要到
// 檔案後面才初始化，宣告成 func 才能保證真正呼叫時 t() 已經可以用。
func currentExpireOptions() -> [ExpireOption] {
    [
        ExpireOption(label: t("expire.30m"), minutes: 30),
        ExpireOption(label: t("expire.1h"), minutes: 60),
        ExpireOption(label: t("expire.2h"), minutes: 120),
        ExpireOption(label: t("expire.4h"), minutes: 240),
        ExpireOption(label: t("expire.never"), minutes: 0)
    ]
}

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

// 所有 port 只共用「一次」ps 呼叫，一次把全部 pid 的資訊撈回來，
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

func shortUptime(_ totalSeconds: Int) -> String {
    let days = totalSeconds / 86400
    let hours = (totalSeconds % 86400) / 3600
    let minutes = (totalSeconds % 3600) / 60
    if days > 0 { return "\(days) d" }
    if hours > 0 { return "\(hours) hr" }
    if minutes > 0 { return "\(minutes) min" }
    return "< 1 min"
}

// 鼴鼠插畫是手動放進 app bundle Resources 的 PNG，沒有走 asset catalog，
// 所以不能用 NSImage(named:)，要自己從 bundle 路徑載入。載入一次快取起來即可。
private var moleImageCache: [String: NSImage] = [:]
func moleImage(_ name: String) -> NSImage? {
    if let cached = moleImageCache[name] { return cached }
    guard let path = Bundle.main.path(forResource: name, ofType: "png"),
          let image = NSImage(contentsOfFile: path) else { return nil }
    moleImageCache[name] = image
    return image
}

// MARK: - Localization
//
// 簡單的雙語字典，不是完整的 .strings/.lproj 系統——只覆蓋使用者最常看到的
// 主要文案（拖曳區、啟動中、Auto Close、Running Projects、警示訊息等），
// 在 Settings 裡切換語言時即時生效，不需要重開 App。
enum AppLanguage: String {
    case zh, en

    static var current: AppLanguage {
        get { AppLanguage(rawValue: UserDefaults.standard.string(forKey: "smartlaunch.language") ?? "zh") ?? .zh }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "smartlaunch.language") }
    }
}

private let localizedStrings: [String: [AppLanguage: String]] = [
    "tagline": [.zh: "別管指令，直接開工", .en: "Skip the commands, get to work."],
    "drop.title": [.zh: "把專案資料夾拖到這裡", .en: "Drop your project folder here"],
    "drop.subtitle": [.zh: "不用記指令，我來判斷", .en: "No commands to remember, I'll figure it out"],
    "drop.button": [.zh: "選擇資料夾", .en: "Choose Folder"],
    "drop.doodle": [.zh: "drag it!", .en: "drag it!"],
    "drop.hover.title": [.zh: "drop it here", .en: "drop it here"],
    "drop.hover.subtitle": [.zh: "我接住了！", .en: "Got it!"],
    "drop.hover.doodle": [.zh: "gimme!", .en: "gimme!"],
    "drop.lastLaunched": [.zh: "上次啟動：", .en: "Last launched: "],
    "launch.title": [.zh: "正在分析專案", .en: "Analyzing project"],
    "launch.subtitle": [.zh: "看看這個資料夾裡藏了什麼", .en: "Let's see what's in this folder"],
    "launch.doodle": [.zh: "digging⋯", .en: "digging⋯"],
    "launch.cancel": [.zh: "先不等了", .en: "Never mind"],
    "empty.title": [.zh: "目前沒有專案在跑", .en: "Nothing running right now"],
    "autoclose.title": [.zh: "自動關閉", .en: "Auto Close"],
    "autoclose.subtitle": [.zh: "閒置專案將自動關閉", .en: "Idle projects will close automatically"],
    "running.title": [.zh: "執行中的專案", .en: "Running Projects"],
    "running.killAll": [.zh: "全部關閉", .en: "Stop All"],
    "settings.title": [.zh: "設定", .en: "Settings"],
    "settings.general": [.zh: "一般", .en: "General"],
    "settings.about": [.zh: "關於", .en: "About"],
    "settings.story": [.zh: "故事", .en: "Story"],
    "story.heading": [.zh: "為什麼做這個 App？", .en: "Why I made this app"],
    "story.p1": [.zh: "我不是專業開發者。Vibe coding 做久了，專案越來越多，啟動指令記不住，連 localhost 開了哪些也常常搞不清楚。", .en: "I'm not a professional developer. After a lot of vibe coding, I ended up with more and more projects, couldn't remember the start commands, and kept losing track of which localhost ports were even running."],
    "story.p2": [.zh: "我又不想每次只是為了重新把專案跑起來，就再問一次 AI。", .en: "And I didn't want to ask an AI all over again just to get a project running."],
    "story.p3": [.zh: "所以做了 mole。把資料夾丟進來，剩下交給它。", .en: "So I made mole. Drop in the folder, and it takes care of the rest."],
    "story.closing": [.zh: "別管指令，直接開工。", .en: "Skip the commands, get to work."],
    "settings.language": [.zh: "語言", .en: "Language"],
    "settings.github": [.zh: "在 GitHub 上查看", .en: "View on GitHub"],
    "settings.license": [.zh: "MIT 授權", .en: "MIT License"],
    "alert.stop.confirm": [.zh: "關閉", .en: "Stop"],
    "alert.cancel": [.zh: "取消", .en: "Cancel"],
    "alert.stopTitle": [.zh: "關閉 localhost:%@？", .en: "Stop localhost:%@?"],
    "alert.killAllTitle": [.zh: "全部關閉？", .en: "Stop all?"],
    "alert.killAllMessage": [.zh: "會關閉 %d 個開發伺服器（localhost:%@)。", .en: "This will stop %d dev server(s) (localhost:%@)."],
    "alert.killAllSkipped": [.zh: "\n有標記「常駐」的 %d 個服務不會被關閉。", .en: "\n%d pinned service(s) marked Keep Alive won't be stopped."],
    "pin.tooltip": [.zh: "常駐：不會被自動過期關閉", .en: "Keep Alive: won't be closed automatically"],
    "project.pinned": [.zh: "常駐中", .en: "pinned"],
    "expire.30m": [.zh: "30 分鐘", .en: "30 min"],
    "expire.1h": [.zh: "1 小時", .en: "1 hour"],
    "expire.2h": [.zh: "2 小時（預設）", .en: "2 hours (default)"],
    "expire.4h": [.zh: "4 小時", .en: "4 hours"],
    "expire.never": [.zh: "停用自動過期", .en: "Never"],
]

func t(_ key: String) -> String {
    localizedStrings[key]?[AppLanguage.current] ?? key
}

// MARK: - Design tokens

// 可愛版色票，直接對應 Figma 參考稿（mole-ui-spec）裡的 --color-* token，
// 保留原本 warm off-white 的基調，只是把飽和度、對比都調得更軟一點。
extension NSColor {
    static let plWindowBg = NSColor(calibratedRed: 0.969, green: 0.957, blue: 0.941, alpha: 1)     // #f7f4f0 bg
    static let plHeroBg = NSColor(calibratedRed: 0.992, green: 0.988, blue: 0.984, alpha: 1)        // #fdfcfb surface
    static let plRowBg = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 1)               // #ffffff card
    static let plRowBgMuted = NSColor(calibratedRed: 0.953, green: 0.937, blue: 0.914, alpha: 1)    // muted warm card
    static let plTextPrimary = NSColor(calibratedRed: 0.110, green: 0.090, blue: 0.090, alpha: 1)   // #1c1917
    static let plTextSecondary = NSColor(calibratedRed: 0.471, green: 0.443, blue: 0.424, alpha: 1) // #78716c
    static let plTextTertiary = NSColor(calibratedRed: 0.659, green: 0.635, blue: 0.620, alpha: 1)  // #a8a29e
    static let plDanger = NSColor(calibratedRed: 0.878, green: 0.439, blue: 0.439, alpha: 1)        // #e07070
    static let plLocalhostText = NSColor(calibratedRed: 0.263, green: 0.373, blue: 0.463, alpha: 1) // darker blue-folder
    static let plUpdateBg = NSColor(calibratedRed: 0.996, green: 0.976, blue: 0.816, alpha: 1)      // #fef9d0 accent-light
    static let plUpdateText = NSColor(calibratedRed: 0.545, green: 0.427, blue: 0.031, alpha: 1)    // dark butter
    static let plPrimaryButtonBg = NSColor(calibratedRed: 0.996, green: 0.976, blue: 0.816, alpha: 1) // #fef9d0
    static let plBorder = NSColor(calibratedRed: 0.910, green: 0.886, blue: 0.855, alpha: 1)        // #e8e2da
    static let plAccent = NSColor(calibratedRed: 0.961, green: 0.835, blue: 0.278, alpha: 1)        // #f5d547 butter yellow
    static let plBlueFolder = NSColor(calibratedRed: 0.569, green: 0.706, blue: 0.831, alpha: 1)    // #91b4d4
    static let plBlueFolderLight = NSColor(calibratedRed: 0.855, green: 0.918, blue: 0.969, alpha: 1) // #daeaf7
}

// MARK: - Small reusable AppKit helpers

// 承載一個圓角卡片背景的 view，取代 SwiftUI 的 RoundedRectangle().fill()
final class RoundedCardView: NSView {
    init(cornerRadius: CGFloat, fill: NSColor, borderColor: NSColor? = nil) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        layer?.backgroundColor = fill.cgColor
        if let borderColor = borderColor {
            layer?.borderColor = borderColor.cgColor
            layer?.borderWidth = 1
        }
        translatesAutoresizingMaskIntoConstraints = false
    }
    required init?(coder: NSCoder) { fatalError() }
}

// 用來承接 click 的按鈕，統一走 closure 而不是 target/action selector 樣板
class ClosureButton: NSButton {
    private var onClick: (() -> Void)?

    convenience init(onClick: @escaping () -> Void) {
        self.init(frame: .zero)
        self.onClick = onClick
        target = self
        action = #selector(handleClick)
        translatesAutoresizingMaskIntoConstraints = false
    }

    @objc private func handleClick() { onClick?() }
}

// 讓一整塊區域（標題、資料夾圖示、網址……）都能點擊觸發同一個動作，取代
// 原本只有一顆小小的 Open 按鈕才能點。故意繼承 NSButton 而不是用純 NSView
// 覆寫 mouseUp——NSTableView 的列本身會攔截 mouseDown 做選取處理，一般
// NSView 收不到點擊，只有真正的 NSControl／NSButton 才能可靠地在表格列
// 裡吃到點擊（跟已經驗證過會動的 pin/stop 圖示鈕是同一套機制）。
final class ClickableRegionView: NSButton {
    private var onClick: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        isBordered = false
        bezelStyle = .inline
        title = ""
        target = self
        action = #selector(handleClick)
    }
    required init?(coder: NSCoder) { fatalError() }

    func setOnClick(_ handler: @escaping () -> Void) {
        onClick = handler
    }

    @objc private func handleClick() { onClick?() }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

// 拖曳資料夾進來的區域：純 AppKit 的 NSDraggingDestination 實作，
// 取代原本 SwiftUI 的 .onDrop，懸浮時用 layer 邊框做提示。
final class DropZoneView: NSView {
    var onDrop: ((URL) -> Void)?
    // 讓外層可以在懸浮/離開時换插畫、換文案、換配色，而不用整個重建。
    var onHoverChange: ((Bool) -> Void)?
    private var isHovering = false {
        didSet {
            updateBorder()
            onHoverChange?(isHovering)
        }
    }
    private let dashLayer = CAShapeLayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 24
        layer?.backgroundColor = NSColor.plHeroBg.cgColor

        // 平常就有一圈很淡的虛線邊框（spec 裡的 dashed border），拖曳懸浮時才變成
        // 實線的 accent 黃色，讓使用者一眼知道「這裡可以放」。
        dashLayer.fillColor = nil
        dashLayer.strokeColor = NSColor(calibratedRed: 0.839, green: 0.800, blue: 0.749, alpha: 1).cgColor
        dashLayer.lineWidth = 1.5
        dashLayer.lineDashPattern = [6, 5]
        layer?.addSublayer(dashLayer)

        registerForDraggedTypes([.fileURL])
        updateBorder()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let inset: CGFloat = 1
        dashLayer.frame = bounds
        dashLayer.path = CGPath(roundedRect: bounds.insetBy(dx: inset, dy: inset), cornerWidth: 24 - inset, cornerHeight: 24 - inset, transform: nil)
    }

    private func updateBorder() {
        dashLayer.strokeColor = isHovering
            ? NSColor.plAccent.cgColor
            : NSColor(calibratedRed: 0.839, green: 0.800, blue: 0.749, alpha: 1).cgColor
        dashLayer.lineWidth = isHovering ? 2 : 1.5
        layer?.backgroundColor = isHovering
            ? NSColor(calibratedRed: 0.996, green: 0.992, blue: 0.961, alpha: 1).cgColor
            : NSColor.plHeroBg.cgColor
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        isHovering = true
        return .copy
    }
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isHovering = false
    }
    override func draggingEnded(_ sender: NSDraggingInfo) {
        isHovering = false
    }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isHovering = false
        guard let items = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              let url = items.first else { return false }
        onDrop?(url)
        return true
    }
}

// 偵測/啟動中顯示的鼴鼠挖土動畫：一組 6 張手繪序列格，用 Timer 輪播模擬 GIF。
final class MoleDigAnimationView: NSImageView {
    private var frames: [NSImage] = []
    private var frameIndex = 0
    private var timer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        frames = (0...5).compactMap { moleImage("dig-anim-\($0)") }
        imageScaling = .scaleProportionallyUpOrDown
        if let first = frames.first { image = first }
    }
    required init?(coder: NSCoder) { fatalError() }

    func startAnimating() {
        stopAnimating()
        guard !frames.isEmpty else { return }
        let t = Timer(timeInterval: 0.18, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.frameIndex = (self.frameIndex + 1) % self.frames.count
            self.image = self.frames[self.frameIndex]
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
    func stopAnimating() {
        timer?.invalidate()
        timer = nil
    }
    deinit { timer?.invalidate() }
}

// 主要操作按鈕（選擇資料夾）的 soft filled 外觀
// 主要操作用的黑色藥丸按鈕（例如「選擇資料夾」「Open」），對應參考稿裡
// bg-[#1c1917] text-white 那個按鈕樣式。
final class PillButton: ClosureButton {
    override init(frame: NSRect) {
        super.init(frame: frame)
    }
    convenience init(title: String, fontSize: CGFloat = 12, onClick: @escaping () -> Void) {
        self.init(onClick: onClick)
        isBordered = false
        wantsLayer = true
        layer?.backgroundColor = NSColor.plTextPrimary.cgColor
        attributedTitle = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: NSColor.white
        ])
        contentTintColor = .white
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        layer?.cornerRadius = bounds.height / 2
    }
}

// 小圓角色塊標籤，對應參考稿的 Badge（框架名稱、process name 這類小標籤）。
func makeBadge(_ text: String, bg: NSColor, fg: NSColor) -> NSView {
    let label = NSTextField(labelWithString: text)
    label.font = NSFont.systemFont(ofSize: 10, weight: .medium)
    label.textColor = fg
    label.translatesAutoresizingMaskIntoConstraints = false

    let card = RoundedCardView(cornerRadius: 5, fill: bg)
    card.addSubview(label)
    NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 6),
        label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -6),
        label.topAnchor.constraint(equalTo: card.topAnchor, constant: 2),
        label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -2)
    ])
    return card
}

// 一個會輕輕脈動的綠色小圓點 + "Running" 文字，標示服務正在運行中。
final class RunningIndicatorView: NSView {
    private let dot = NSView()

    override init(frame: NSRect) {
        super.init(frame: frame)
    }

    convenience init() {
        self.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        dot.wantsLayer = true
        dot.layer?.cornerRadius = 3
        dot.layer?.backgroundColor = NSColor(calibratedRed: 0.525, green: 0.788, blue: 0.541, alpha: 1).cgColor
        dot.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(labelWithString: "Running")
        label.font = NSFont.systemFont(ofSize: 11)
        label.textColor = NSColor(calibratedRed: 0.227, green: 0.486, blue: 0.251, alpha: 1)

        let stack = NSStackView(views: [dot, label])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1.0
        pulse.toValue = 0.35
        pulse.duration = 1.0
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        dot.layer?.add(pulse, forKey: "pulse")
    }
    required init?(coder: NSCoder) { fatalError() }
}

// 一個 12x12 的圓角灰底小圈點，永遠放在文字之間當分隔符。
func dotSeparator() -> NSView {
    let label = NSTextField(labelWithString: "·")
    label.font = NSFont.systemFont(ofSize: 11)
    label.textColor = .plBorder
    return label
}

// 拖曳區右上角那道手繪感的小箭頭，純用 CAShapeLayer 畫貝茲曲線。
final class HandDrawnArrowView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }
    required init?(coder: NSCoder) { fatalError() }

    var strokeColor: NSColor = .plTextTertiary {
        didSet { needsLayout = true }
    }

    override func layout() {
        super.layout()
        layer?.sublayers?.removeAll()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: bounds.width - 4, y: bounds.height - 2))
        path.addCurve(
            to: CGPoint(x: 4, y: 4),
            control1: CGPoint(x: bounds.width - 18, y: bounds.height - 2),
            control2: CGPoint(x: 14, y: 16)
        )
        let shaft = CAShapeLayer()
        shaft.path = path
        shaft.strokeColor = strokeColor.cgColor
        shaft.fillColor = nil
        shaft.lineWidth = 1.5
        shaft.lineCap = .round
        layer?.addSublayer(shaft)

        let head = CGMutablePath()
        head.move(to: CGPoint(x: 4, y: 4))
        head.addLine(to: CGPoint(x: 9, y: 9))
        head.move(to: CGPoint(x: 4, y: 4))
        head.addLine(to: CGPoint(x: 10, y: 3))
        let headLayer = CAShapeLayer()
        headLayer.path = head
        headLayer.strokeColor = strokeColor.cgColor
        headLayer.fillColor = nil
        headLayer.lineWidth = 1.5
        headLayer.lineCap = .round
        layer?.addSublayer(headLayer)
    }
}

// MARK: - Ports table (pure AppKit)
//
// 這個清單過去用 SwiftUI 的 List/ForEach 實作，是更新頻率最高的畫面內容；後來發現
// 就算把它單獨換成 NSTableView，閃退仍會在完全空白、還沒渲染任何 port 資料的
// NSHostingView.beginTransaction() 第一次掛載時發生——代表問題不在這個清單本身，
// 而是這台機器上 SwiftUI/AttributeGraph 引擎本身的問題。所以最終整個視窗內容
// 都改用純 AppKit 手刻，完全不再建立任何 NSHostingController/NSHostingView。
final class PortsTableController: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    weak var tableView: NSTableView?

    var devPorts: [PortInfo] = []
    var persistentPorts: Set<String> = []
    var projectNames: [String: String] = [:]
    var siteTitles: [String: String] = [:]
    var siteFavicons: [String: NSImage] = [:]

    var onOpen: ((String) -> Void)?
    var onTogglePersistent: ((String) -> Void)?
    var onStop: ((PortInfo) -> Void)?

    private enum RowItem {
        case empty
        case project(PortInfo)
    }
    private var rows: [RowItem] = []

    // System services 清單拿掉了：使用者反正也關不掉那些系統背景服務，
    // 顯示一堆看了也不能做什麼的東西只是雜訊，不如只留使用者真正在乎的
    // 自己啟動的開發專案。
    func reload() {
        var r: [RowItem] = []
        if devPorts.isEmpty {
            r.append(.empty)
        } else {
            for info in devPorts { r.append(.project(info)) }
        }
        rows = r
        tableView?.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool { false }

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool { false }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch rows[row] {
        case .empty: return 130
        case .project: return 68
        }
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch rows[row] {
        case .empty:
            return makeEmptyRow()
        case .project(let info):
            let isFirst = !rows[0..<row].contains { if case .project = $0 { return true } else { return false } }
            return makeProjectRow(info, showMascot: isFirst)
        }
    }

    private func makeEmptyRow() -> NSView {
        let wrapper = NSView()

        let mound = NSImageView(image: moleImage("mound") ?? NSImage())
        mound.imageScaling = .scaleProportionallyUpOrDown
        mound.translatesAutoresizingMaskIntoConstraints = false
        mound.widthAnchor.constraint(equalToConstant: 92).isActive = true
        mound.heightAnchor.constraint(equalToConstant: 70).isActive = true

        let label = NSTextField(labelWithString: t("empty.title"))
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = .plTextTertiary
        label.alignment = .center

        let zzz = NSTextField(labelWithString: "zzz⋯")
        zzz.font = NSFont(name: "Noteworthy", size: 13) ?? NSFont.systemFont(ofSize: 12, weight: .medium)
        zzz.textColor = .plTextTertiary.withAlphaComponent(0.8)
        zzz.alignment = .center

        let stack = NSStackView(views: [mound, label, zzz])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor)
        ])
        return wrapper
    }

    private func makeProjectRow(_ info: PortInfo, showMascot: Bool) -> NSView {
        let wrapper = NSView()

        let card = RoundedCardView(cornerRadius: 14, fill: .plRowBg, borderColor: .plBorder)
        wrapper.addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            card.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 4),
            card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -4)
        ])

        // 資料夾圖示色塊，取代原本沒有任何識別物的純文字列；如果這個服務不是
        // 我們啟動的、但抓得到它自己網頁的 favicon，就直接顯示那個 favicon，
        // 比一個泛用的資料夾圖示更能讓人一眼認出「這是哪個網站」。
        let folderChip = RoundedCardView(cornerRadius: 9, fill: .plBlueFolderLight)
        let favicon = siteFavicons[info.port]
        let folderIcon = NSImageView(image: favicon ?? NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil) ?? NSImage())
        if favicon == nil {
            folderIcon.contentTintColor = .plBlueFolder
            folderIcon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        }
        folderIcon.imageScaling = .scaleProportionallyUpOrDown
        folderIcon.translatesAutoresizingMaskIntoConstraints = false
        folderChip.addSubview(folderIcon)
        let iconSize: CGFloat = favicon == nil ? 18 : 22
        NSLayoutConstraint.activate([
            folderChip.widthAnchor.constraint(equalToConstant: 34),
            folderChip.heightAnchor.constraint(equalToConstant: 34),
            folderIcon.widthAnchor.constraint(equalToConstant: iconSize),
            folderIcon.heightAnchor.constraint(equalToConstant: iconSize),
            folderIcon.centerXAnchor.constraint(equalTo: folderChip.centerXAnchor),
            folderIcon.centerYAnchor.constraint(equalTo: folderChip.centerYAnchor)
        ])

        // 名稱優先顯示我們自己啟動時記住的專案（資料夾）名稱；不是我們啟動的
        // 就試著用抓到的網頁 <title>，再不然才退回顯示 process 名稱。
        let displayName = projectNames[info.port] ?? siteTitles[info.port] ?? info.processName
        let isPinned = persistentPorts.contains(info.port)

        let nameLabel = NSTextField(labelWithString: displayName)
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = .plTextPrimary
        nameLabel.lineBreakMode = .byTruncatingTail
        // 長標題（例如抓到的網頁 <title>）如果不強制壓縮，會把整排往右推、
        // 連帶讓 pin/stop 圖示位置跟著跑掉，不同卡片對不齊。降低抗壓縮優先權，
        // 讓它該截斷就截斷，位置固定不會受標題長度影響。
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.cell?.truncatesLastVisibleLine = true
        // 上面那個優先權只對 nameLabel 自己有效，不會往上傳到包著它的 nameRow／
        // textStack 這兩層 NSStackView（它們有自己的壓縮抵抗優先權，預設偏高）。
        // 結果就是長標題那排，clickRegion 的寬度計算被這兩層「打折扣」，導致
        // rightStack 的實際位置跟著跑掉。直接把 nameLabel 釘死在 clickRegion 的
        // 右邊界，跳過中間兩層 stack 的模糊地帶，才能保證每排都截斷在同一個點。
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        var nameRowViews: [NSView] = [nameLabel]
        if isPinned {
            nameRowViews.append(makeBadge(t("project.pinned"), bg: NSColor.plBorder.withAlphaComponent(0.5), fg: .plTextSecondary))
        }
        let nameRow = NSStackView(views: nameRowViews)
        nameRow.orientation = .horizontal
        nameRow.alignment = .centerY
        nameRow.spacing = 6

        let urlButton = ClosureButton(onClick: { [weak self] in
            self?.onOpen?(info.port)
        })
        urlButton.attributedTitle = NSAttributedString(
            string: "localhost:\(info.port)",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.plBlueFolder
            ]
        )
        urlButton.isBordered = false
        urlButton.bezelStyle = .inline
        urlButton.contentTintColor = .plBlueFolder
        urlButton.toolTip = "\(info.uptime)\n\(info.command)"

        let processBadge = makeBadge(info.processName, bg: .plRowBgMuted, fg: .plTextSecondary)
        let runningIndicator = RunningIndicatorView()
        let durationLabel = NSTextField(labelWithString: shortUptime(info.uptimeSeconds))
        durationLabel.font = NSFont.systemFont(ofSize: 11)
        durationLabel.textColor = .plTextTertiary

        let metaRow = NSStackView(views: [urlButton, dotSeparator(), processBadge, dotSeparator(), runningIndicator, dotSeparator(), durationLabel])
        metaRow.orientation = .horizontal
        metaRow.alignment = .centerY
        metaRow.spacing = 6

        let textStack = NSStackView(views: [nameRow, metaRow])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        // 常駐（Keep Alive）改回一個外露的星星圖示鈕，不要藏進選單裡——
        // 使用者明確說希望常駐這個功能是看得到、按得到的，不是要點兩下選單才找得到。
        let pinButton = ClosureButton(onClick: { [weak self] in
            self?.onTogglePersistent?(info.port)
        })
        pinButton.image = NSImage(systemSymbolName: isPinned ? "star.fill" : "star", accessibilityDescription: "常駐")
        pinButton.isBordered = false
        pinButton.bezelStyle = .inline
        pinButton.contentTintColor = isPinned ? .plAccent : .plTextTertiary
        pinButton.toolTip = t("pin.tooltip")
        pinButton.widthAnchor.constraint(equalToConstant: 22).isActive = true
        pinButton.heightAnchor.constraint(equalToConstant: 22).isActive = true

        // Stop 也是外露的圖示鈕（跟 pin 並排），不用再點開選單才找得到。
        let stopButton = ClosureButton(onClick: { [weak self] in
            self?.onStop?(info)
        })
        stopButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Stop")
        stopButton.imageScaling = .scaleProportionallyDown
        stopButton.isBordered = false
        stopButton.bezelStyle = .inline
        stopButton.contentTintColor = .plDanger
        stopButton.toolTip = "Stop"
        stopButton.widthAnchor.constraint(equalToConstant: 22).isActive = true
        stopButton.heightAnchor.constraint(equalToConstant: 22).isActive = true

        let rightStack = NSStackView(views: [pinButton, stopButton])
        rightStack.orientation = .horizontal
        rightStack.alignment = .centerY
        rightStack.spacing = 10
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        // 拿掉單獨的 Open 按鈕，改成整個左側區域（圖示、標題、網址）都能點擊
        // 開瀏覽器——按鈕還是比純文字好按，但沒必要非得瞄準一顆小按鈕不可。
        let clickRegion = ClickableRegionView()
        clickRegion.setOnClick { [weak self] in self?.onOpen?(info.port) }
        clickRegion.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(clickRegion)
        clickRegion.addSubview(folderChip)
        clickRegion.addSubview(textStack)
        card.addSubview(rightStack)
        NSLayoutConstraint.activate([
            clickRegion.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            clickRegion.topAnchor.constraint(equalTo: card.topAnchor),
            clickRegion.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            clickRegion.trailingAnchor.constraint(equalTo: rightStack.leadingAnchor, constant: -14),

            folderChip.leadingAnchor.constraint(equalTo: clickRegion.leadingAnchor, constant: 12),
            folderChip.centerYAnchor.constraint(equalTo: clickRegion.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: folderChip.trailingAnchor, constant: 10),
            textStack.centerYAnchor.constraint(equalTo: clickRegion.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: clickRegion.trailingAnchor),
            // 直接釘住 nameLabel 本人，跳過中間 nameRow/textStack 兩層 NSStackView
            // 自己的壓縮抵抗優先權（預設偏高，會讓上面那條 <= 沒有真的生效）。
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: clickRegion.trailingAnchor, constant: -4),

            rightStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -2),
            rightStack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        // 只在第一張卡片右下角探頭一隻小鼴鼠，其餘卡片保持乾淨——
        // spec 裡特別提醒「不需要每一張 Card 都很大，不要造成資訊閱讀干擾」。
        if showMascot, let mascotImage = moleImage("peek-small") {
            let mascot = NSImageView(image: mascotImage)
            mascot.imageScaling = .scaleProportionallyUpOrDown
            mascot.translatesAutoresizingMaskIntoConstraints = false
            wrapper.addSubview(mascot)
            NSLayoutConstraint.activate([
                mascot.widthAnchor.constraint(equalToConstant: 34),
                mascot.heightAnchor.constraint(equalToConstant: 26),
                mascot.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
                mascot.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: 4)
            ])
        }

        return wrapper
    }

}

// MARK: - Settings window

final class SettingsViewController: NSViewController {
    var onLanguageChanged: (() -> Void)?
    private let tabView = NSTabView()
    private var generalItem: NSTabViewItem!
    private var storyItem: NSTabViewItem!
    private var aboutItem: NSTabViewItem!

    override func loadView() {
        let v = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 380))
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.plWindowBg.cgColor
        view = v
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabView.translatesAutoresizingMaskIntoConstraints = false

        generalItem = NSTabViewItem(identifier: "general")
        storyItem = NSTabViewItem(identifier: "story")
        aboutItem = NSTabViewItem(identifier: "about")
        tabView.addTabViewItem(generalItem)
        tabView.addTabViewItem(storyItem)
        tabView.addTabViewItem(aboutItem)
        refreshLocalizedContent()

        view.addSubview(tabView)
        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tabView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
    }

    // 語言選單就在這個視窗裡面，所以切換當下這個視窗自己的分頁標題、視窗標題、
    // 內容都要跟著重建一次，不能只靠「下次打開才是新語言」。
    private func refreshLocalizedContent() {
        view.window?.title = t("settings.title")
        generalItem.label = t("settings.general")
        generalItem.view = buildGeneralTab()
        storyItem.label = t("settings.story")
        storyItem.view = buildStoryTab()
        aboutItem.label = t("settings.about")
        aboutItem.view = buildAboutTab()
    }

    private func buildStoryTab() -> NSView {
        let container = NSView()

        let heading = NSTextField(wrappingLabelWithString: t("story.heading"))
        heading.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        heading.textColor = .plTextPrimary

        let p1 = NSTextField(wrappingLabelWithString: t("story.p1"))
        let p2 = NSTextField(wrappingLabelWithString: t("story.p2"))
        let p3 = NSTextField(wrappingLabelWithString: t("story.p3"))
        for field in [p1, p2, p3] {
            field.font = NSFont.systemFont(ofSize: 12)
            field.textColor = .plTextSecondary
        }

        let closing = NSTextField(wrappingLabelWithString: t("story.closing"))
        closing.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        closing.textColor = .plTextPrimary

        let stack = NSStackView(views: [heading, p1, p2, p3, closing])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(6, after: heading)
        stack.setCustomSpacing(18, after: p3)

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -22)
        ])
        for field in [heading, p1, p2, p3, closing] {
            field.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        return container
    }

    private func buildGeneralTab() -> NSView {
        let container = NSView()

        let label = NSTextField(labelWithString: t("settings.language"))
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = .plTextPrimary
        label.translatesAutoresizingMaskIntoConstraints = false

        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.addItem(withTitle: "繁體中文")
        popup.addItem(withTitle: "English")
        popup.selectItem(at: AppLanguage.current == .zh ? 0 : 1)
        popup.target = self
        popup.action = #selector(languageChanged(_:))
        popup.translatesAutoresizingMaskIntoConstraints = false
        popup.widthAnchor.constraint(equalToConstant: 140).isActive = true

        container.addSubview(label)
        container.addSubview(popup)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 28),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            popup.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            popup.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24)
        ])
        return container
    }

    @objc private func languageChanged(_ sender: NSPopUpButton) {
        AppLanguage.current = sender.indexOfSelectedItem == 0 ? .zh : .en
        onLanguageChanged?()
        refreshLocalizedContent()
    }

    private func buildAboutTab() -> NSView {
        let container = NSView()

        // 鼴鼠插畫當主視覺，下面配一個小小的字體 logo。
        let illustration = NSImageView(image: moleImage("about-relax") ?? NSImage())
        illustration.imageScaling = .scaleProportionallyUpOrDown
        illustration.translatesAutoresizingMaskIntoConstraints = false
        if let img = moleImage("about-relax") {
            let aspect = img.size.width / img.size.height
            illustration.heightAnchor.constraint(equalToConstant: 100).isActive = true
            illustration.widthAnchor.constraint(equalToConstant: 100 * aspect).isActive = true
        }

        let logo = NSImageView(image: moleImage("wordmark-logo") ?? NSImage())
        logo.imageScaling = .scaleProportionallyUpOrDown
        logo.translatesAutoresizingMaskIntoConstraints = false
        if let img = moleImage("wordmark-logo") {
            let aspect = img.size.width / img.size.height
            logo.heightAnchor.constraint(equalToConstant: 34).isActive = true
            logo.widthAnchor.constraint(equalToConstant: 34 * aspect).isActive = true
        }

        let centerStack = NSStackView(views: [illustration, logo])
        centerStack.orientation = .vertical
        centerStack.alignment = .centerX
        centerStack.spacing = 10
        centerStack.translatesAutoresizingMaskIntoConstraints = false

        // 左下：小一點的 GitHub 圖示 + 版本號。
        let githubButton = ClosureButton(onClick: {
            if let url = URL(string: "https://github.com/ST6AR1/smart-launch") {
                NSWorkspace.shared.open(url)
            }
        })
        githubButton.isBordered = false
        githubButton.bezelStyle = .inline
        githubButton.imageScaling = .scaleProportionallyDown
        if let path = Bundle.main.path(forResource: "github-mark", ofType: "png"),
           let nsImage = NSImage(contentsOfFile: path) {
            nsImage.isTemplate = true
            githubButton.image = nsImage
        } else {
            githubButton.image = NSImage(systemSymbolName: "chevron.left.forwardslash.chevron.right", accessibilityDescription: nil)
        }
        githubButton.contentTintColor = .plTextTertiary
        githubButton.toolTip = "GitHub"
        githubButton.widthAnchor.constraint(equalToConstant: 15).isActive = true
        githubButton.heightAnchor.constraint(equalToConstant: 15).isActive = true

        let versionLabel = NSTextField(labelWithString: "v\(currentVersion)")
        versionLabel.font = NSFont.systemFont(ofSize: 10)
        versionLabel.textColor = .plTextTertiary

        let bottomLeft = NSStackView(views: [githubButton, versionLabel])
        bottomLeft.orientation = .horizontal
        bottomLeft.alignment = .centerY
        bottomLeft.spacing = 5

        // 右下：署名，顏文字保留、不跟著語言切換翻譯。
        let creditLabel = NSTextField(labelWithString: "由 溫 Wen 和 Claude 協同製作 ⌯^⦁𖥦⦁^⌯")
        creditLabel.font = NSFont.systemFont(ofSize: 10)
        creditLabel.textColor = .plTextTertiary

        let bottomRow = NSStackView(views: [bottomLeft, NSView(), creditLabel])
        bottomRow.orientation = .horizontal
        bottomRow.alignment = .centerY
        bottomRow.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(centerStack)
        container.addSubview(bottomRow)
        NSLayoutConstraint.activate([
            centerStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -14),

            bottomRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            bottomRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            bottomRow.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        return container
    }
}

// MARK: - Main window content (pure AppKit, no SwiftUI anywhere)

final class MainViewController: NSViewController {
    // MARK: State
    private var ports: [PortInfo] = []
    private var isRefreshing = false
    private var lastLaunched = ""
    // 記住「這個 session 裡我們自己啟動的 port 對應哪個資料夾名稱」，讓 Running
    // Projects 卡片能顯示真正的專案名稱而不是只有 process 名稱；重開 App 前就啟動
    // 好、我們沒參與偵測的 port 沒有這筆資料，卡片會退回顯示 process 名稱。
    private var launchedProjectNames: [String: String] = [:]
    // 對於不是我們自己啟動的服務（例如開 App 前就在跑的），試著把它自己
    // 網頁的 <title> 跟 favicon 抓回來，卡片才不會全部都只顯示乾巴巴的 "node"。
    // 一個 port 只抓一次，抓過（不管成功失敗）就不會重試，避免每次 refresh 都打。
    private var fetchedSiteTitles: [String: String] = [:]
    private var fetchedFavicons: [String: NSImage] = [:]
    private var siteInfoFetchAttempted: Set<String> = []
    private var autoExpiredNotice = ""
    private var isLaunching = false
    private var launchStatus = ""
    private var pollToken = UUID()
    private var updateAvailable: UpdateInfo?
    private var isUpdating = false
    private var updateStatus = ""

    private var persistentPortsRaw: String {
        get { UserDefaults.standard.string(forKey: "smartlaunch.persistentPorts") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "smartlaunch.persistentPorts") }
    }
    private var expireMinutes: Int {
        get {
            if UserDefaults.standard.object(forKey: "smartlaunch.expireMinutes") == nil { return 120 }
            return UserDefaults.standard.integer(forKey: "smartlaunch.expireMinutes")
        }
        set { UserDefaults.standard.set(newValue, forKey: "smartlaunch.expireMinutes") }
    }
    private var persistentPorts: Set<String> {
        Set(persistentPortsRaw.split(separator: ",").map(String.init))
    }
    private var devPorts: [PortInfo] { ports.filter { $0.isDev } }

    private var refreshTimer: Timer?

    // MARK: Views
    private let toolbarHost = NSView()
    private weak var taglineLabel: NSTextField?
    private var settingsWindow: NSWindow?
    private let topStack = NSStackView()
    private let updateBannerHost = NSView()
    private let heroCardHost = NSView()
    private let autoCloseHost = NSView()
    private let runningHeaderHost = NSView()
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let portsTable = PortsTableController()
    private var expirePopup: NSPopUpButton!

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.plWindowBg.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        refresh()
        checkForUpdate { [weak self] info in
            DispatchQueue.main.async {
                self?.updateAvailable = info
                self?.rebuildUpdateBanner()
            }
        }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    // MARK: Layout

    private func buildLayout() {
        topStack.orientation = .vertical
        topStack.alignment = .leading
        topStack.spacing = 16
        topStack.translatesAutoresizingMaskIntoConstraints = false

        // Toolbar 是獨立於內容區的一條列（貼齊視窗兩側，下面一條細分隔線），
        // 不是內容區裡的第一段——這樣看起來才像 desktop app 的 toolbar，
        // 而不是網頁的 navbar 縮在內容欄裡。
        toolbarHost.translatesAutoresizingMaskIntoConstraints = false
        let headerContent = buildHeader()
        headerContent.translatesAutoresizingMaskIntoConstraints = false
        toolbarHost.addSubview(headerContent)
        let toolbarSeparator = NSView()
        toolbarSeparator.wantsLayer = true
        toolbarSeparator.layer?.backgroundColor = NSColor.plBorder.cgColor
        toolbarSeparator.translatesAutoresizingMaskIntoConstraints = false
        toolbarHost.addSubview(toolbarSeparator)
        NSLayoutConstraint.activate([
            headerContent.topAnchor.constraint(equalTo: toolbarHost.topAnchor, constant: 14),
            headerContent.leadingAnchor.constraint(equalTo: toolbarHost.leadingAnchor, constant: 20),
            headerContent.trailingAnchor.constraint(equalTo: toolbarHost.trailingAnchor, constant: -20),
            headerContent.bottomAnchor.constraint(equalTo: toolbarSeparator.topAnchor, constant: -12),
            toolbarSeparator.heightAnchor.constraint(equalToConstant: 1),
            toolbarSeparator.leadingAnchor.constraint(equalTo: toolbarHost.leadingAnchor),
            toolbarSeparator.trailingAnchor.constraint(equalTo: toolbarHost.trailingAnchor),
            toolbarSeparator.bottomAnchor.constraint(equalTo: toolbarHost.bottomAnchor)
        ])

        topStack.addArrangedSubview(updateBannerHost)
        topStack.addArrangedSubview(heroCardHost)
        topStack.addArrangedSubview(autoCloseHost)
        topStack.addArrangedSubview(runningHeaderHost)

        for host in [updateBannerHost, heroCardHost, autoCloseHost, runningHeaderHost] {
            host.translatesAutoresizingMaskIntoConstraints = false
            host.widthAnchor.constraint(equalTo: topStack.widthAnchor).isActive = true
        }

        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .none
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.rowSizeStyle = .custom
        tableView.gridStyleMask = []
        tableView.style = .plain
        tableView.usesAlternatingRowBackgroundColors = false
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("main"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.dataSource = portsTable
        tableView.delegate = portsTable
        portsTable.tableView = tableView
        portsTable.onOpen = { [weak self] port in self?.openBrowser(port: port) }
        portsTable.onTogglePersistent = { [weak self] port in self?.togglePersistent(port) }
        portsTable.onStop = { [weak self] info in self?.confirmStop(info) }

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // 原本主畫面底部的署名/GitHub/授權那排 footer 拿掉了，內容併進 Settings
        // 的「關於」分頁——那裡才是使用者會去找這些資訊的地方，主畫面不需要。
        view.addSubview(toolbarHost)
        view.addSubview(topStack)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            toolbarHost.topAnchor.constraint(equalTo: view.topAnchor),
            toolbarHost.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarHost.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            topStack.topAnchor.constraint(equalTo: toolbarHost.bottomAnchor, constant: 16),
            topStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])

        rebuildUpdateBanner()
        rebuildHeroCard()
        rebuildAutoClose()
        rebuildRunningHeader()
        syncPortsTable()
    }

    // Desktop app 的 toolbar，不是網頁 navbar：logo 跟 tagline 水平並排在同一條基準線上，
    // 右邊放一個一般的 icon+text pill 按鈕，整條列貼著視窗兩側、下面有分隔線
    // （分隔線在 buildLayout 裡的 toolbarHost 加）。
    private func buildHeader() -> NSView {
        let titleImage = NSImageView(image: moleImage("wordmark-logo") ?? NSImage())
        titleImage.imageScaling = .scaleProportionallyUpOrDown
        titleImage.translatesAutoresizingMaskIntoConstraints = false
        if let logo = moleImage("wordmark-logo") {
            let aspect = logo.size.width / logo.size.height
            titleImage.heightAnchor.constraint(equalToConstant: 46).isActive = true
            titleImage.widthAnchor.constraint(equalToConstant: 46 * aspect).isActive = true
        }

        let tagline = NSTextField(labelWithString: t("tagline"))
        tagline.font = NSFont.systemFont(ofSize: 10)
        tagline.textColor = .plTextTertiary
        taglineLabel = tagline

        let leftStack = NSStackView(views: [titleImage, tagline])
        leftStack.orientation = .horizontal
        leftStack.alignment = .centerY
        leftStack.spacing = 9

        // GitHub 連結移進 Settings 的「關於」分頁；這裡右上角改成一隻抱著
        // 扳手的鼴鼠，點下去開 Settings 視窗（語言切換等設定都在裡面）。
        let settingsButton = ClosureButton(onClick: { [weak self] in self?.showSettings() })
        settingsButton.isBordered = false
        settingsButton.bezelStyle = .inline
        settingsButton.toolTip = t("settings.title")
        settingsButton.imageScaling = .scaleProportionallyUpOrDown
        settingsButton.image = moleImage("wrench")
        settingsButton.widthAnchor.constraint(equalToConstant: 34).isActive = true
        settingsButton.heightAnchor.constraint(equalToConstant: 34).isActive = true

        let row = NSStackView(views: [leftStack, NSView(), settingsButton])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.distribution = .fill
        row.setHuggingPriority(.defaultLow, for: .horizontal)
        return row
    }

    // MARK: Settings

    // 每次打開都重建，不快取視窗——不然語言切換後，Tab 標題、視窗標題這些在
    // viewDidLoad 當下就寫死文字的地方，下次打開還是會停在切換前的語言。
    private func showSettings() {
        settingsWindow?.close()
        let vc = SettingsViewController()
        vc.onLanguageChanged = { [weak self] in self?.applyLanguageChange() }
        let win = NSWindow(contentViewController: vc)
        win.styleMask = [.titled, .closable]
        win.title = t("settings.title")
        win.isReleasedWhenClosed = false
        settingsWindow = win
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // 語言切換後即時套用：不用重開 App，直接把還在畫面上的動態內容重建一次。
    private func applyLanguageChange() {
        taglineLabel?.stringValue = t("tagline")
        rebuildHeroCard()
        rebuildAutoClose()
        rebuildRunningHeader()
        syncPortsTable()
    }

    // MARK: Update banner

    private func rebuildUpdateBanner() {
        updateBannerHost.subviews.forEach { $0.removeFromSuperview() }
        guard let update = updateAvailable else {
            updateBannerHost.isHidden = true
            return
        }
        updateBannerHost.isHidden = false

        let card = RoundedCardView(cornerRadius: 14, fill: .plUpdateBg)
        updateBannerHost.addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: updateBannerHost.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: updateBannerHost.trailingAnchor),
            card.topAnchor.constraint(equalTo: updateBannerHost.topAnchor),
            card.bottomAnchor.constraint(equalTo: updateBannerHost.bottomAnchor)
        ])

        if isUpdating {
            let spinner = NSProgressIndicator()
            spinner.style = .spinning
            spinner.controlSize = .small
            spinner.startAnimation(nil)
            spinner.translatesAutoresizingMaskIntoConstraints = false

            let label = NSTextField(labelWithString: updateStatus.isEmpty ? "正在更新…" : updateStatus)
            label.font = NSFont.systemFont(ofSize: 12)
            label.textColor = .plTextPrimary

            let row = NSStackView(views: [spinner, label])
            row.orientation = .horizontal
            row.spacing = 8
            row.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(row)
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
                row.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -14),
                row.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
                row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
            ])
        } else {
            let label = NSTextField(labelWithString: "🎉 有新版本 v\(update.version) 可下載")
            label.font = NSFont.systemFont(ofSize: 12)
            label.textColor = .plTextPrimary
            label.translatesAutoresizingMaskIntoConstraints = false

            let actionButton = ClosureButton(onClick: { [weak self] in
                guard let self = self else { return }
                if update.dmgURL != nil {
                    self.performUpdate(update)
                } else {
                    NSWorkspace.shared.open(update.releasePageURL)
                }
            })
            actionButton.isBordered = false
            actionButton.bezelStyle = .inline
            actionButton.attributedTitle = NSAttributedString(
                string: update.dmgURL != nil ? "立即更新" : "前往查看",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                    .foregroundColor: NSColor.plUpdateText
                ]
            )

            card.addSubview(label)
            card.addSubview(actionButton)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
                label.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                actionButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
                actionButton.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                card.topAnchor.constraint(equalTo: label.topAnchor, constant: -10),
                card.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 10)
            ])
        }
    }

    // 下載新版 DMG → 掛載 → 複製到自己現在的路徑蓋過舊版 → 卸載 → 重開新版、結束自己。
    private func performUpdate(_ update: UpdateInfo) {
        guard let dmgURL = update.dmgURL else { return }
        isUpdating = true
        updateStatus = "正在下載更新…"
        rebuildUpdateBanner()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            func fail(_ message: String) {
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isUpdating = false
                    self.updateStatus = ""
                    self.autoExpiredNotice = message
                    self.rebuildUpdateBanner()
                    self.rebuildAutoClose()
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

            DispatchQueue.main.async { self?.updateStatus = "正在安裝…"; self?.rebuildUpdateBanner() }

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

            DispatchQueue.main.async { self?.updateStatus = "正在替換舊版本…"; self?.rebuildUpdateBanner() }

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

            DispatchQueue.main.async { self?.updateStatus = "更新完成，重新啟動中…"; self?.rebuildUpdateBanner() }

            let openTask = Process()
            openTask.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            openTask.arguments = [currentAppPath]
            try? openTask.run()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                NSApp.terminate(nil)
            }
        }
    }

    // MARK: Hero card

    private func rebuildHeroCard() {
        heroCardHost.subviews.forEach { $0.removeFromSuperview() }

        let dropZone = DropZoneView(frame: .zero)
        dropZone.translatesAutoresizingMaskIntoConstraints = false
        dropZone.onDrop = { [weak self] url in
            self?.lastLaunched = url.lastPathComponent
            self?.launchAndAutoOpen(path: url.path)
        }
        heroCardHost.addSubview(dropZone)

        let shadowContainer = NSView()
        shadowContainer.wantsLayer = true
        shadowContainer.layer?.shadowOpacity = 0.06
        shadowContainer.layer?.shadowRadius = 14
        shadowContainer.layer?.shadowOffset = CGSize(width: 0, height: -4)
        shadowContainer.translatesAutoresizingMaskIntoConstraints = false
        heroCardHost.addSubview(shadowContainer, positioned: .below, relativeTo: dropZone)
        NSLayoutConstraint.activate([
            shadowContainer.leadingAnchor.constraint(equalTo: dropZone.leadingAnchor),
            shadowContainer.trailingAnchor.constraint(equalTo: dropZone.trailingAnchor),
            shadowContainer.topAnchor.constraint(equalTo: dropZone.topAnchor),
            shadowContainer.bottomAnchor.constraint(equalTo: dropZone.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            dropZone.leadingAnchor.constraint(equalTo: heroCardHost.leadingAnchor),
            dropZone.trailingAnchor.constraint(equalTo: heroCardHost.trailingAnchor),
            dropZone.topAnchor.constraint(equalTo: heroCardHost.topAnchor),
            dropZone.bottomAnchor.constraint(equalTo: heroCardHost.bottomAnchor),
            dropZone.heightAnchor.constraint(equalToConstant: isLaunching ? 250 : 224)
        ])

        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.alignment = .centerX
        contentStack.spacing = 9
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        dropZone.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: dropZone.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: dropZone.centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: dropZone.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: dropZone.trailingAnchor, constant: -24)
        ])

        if isLaunching {
            let digAnim = MoleDigAnimationView(frame: .zero)
            digAnim.translatesAutoresizingMaskIntoConstraints = false
            digAnim.widthAnchor.constraint(equalToConstant: 84).isActive = true
            digAnim.heightAnchor.constraint(equalToConstant: 68).isActive = true
            digAnim.startAnimating()

            let doodle = NSTextField(labelWithString: t("launch.doodle"))
            doodle.font = NSFont(name: "Noteworthy-Bold", size: 13) ?? NSFont.systemFont(ofSize: 12, weight: .medium)
            doodle.textColor = .plUpdateText

            let title = NSTextField(labelWithString: t("launch.title"))
            title.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
            title.textColor = .plTextPrimary

            let status = NSTextField(wrappingLabelWithString: launchStatus.isEmpty ? t("launch.subtitle") : launchStatus)
            status.font = NSFont.systemFont(ofSize: 12)
            status.textColor = .plTextSecondary
            status.alignment = .center
            status.maximumNumberOfLines = 2
            status.widthAnchor.constraint(lessThanOrEqualToConstant: 380).isActive = true

            let progress = NSProgressIndicator()
            progress.style = .bar
            progress.isIndeterminate = true
            progress.controlSize = .small
            progress.startAnimation(nil)
            progress.translatesAutoresizingMaskIntoConstraints = false
            progress.widthAnchor.constraint(equalToConstant: 160).isActive = true

            let cancelButton = ClosureButton(onClick: { [weak self] in self?.cancelWaiting() })
            cancelButton.isBordered = false
            cancelButton.bezelStyle = .inline
            cancelButton.attributedTitle = NSAttributedString(
                string: t("launch.cancel"),
                attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.plTextSecondary
                ]
            )

            contentStack.addArrangedSubview(digAnim)
            contentStack.addArrangedSubview(doodle)
            contentStack.setCustomSpacing(6, after: doodle)
            contentStack.addArrangedSubview(title)
            contentStack.addArrangedSubview(status)
            contentStack.setCustomSpacing(10, after: status)
            contentStack.addArrangedSubview(progress)
            contentStack.setCustomSpacing(6, after: progress)
            contentStack.addArrangedSubview(cancelButton)
        } else {
            let mascot = NSImageView(image: moleImage("hold-folder-idle") ?? NSImage())
            mascot.imageScaling = .scaleProportionallyUpOrDown
            mascot.translatesAutoresizingMaskIntoConstraints = false
            mascot.widthAnchor.constraint(equalToConstant: 96).isActive = true
            mascot.heightAnchor.constraint(equalToConstant: 68).isActive = true

            let title = NSTextField(labelWithString: t("drop.title"))
            title.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
            title.textColor = .plTextPrimary

            let subtitle = NSTextField(labelWithString: t("drop.subtitle"))
            subtitle.font = NSFont.systemFont(ofSize: 12)
            subtitle.textColor = .plTextSecondary

            let chooseButton = PillButton(title: t("drop.button"), onClick: { [weak self] in self?.chooseFolder() })
            chooseButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
            chooseButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 112).isActive = true

            contentStack.addArrangedSubview(mascot)
            contentStack.addArrangedSubview(title)
            contentStack.addArrangedSubview(subtitle)
            contentStack.setCustomSpacing(10, after: subtitle)
            contentStack.addArrangedSubview(chooseButton)

            if !lastLaunched.isEmpty {
                let lastLabel = NSTextField(labelWithString: t("drop.lastLaunched") + lastLaunched)
                lastLabel.font = NSFont.systemFont(ofSize: 10)
                lastLabel.textColor = .plTextTertiary
                contentStack.setCustomSpacing(8, after: chooseButton)
                contentStack.addArrangedSubview(lastLabel)
            }

            // 角落的手寫小提示 + 手繪箭頭，spec 裡唯一允許出現手寫字的地方之一。
            let doodle = NSTextField(labelWithString: t("drop.doodle"))
            doodle.font = NSFont(name: "Noteworthy-Bold", size: 14) ?? NSFont.systemFont(ofSize: 12, weight: .medium)
            doodle.textColor = .plTextTertiary
            doodle.translatesAutoresizingMaskIntoConstraints = false
            doodle.frameCenterRotation = -6

            let arrow = HandDrawnArrowView(frame: .zero)
            arrow.strokeColor = .plTextTertiary
            arrow.translatesAutoresizingMaskIntoConstraints = false

            dropZone.addSubview(arrow)
            dropZone.addSubview(doodle)
            NSLayoutConstraint.activate([
                doodle.topAnchor.constraint(equalTo: dropZone.topAnchor, constant: 14),
                doodle.trailingAnchor.constraint(equalTo: dropZone.trailingAnchor, constant: -22),
                arrow.widthAnchor.constraint(equalToConstant: 30),
                arrow.heightAnchor.constraint(equalToConstant: 22),
                arrow.topAnchor.constraint(equalTo: doodle.bottomAnchor, constant: 2),
                arrow.trailingAnchor.constraint(equalTo: dropZone.trailingAnchor, constant: -14)
            ])

            // 左下角的小腳印裝飾，很淡，只是個氣氛細節。
            if let paw = moleImage("pawprints") {
                let pawView = NSImageView(image: paw)
                pawView.imageScaling = .scaleProportionallyUpOrDown
                pawView.alphaValue = 0.35
                pawView.translatesAutoresizingMaskIntoConstraints = false
                dropZone.addSubview(pawView)
                NSLayoutConstraint.activate([
                    pawView.widthAnchor.constraint(equalToConstant: 46),
                    pawView.heightAnchor.constraint(equalToConstant: 23),
                    pawView.leadingAnchor.constraint(equalTo: dropZone.leadingAnchor, constant: 18),
                    pawView.bottomAnchor.constraint(equalTo: dropZone.bottomAnchor, constant: -14)
                ])
            }

            // 拖曳懸浮時：邊框變 accent 黃、鼴鼠換成伸手接住的姿勢、文案跟著換。
            dropZone.onHoverChange = { isHovering in
                if isHovering {
                    mascot.image = moleImage("carry-folder") ?? mascot.image
                    title.stringValue = t("drop.hover.title")
                    subtitle.stringValue = t("drop.hover.subtitle")
                    doodle.stringValue = t("drop.hover.doodle")
                    doodle.textColor = .plUpdateText
                } else {
                    mascot.image = moleImage("hold-folder-idle") ?? mascot.image
                    title.stringValue = t("drop.title")
                    subtitle.stringValue = t("drop.subtitle")
                    doodle.stringValue = t("drop.doodle")
                    doodle.textColor = .plTextTertiary
                }
            }
        }
    }

    // MARK: Auto Close row

    private func rebuildAutoClose() {
        autoCloseHost.subviews.forEach { $0.removeFromSuperview() }

        let title = NSTextField(labelWithString: t("autoclose.title"))
        title.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        title.textColor = .plTextPrimary

        let subtitle = NSTextField(labelWithString: t("autoclose.subtitle"))
        subtitle.font = NSFont.systemFont(ofSize: 11)
        subtitle.textColor = .plTextSecondary

        let textStack = NSStackView(views: [title, subtitle])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2

        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        popup.bezelStyle = .rounded
        for opt in currentExpireOptions() {
            popup.addItem(withTitle: opt.label)
        }
        if let idx = currentExpireOptions().firstIndex(where: { $0.minutes == expireMinutes }) {
            popup.selectItem(at: idx)
        }
        popup.target = self
        popup.action = #selector(expirePopupChanged(_:))
        popup.widthAnchor.constraint(equalToConstant: 130).isActive = true
        expirePopup = popup

        let row = NSStackView(views: [textStack, NSView(), popup])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.distribution = .fill

        let outer = NSStackView()
        outer.orientation = .vertical
        outer.alignment = .leading
        outer.spacing = 6
        outer.translatesAutoresizingMaskIntoConstraints = false
        outer.addArrangedSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        row.widthAnchor.constraint(equalTo: outer.widthAnchor).isActive = true

        if !autoExpiredNotice.isEmpty {
            let notice = NSTextField(wrappingLabelWithString: autoExpiredNotice)
            notice.font = NSFont.systemFont(ofSize: 10)
            notice.textColor = .plTextTertiary
            outer.addArrangedSubview(notice)
            notice.widthAnchor.constraint(equalTo: outer.widthAnchor).isActive = true
        }

        autoCloseHost.addSubview(outer)
        NSLayoutConstraint.activate([
            outer.leadingAnchor.constraint(equalTo: autoCloseHost.leadingAnchor),
            outer.trailingAnchor.constraint(equalTo: autoCloseHost.trailingAnchor),
            outer.topAnchor.constraint(equalTo: autoCloseHost.topAnchor),
            outer.bottomAnchor.constraint(equalTo: autoCloseHost.bottomAnchor)
        ])
    }

    @objc private func expirePopupChanged(_ sender: NSPopUpButton) {
        let idx = sender.indexOfSelectedItem
        let options = currentExpireOptions()
        guard idx >= 0 && idx < options.count else { return }
        expireMinutes = options[idx].minutes
    }

    // MARK: Running Projects header

    private func rebuildRunningHeader() {
        runningHeaderHost.subviews.forEach { $0.removeFromSuperview() }

        let title = NSTextField(labelWithString: t("running.title"))
        title.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        title.textColor = .plTextPrimary

        var trailingViews: [NSView] = []

        if !devPorts.isEmpty {
            let killAllButton = ClosureButton(onClick: { [weak self] in self?.confirmKillAll() })
            killAllButton.isBordered = false
            killAllButton.bezelStyle = .inline
            killAllButton.attributedTitle = NSAttributedString(
                string: t("running.killAll"),
                attributes: [
                    .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                    .foregroundColor: NSColor.plDanger
                ]
            )
            trailingViews.append(killAllButton)
        }

        let refreshButton = ClosureButton(onClick: { [weak self] in self?.refresh() })
        refreshButton.isBordered = false
        refreshButton.bezelStyle = .inline
        refreshButton.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "重新整理")
        refreshButton.contentTintColor = .plTextSecondary
        trailingViews.append(refreshButton)

        let row = NSStackView(views: [title, NSView()] + trailingViews)
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        row.distribution = .fill
        row.translatesAutoresizingMaskIntoConstraints = false

        runningHeaderHost.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: runningHeaderHost.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: runningHeaderHost.trailingAnchor),
            row.topAnchor.constraint(equalTo: runningHeaderHost.topAnchor),
            row.bottomAnchor.constraint(equalTo: runningHeaderHost.bottomAnchor)
        ])
    }

    // MARK: Footer

    // MARK: Actions

    private func openBrowser(port: String) {
        if let url = URL(string: "http://localhost:\(port)") {
            NSWorkspace.shared.open(url)
        }
    }

    private func togglePersistent(_ port: String) {
        var set = persistentPorts
        if set.contains(port) { set.remove(port) } else { set.insert(port) }
        persistentPortsRaw = set.sorted().joined(separator: ",")
        portsTable.persistentPorts = persistentPorts
        portsTable.reload()
    }

    private func confirmStop(_ info: PortInfo) {
        let alert = NSAlert()
        alert.messageText = String(format: t("alert.stopTitle"), info.port)
        alert.informativeText = "\(info.processName) · PID \(info.pid)\n\(info.command)"
        alert.addButton(withTitle: t("alert.stop.confirm"))
        alert.addButton(withTitle: t("alert.cancel"))
        alert.buttons.first?.hasDestructiveAction = true
        guard let window = view.window else { return }
        alert.beginSheetModal(for: window) { [weak self] response in
            if response == .alertFirstButtonReturn {
                self?.doKill(info)
            }
        }
    }

    private func confirmKillAll() {
        let toKill = devPorts.filter { !isPersistent($0.port) }
        let skipped = devPorts.count - toKill.count
        var msg = String(format: t("alert.killAllMessage"), toKill.count, toKill.map { $0.port }.joined(separator: ", localhost:"))
        if skipped > 0 {
            msg += String(format: t("alert.killAllSkipped"), skipped)
        }
        let alert = NSAlert()
        alert.messageText = t("alert.killAllTitle")
        alert.informativeText = msg
        alert.addButton(withTitle: t("running.killAll"))
        alert.addButton(withTitle: t("alert.cancel"))
        alert.buttons.first?.hasDestructiveAction = true
        guard let window = view.window else { return }
        alert.beginSheetModal(for: window) { [weak self] response in
            if response == .alertFirstButtonReturn {
                self?.killAll()
            }
        }
    }

    private func isPersistent(_ port: String) -> Bool {
        persistentPorts.contains(port)
    }

    private func killAll() {
        for info in devPorts where !isPersistent(info.port) {
            Darwin.kill(info.pid, SIGTERM)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.refresh()
        }
    }

    private func doKill(_ info: PortInfo) {
        Darwin.kill(info.pid, SIGTERM)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.refresh()
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "選擇"
        guard let window = view.window else { return }
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.lastLaunched = url.lastPathComponent
            self?.launchAndAutoOpen(path: url.path)
        }
    }

    func handleOpenURL(_ url: URL) {
        lastLaunched = url.lastPathComponent
        launchAndAutoOpen(path: url.path)
    }

    // MARK: Refresh / expiry

    private func syncPortsTable() {
        portsTable.devPorts = devPorts
        portsTable.persistentPorts = persistentPorts
        portsTable.projectNames = launchedProjectNames
        portsTable.siteTitles = fetchedSiteTitles
        portsTable.siteFavicons = fetchedFavicons
        portsTable.reload()
    }

    private func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let fetched = fetchPorts()
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.ports = fetched
                self.checkExpiry(fetched)
                self.isRefreshing = false
                self.syncPortsTable()
                self.rebuildRunningHeader()
                self.fetchMissingSiteInfo(fetched)
            }
        }
    }

    // 只對「不是我們自己啟動、也還沒抓過」的 dev port 才去要 title/favicon，
    // 每個 port 一輩子只試一次，不會每次 8 秒刷新就重打一輪。
    private func fetchMissingSiteInfo(_ fetched: [PortInfo]) {
        for info in fetched where info.isDev {
            guard launchedProjectNames[info.port] == nil else { continue }
            guard !siteInfoFetchAttempted.contains(info.port) else { continue }
            siteInfoFetchAttempted.insert(info.port)
            let port = info.port
            fetchSiteInfo(port: port) { [weak self] title, icon in
                guard let self = self else { return }
                if let title = title { self.fetchedSiteTitles[port] = title }
                if let icon = icon { self.fetchedFavicons[port] = icon }
                if title != nil || icon != nil {
                    self.syncPortsTable()
                }
            }
        }
    }

    private func checkExpiry(_ fetched: [PortInfo]) {
        guard expireMinutes > 0 else { return }
        let limitSeconds = expireMinutes * 60
        for info in fetched where info.isDev {
            guard !isPersistent(info.port) else { continue }
            if info.uptimeSeconds >= limitSeconds {
                Darwin.kill(info.pid, SIGTERM)
                autoExpiredNotice = "已自動關閉 localhost:\(info.port)（運行超過 \(expireMinutes) 分鐘）"
                rebuildAutoClose()
            }
        }
    }

    // MARK: Launch + poll

    private func launchAndAutoOpen(path: String) {
        isLaunching = true
        launchStatus = "正在偵測專案類型…"
        rebuildHeroCard()
        let token = UUID()
        pollToken = token
        let projectName = URL(fileURLWithPath: path).lastPathComponent

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let before = Set(fetchPorts().filter { $0.isDev }.map { $0.port })
            launchProject(at: path)

            Thread.sleep(forTimeInterval: 0.5)
            if isLikelyNonWebLaunch() {
                DispatchQueue.main.async {
                    guard let self = self, self.pollToken == token else { return }
                    self.isLaunching = false
                    self.launchStatus = ""
                    self.lastLaunched += "（已開啟）"
                    self.rebuildHeroCard()
                }
                return
            }

            DispatchQueue.main.async {
                guard let self = self, self.pollToken == token else { return }
                self.launchStatus = "已在 Terminal 啟動，等待服務就緒…"
                self.rebuildHeroCard()
            }

            self?.pollForNewServer(before: before, projectName: projectName, attemptsLeft: pollMaxAttempts, token: token)
        }
    }

    private func cancelWaiting() {
        pollToken = UUID()
        isLaunching = false
        launchStatus = ""
        rebuildHeroCard()
    }

    private func pollForNewServer(before: Set<String>, projectName: String, attemptsLeft: Int, token: UUID) {
        guard attemptsLeft > 0 else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.pollToken == token else { return }
                self.isLaunching = false
                self.launchStatus = ""
                self.autoExpiredNotice = "已啟動，但沒有偵測到新的網頁 port（可能是原生 App、純後端／資料庫服務，本來就不會有網頁；若還在等 Docker，可以到 Terminal 視窗確認進度，不需要重新拖曳）"
                self.rebuildHeroCard()
                self.rebuildAutoClose()
                self.refresh()
            }
            return
        }
        Thread.sleep(forTimeInterval: 1)
        var stillCurrent = true
        DispatchQueue.main.sync { [weak self] in stillCurrent = (self?.pollToken == token) }
        guard stillCurrent else { return }

        let elapsed = pollMaxAttempts - attemptsLeft + 1
        if elapsed % 3 == 0 || elapsed == 1 {
            let logLine = lastLogLine()
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.pollToken == token else { return }
                if logLine.isEmpty {
                    self.launchStatus = "等待服務就緒…（已等待 \(elapsed) 秒，隨時可以到 Terminal 查看）"
                } else {
                    self.launchStatus = "\(logLine)\n（已等待 \(elapsed) 秒）"
                }
                self.rebuildHeroCard()
            }
        }
        let current = fetchPorts().filter { $0.isDev }
        if let newOne = current.first(where: { !before.contains($0.port) }) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.pollToken == token else { return }
                self.isLaunching = false
                self.launchStatus = ""
                self.launchedProjectNames[newOne.port] = projectName
                self.rebuildHeroCard()
                self.refresh()
                self.openBrowser(port: newOne.port)
            }
        } else {
            pollForNewServer(before: before, projectName: projectName, attemptsLeft: attemptsLeft - 1, token: token)
        }
    }
}

// MARK: - App

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var mainViewController: MainViewController!

    // 徹底關掉 macOS 的「上次意外退出，要不要重新打開視窗」對話框。
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let vc = MainViewController()
        mainViewController = vc
        let win = NSWindow(contentViewController: vc)
        win.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isRestorable = false
        win.setFrameAutosaveName("")
        win.isReleasedWhenClosed = false
        win.minSize = NSSize(width: 560, height: 620)

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = NSSize(width: 600, height: 680)
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
            mainViewController?.handleOpenURL(url)
        }
    }
}

let delegate = AppDelegate()
let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.delegate = delegate
app.run()
