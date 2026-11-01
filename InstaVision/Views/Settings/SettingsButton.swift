import SwiftUI

/// Gear button that presents the settings sheet. Used in every tab's toolbar.
struct SettingsButton: View {
    @State private var isPresented = false

    var body: some View {
        Button("Settings", systemImage: "gearshape") { isPresented = true }
            .sheet(isPresented: $isPresented) { SettingsView() }
    }
}
