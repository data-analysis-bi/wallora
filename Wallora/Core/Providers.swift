import Foundation
import Security

enum ProviderError: LocalizedError {
    case http(Int)
    var errorDescription: String? {
        switch self {
        case .http(401): return "Unsplash rejected the key (401). Check you pasted the Access Key."
        case .http(403): return "Unsplash rate limit reached (demo keys: 50 requests/hour). Try again later."
        case .http(let c): return "Unsplash error \(c)."
        }
    }
}

enum BundledProvider {
    private static func g(_ id: String, _ title: String, _ cat: WallCategory, _ hex: [String]) -> Wallpaper {
        Wallpaper(id: "g-\(id)", title: title, category: cat, source: .gradient(hex))
    }
    private static func p(_ n: String, _ title: String, _ cat: WallCategory, _ style: String, _ seed: Int, _ pal: [String]) -> Wallpaper {
        Wallpaper(id: "p-\(n)", title: title, category: cat, source: .procedural(style: style, seed: seed, palette: pal))
    }

    static let catalog: [Wallpaper] = [
        Wallpaper(id: "b-dusk", title: "Dusk Ridges", category: .mountains, source: .bundled("dusk-ridges")),
        Wallpaper(id: "b-orbs", title: "Violet Orbs", category: .abstract, source: .bundled("violet-orbs")),

        // Mountains
        p("golden", "Golden Hour", .mountains, "ridges", 11, ["FBD3A1", "F29E75", "8DA9A6", "5C8A92", "3A6877", "22465A", "0F2A3A"]),
        p("mist", "Misty Pines", .mountains, "ridges", 23, ["CFE0DC", "A9C5C0", "8FB0AD", "5F8B8C", "3B6468", "1E3F45"]),
        p("rose", "Rose Peaks", .mountains, "ridges", 37, ["F6D5D0", "E6A3B1", "B58BA8", "865F8E", "5A3E73", "2E1F4D"]),
        p("night", "Night Range", .mountains, "ridges", 41, ["0B1026", "2A3A6B", "2F4A7A", "203A66", "142850", "0A1630"]),
        p("desert", "Desert Dusk", .mountains, "ridges", 53, ["FFD9A8", "F08A5D", "C46A55", "8E4A4F", "5A334A", "2F1F3D"]),
        p("emerald", "Emerald Valley", .nature, "ridges", 67, ["D6F0E0", "9CD3B8", "6DB39A", "3F8C7C", "23665F", "0F3E3F"]),
        p("forest", "Forest Haze", .nature, "ridges", 71, ["E4EFE0", "B7D3B0", "8FBA8C", "5E9A6B", "3A7050", "1F4535"]),

        // Seasonal
        p("autumn", "Autumn Hills", .seasonal, "ridges", 83, ["FFE2B8", "F2A65A", "D9823B", "B25F2E", "7F3F25", "4A2A1E"]),
        p("winter", "Winter Frost", .seasonal, "ridges", 97, ["E8F1FA", "C6DCEF", "A9C4DD", "7FA3C6", "567FA8", "34567F"]),
        p("spring", "Spring Bloom", .seasonal, "ridges", 101, ["FDE5EC", "F9C0D0", "EBA3BC", "C98AB0", "8F6A9E", "5B4B85"]),
        p("summer", "Summer Sunset", .seasonal, "waves", 5, ["FFB347", "FF5E62", "FF8F6B", "E8506A", "A83279"]),

        // Space
        p("cosmic", "Cosmic Dust", .space, "stars", 3, ["05000C", "1A0B3A", "6A3FA0"]),
        p("deepfield", "Deep Field", .space, "stars", 8, ["000000", "050A24", "1F3A93"]),
        p("crimson", "Crimson Night", .space, "stars", 13, ["0A0003", "2A0A14", "C0392B"]),
        p("tealneb", "Teal Nebula", .space, "stars", 19, ["00060A", "06303A", "2EC4B6"]),

        // Abstract
        p("violet-ecl", "Violet Eclipse", .abstract, "orbs", 0, ["050507", "6A3FA0", "B28DFF"]),
        p("amber-ecl", "Amber Eclipse", .abstract, "orbs", 0, ["060403", "C0702A", "FFC27A"]),
        p("azure-ecl", "Azure Eclipse", .abstract, "orbs", 0, ["03060A", "1F6FEB", "8CC8FF"]),
        p("rose-ecl", "Rose Eclipse", .abstract, "orbs", 0, ["070305", "C2185B", "FF8AB5"]),
        p("ocean", "Ocean Drift", .abstract, "waves", 29, ["0B1D3A", "184E77", "1E6091", "168AAD", "76C893"]),
        p("silk", "Sunset Silk", .abstract, "waves", 31, ["2B0F3A", "5B1A57", "A8326B", "E0577A", "FF9A76"]),
        p("mint", "Mint Silk", .abstract, "waves", 43, ["0F2B2B", "164E4E", "2A7F7A", "3FB3A0", "9FE8C9"]),

        // Technology
        p("neon", "Neon Grid", .technology, "grid", 0, ["02040D", "0A1A3A", "2E86DE"]),
        p("matrix", "Matrix Green", .technology, "grid", 0, ["000A05", "001F12", "2EE59D"]),
        p("magenta", "Magenta Grid", .technology, "grid", 0, ["08020D", "1E0A33", "E040FB"]),
        g("circuit", "Circuit", .technology, ["02111F", "0B3D6B", "2E86DE"]),

        // Minimalist
        p("halo", "Halo", .minimalist, "rings", 0, ["F4F1EC", "E3DED3", "8A8577"]),
        p("ripple-dark", "Ripple Dark", .minimalist, "rings", 0, ["14161A", "1F2329", "8C96A3"]),
        p("ripple-blue", "Ripple Blue", .minimalist, "rings", 0, ["EAF2F8", "CFE0EE", "5B87B3"]),
        g("paper", "Paper", .minimalist, ["F4F1EC", "D9D4CA"]),
        g("slate", "Slate", .minimalist, ["3A3F47", "1A1D22"]),

        // AMOLED
        g("void", "Void", .amoled, ["000000", "000000"]),
        g("ember", "Ember Edge", .amoled, ["000000", "000000", "2A0E0E"]),
        p("blackhalo", "Black Halo", .amoled, "rings", 0, ["000000", "000000", "6A6A6A"]),
        p("violet-edge", "Violet Edge", .amoled, "orbs", 0, ["000000", "3A1C71", "9B6DE0"]),

        // Dark aesthetic
        g("midnight", "Midnight", .dark, ["0B0B1A", "1B1B3A"]),
        g("graphite", "Graphite", .dark, ["0D0D0D", "2B2B2B"]),
        p("dunes", "Dark Dunes", .dark, "waves", 47, ["0B0B12", "15151F", "1D1D2B", "262638", "31314A"]),
        p("ink", "Ink Ridges", .dark, "ridges", 59, ["1B1B2A", "0F0F1A", "1A1A2C", "141424", "0E0E1C", "08080F"]),

        // Gradients
        g("aurora", "Aurora", .gradients, ["0F2027", "2C5364", "6DD5ED"]),
        g("peach", "Peach Fizz", .gradients, ["FFB88C", "DE6262"]),
        g("lagoon", "Lagoon", .gradients, ["0F3443", "34E89E"]),
        g("violetnight", "Violet Night", .gradients, ["1A1033", "6A3FA0", "D76D77"]),
        g("frost", "Frost", .seasonal, ["A1C4FD", "C2E9FB"]),
        g("nebula", "Nebula", .gradients, ["05000C", "3A1C71", "D76D77"]),
        g("deepspace", "Deep Space", .gradients, ["000000", "0B1026", "1F3A93"])
    ]
}

/// Unsplash (licensed). Needs your own Access Key from unsplash.com/developers.
struct UnsplashProvider {
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

    func fetch(query: String, category: WallCategory) async throws -> [Wallpaper] {
        var c = URLComponents(string: "https://api.unsplash.com/search/photos")!
        c.queryItems = [.init(name: "query", value: query), .init(name: "orientation", value: "portrait"), .init(name: "per_page", value: "20")]
        var req = URLRequest(url: c.url!)
        req.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode != 200 { throw ProviderError.http(http.statusCode) }
        return try JSONDecoder().decode(Search.self, from: data).results.map {
            Wallpaper(id: "u-\($0.id)", title: ($0.description ?? $0.alt_description ?? "Photo").capitalized,
                      category: category, source: .remote(thumb: $0.urls.small, regular: $0.urls.regular, full: $0.urls.full),
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
