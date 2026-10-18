import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var items = Store.load()
    @State private var adding = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if Store.available {
                        Text("Synced with the widget. Changes show up automatically.")
                    } else {
                        Text("Sync isn't available on this install. Edit the list by long-pressing the widget > Edit Widget instead.")
                    }
                }
                .font(.footnote)

                Section("Widget apps") {
                    if items.isEmpty { Text("Tap + to add an app.").foregroundStyle(.secondary) }
                    ForEach($items) { $item in
                        VStack(alignment: .leading, spacing: 2) {
                            TextField("Label", text: $item.name)
                            Text(item.url).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { items.remove(atOffsets: $0) }
                    .onMove { items.move(fromOffsets: $0, toOffset: $1) }
                }
            }
            .navigationTitle("Blank")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { adding = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $adding) { AddView { items.append($0) } }
            .onChange(of: items) {
                Store.save(items)
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

struct AddView: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (LinkItem) -> Void

    @State private var mode = 0
    @State private var app = Catalog.apps[0]
    @State private var label = ""
    @State private var shortcut = ""
    @State private var custom = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $mode) {
                    Text("App").tag(0)
                    Text("Shortcut").tag(1)
                    Text("URL").tag(2)
                }
                .pickerStyle(.segmented)

                if mode == 0 {
                    Picker("App", selection: $app) {
                        ForEach(Catalog.apps) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.menu)
                } else if mode == 1 {
                    TextField("Shortcut name (exact)", text: $shortcut)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Text("For any app not in the list: in the Shortcuts app, make a shortcut with the 'Open App' action (it lists every app on your phone), then type its name here.")
                        .font(.footnote)
                } else {
                    TextField("URL, e.g. myapp://", text: $custom)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                }
                TextField("Label on widget (optional)", text: $label)
            }
            .navigationTitle("Add")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Add") { add() }.disabled(!valid) }
            }
        }
    }

    var valid: Bool {
        switch mode {
        case 0: return true
        case 1: return !shortcut.trimmingCharacters(in: .whitespaces).isEmpty
        default: return !custom.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    func add() {
        let name: String, url: String
        switch mode {
        case 0: name = app.name; url = app.url
        case 1: name = shortcut; url = Catalog.shortcutURL(shortcut.trimmingCharacters(in: .whitespaces))
        default: name = custom; url = custom.trimmingCharacters(in: .whitespaces)
        }
        onAdd(LinkItem(name: label.isEmpty ? name : label, url: url))
        dismiss()
    }
}
