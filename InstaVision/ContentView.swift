import SwiftUI
import InstaVisionKit

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.aperture")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("InstaVision")
                .font(.extraLargeTitle)
            Text("Your Instagram, in your space.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(48)
        .glassBackgroundEffect()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
