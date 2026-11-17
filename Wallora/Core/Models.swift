import SwiftUI
import SwiftData

enum WallCategory: String, CaseIterable, Codable, Identifiable {
    case minimalist = "Minimalist", amoled = "AMOLED", nature = "Nature", mountains = "Mountains",
         space = "Space", abstract = "Abstract", architecture = "Architecture", cars = "Cars",
         anime = "Anime", technology = "Technology", dark = "Dark Aesthetic", gradients = "Gradients",
         uhd = "4K & Ultra HD", seasonal = "Seasonal"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .minimalist: return "circle.lefthalf.filled"
        case .amoled: return "moon.fill"
        case .nature: return "leaf.fill"
        case .mountains: return "mountain.2.fill"
        case .space: return "sparkles"
        case .abstract: return "scribble.variable"
        case .architecture: return "building.2.fill"
        case .cars: return "car.fill"
        case .anime: return "paintbrush.pointed.fill"
        case .technology: return "cpu"
        case .dark: return "moon.stars.fill"
        case .gradients: return "circle.hexagongrid.fill"
        case .uhd: return "4k.tv"
        case .seasonal: return "snowflake"
        }
    }
    var colors: [Color] {
        switch self {
        case .minimalist: return [Color(hex: "D9D4CA"), Color(hex: "F4F1EC")]
        case .amoled: return [.black, Color(hex: "222222")]
        case .nature: return [Color(hex: "2F5D50"), Color(hex: "9BC5A8")]
        case .mountains: return [Color(hex: "2D5B6B"), Color(hex: "EBA88A")]
        case .space: return [Color(hex: "0B0016"), Color(hex: "6A3FA0")]
        case .abstract: return [Color(hex: "1A1033"), Color(hex: "9B6DE0")]
        case .architecture: return [Color(hex: "40444B"), Color(hex: "A9AFB8")]
        case .cars: return [Color(hex: "3A0D0D"), Color(hex: "C0392B")]
        case .anime: return [Color(hex: "FF9AA2"), Color(hex: "B5A7FF")]
        case .technology: return [Color(hex: "0A1F33"), Color(hex: "2E86DE")]
        case .dark: return [Color(hex: "0B0B1A"), Color(hex: "2A2A52")]
        case .gradients: return [Color(hex: "FFB88C"), Color(hex: "DE6262")]
        case .uhd: return [Color(hex: "11998E"), Color(hex: "38EF7D")]
        case .seasonal: return [Color(hex: "A1C4FD"), Color(hex: "C2E9FB")]
        }
    }
}

struct Wallpaper: Identifiable, Hashable, Codable {
    enum Source: Hashable, Codable {
        case bundled(String)          // file in app bundle (.jpg)
        case gradient([String])       // procedurally rendered at any resolution
        case remote(thumb: URL, regular: URL, full: URL)
    }
    let id: String
    let title: String
    let category: WallCategory
    let source: Source
    var attribution: String? = nil
    var attributionURL: URL? = nil
    var downloadLocation: URL? = nil   // Unsplash requires a ping when a photo is downloaded
}

@Model final class FavoriteWallpaper {
    @Attribute(.unique) var wallpaperID: String
    var addedAt: Date
    init(wallpaperID: String) { self.wallpaperID = wallpaperID; self.addedAt = .now }
}

@Model final class DownloadRecord {
    var wallpaperID: String
    var title: String
    var date: Date
    init(wallpaperID: String, title: String) { self.wallpaperID = wallpaperID; self.title = title; self.date = .now }
}
