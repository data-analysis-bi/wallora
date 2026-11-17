import Foundation
import Security

protocol WallpaperProvider {
    func fetch(query: String) async throws -> [Wallpaper]
}

enum BundledProvider {
    private static func g(_ id: String, _ title: String, _ cat: WallCategory, _ hex: [String]) -> Wallpaper {
        Wallpaper(id: "g-\(id)", title: title, category: cat, source: .gradient(hex))
    }
    static let catalog: [Wallpaper] = [
        Wallpaper(id: "b-dusk", title: "Dusk Ridges", category: .mountains, source: .bundled("dusk-ridges")),
        Wallpaper(id: "b-orbs", title: "Violet Orbs", category: .abstract, source: .bundled("violet-orbs")),
        g("void", "Void", .amoled, ["000000", "000000"]),
        g("ember", "Ember Edge", .amoled, ["000000", "000000", "2A0E0E"]),
        g("paper", "Paper", .minimalist, ["F4F1EC", "D9D4CA"]),
        g("slate", "Slate", .minimalist, ["3A3F47", "1A1D22"]),
        g("aurora", "Aurora", .gradients, ["0F2027", "2C5364", "6DD5ED"]),
        g("peach", "Peach Fizz", .gradients, ["FFB88C", "DE6262"]),
        g("lagoon", "Lagoon", .gradients, ["0F3443", "34E89E"]),
        g("violetnight", "Violet Night", .gradients, ["1A1033", "6A3FA0", "D76D77"]),
        g("nebula", "Nebula", .space, ["05000C", "3A1C71", "D76D77"]),
        g("deepspace", "Deep Space", .space, ["000000", "0B1026", "1F3A93"]),
        g("midnight", "Midnight", .dark, ["0B0B1A", "1B1B3A"]),
        g("graphite", "Graphite", .dark, ["0D0D0D", "2B2B2B"]),
        g("circuit", "Circuit", .technology, ["02111F", "0B3D6B", "2E86DE"]),
        g("frost", "Frost", .seasonal, ["A1C4FD", "C2E9FB"])
    ]
}

/// Unsplash (licensed). Needs your own Access Key from unsplash.com/developers.
struct UnsplashProvider: WallpaperProvider {
    let accessKey: String

    private struct Result: Decodable {
        struct Urls: Decodable { let small: URL; let regular: URL; let full: URL }
        struct User: Decodable { let name: String; let links: Links }
        struct Links: Decodable { let html: URL }
        struct PhotoLinks: Decodable { let download_location: URL }
        let id: String; let description: String?; let alt_description: String?
        let urls: Urls; let user: User; let links: PhotoLinks
    }
    private struct Search: Decodable { let results: [Result] }

    func fetch(query: String) async throws -> [Wallpaper] {
        var c = URLComponents(string: "https://api.unsplash.com/search/photos")!
        c.queryItems = [.init(name: "query", value: query), .init(name: "orientation", value: "portrait"), .init(name: "per_page", value: "30")]
        var req = URLRequest(url: c.url!)
        req.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(Search.self, from: data).results.map {
            Wallpaper(id: "u-\($0.id)", title: ($0.description ?? $0.alt_description ?? "Photo").capitalized,
                      category: .nature, source: .remote(thumb: $0.urls.small, regular: $0.urls.regular, full: $0.urls.full),
                      attribution: "Photo by \($0.user.name) on Unsplash", attributionURL: $0.user.links.html,
                      downloadLocation: $0.links.download_location)
        }
    }

    func trackDownload(_ url: URL) async {
        var req = URLRequest(url: url)
        req.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: req)
    }
}

enum Keychain {
    static func set(_ value: String, for key: String) {
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key]
        SecItemDelete(base as CFDictionary)
        guard !value.isEmpty else { return }
        var add = base; add[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(add as CFDictionary, nil)
    }
    static func get(_ key: String) -> String? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key,
                                kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let d = out as? Data else { return nil }
        return String(data: d, encoding: .utf8)
    }
}
