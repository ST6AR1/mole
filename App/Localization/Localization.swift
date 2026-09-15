import Foundation

// MARK: - Localization
//
// 9-language i18n system. Each supported language's copy lives in its own
// `Strings.<lang>.swift` file (a flat `[String: String]` dictionary), and this
// file just assembles them + exposes `t()`/`tf()` lookups plus first-launch
// system-locale detection.
//
// GOING FORWARD: every new user-visible string needs a translation key added
// to ALL 9 `Strings.*.swift` files before it's referenced anywhere in the app.
// No new hardcoded UI strings — ever. Missing keys silently fall back to
// English at runtime (never to the raw key, never a crash); in DEBUG builds a
// one-time console warning lists any keys missing from any language.

enum AppLanguage: String, CaseIterable {
    case en, zhTW, zhCN, ja, ko, fr, es, de, ptBR

    // Fixed display order everywhere a language list appears (Settings dropdown,
    // etc.) — NEVER alphabetical, NEVER re-sorted, so a user can always find
    // their language even while stuck in one they can't read.
    static let orderedLanguages: [AppLanguage] = [.en, .zhTW, .zhCN, .ja, .ko, .fr, .es, .de, .ptBR]

    // Each language's own name, written in ITS OWN language (never translated
    // into the currently active UI language).
    var nativeName: String {
        switch self {
        case .en: return "English"
        case .zhTW: return "繁體中文"
        case .zhCN: return "简体中文"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .fr: return "Français"
        case .es: return "Español"
        case .de: return "Deutsch"
        case .ptBR: return "Português (Brasil)"
        }
    }

    private static let defaultsKey = "smartlaunch.language"

    static var current: AppLanguage {
        get {
            guard let raw = UserDefaults.standard.string(forKey: defaultsKey) else {
                // First launch ever (no stored preference at all): detect once
                // from the system locale, persist it, and never auto-detect again.
                let detected = detectFromSystem()
                UserDefaults.standard.set(detected.rawValue, forKey: defaultsKey)
                return detected
            }
            // Back-compat with the old two-language build, which stored "zh"/"en".
            if raw == "zh" { return .zhTW }
            return AppLanguage(rawValue: raw) ?? .en
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey) }
    }

    // Pure function: maps the system locale down to one of the 9 supported
    // languages, else falls back to English. Parses language+script+region via
    // `Locale` APIs rather than naive string-prefix matching, since macOS
    // reports Chinese locales as e.g. `zh-Hant-TW` / `zh-Hans-CN`, not the
    // literal strings `zh-TW` / `zh-CN`.
    static func detectFromSystem() -> AppLanguage {
        for identifier in Locale.preferredLanguages {
            let locale = Locale(identifier: identifier)
            let languageCode = locale.language.languageCode?.identifier ?? ""
            let script = locale.language.script?.identifier
            let region = locale.language.region?.identifier

            switch languageCode {
            case "zh":
                if script == "Hant" { return .zhTW }
                if script == "Hans" { return .zhCN }
                // No explicit script tag: fall back on region.
                if let region = region {
                    if ["TW", "HK", "MO"].contains(region) { return .zhTW }
                    if ["CN", "SG"].contains(region) { return .zhCN }
                }
                // Ambiguous zh with neither script nor a recognized region: default Traditional.
                return .zhTW
            case "ja": return .ja
            case "ko": return .ko
            case "fr": return .fr
            case "es": return .es
            case "de": return .de
            case "pt":
                // Only pt-BR is supported; any other Portuguese variant still
                // falls back to pt-BR (never English) per product spec.
                return .ptBR
            default:
                continue
            }
        }
        return .en
    }
}

private let allStrings: [AppLanguage: [String: String]] = [
    .en: stringsEN,
    .zhTW: stringsZhTW,
    .zhCN: stringsZhCN,
    .ja: stringsJA,
    .ko: stringsKO,
    .fr: stringsFR,
    .es: stringsES,
    .de: stringsDE,
    .ptBR: stringsPtBR,
]

func t(_ key: String) -> String {
    if let value = allStrings[AppLanguage.current]?[key] { return value }
    if let fallback = allStrings[.en]?[key] {
        #if DEBUG
        print("[i18n] missing key \"\(key)\" for \(AppLanguage.current.rawValue), falling back to English")
        #endif
        return fallback
    }
    #if DEBUG
    print("[i18n] missing key \"\(key)\" in every language — check Strings.*.swift")
    #endif
    return key
}

func tf(_ key: String, _ args: CVarArg...) -> String {
    String(format: t(key), arguments: args)
}

#if DEBUG
// Debug-only consistency check: warns (never crashes, never shown to users)
// if any language's file is missing keys that exist in English.
func checkLocalizationConsistency() {
    guard let enKeys = allStrings[.en]?.keys else { return }
    let referenceKeys = Set(enKeys)
    for language in AppLanguage.orderedLanguages where language != .en {
        let keys: Set<String> = allStrings[language].map { Set($0.keys) } ?? []
        let missing = referenceKeys.subtracting(keys)
        if !missing.isEmpty {
            print("[i18n] \(language.rawValue) is missing \(missing.count) key(s): \(missing.sorted().joined(separator: ", "))")
        }
    }
}
#endif
