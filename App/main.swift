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

// MARK: - Design tokens

extension NSColor {
    static let plWindowBg = NSColor(calibratedRed: 0.953, green: 0.949, blue: 0.937, alpha: 1)
    static let plHeroBg = NSColor(calibratedRed: 0.992, green: 0.992, blue: 0.984, alpha: 1)
    static let plRowBg = NSColor(calibratedRed: 0.973, green: 0.969, blue: 0.953, alpha: 1)
    static let plRowBgMuted = NSColor(calibratedRed: 0.961, green: 0.957, blue: 0.941, alpha: 1)
    static let plTextPrimary = NSColor(calibratedRed: 0.110, green: 0.110, blue: 0.118, alpha: 1)
    static let plTextSecondary = NSColor(calibratedRed: 0.557, green: 0.557, blue: 0.576, alpha: 1)
    static let plTextTertiary = NSColor(calibratedRed: 0.690, green: 0.686, blue: 0.675, alpha: 1)
    static let plDanger = NSColor(calibratedRed: 0.753, green: 0.224, blue: 0.169, alpha: 1)
    static let plLocalhostText = NSColor(calibratedRed: 0.227, green: 0.227, blue: 0.235, alpha: 1)
    static let plUpdateBg = NSColor(calibratedRed: 0.933, green: 0.945, blue: 0.965, alpha: 1)
    static let plUpdateText = NSColor(calibratedRed: 0.227, green: 0.353, blue: 0.549, alpha: 1)
    static let plPrimaryButtonBg = NSColor(calibratedRed: 0.941, green: 0.937, blue: 0.925, alpha: 1)
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

// 拖曳資料夾進來的區域：純 AppKit 的 NSDraggingDestination 實作，
// 取代原本 SwiftUI 的 .onDrop，懸浮時用 layer 邊框做提示。
final class DropZoneView: NSView {
    var onDrop: ((URL) -> Void)?
    private var isHovering = false {
        didSet { updateBorder() }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 30
        layer?.backgroundColor = NSColor.plHeroBg.cgColor
        registerForDraggedTypes([.fileURL])
        updateBorder()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func updateBorder() {
        layer?.borderWidth = isHovering ? 2 : 0
        layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.5).cgColor
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

// 主要操作按鈕（選擇資料夾）的 soft filled 外觀
final class SoftFilledButton: ClosureButton {
    override init(frame: NSRect) {
        super.init(frame: frame)
    }
    convenience init(title: String, onClick: @escaping () -> Void) {
        self.init(onClick: onClick)
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.backgroundColor = NSColor.plPrimaryButtonBg.cgColor
        attributedTitle = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.plTextPrimary
        ])
        contentTintColor = .plTextPrimary
    }
    required init?(coder: NSCoder) { fatalError() }
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
    var otherPorts: [PortInfo] = []
    var showOtherServices = false
    var persistentPorts: Set<String> = []

    var onOpen: ((String) -> Void)?
    var onTogglePersistent: ((String) -> Void)?
    var onStop: ((PortInfo) -> Void)?
    var onToggleOthers: (() -> Void)?

    private enum RowItem {
        case empty
        case project(PortInfo)
        case othersHeader(Int)
        case other(PortInfo)
    }
    private var rows: [RowItem] = []

    func reload() {
        var r: [RowItem] = []
        if devPorts.isEmpty {
            r.append(.empty)
        } else {
            for info in devPorts { r.append(.project(info)) }
        }
        if !otherPorts.isEmpty {
            r.append(.othersHeader(otherPorts.count))
            if showOtherServices {
                for info in otherPorts { r.append(.other(info)) }
            }
        }
        rows = r
        tableView?.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool { false }

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool { false }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch rows[row] {
        case .empty: return 72
        case .project: return 80
        case .othersHeader: return 32
        case .other: return 40
        }
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch rows[row] {
        case .empty:
            return makeEmptyRow()
        case .project(let info):
            return makeProjectRow(info)
        case .othersHeader(let count):
            return makeOthersHeaderRow(count)
        case .other(let info):
            return makeOtherRow(info)
        }
    }

    private func makeEmptyRow() -> NSView {
        let wrapper = NSView()
        let label = NSTextField(labelWithString: "目前沒有專案在跑")
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = .plTextTertiary
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor)
        ])
        return wrapper
    }

    private func makeProjectRow(_ info: PortInfo) -> NSView {
        let wrapper = NSView()

        let card = RoundedCardView(cornerRadius: 20, fill: .plRowBg, borderColor: NSColor.black.withAlphaComponent(0.04))
        wrapper.addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            card.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 5),
            card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -5)
        ])

        let linkButton = ClosureButton(onClick: { [weak self] in
            self?.onOpen?(info.port)
        })
        linkButton.attributedTitle = NSAttributedString(
            string: "localhost:\(info.port)  ↗",
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: NSColor.plLocalhostText
            ]
        )
        linkButton.isBordered = false
        linkButton.bezelStyle = .inline
        linkButton.alignment = .left
        linkButton.contentTintColor = .plLocalhostText
        linkButton.toolTip = "\(info.uptime)\n\(info.command)"

        let subLabel = NSTextField(labelWithString: "\(info.processName) · \(shortUptime(info.uptimeSeconds))")
        subLabel.font = NSFont.systemFont(ofSize: 11)
        subLabel.textColor = .plTextSecondary
        subLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = NSStackView(views: [linkButton, subLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let isPinned = persistentPorts.contains(info.port)
        let pinButton = ClosureButton(onClick: { [weak self] in
            self?.onTogglePersistent?(info.port)
        })
        pinButton.image = NSImage(systemSymbolName: isPinned ? "pin.fill" : "pin", accessibilityDescription: "常駐")
        pinButton.isBordered = false
        pinButton.bezelStyle = .inline
        pinButton.contentTintColor = isPinned ? .plTextPrimary : .plTextTertiary
        pinButton.toolTip = "常駐：不會被自動過期關閉"
        pinButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        pinButton.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let stopButton = ClosureButton(onClick: { [weak self] in
            self?.onStop?(info)
        })
        stopButton.attributedTitle = NSAttributedString(
            string: "Stop",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.plDanger
            ]
        )
        stopButton.isBordered = false
        stopButton.bezelStyle = .inline

        let rightStack = NSStackView(views: [pinButton, stopButton])
        rightStack.orientation = .horizontal
        rightStack.alignment = .centerY
        rightStack.spacing = 10
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(textStack)
        card.addSubview(rightStack)
        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            rightStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            rightStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: rightStack.leadingAnchor, constant: -8)
        ])

        return wrapper
    }

    private func makeOthersHeaderRow(_ count: Int) -> NSView {
        let wrapper = NSView()
        let button = ClosureButton(onClick: { [weak self] in
            self?.onToggleOthers?()
        })
        let chevronName = showOtherServices ? "chevron.down" : "chevron.right"
        button.attributedTitle = NSAttributedString(
            string: "System services (\(count))",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.plTextTertiary
            ]
        )
        button.image = NSImage(systemSymbolName: chevronName, accessibilityDescription: nil)
        button.imagePosition = .imageTrailing
        button.isBordered = false
        button.bezelStyle = .inline
        button.contentTintColor = .plTextTertiary
        button.alignment = .left

        wrapper.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            button.trailingAnchor.constraint(lessThanOrEqualTo: wrapper.trailingAnchor),
            button.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor, constant: 4)
        ])
        return wrapper
    }

    private func makeOtherRow(_ info: PortInfo) -> NSView {
        let wrapper = NSView()
        let card = RoundedCardView(cornerRadius: 14, fill: .plRowBgMuted)
        wrapper.addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            card.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 3),
            card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -3)
        ])

        let portLabel = NSTextField(labelWithString: "localhost:\(info.port)")
        portLabel.font = NSFont.systemFont(ofSize: 11)
        portLabel.textColor = .plTextSecondary
        portLabel.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = NSTextField(labelWithString: info.processName)
        nameLabel.font = NSFont.systemFont(ofSize: 10)
        nameLabel.textColor = .plTextTertiary
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [portLabel, nameLabel])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -12),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        return wrapper
    }
}

// MARK: - Main window content (pure AppKit, no SwiftUI anywhere)

final class MainViewController: NSViewController {
    // MARK: State
    private var ports: [PortInfo] = []
    private var isRefreshing = false
    private var lastLaunched = ""
    private var autoExpiredNotice = ""
    private var showOtherServices = false
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
    private var otherPorts: [PortInfo] { ports.filter { !$0.isDev } }

    private var refreshTimer: Timer?

    // MARK: Views
    private let topStack = NSStackView()
    private let updateBannerHost = NSView()
    private let heroCardHost = NSView()
    private let autoCloseHost = NSView()
    private let runningHeaderHost = NSView()
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    private let footerHost = NSView()
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

        topStack.addArrangedSubview(buildHeader())
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
        portsTable.onToggleOthers = { [weak self] in
            guard let self = self else { return }
            self.showOtherServices.toggle()
            self.portsTable.showOtherServices = self.showOtherServices
            self.portsTable.reload()
        }

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        footerHost.translatesAutoresizingMaskIntoConstraints = false
        buildFooter()

        view.addSubview(topStack)
        view.addSubview(scrollView)
        view.addSubview(footerHost)

        NSLayoutConstraint.activate([
            topStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            topStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: footerHost.topAnchor, constant: -4),

            footerHost.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            footerHost.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            footerHost.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -14)
        ])

        rebuildUpdateBanner()
        rebuildHeroCard()
        rebuildAutoClose()
        rebuildRunningHeader()
        syncPortsTable()
    }

    private func buildHeader() -> NSView {
        let title = NSTextField(labelWithString: "Smart Launch")
        title.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        title.textColor = .plTextPrimary

        let subtitle = NSTextField(labelWithString: "讓本機專案重新啟動變簡單")
        subtitle.font = NSFont.systemFont(ofSize: 12)
        subtitle.textColor = .plTextSecondary

        let textStack = NSStackView(views: [title, subtitle])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2

        let githubButton = ClosureButton(onClick: {
            if let url = URL(string: "https://github.com/ST6AR1/smart-launch") {
                NSWorkspace.shared.open(url)
            }
        })
        githubButton.isBordered = false
        githubButton.bezelStyle = .inline
        githubButton.wantsLayer = true
        githubButton.layer?.cornerRadius = 14
        githubButton.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.04).cgColor
        githubButton.toolTip = "在 GitHub 上查看這個專案"
        githubButton.widthAnchor.constraint(equalToConstant: 28).isActive = true
        githubButton.heightAnchor.constraint(equalToConstant: 28).isActive = true
        if let path = Bundle.main.path(forResource: "github-mark", ofType: "png"),
           let nsImage = NSImage(contentsOfFile: path) {
            nsImage.isTemplate = true
            githubButton.image = nsImage
        } else {
            githubButton.image = NSImage(systemSymbolName: "chevron.left.forwardslash.chevron.right", accessibilityDescription: nil)
        }
        githubButton.imageScaling = .scaleProportionallyDown
        githubButton.contentTintColor = .plTextTertiary

        let row = NSStackView(views: [textStack, NSView(), githubButton])
        row.orientation = .horizontal
        row.alignment = .top
        row.distribution = .fill
        row.setHuggingPriority(.defaultLow, for: .horizontal)
        return row
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
        shadowContainer.layer?.shadowOpacity = 0.08
        shadowContainer.layer?.shadowRadius = 16
        shadowContainer.layer?.shadowOffset = CGSize(width: 0, height: -6)
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
            dropZone.heightAnchor.constraint(equalToConstant: isLaunching ? 160 : 170)
        ])

        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.alignment = .centerX
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        dropZone.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: dropZone.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: dropZone.centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: dropZone.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: dropZone.trailingAnchor, constant: -24)
        ])

        if isLaunching {
            let spinner = NSProgressIndicator()
            spinner.style = .spinning
            spinner.controlSize = .small
            spinner.startAnimation(nil)

            let status = NSTextField(wrappingLabelWithString: launchStatus.isEmpty ? "正在啟動…" : launchStatus)
            status.font = NSFont.systemFont(ofSize: 12)
            status.textColor = .plTextSecondary
            status.alignment = .center
            status.maximumNumberOfLines = 2
            status.widthAnchor.constraint(lessThanOrEqualToConstant: 380).isActive = true

            let cancelButton = ClosureButton(onClick: { [weak self] in self?.cancelWaiting() })
            cancelButton.isBordered = false
            cancelButton.bezelStyle = .inline
            cancelButton.attributedTitle = NSAttributedString(
                string: "先不等了",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.plTextSecondary
                ]
            )

            contentStack.addArrangedSubview(spinner)
            contentStack.addArrangedSubview(status)
            contentStack.addArrangedSubview(cancelButton)
        } else {
            let icon = NSImageView(image: NSImage(systemSymbolName: "folder", accessibilityDescription: nil) ?? NSImage())
            icon.contentTintColor = .plTextSecondary
            icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 22, weight: .light)

            let title = NSTextField(labelWithString: "把專案資料夾拖到這裡")
            title.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
            title.textColor = .plTextPrimary

            let subtitle = NSTextField(labelWithString: "自動判斷並啟動 localhost")
            subtitle.font = NSFont.systemFont(ofSize: 12)
            subtitle.textColor = .plTextSecondary

            let chooseButton = SoftFilledButton(title: "選擇資料夾", onClick: { [weak self] in self?.chooseFolder() })
            chooseButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
            chooseButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

            contentStack.addArrangedSubview(icon)
            contentStack.addArrangedSubview(title)
            contentStack.addArrangedSubview(subtitle)
            contentStack.setCustomSpacing(4, after: subtitle)
            contentStack.addArrangedSubview(chooseButton)

            if !lastLaunched.isEmpty {
                let lastLabel = NSTextField(labelWithString: "上次啟動：\(lastLaunched)")
                lastLabel.font = NSFont.systemFont(ofSize: 10)
                lastLabel.textColor = .plTextTertiary
                contentStack.addArrangedSubview(lastLabel)
            }
        }
    }

    // MARK: Auto Close row

    private func rebuildAutoClose() {
        autoCloseHost.subviews.forEach { $0.removeFromSuperview() }

        let title = NSTextField(labelWithString: "Auto Close")
        title.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        title.textColor = .plTextPrimary

        let subtitle = NSTextField(labelWithString: "閒置專案將自動關閉")
        subtitle.font = NSFont.systemFont(ofSize: 11)
        subtitle.textColor = .plTextSecondary

        let textStack = NSStackView(views: [title, subtitle])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2

        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        popup.bezelStyle = .rounded
        for opt in expireOptions {
            popup.addItem(withTitle: opt.label)
        }
        if let idx = expireOptions.firstIndex(where: { $0.minutes == expireMinutes }) {
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
        guard idx >= 0 && idx < expireOptions.count else { return }
        expireMinutes = expireOptions[idx].minutes
    }

    // MARK: Running Projects header

    private func rebuildRunningHeader() {
        runningHeaderHost.subviews.forEach { $0.removeFromSuperview() }

        let title = NSTextField(labelWithString: "Running Projects")
        title.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        title.textColor = .plTextPrimary

        var trailingViews: [NSView] = []

        if !devPorts.isEmpty {
            let killAllButton = ClosureButton(onClick: { [weak self] in self?.confirmKillAll() })
            killAllButton.isBordered = false
            killAllButton.bezelStyle = .inline
            killAllButton.attributedTitle = NSAttributedString(
                string: "全部關閉",
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

    private func buildFooter() {
        let line1 = NSTextField(labelWithString: "由溫Wen 與 claude寶寶 聯合製作 ⌯^⦁𖥦⦁^⌯")
        let githubLink = ClosureButton(onClick: {
            if let url = URL(string: "https://github.com/ST6AR1") {
                NSWorkspace.shared.open(url)
            }
        })
        githubLink.isBordered = false
        githubLink.bezelStyle = .inline
        githubLink.attributedTitle = NSAttributedString(string: "GitHub @ST6AR1")
        let versionLabel = NSTextField(labelWithString: "v\(currentVersion)")

        for field in [line1, versionLabel] {
            field.font = NSFont.systemFont(ofSize: 10)
            field.textColor = .plTextTertiary.withAlphaComponent(0.7)
            field.alignment = .center
        }
        githubLink.attributedTitle = NSAttributedString(
            string: "GitHub @ST6AR1",
            attributes: [
                .font: NSFont.systemFont(ofSize: 10),
                .foregroundColor: NSColor.plTextTertiary.withAlphaComponent(0.7)
            ]
        )

        let stack = NSStackView(views: [line1, githubLink, versionLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        footerHost.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: footerHost.centerXAnchor),
            stack.topAnchor.constraint(equalTo: footerHost.topAnchor),
            stack.bottomAnchor.constraint(equalTo: footerHost.bottomAnchor)
        ])
    }

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
        alert.messageText = "關閉 localhost:\(info.port)？"
        alert.informativeText = "\(info.processName) · PID \(info.pid)\n\(info.command)"
        alert.addButton(withTitle: "關閉")
        alert.addButton(withTitle: "取消")
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
        var msg = "會關閉 \(toKill.count) 個開發伺服器（localhost:\(toKill.map { $0.port }.joined(separator: ", localhost:")))。"
        if skipped > 0 {
            msg += "\n有標記「常駐」的 \(skipped) 個服務不會被關閉。"
        }
        let alert = NSAlert()
        alert.messageText = "全部關閉？"
        alert.informativeText = msg
        alert.addButton(withTitle: "全部關閉")
        alert.addButton(withTitle: "取消")
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
        portsTable.otherPorts = otherPorts
        portsTable.showOtherServices = showOtherServices
        portsTable.persistentPorts = persistentPorts
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

            self?.pollForNewServer(before: before, attemptsLeft: pollMaxAttempts, token: token)
        }
    }

    private func cancelWaiting() {
        pollToken = UUID()
        isLaunching = false
        launchStatus = ""
        rebuildHeroCard()
    }

    private func pollForNewServer(before: Set<String>, attemptsLeft: Int, token: UUID) {
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
                self.rebuildHeroCard()
                self.refresh()
                self.openBrowser(port: newOne.port)
            }
        } else {
            pollForNewServer(before: before, attemptsLeft: attemptsLeft - 1, token: token)
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
            mainViewController?.handleOpenURL(url)
        }
    }
}

let delegate = AppDelegate()
let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.delegate = delegate
app.run()
