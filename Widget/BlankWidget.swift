import WidgetKit
import SwiftUI
import AppIntents

// Fallback list used when app-to-widget sync isn't available: pick apps from a dropdown in Edit Widget.
struct AppChoice: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "App"
    static var defaultQuery = AppChoiceQuery()
    var id: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(id)") }
}

struct AppChoiceQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [AppChoice] {
        identifiers.map { AppChoice(id: $0) }
    }
    func suggestedEntities() async throws -> [AppChoice] {
        Catalog.apps.map { AppChoice(id: $0.name) }
    }
}

struct LinksIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Apps"
    static var description = IntentDescription("Pick the apps to show.")

    @Parameter(title: "App 1") var a1: AppChoice?
    @Parameter(title: "App 2") var a2: AppChoice?
    @Parameter(title: "App 3") var a3: AppChoice?
    @Parameter(title: "App 4") var a4: AppChoice?
    @Parameter(title: "App 5") var a5: AppChoice?
    @Parameter(title: "App 6") var a6: AppChoice?
    @Parameter(title: "App 7") var a7: AppChoice?
    @Parameter(title: "App 8") var a8: AppChoice?
    @Parameter(title: "App 9") var a9: AppChoice?
    @Parameter(title: "App 10") var a10: AppChoice?
}

struct LinkEntry: TimelineEntry {
    let date: Date
    let items: [LinkItem]
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LinkEntry { LinkEntry(date: .now, items: []) }
    func snapshot(for c: LinksIntent, in context: Context) async -> LinkEntry { entry(c) }
    func timeline(for c: LinksIntent, in context: Context) async -> Timeline<LinkEntry> {
        Timeline(entries: [entry(c)], policy: .never)
    }

    private func entry(_ c: LinksIntent) -> LinkEntry {
        var items = Store.load()   // list edited inside the app
        if items.isEmpty {
            let picks = [c.a1, c.a2, c.a3, c.a4, c.a5, c.a6, c.a7, c.a8, c.a9, c.a10]
                .compactMap { $0 }
                .compactMap { p in Catalog.apps.first { $0.name == p.id } }
            let apps = picks.isEmpty ? Array(Catalog.apps.prefix(5)) : picks
            items = apps.map { LinkItem(name: $0.name, url: $0.url) }
        }
        return LinkEntry(date: .now, items: items)
    }
}

struct BlankWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: LinkEntry

    // default branch covers the iOS 27 extra-large portrait family
    var size: CGFloat {
        switch family {
        case .systemSmall: return 15
        case .systemMedium: return 18
        case .systemLarge: return 24
        default: return 30
        }
    }

    var body: some View {
        VStack(spacing: size * 0.7) {
            ForEach(entry.items) { item in
                if let url = item.link {
                    Link(destination: url) { label(item.name) }
                } else {
                    label(item.name)
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) { Color.clear }
    }

    func label(_ s: String) -> some View {
        Text(s)
            .font(.system(size: size, weight: .light))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}

struct BlankWidget: Widget {
    static var families: [WidgetFamily] {
        var f: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
        if #available(iOS 27, *) { f.append(.systemExtraLargePortrait) }
        return f
    }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "BlankWidget", intent: LinksIntent.self, provider: Provider()) {
            BlankWidgetView(entry: $0)
        }
        .configurationDisplayName("Blank")
        .description("Text-only app launcher.")
        .supportedFamilies(Self.families)
    }
}

@main
struct BlankWidgetBundle: WidgetBundle {
    var body: some Widget { BlankWidget() }
}
