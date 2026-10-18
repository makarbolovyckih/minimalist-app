import Foundation

struct LinkItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var url: String
    var link: URL? { URL(string: url) }
}

struct CatalogApp: Identifiable, Hashable {
    let name: String
    let url: String
    var id: String { name }
}

enum Catalog {
    // iOS gives apps no way to list what's installed, so this is a built-in list of
    // apps with known URL schemes. Anything else: use a Shortcut ("Open App" lists every app) or a custom URL.
    static let apps: [CatalogApp] = [
        .init(name: "Messages", url: "sms:"),
        .init(name: "Phone", url: "tel:"),
        .init(name: "Mail", url: "message://"),
        .init(name: "Maps", url: "maps://"),
        .init(name: "Music", url: "music://"),
        .init(name: "FaceTime", url: "facetime:"),
        .init(name: "Safari", url: "x-web-search://"),
        .init(name: "Photos", url: "photos-redirect://"),
        .init(name: "Notes", url: "mobilenotes://"),
        .init(name: "Calendar", url: "calshow://"),
        .init(name: "Reminders", url: "x-apple-reminderkit://"),
        .init(name: "Files", url: "shareddocuments://"),
        .init(name: "Wallet", url: "shoebox://"),
        .init(name: "Health", url: "x-apple-health://"),
        .init(name: "Podcasts", url: "podcasts://"),
        .init(name: "App Store", url: "itms-apps://"),
        .init(name: "Shortcuts", url: "shortcuts://"),
        .init(name: "Instagram", url: "instagram://"),
        .init(name: "WhatsApp", url: "whatsapp://"),
        .init(name: "Telegram", url: "tg://"),
        .init(name: "Spotify", url: "spotify://"),
        .init(name: "YouTube", url: "youtube://"),
        .init(name: "Gmail", url: "googlegmail://"),
        .init(name: "Google Maps", url: "comgooglemaps://"),
        .init(name: "Chrome", url: "googlechrome://"),
        .init(name: "Discord", url: "discord://"),
        .init(name: "Snapchat", url: "snapchat://"),
        .init(name: "TikTok", url: "tiktok://"),
        .init(name: "X", url: "twitter://"),
        .init(name: "Reddit", url: "reddit://"),
        .init(name: "Netflix", url: "nflx://"),
        .init(name: "Uber", url: "uber://"),
        .init(name: "Slack", url: "slack://"),
        .init(name: "Notion", url: "notion://"),
    ]

    static func shortcutURL(_ name: String) -> String {
        var ok = CharacterSet.alphanumerics
        ok.insert(charactersIn: "-._~")
        return "shortcuts://run-shortcut?name=" + (name.addingPercentEncoding(withAllowedCharacters: ok) ?? name)
    }
}

// Shares the list between the app and the widget through an App Group.
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

    static func load() -> [LinkItem] {
        guard available,
              let d = UserDefaults(suiteName: groupID)?.data(forKey: "items"),
              let items = try? JSONDecoder().decode([LinkItem].self, from: d) else { return [] }
        return items
    }

    static func save(_ items: [LinkItem]) {
        guard available, let d = try? JSONEncoder().encode(items) else { return }
        UserDefaults(suiteName: groupID)?.set(d, forKey: "items")
    }
}
