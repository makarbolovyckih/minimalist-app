import SwiftUI
import AppIntents
#if APP_TARGET
import UIKit
#endif

struct LinkItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var url: String
    var link: URL? { URL(string: url) }
}

struct CatalogApp: Identifiable, Hashable {
    let name: String
    let url: String
    var shortcut = false   // true = needs a Shortcut named after the app
    var id: String { name }
}

final class LaunchState: ObservableObject {
    static let shared = LaunchState()
    @Published var hiding = false
}

// Third-party apps: the widget launches Blank, which then opens the target app (custom schemes can't be opened straight from a widget).
@available(iOS 17.0, *)
struct LaunchIntent: AppIntent {
    static var title: LocalizedStringResource = "Open app"
    static var openAppWhenRun: Bool = true
    @Parameter(title: "URL") var url: URL
    init() {}
    init(url: URL) { self.url = url }
    @MainActor
    func perform() async throws -> some IntentResult {
        #if APP_TARGET
        LaunchState.shared.hiding = true
        try? await Task.sleep(nanoseconds: 150_000_000)
        _ = await UIApplication.shared.open(url, options: [:])
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        LaunchState.shared.hiding = false
        #endif
        return .result()
    }
}

enum Catalog {
    // iOS gives apps NO way to list what's installed, so this is a built-in list of apps with known URL schemes.
    // Anything else (Camera, Calculator, Clock...): use a Shortcut ("Open App" lists every app) or a custom URL.
    private static let direct: [CatalogApp] = [
        // Apple
        ("Books", "ibooks://"), ("Calendar", "calshow://"), ("Contacts", "contacts://"), ("FaceTime", "facetime:"),
        ("Files", "shareddocuments://"), ("Find My", "findmy://"), ("Fitness", "fitness://"), ("Freeform", "freeform://"),
        ("Health", "x-apple-health://"), ("Home", "x-hm://"), ("Magnifier", "magnifier://"), ("Mail", "message://"),
        ("Maps", "maps://"), ("Measure", "measure://"), ("Messages", "sms:"), ("Music", "music://"),
        ("Notes", "mobilenotes://"), ("Photos", "photos-redirect://"), ("Podcasts", "podcasts://"),
        ("Reminders", "x-apple-reminderkit://"), ("Safari", "x-web-search://"), ("Settings", "App-Prefs:"),
        ("Shortcuts", "shortcuts://"), ("Stocks", "stocks://"), ("TV", "videos://"), ("Voice Memos", "voicememos://"),
        ("Wallet", "shoebox://"), ("Weather", "weather://"), ("App Store", "itms-apps://"),
        // Third party
        ("1Password", "onepassword://"), ("Amazon", "com.amazon.mobile.shopping://"), ("Audible", "audible://"),
        ("Bitwarden", "bitwarden://"), ("Cash App", "cashme://"), ("ChatGPT", "chatgpt://"), ("Chrome", "googlechrome://"),
        ("Discord", "discord://"), ("Disney+", "disneyplus://"), ("DoorDash", "doordash://"), ("Dropbox", "dbapi-1://"),
        ("Duolingo", "duolingo://"), ("Facebook", "fb://"), ("Firefox", "firefox://"), ("Gmail", "googlegmail://"),
        ("Google Calendar", "googlecalendar://"), ("Google Drive", "googledrive://"), ("Google Maps", "comgooglemaps://"),
        ("Google Photos", "googlephotos://"), ("Google Translate", "googletranslate://"), ("Hulu", "hulu://"),
        ("Instagram", "instagram://"), ("Kindle", "kindle://"), ("LinkedIn", "linkedin://"), ("Lyft", "lyft://"),
        ("Messenger", "fb-messenger://"), ("Netflix", "nflx://"), ("Notion", "notion://"), ("Outlook", "ms-outlook://"),
        ("PayPal", "paypal://"), ("Pinterest", "pinterest://"), ("Prime Video", "aiv://"), ("Reddit", "reddit://"),
        ("Shazam", "shazam://"), ("Signal", "sgnl://"), ("Slack", "slack://"), ("Snapchat", "snapchat://"),
        ("SoundCloud", "soundcloud://"), ("Spotify", "spotify://"), ("Strava", "strava://"), ("Teams", "msteams://"),
        ("Telegram", "tg://"), ("Threads", "threads://"), ("TikTok", "tiktok://"), ("Tinder", "tinder://"),
        ("Twitch", "twitch://"), ("Uber", "uber://"), ("Uber Eats", "ubereats://"), ("Venmo", "venmo://"),
        ("Waze", "waze://"), ("WhatsApp", "whatsapp://"), ("X", "twitter://"), ("YouTube", "youtube://"),
        ("YouTube Music", "youtubemusic://"), ("Zoom", "zoomus://"),
    ].map { CatalogApp(name: $0.0, url: $0.1) }

    // Apple gives these no link at all, so each runs a Shortcut with the "Open App" action, named exactly like the app.
    private static let viaShortcut: [CatalogApp] =
        ["Calculator", "Camera", "Clock", "Phone"].map {
            CatalogApp(name: $0, url: shortcutURL($0), shortcut: true)
        }

    static let apps: [CatalogApp] = (direct + viaShortcut).sorted { $0.name < $1.name }

    static let defaults = ["Mail", "Maps", "Music", "Notes", "Photos"]

    // Schemes handled by the system itself (these open fine through OpenURLIntent).
    static let systemSchemes: Set<String> = [
        "http", "https", "tel", "mailto", "message", "maps", "music", "facetime", "x-web-search",
        "photos-redirect", "mobilenotes", "calshow", "x-apple-reminderkit", "shareddocuments", "shoebox",
        "x-apple-health", "podcasts", "itms-apps", "shortcuts", "app-prefs", "findmy", "ibooks", "videos",
        "stocks", "x-hm", "fitness", "voicememos", "measure", "magnifier", "freeform", "weather", "contacts",
    ]

    static func isSystem(_ url: URL) -> Bool {
        systemSchemes.contains((url.scheme ?? "").lowercased())
    }

    static func shortcutURL(_ name: String) -> String {
        var ok = CharacterSet.alphanumerics
        ok.insert(charactersIn: "-._~")
        return "shortcuts://run-shortcut?name=" + (name.addingPercentEncoding(withAllowedCharacters: ok) ?? name)
    }
}

extension Color {
    init(hex: String) {
        var v: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 255) / 255, green: Double((v >> 8) & 255) / 255, blue: Double(v & 255) / 255)
    }
}

func hexLuminance(_ hex: String) -> Double {
    var v: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&v)
    let r = Double((v >> 16) & 255), g = Double((v >> 8) & 255), b = Double(v & 255)
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255
}

// Shares data between the app and the widget through an App Group.
// The group id is read from the provisioning profile, because sideloading tools rewrite it.
enum Store {
    static let groupID: String = {
        if let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let s = String(data: data, encoding: .isoLatin1),
           let a = s.range(of: "<?xml"), let b = s.range(of: "</plist>"), a.lowerBound < b.upperBound,
           let plist = try? PropertyListSerialization.propertyList(from: Data(s[a.lowerBound..<b.upperBound].utf8), format: nil) as? [String: Any],
           let ent = plist["Entitlements"] as? [String: Any],
           let groups = ent["com.apple.security.application-groups"] as? [String],
           let g = groups.first { return g }
        return "group.com.blankclone.app"
    }()

    static var available: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) != nil
    }

    private static var defaults: UserDefaults? { available ? UserDefaults(suiteName: groupID) : nil }

    static func load() -> [LinkItem] {
        guard let d = defaults?.data(forKey: "items"),
              let items = try? JSONDecoder().decode([LinkItem].self, from: d) else { return [] }
        return items
    }

    static func save(_ items: [LinkItem]) {
        guard let d = try? JSONEncoder().encode(items) else { return }
        defaults?.set(d, forKey: "items")
    }

    static var bgHex: String {
        get { defaults?.string(forKey: "bg") ?? "000000" }
        set { defaults?.set(newValue, forKey: "bg") }
    }
}
