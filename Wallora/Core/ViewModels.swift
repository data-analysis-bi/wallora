import SwiftUI
import WidgetKit

@MainActor @Observable
final class CatalogViewModel {
    var all: [Wallpaper] = BundledProvider.catalog
    var hasRemote = false

    func load() async {
        guard let key = Keychain.get("unsplash"), !key.isEmpty else { hasRemote = false; all = BundledProvider.catalog; return }
        let provider = UnsplashProvider(accessKey: key)
        var remote: [Wallpaper] = []
        for q in ["minimal wallpaper", "mountains", "architecture", "space", "dark abstract"] {
            if let r = try? await provider.fetch(query: q) { remote += r }
        }
        hasRemote = !remote.isEmpty
        all = BundledProvider.catalog + remote
    }
    var daily: Wallpaper {
        let d = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return all[d % all.count]
    }
    var featured: [Wallpaper] { Array(all.prefix(12)) }
    func random() -> Wallpaper { all.randomElement() ?? daily }
    func wallpapers(in c: WallCategory) -> [Wallpaper] { all.filter { $0.category == c } }
    func search(_ q: String) -> [Wallpaper] {
        let t = q.lowercased()
        return all.filter { $0.title.lowercased().contains(t) || $0.category.rawValue.lowercased().contains(t) }
    }
}

@MainActor @Observable
final class DesignLibrary {
    var designs: [WidgetDesign] = DesignStore.load()
    func upsert(_ d: WidgetDesign) {
        if let i = designs.firstIndex(where: { $0.id == d.id }) { designs[i] = d } else { designs.append(d) }
        persist()
    }
    func delete(_ d: WidgetDesign) { designs.removeAll { $0.id == d.id }; persist() }
    func reload() { designs = DesignStore.load() }
    private func persist() { DesignStore.save(designs); WidgetCenter.shared.reloadAllTimelines() }
}
