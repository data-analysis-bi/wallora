import SwiftUI
import SwiftData

@main
struct WalloraApp: App {
    @State private var catalog = CatalogViewModel()
    @State private var library = DesignLibrary()
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(catalog)
                .environment(library)
                .task { await catalog.load() }
        }
        .modelContainer(for: [FavoriteWallpaper.self, DownloadRecord.self])
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            DiscoverView().tabItem { Label("Discover", systemImage: "sparkles") }
            CategoriesView().tabItem { Label("Categories", systemImage: "square.grid.2x2.fill") }
            WidgetsView().tabItem { Label("Widgets", systemImage: "rectangle.3.group.fill") }
            FavoritesView().tabItem { Label("Favorites", systemImage: "heart.fill") }
            ProfileView().tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
    }
}
