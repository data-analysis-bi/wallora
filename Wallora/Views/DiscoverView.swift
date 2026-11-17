import SwiftUI

struct DiscoverView: View {
    @Environment(CatalogViewModel.self) private var catalog
    @State private var query = ""
    @State private var hero: Wallpaper?

    var body: some View {
        NavigationStack {
            ScrollView {
                if query.isEmpty {
                    VStack(alignment: .leading, spacing: 22) {
                        Button { hero = catalog.daily } label: {
                            Color.clear.frame(height: 400).frame(maxWidth: .infinity)
                                .overlay(WallpaperImage(wallpaper: catalog.daily, full: true))
                                .overlay(LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom))
                                .overlay(alignment: .bottomLeading) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("WALLPAPER OF THE DAY").font(.caption2.weight(.semibold)).tracking(1.4).opacity(0.8)
                                        Text(catalog.daily.title).font(.system(.title, design: .rounded, weight: .bold))
                                    }.foregroundStyle(.white).padding(22)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                                .padding(.horizontal)
                        }.buttonStyle(.plain)

                        ShlokaOfTheDayCard()

                        Text("Featured").font(.title2.bold()).padding(.horizontal)
                        WallpaperGrid(wallpapers: catalog.featured)
                        if !catalog.hasRemote {
                            Label("Add an Unsplash key in Profile to unlock thousands more photos.", systemImage: "key.fill")
                                .font(.footnote).foregroundStyle(.secondary).padding(.horizontal)
                        }
                    }.padding(.bottom, 30)
                } else {
                    WallpaperGrid(wallpapers: catalog.search(query))
                }
            }
            .navigationTitle("Discover")
            .searchable(text: $query, prompt: "Search wallpapers & categories")
            .toolbar {
                Button { hero = catalog.random() } label: { Image(systemName: "dice.fill") }
            }
            .fullScreenCover(item: $hero) { ViewerView(wallpaper: $0) }
        }
    }
}

struct CategoriesView: View {
    @Environment(CatalogViewModel.self) private var catalog
    private let cols = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: cols, spacing: 14) {
                    ForEach(WallCategory.allCases) { c in
                        NavigationLink(value: c) {
                            ZStack(alignment: .bottomLeading) {
                                LinearGradient(colors: c.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                Image(systemName: c.symbol).font(.system(size: 46)).foregroundStyle(.white.opacity(0.22))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(14)
                                VStack(alignment: .leading) {
                                    Text(c.rawValue).font(.system(.headline, design: .rounded))
                                    Text("\(catalog.wallpapers(in: c).count) wallpapers").font(.caption).opacity(0.8)
                                }.foregroundStyle(.white).padding(14)
                            }
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                    }
                }.padding()
            }
            .navigationTitle("Categories")
            .navigationDestination(for: WallCategory.self) { c in
                ScrollView {
                    let items = catalog.wallpapers(in: c)
                    if items.isEmpty {
                        ContentUnavailableView("Nothing here yet", systemImage: c.symbol,
                                               description: Text("Add an Unsplash access key in Profile to browse licensed photos."))
                    } else { WallpaperGrid(wallpapers: items) }
                }.navigationTitle(c.rawValue)
            }
        }
    }
}
