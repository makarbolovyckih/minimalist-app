import SwiftUI

struct ContentView: View {
    var body: some View {
        List {
            Section("Setup") {
                Text("1. Set a black wallpaper.")
                Text("2. Long-press the Home Screen, tap + and add the widget. On iOS 27 drag its corner handle to the extra-large size.")
                Text("3. Long-press the widget, tap Edit Widget, and fill in Link 1-10 as  Label|url")
            }
            Section("Example links") {
                Text("Messages|sms:")
                Text("Phone|tel:")
                Text("Mail|mailto:")
                Text("Camera|camera://")
                Text("Settings|App-Prefs:")
                Text("Maps|maps://")
                Text("Music|music://")
                Text("Run a Shortcut|shortcuts://run-shortcut?name=MyShortcut")
            }
            Section("Tip") {
                Text("Any app with a URL scheme works. Search '<app name> url scheme'.")
            }
        }
    }
}
