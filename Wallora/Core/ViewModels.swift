import SwiftUI
import WidgetKit

@MainActor @Observable
final class CatalogViewModel {
    var all: [Wallpaper] = BundledProvider.catalog
    var hasRemote = false
    var isLoading = false
    var status: String?
    private var remote: [Wallpaper] = []

    private static let queries: [(WallCategory, String)] = [
        (.nature, "nature landscape"), (.mountains, "mountains"), (.space, "galaxy night sky"),
        (.abstract, "abstract art"), (.architecture, "modern architecture"), (.cars, "supercar"),
        (.anime, "illustration art"), (.technology, "technology dark"), (.dark, "dark moody"),
        (.minimalist, "minimal"), (.amoled, "black minimal"), (.gradients, "gradient"),
        (.uhd, "landscape"), (.seasonal, "autumn winter")
    ]
    private struct Cache: Codable { var date: Date; var items: [Wallpaper] }
    private var cacheURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("remote-catalog.json")
    }

    /// Cached for 12 h so we stay far below Unsplash's rate limit.
    func load(force: Bool = false) async {
        guard let key = Keychain.get("unsplash"), !key.isEmpty else { remote = []; apply(); status = nil; return }
        if let data = try? Data(contentsOf: cacheURL), let c = try? JSONDecoder().decode(Cache.self, from: data), !c.items.isEmpty {
            remote = c.items; apply()
            if !force && Date().timeIntervalSince(c.date) < 12 * 3600 { status = "\(remote.count) photos (cached)"; return }
        }
        isLoading = true; defer { isLoading = false }
        let provider = UnsplashProvider(accessKey: key)
        var fresh: [Wallpaper] = []; var seen = Set<String>(); var lastError: String?
        for (cat, q) in Self.queries {
            do {
                for w in try await provider.fetch(query: q, category: cat) where seen.insert(w.id).inserted { fresh.append(w) }
            } catch { lastError = error.localizedDescription; if case ProviderError.http = error { break } }
        }
        if fresh.isEmpty { status = lastError ?? "No photos returned."; return }
        remote = fresh; apply()
        status = "\(fresh.count) photos loaded" + (lastError.map { " — \($0)" } ?? "")
        if let data = try? JSONEncoder().encode(Cache(date: .now, items: fresh)) { try? data.write(to: cacheURL, options: .atomic) }
    }

    private func apply() { hasRemote = !remote.isEmpty; all = BundledProvider.catalog + remote }

    var daily: Wallpaper {
        let d = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return all[d % all.count]
    }
    /// Two from every category so the home feed is varied.
    var featured: [Wallpaper] { WallCategory.allCases.flatMap { Array(wallpapers(in: $0).prefix(2)) } }
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
