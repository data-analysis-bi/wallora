import SwiftUI

struct WallpaperImage: View {
    let wallpaper: Wallpaper
    var full = false
    @State private var image: UIImage?
    var body: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            if let image { Image(uiImage: image).resizable().scaledToFill().transition(.opacity) }
        }
        .task(id: wallpaper.id) { image = await ImageLoader.shared.image(for: wallpaper, full: full) }
        .animation(.easeOut(duration: 0.25), value: image != nil)
    }
}

struct WallpaperGrid: View {
    let wallpapers: [Wallpaper]
    @State private var selected: Wallpaper?
    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    var body: some View {
        LazyVGrid(columns: cols, spacing: 12) {
            ForEach(wallpapers) { w in
                Button { selected = w } label: {
                    Color.clear.aspectRatio(9 / 19.5, contentMode: .fit)
                        .overlay(WallpaperImage(wallpaper: w))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(alignment: .bottomLeading) {
                            Text(w.title).font(.caption.weight(.semibold)).foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(.black.opacity(0.35), in: Capsule()).padding(10)
                        }
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .fullScreenCover(item: $selected) { ViewerView(wallpaper: $0) }
    }
}

enum PreviewSize: String, CaseIterable, Identifiable {
    case small = "Small", medium = "Medium", large = "Large"
    var id: String { rawValue }
    var dims: CGSize {
        switch self {
        case .small: return CGSize(width: 158, height: 158)
        case .medium: return CGSize(width: 338, height: 158)
        case .large: return CGSize(width: 338, height: 354)
        }
    }
    var family: WidgetFamily {
        switch self { case .small: return .systemSmall; case .medium: return .systemMedium; case .large: return .systemLarge }
    }
}

import WidgetKit
struct WidgetPreview: View {
    let design: WidgetDesign
    var size: PreviewSize = .small
    var body: some View {
        DesignContent(design: design, family: size.family)
            .padding(14)
            .frame(width: size.dims.width, height: size.dims.height)
            .background(DesignBackground(design: design))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
    }
}
