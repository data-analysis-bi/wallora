import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(CatalogViewModel.self) private var catalog
    @Environment(DesignLibrary.self) private var library
    @Query(sort: \FavoriteWallpaper.addedAt, order: .reverse) private var favs: [FavoriteWallpaper]
    @State private var tab = 0
    @State private var editing: WidgetDesign?

    var body: some View {
        NavigationStack {
            ScrollView {
                Picker("", selection: $tab) { Text("Wallpapers").tag(0); Text("Widgets").tag(1) }
                    .pickerStyle(.segmented).padding(.horizontal).padding(.bottom, 8)
                if tab == 0 {
                    let items = favs.compactMap { f in catalog.all.first { $0.id == f.wallpaperID } }
                    if items.isEmpty { ContentUnavailableView("No favorites yet", systemImage: "heart", description: Text("Tap the heart on any wallpaper.")) }
                    else { WallpaperGrid(wallpapers: items) }
                } else {
                    if library.designs.isEmpty { ContentUnavailableView("No saved widgets", systemImage: "rectangle.3.group", description: Text("Create one in the Widgets tab.")) }
                    VStack(spacing: 22) {
                        ForEach(library.designs) { d in
                            Button { editing = d } label: { WidgetPreview(design: d, size: .medium) }.buttonStyle(.plain)
                                .contextMenu { Button("Delete", systemImage: "trash", role: .destructive) { library.delete(d) } }
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .sheet(item: $editing) { StudioView(design: $0) }
        }
    }
}

struct ProfileView: View {
    @Environment(CatalogViewModel.self) private var catalog
    @Environment(DesignLibrary.self) private var library
    @Query(sort: \DownloadRecord.date, order: .reverse) private var downloads: [DownloadRecord]
    @AppStorage("quality") private var quality = "high"
    @State private var key = Keychain.get("unsplash") ?? ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Download quality") {
                    Picker("Quality", selection: $quality) { Text("High").tag("high"); Text("Ultra (largest)").tag("ultra") }.pickerStyle(.segmented)
                }
                Section {
                    SecureField("Unsplash Access Key", text: $key).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button("Save key & refresh") { Keychain.set(key.trimmingCharacters(in: .whitespaces), for: "unsplash"); Task { await catalog.load() } }
                } header: { Text("Wallpaper source") } footer: { Text("Free key from unsplash.com/developers. Stored in the iOS Keychain. Photos show photographer attribution.") }
                Section("Widgets") {
                    LabeledContent("Shared with widgets", value: AppGroup.isShared ? "Yes" : "No")
                    ShareLink("Back up widget designs", item: DesignStore.url)
                    Button("Reload widget designs") { library.reload() }
                } 
                Section("Downloads (\(downloads.count))") {
                    ForEach(downloads.prefix(10)) { d in
                        HStack { Text(d.title); Spacer(); Text(d.date, style: .date).foregroundStyle(.secondary).font(.caption) }
                    }
                }
                Section("Storage") { Button("Clear image cache", role: .destructive) { ImageLoader.shared.clearDiskCache() } }
                Section("About") {
                    Text("iOS only lets you change wallpaper through Settings, so Wallora saves to Photos and guides you. Widget refresh timing is controlled by iOS.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }.navigationTitle("Profile")
        }
    }
}
