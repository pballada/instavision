import SwiftUI
import InstaVisionKit

/// Pages through the items of a carousel album. Single posts show without paging chrome.
struct CarouselView: View {
    let items: [InstagramMedia]
    @State private var selection: InstagramMedia.ID?

    var body: some View {
        if items.count <= 1, let item = items.first {
            MediaItemView(item: item)
        } else {
            TabView(selection: $selection) {
                ForEach(items) { item in
                    MediaItemView(item: item).tag(Optional(item.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .overlay { arrows }
            .onAppear { selection = selection ?? items.first?.id }
        }
    }

    private var index: Int { items.firstIndex { $0.id == selection } ?? 0 }

    private var arrows: some View {
        HStack {
            arrow("chevron.left", label: "Previous", offset: -1).opacity(index > 0 ? 1 : 0)
            Spacer()
            arrow("chevron.right", label: "Next", offset: 1).opacity(index < items.count - 1 ? 1 : 0)
        }
        .padding(20)
    }

    private func arrow(_ systemImage: String, label: String, offset: Int) -> some View {
        Button(label, systemImage: systemImage) {
            let target = min(max(index + offset, 0), items.count - 1)
            withAnimation { selection = items[target].id }
        }
        .labelStyle(.iconOnly)
        .buttonBorderShape(.circle)
    }
}
