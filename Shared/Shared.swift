import SwiftUI
import UIKit
import WidgetKit

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
    init(r: Double, g: Double, b: Double) { self.r = r; self.g = g; self.b = b }
    init(_ color: Color) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(r: Double(r), g: Double(g), b: Double(b))
    }
}

struct WidgetDesign: Codable, Identifiable, Hashable {
    enum Kind: String, Codable, CaseIterable {
        case text, quote, countdown, date
        var title: String { rawValue.capitalized }
    }
    enum FontStyle: String, Codable, CaseIterable {
        case standard, rounded, serif, mono
        var title: String { rawValue.capitalized }
        var design: Font.Design {
            switch self {
            case .standard: return .default
            case .rounded: return .rounded
            case .serif: return .serif
            case .mono: return .monospaced
            }
        }
    }
    var id = UUID()
    var name = "My Widget"
    var kind: Kind = .text
    var text = "Stay present"
    var symbol = "sparkles"
    var foreground = RGB(r: 1, g: 1, b: 1)
    var background = RGB(r: 0.05, g: 0.05, b: 0.07)
    var fontStyle: FontStyle = .rounded
    var targetDate = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    var backgroundImage: String? = nil

    static let sample = WidgetDesign()
}

enum Quotes {
    static let all: [(text: String, author: String)] = [
        ("Begin anywhere.", "John Cage"),
        ("What we do every day matters more than what we do once in a while.", "Gretchen Rubin"),
        ("The best view comes after the hardest climb.", "Proverb"),
        ("Do the next right thing.", "Proverb"),
        ("Small steps, taken daily, move mountains.", "Proverb"),
        ("Simplicity is the ultimate sophistication.", "Leonardo da Vinci (attrib.)"),
        ("You have power over your mind, not outside events.", "Marcus Aurelius"),
        ("A journey of a thousand miles begins with a single step.", "Lao Tzu")
    ]
    static var today: (text: String, author: String) {
        let d = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return all[d % all.count]
    }
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

// MARK: - Shared widget rendering (used by the app preview AND the widget extension)

struct DesignBackground: View {
    let design: WidgetDesign
    var body: some View {
        ZStack {
            design.background.color
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

    private var days: Int {
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: .now), to: cal.startOfDay(for: design.targetDate)).day ?? 0
    }
    private var headline: String {
        switch design.kind {
        case .text: return design.text
        case .quote: return Quotes.today.text
        case .countdown: return "\(max(days, 0))"
        case .date: return Date.now.formatted(.dateTime.day())
        }
    }
    private var subline: String {
        switch design.kind {
        case .text: return design.name
        case .quote: return Quotes.today.author
        case .countdown: return "days · \(design.text)"
        case .date: return Date.now.formatted(.dateTime.weekday(.wide).month(.wide))
        }
    }
    private var bigSize: CGFloat {
        let long = design.kind == .quote || design.kind == .text
        switch family {
        case .systemSmall: return long ? 18 : 52
        case .systemMedium: return long ? 24 : 60
        default: return long ? 32 : 84
        }
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: design.symbol).font(.caption)
                    Text(design.kind == .countdown ? "\(max(days, 0))" : design.kind == .date ? Date.now.formatted(.dateTime.day()) : String(design.text.prefix(3)))
                        .font(.system(.title3, design: design.fontStyle.design, weight: .semibold)).minimumScaleFactor(0.5)
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Label(design.kind == .countdown ? design.text : design.name, systemImage: design.symbol)
                    .font(.system(.caption, design: design.fontStyle.design, weight: .bold))
                Text(design.kind == .countdown ? "\(max(days, 0)) days" : headline)
                    .font(.system(.footnote, design: design.fontStyle.design)).lineLimit(2)
            }.frame(maxWidth: .infinity, alignment: .leading)
        case .accessoryInline:
            Label(design.kind == .countdown ? "\(max(days, 0))d · \(design.text)" : headline, systemImage: design.symbol)
        default:
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: design.symbol).font(.title3.weight(.semibold))
                Spacer(minLength: 0)
                Text(headline)
                    .font(.system(size: bigSize, weight: .semibold, design: design.fontStyle.design))
                    .minimumScaleFactor(0.5).lineLimit(design.kind == .quote || design.kind == .text ? 5 : 1)
                Text(subline).font(.system(.caption, design: design.fontStyle.design)).opacity(0.7).lineLimit(1)
            }
            .foregroundStyle(design.foreground.color)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(family == .systemSmall ? 2 : 6)
        }
    }
}
