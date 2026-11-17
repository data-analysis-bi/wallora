import SwiftUI
import UIKit
import WidgetKit
import ImageIO

enum AppGroup {
    static let id = "group.com.wallora.app"
    /// Falls back to Documents if the App Group isn't available (e.g. sideload signing dropped it).
    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    static var isShared: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) != nil
    }
}

extension Color {
    init(hex: String) {
        var v: UInt64 = 0
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}

struct RGB: Codable, Hashable {
    var r: Double, g: Double, b: Double
    var color: Color { Color(red: r, green: g, blue: b) }
    var hex: String { String(format: "%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded())) }
    /// Accepts "FF9933" or "#ff9933"; returns nil for anything else.
    static func fromHex(_ text: String?) -> RGB? {
        guard let t = text?.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: ""),
              t.count == 6, t.allSatisfy({ $0.isHexDigit }) else { return nil }
        return RGB(Color(hex: t))
    }
    init(r: Double, g: Double, b: Double) { self.r = r; self.g = g; self.b = b }
    init(_ color: Color) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(r: Double(r), g: Double(g), b: Double(b))
    }
}

// MARK: - Languages, themes, shlokas

enum ShlokaLanguage: String, Codable, CaseIterable, Identifiable {
    case sanskrit, sanskritGu, english, hindi, gujarati, sanskritEnglish
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sanskrit: return "Sanskrit (देवनागरी)"
        case .sanskritGu: return "Sanskrit (ગુજરાતી લિપિ)"
        case .english: return "English"
        case .hindi: return "हिन्दी"
        case .gujarati: return "ગુજરાતી"
        case .sanskritEnglish: return "Sanskrit + English"
        }
    }
}

enum WalloraTheme: String, Codable, CaseIterable, Identifiable {
    case saffron, midnight, parchment, lotus, forest, amoled
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var colors: (fg: String, bg: String, bg2: String) {
        switch self {
        case .saffron: return ("FFF8E7", "E8761E", "B5460F")
        case .midnight: return ("F2E9D8", "1B1F3B", "0B0D1C")
        case .parchment: return ("3B2A1A", "F4E9D3", "E3D0A8")
        case .lotus: return ("FFE9F3", "A8467F", "5C1F4A")
        case .forest: return ("E6F2E6", "2E5A45", "14302A")
        case .amoled: return ("FFFFFF", "000000", "000000")
        }
    }
}

struct Shloka: Codable, Identifiable, Hashable {
    let id: String
    let ref: String
    let sa: String
    let en: String
    let hi: String
    let gu: String
}

enum Script {
    /// Devanagari → Gujarati script (the two Unicode blocks are laid out in parallel, 0x180 apart).
    static func gujarati(_ s: String) -> String {
        var out = String.UnicodeScalarView()
        for u in s.unicodeScalars {
            let v = u.value
            if ((0x0901...0x0963).contains(v) || (0x0966...0x096F).contains(v)),
               let n = Unicode.Scalar(v + 0x180), n.properties.generalCategory != .unassigned {
                out.append(n)
            } else { out.append(u) }
        }
        return String(out)
    }
}

enum ShlokaStore {
    static let all: [Shloka] = {
        guard let url = Bundle.main.url(forResource: "ramayana_curated", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Shloka].self, from: data) else { return [] }
        return list
    }()

    /// Consecutive slots step through the list, so you see a new verse each day (or every N hours).
    static func pick(at date: Date, rotationHours: Int) -> Shloka? {
        guard !all.isEmpty else { return nil }
        let h = max(1, min(rotationHours, 24))
        let cal = Calendar.current
        let days = Int(cal.startOfDay(for: date).timeIntervalSince1970 / 86_400)
        let slot = cal.component(.hour, from: date) / h
        let index = days * (24 / h) + slot
        return all[((index % all.count) + all.count) % all.count]
    }

    /// Lines to show for a language (primary first).
    static func lines(_ s: Shloka, _ lang: ShlokaLanguage) -> [String] {
        switch lang {
        case .sanskrit: return [s.sa]
        case .sanskritGu: return [Script.gujarati(s.sa)]
        case .english: return [s.en]
        case .hindi: return [s.hi]
        case .gujarati: return [s.gu]
        case .sanskritEnglish: return [s.sa, s.en]
        }
    }
}

// MARK: - Widget design model

struct WidgetDesign: Codable, Identifiable, Hashable {
    enum Kind: String, Codable, CaseIterable {
        case shloka, text, countdown, date
        var title: String {
            switch self { case .shloka: return "Ramayana shloka"; case .text: return "Custom text"; case .countdown: return "Countdown"; case .date: return "Date" }
        }
        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Kind(rawValue: raw) ?? .shloka   // older builds saved "quote"
        }
    }
    enum FontStyle: String, Codable, CaseIterable {
        case standard, rounded, serif, mono
        var title: String { rawValue.capitalized }
        var design: Font.Design {
            switch self { case .standard: return .default; case .rounded: return .rounded; case .serif: return .serif; case .mono: return .monospaced }
        }
    }

    var id = UUID()
    var name = "My Widget"
    var kind: Kind = .shloka
    var text = "Jai Shri Ram"
    var symbol = "sparkles"
    var language: ShlokaLanguage = .sanskritEnglish
    var rotationHours = 24
    var foreground = RGB(Color(hex: "FFF8E7"))
    var background = RGB(Color(hex: "E8761E"))
    var background2: RGB? = RGB(Color(hex: "B5460F"))
    var fontStyle: FontStyle = .serif
    var targetDate = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    var backgroundImage: String? = nil

    init() {}

    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        name = (try? c.decode(String.self, forKey: .name)) ?? name
        kind = (try? c.decode(Kind.self, forKey: .kind)) ?? .shloka
        text = (try? c.decode(String.self, forKey: .text)) ?? text
        symbol = (try? c.decode(String.self, forKey: .symbol)) ?? symbol
        language = (try? c.decode(ShlokaLanguage.self, forKey: .language)) ?? language
        rotationHours = (try? c.decode(Int.self, forKey: .rotationHours)) ?? 24
        foreground = (try? c.decode(RGB.self, forKey: .foreground)) ?? foreground
        background = (try? c.decode(RGB.self, forKey: .background)) ?? background
        background2 = try? c.decode(RGB.self, forKey: .background2)
        fontStyle = (try? c.decode(FontStyle.self, forKey: .fontStyle)) ?? fontStyle
        targetDate = (try? c.decode(Date.self, forKey: .targetDate)) ?? targetDate
        backgroundImage = try? c.decode(String.self, forKey: .backgroundImage)
    }

    mutating func apply(theme: WalloraTheme) {
        let t = theme.colors
        foreground = RGB(Color(hex: t.fg)); background = RGB(Color(hex: t.bg)); background2 = RGB(Color(hex: t.bg2))
    }

    static let sample = WidgetDesign()
}

enum DesignStore {
    static var url: URL { AppGroup.containerURL.appendingPathComponent("designs.json") }

    static func load() -> [WidgetDesign] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([WidgetDesign].self, from: data)) ?? []
    }
    static func save(_ designs: [WidgetDesign]) {
        if let data = try? JSONEncoder().encode(designs) { try? data.write(to: url, options: .atomic) }
    }
    static func saveBackground(_ image: UIImage, id: UUID) -> String? {
        let maxSide: CGFloat = 1000
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1
        let small = UIGraphicsImageRenderer(size: size, format: fmt).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        let name = "bg-\(id.uuidString)-\(Int(Date().timeIntervalSince1970)).jpg"
        guard let data = small.jpegData(compressionQuality: 0.8) else { return nil }
        try? data.write(to: AppGroup.containerURL.appendingPathComponent(name), options: .atomic)
        return name
    }
    static func image(named: String) -> UIImage? {
        UIImage(contentsOfFile: AppGroup.containerURL.appendingPathComponent(named).path)
    }
}

// MARK: - Shared widget rendering (app preview AND widget extension)

struct DesignBackground: View {
    let design: WidgetDesign
    var body: some View {
        ZStack {
            if let b2 = design.background2 {
                LinearGradient(colors: [design.background.color, b2.color], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else { design.background.color }
            if let name = design.backgroundImage, let img = DesignStore.image(named: name) {
                Color.clear.overlay(Image(uiImage: img).resizable().scaledToFill()).clipped()
                Color.black.opacity(0.28)
            }
        }
    }
}

struct DesignContent: View {
    let design: WidgetDesign
    let family: WidgetFamily
    var date: Date = .now

    private var days: Int {
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: design.targetDate)).day ?? 0
    }
    private var shloka: Shloka? { ShlokaStore.pick(at: date, rotationHours: design.rotationHours) }
    private var verseLines: [String] { shloka.map { ShlokaStore.lines($0, design.language) } ?? ["Add ramayana_curated.json"] }

    private func f(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font { .system(size: size, weight: weight, design: design.fontStyle.design) }

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    if !design.symbol.isEmpty && design.kind != .shloka { Image(systemName: design.symbol).font(.caption) }
                    Text(circularText).font(f(design.kind == .shloka ? 22 : 18)).minimumScaleFactor(0.5)
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                switch design.kind {
                case .shloka:
                    Text(verseLines[0].replacingOccurrences(of: "\n", with: " ")).font(f(12, .medium)).lineLimit(3).minimumScaleFactor(0.7)
                    if let s = shloka { Text(s.ref).font(.system(size: 10)).opacity(0.7).lineLimit(1) }
                case .countdown:
                    Label(design.text, systemImage: design.symbol).font(f(12, .bold))
                    Text("\(max(days, 0)) days").font(f(14))
                case .date:
                    Text(date.formatted(.dateTime.weekday(.wide))).font(f(14, .bold))
                    Text(date.formatted(.dateTime.month(.wide).day())).font(f(12, .regular))
                case .text:
                    Text(design.text).font(f(13)).lineLimit(3)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        case .accessoryInline:
            switch design.kind {
            case .shloka: Label(shloka?.ref ?? "Ramayana", systemImage: "sparkles")
            case .countdown: Label("\(max(days, 0))d · \(design.text)", systemImage: design.symbol.isEmpty ? "hourglass" : design.symbol)
            case .date: Text(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
            case .text: Text(design.text)
            }
        default:
            homeLayout
        }
    }

    private var circularText: String {
        switch design.kind {
        case .shloka: return "ॐ"
        case .countdown: return "\(max(days, 0))"
        case .date: return date.formatted(.dateTime.day())
        case .text: return String(design.text.prefix(3))
        }
    }

    private var homeLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !design.symbol.isEmpty {
                Image(systemName: design.symbol).font(.footnote.weight(.semibold)).widgetAccentable()
            }
            Spacer(minLength: 0)
            switch design.kind {
            case .shloka:
                let primary: CGFloat = family == .systemSmall ? 14 : (family == .systemMedium ? 17 : 23)
                let lines = family == .systemSmall ? Array(verseLines.prefix(1)) : verseLines
                ForEach(lines.indices, id: \.self) { i in
                    Text(lines[i]).font(f(i == 0 ? primary : primary * 0.72, i == 0 ? .semibold : .regular))
                        .opacity(i == 0 ? 1 : 0.85).minimumScaleFactor(0.55).widgetAccentable(i == 0)
                }
                if let s = shloka { Text(s.ref).font(.system(size: 10, design: design.fontStyle.design)).opacity(0.65).lineLimit(1) }
            case .text:
                Text(design.text).font(f(family == .systemSmall ? 22 : 32)).minimumScaleFactor(0.5).widgetAccentable()
                Text(design.name).font(.caption).opacity(0.7)
            case .countdown:
                Text("\(max(days, 0))").font(f(family == .systemSmall ? 52 : 70)).widgetAccentable()
                Text("days · \(design.text)").font(.caption).opacity(0.75).lineLimit(1)
            case .date:
                Text(date.formatted(.dateTime.day())).font(f(family == .systemSmall ? 52 : 70)).widgetAccentable()
                Text(date.formatted(.dateTime.weekday(.wide).month(.wide))).font(.caption).opacity(0.75)
            }
        }
        .foregroundStyle(design.foreground.color)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}


enum ImageTools {
    /// Widgets have a small memory budget, so large photos are shrunk with ImageIO before drawing.
    static func downsample(_ data: Data, maxPixel: CGFloat = 900) -> UIImage? {
        guard let src = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary) else { return nil }
        let opts: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceShouldCacheImmediately: true,
                                     kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceThumbnailMaxPixelSize: maxPixel]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        return UIImage(cgImage: cg)
    }
}
