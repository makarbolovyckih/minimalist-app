import WidgetKit
import SwiftUI
import AppIntents

// Each slot is "Label|url". Empty slots are skipped.
struct LinksIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Links"
    static var description = IntentDescription("Each link as  Label|url")

    @Parameter(title: "Link 1", default: "Messages|sms:") var l1: String
    @Parameter(title: "Link 2", default: "Phone|tel:") var l2: String
    @Parameter(title: "Link 3", default: "Mail|mailto:") var l3: String
    @Parameter(title: "Link 4", default: "Maps|maps://") var l4: String
    @Parameter(title: "Link 5", default: "Music|music://") var l5: String
    @Parameter(title: "Link 6", default: "") var l6: String
    @Parameter(title: "Link 7", default: "") var l7: String
    @Parameter(title: "Link 8", default: "") var l8: String
    @Parameter(title: "Link 9", default: "") var l9: String
    @Parameter(title: "Link 10", default: "") var l10: String
}

struct LinkItem: Identifiable {
    let id: Int
    let label: String
    let url: URL?
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
        let raw = [c.l1, c.l2, c.l3, c.l4, c.l5, c.l6, c.l7, c.l8, c.l9, c.l10]
        let items = raw.enumerated().compactMap { i, s -> LinkItem? in
            let parts = s.split(separator: "|", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard let label = parts.first, !label.isEmpty else { return nil }
            return LinkItem(id: i, label: label, url: parts.count > 1 ? URL(string: parts[1]) : nil)
        }
        return LinkEntry(date: .now, items: items)
    }
}

struct BlankWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: LinkEntry

    // default branch covers the iOS 27 extra-large portrait family without naming it
    var size: CGFloat {
        switch family {
        case .systemSmall: return 15
        case .systemMedium: return 18
        case .systemLarge: return 24
        default: return 30
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: size * 0.6) {
            ForEach(entry.items) { item in
                if let url = item.url {
                    Link(destination: url) { label(item.label) }
                } else {
                    label(item.label)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }

    func label(_ s: String) -> some View {
        Text(s).font(.system(size: size, weight: .light)).foregroundStyle(.primary)
    }
}

struct BlankWidget: Widget {
    // XL_PORTRAIT is set by the build workflow when the SDK is iOS 27+
    static var families: [WidgetFamily] {
        var f: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
        #if XL_PORTRAIT
        if #available(iOS 27, *) { f.append(.systemExtraLargePortrait) }
        #endif
        return f
    }

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "BlankWidget", intent: LinksIntent.self, provider: Provider()) {
            BlankWidgetView(entry: $0)
        }
        .configurationDisplayName("Blank")
        .description("Text-only app launcher.")
        .supportedFamilies(Self.families)
        .contentMarginsDisabled()
    }
}

@main
struct BlankWidgetBundle: WidgetBundle {
    var body: some Widget { BlankWidget() }
}
