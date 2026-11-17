import WidgetKit
import SwiftUI
import AppIntents
import UniformTypeIdentifiers

@main
struct WalloraWidgetBundle: WidgetBundle {
    var body: some Widget {
        DesignWidget()
        CalendarWidget()
        AnalogClockWidget()
        DateAccessoryWidget()
    }
}

// MARK: - Configurable widget (Edit Widget panel — works without App Groups)

enum ContentOption: String, AppEnum {
    case shloka, text, countdown, date
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Content"
    static var caseDisplayRepresentations: [ContentOption: DisplayRepresentation] = [
        .shloka: "Ramayana shloka", .text: "Custom text", .countdown: "Countdown", .date: "Today's date"]
    var kind: WidgetDesign.Kind {
        switch self { case .shloka: return .shloka; case .text: return .text; case .countdown: return .countdown; case .date: return .date }
    }
}

enum LanguageOption: String, AppEnum {
    case sanskritEnglish, sanskrit, sanskritGu, english, hindi, gujarati
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Language"
    static var caseDisplayRepresentations: [LanguageOption: DisplayRepresentation] = [
        .sanskritEnglish: "Sanskrit + English", .sanskrit: "Sanskrit (देवनागरी)", .sanskritGu: "Sanskrit (ગુજરાતી લિપિ)",
        .english: "English", .hindi: "हिन्दी", .gujarati: "ગુજરાતી"]
    var value: ShlokaLanguage { ShlokaLanguage(rawValue: rawValue) ?? .sanskritEnglish }
}

enum ThemeOption: String, AppEnum {
    case saffron, midnight, parchment, lotus, forest, amoled
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Theme"
    static var caseDisplayRepresentations: [ThemeOption: DisplayRepresentation] = [
        .saffron: "Saffron", .midnight: "Midnight", .parchment: "Parchment", .lotus: "Lotus", .forest: "Forest", .amoled: "AMOLED black"]
    var value: WalloraTheme { WalloraTheme(rawValue: rawValue) ?? .saffron }
}

enum FontOption: String, AppEnum {
    case serif, rounded, standard, mono
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Font"
    static var caseDisplayRepresentations: [FontOption: DisplayRepresentation] = [
        .serif: "Serif", .rounded: "Rounded", .standard: "Standard", .mono: "Monospaced"]
    var value: WidgetDesign.FontStyle { WidgetDesign.FontStyle(rawValue: rawValue) ?? .serif }
}

enum SymbolOption: String, AppEnum {
    case sparkles, sun = "sun.max.fill", moon = "moon.stars.fill", leaf = "leaf.fill", flame = "flame.fill",
         heart = "heart.fill", bolt = "bolt.fill", book = "book.fill", noSymbol = ""
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Symbol"
    static var caseDisplayRepresentations: [SymbolOption: DisplayRepresentation] = [
        .sparkles: "Sparkles", .sun: "Sun", .moon: "Moon", .leaf: "Leaf", .flame: "Flame", .heart: "Heart", .bolt: "Bolt", .book: "Book", .noSymbol: "None"]
}

enum RotationOption: String, AppEnum {
    case daily, twelve, six, three, hourly
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Change shloka"
    static var caseDisplayRepresentations: [RotationOption: DisplayRepresentation] = [
        .daily: "Every day", .twelve: "Every 12 hours", .six: "Every 6 hours", .three: "Every 3 hours", .hourly: "Every hour"]
    var hours: Int {
        switch self { case .daily: return 24; case .twelve: return 12; case .six: return 6; case .three: return 3; case .hourly: return 1 }
    }
}

struct DesignEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Saved design"
    static var defaultQuery = DesignQuery()
    var id: String
    var name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct DesignQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [DesignEntity] {
        DesignStore.load().filter { identifiers.contains($0.id.uuidString) }
            .map { DesignEntity(id: $0.id.uuidString, name: $0.name) }
    }
    func suggestedEntities() async throws -> [DesignEntity] {
        DesignStore.load().map { DesignEntity(id: $0.id.uuidString, name: $0.name) }
    }
}

struct SelectDesignIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Customize"
    static var description = IntentDescription("Choose what the widget shows and how it looks.")

    @Parameter(title: "Content", default: .shloka) var content: ContentOption
    @Parameter(title: "Language", default: .sanskritEnglish) var language: LanguageOption
    @Parameter(title: "Theme", default: .saffron) var theme: ThemeOption
    @Parameter(title: "Font", default: .serif) var font: FontOption
    @Parameter(title: "Symbol", default: .sparkles) var symbol: SymbolOption
    @Parameter(title: "Change shloka", default: .daily) var rotation: RotationOption
    @Parameter(title: "Custom text / event name") var text: String?
    @Parameter(title: "Countdown date") var date: Date?
    @Parameter(title: "Text color (hex, optional)") var textHex: String?
    @Parameter(title: "Background color (hex, optional)") var backgroundHex: String?
    @Parameter(title: "Background photo", supportedTypeIdentifiers: ["public.image"]) var photo: IntentFile?
    @Parameter(title: "Saved design (optional)") var design: DesignEntity?
}

struct DesignEntry: TimelineEntry {
    let date: Date
    let design: WidgetDesign
    var photo: UIImage? = nil
}

struct DesignProvider: AppIntentTimelineProvider {
    private func makeDesign(_ c: SelectDesignIntent) -> WidgetDesign {
        if let id = c.design?.id, let saved = DesignStore.load().first(where: { $0.id.uuidString == id }) { return saved }
        var d = WidgetDesign()
        d.kind = c.content.kind
        d.language = c.language.value
        d.fontStyle = c.font.value
        d.symbol = c.symbol.rawValue
        d.rotationHours = c.rotation.hours
        d.apply(theme: c.theme.value)
        d.text = (c.text?.isEmpty == false ? c.text! : (d.kind == .countdown ? "Event" : "Jai Shri Ram"))
        d.targetDate = c.date ?? Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
        if let fg = RGB.fromHex(c.textHex) { d.foreground = fg }
        if let bg = RGB.fromHex(c.backgroundHex) { d.background = bg; d.background2 = nil }
        d.name = "Wallora"
        return d
    }

    func placeholder(in context: Context) -> DesignEntry { DesignEntry(date: .now, design: .sample) }
    func snapshot(for configuration: SelectDesignIntent, in context: Context) async -> DesignEntry {
        DesignEntry(date: .now, design: makeDesign(configuration), photo: photo(configuration))
    }
    private func photo(_ c: SelectDesignIntent) -> UIImage? {
        guard let data = c.photo?.data else { return nil }
        return ImageTools.downsample(data)
    }
    func timeline(for configuration: SelectDesignIntent, in context: Context) async -> Timeline<DesignEntry> {
        let d = makeDesign(configuration)
        let pic = photo(configuration)
        let now = Date()
        let cal = Calendar.current
        let h = max(1, d.rotationHours)
        let slotHour = (cal.component(.hour, from: now) / h) * h
        let slotStart = cal.date(bySettingHour: slotHour, minute: 0, second: 0, of: now) ?? now
        var entries = [DesignEntry(date: now, design: d, photo: pic)]
        var t = slotStart.addingTimeInterval(Double(h) * 3600)
        let end = now.addingTimeInterval(86_400)
        while t < end { entries.append(DesignEntry(date: t, design: d, photo: pic)); t = t.addingTimeInterval(Double(h) * 3600) }
        return Timeline(entries: entries, policy: .after(end))
    }
}

struct DesignWidgetView: View {
    let entry: DesignEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        DesignContent(design: entry.design, family: family, date: entry.date)
            .widgetURL(URL(string: "wallora://open"))
            .containerBackground(for: .widget) {
                ZStack {
                    DesignBackground(design: entry.design)
                    if let p = entry.photo {
                        Color.clear.overlay(Image(uiImage: p).resizable().scaledToFill()).clipped()
                        Color.black.opacity(0.3)
                    }
                }
            }
    }
}

struct DesignWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "WalloraCustom", intent: SelectDesignIntent.self, provider: DesignProvider()) { entry in
            DesignWidgetView(entry: entry)
        }
        .configurationDisplayName("Ramayana & Custom")
        .description("Valmiki Ramayana shlokas in Sanskrit, Hindi, Gujarati or English — or your own text, countdown or date. Touch and hold → Edit Widget: language, theme, colors, font, photo.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Calendar (Home Screen)

struct DayEntry: TimelineEntry { let date: Date }

struct DayProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry { DayEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) { completion(DayEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let next = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        completion(Timeline(entries: [DayEntry(date: .now)], policy: .after(next)))
    }
}

struct MonthGrid: View {
    let date: Date
    private var rows: [[Int?]] {
        let cal = Calendar.current
        let first = cal.date(from: cal.dateComponents([.year, .month], from: date))!
        let offset = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        let count = cal.range(of: .day, in: .month, for: date)?.count ?? 30
        var cells: [Int?] = Array(repeating: nil, count: offset) + (1...count).map { Optional($0) }
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }
    var body: some View {
        let today = Calendar.current.component(.day, from: date)
        VStack(alignment: .trailing, spacing: 3) {
            Text(date.formatted(.dateTime.month(.wide)).uppercased())
                .font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.white)
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { c in
                        let v = rows[r][c]
                        Text(v.map(String.init) ?? "")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .frame(width: 20, height: 16)
                            .foregroundStyle(v == today ? .black : .white)
                            .background { if v == today { RoundedRectangle(cornerRadius: 4).fill(.white) } }
                    }
                }
            }
        }
    }
}

struct CalendarWidgetView: View {
    let entry: DayEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        Group {
            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                        .font(.system(size: 22, weight: .semibold, design: .rounded)).foregroundStyle(.red)
                    Text(entry.date.formatted(.dateTime.day()))
                        .font(.system(size: 64, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                    Spacer(minLength: 0)
                    Text(entry.date.formatted(.dateTime.month(.wide))).font(.system(.footnote, design: .rounded)).foregroundStyle(.white.opacity(0.6))
                }.frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack {
                    VStack(spacing: -4) {
                        Text(entry.date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                        Text(entry.date.formatted(.dateTime.day()))
                            .font(.system(size: 64, weight: .semibold, design: .rounded))
                    }.foregroundStyle(.white).frame(maxWidth: .infinity)
                    MonthGrid(date: entry.date)
                }
            }
        }
        .containerBackground(.black, for: .widget)
    }
}

struct CalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WalloraCalendar", provider: DayProvider()) { CalendarWidgetView(entry: $0) }
            .configurationDisplayName("Calendar")
            .description("Bold day and month grid on pure black.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Analog clock

struct AnalogClock: View {
    let date: Date
    var body: some View {
        GeometryReader { g in
            let r = min(g.size.width, g.size.height) / 2
            let cal = Calendar.current
            let h = Double(cal.component(.hour, from: date) % 12)
            let m = Double(cal.component(.minute, from: date))
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    Capsule().fill(.white.opacity(i % 3 == 0 ? 1 : 0.35))
                        .frame(width: 2, height: i % 3 == 0 ? r * 0.12 : r * 0.06)
                        .offset(y: -r * 0.88).rotationEffect(.degrees(Double(i) * 30))
                }
                Capsule().fill(.white).frame(width: 4, height: r * 0.5)
                    .offset(y: -r * 0.25).rotationEffect(.degrees((h + m / 60) * 30))
                Capsule().fill(.white.opacity(0.85)).frame(width: 3, height: r * 0.75)
                    .offset(y: -r * 0.375).rotationEffect(.degrees(m * 6))
                Circle().fill(.orange).frame(width: 8, height: 8)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
    }
}

struct AnalogProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry { DayEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) { completion(DayEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let start = Calendar.current.date(bySetting: .second, value: 0, of: .now) ?? .now
        let entries = (0..<60).map { DayEntry(date: start.addingTimeInterval(Double($0) * 60)) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct AnalogClockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WalloraAnalog", provider: AnalogProvider()) { entry in
            AnalogClock(date: entry.date).padding(4).containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Analog Clock")
        .description("Minimal analog clock. iOS decides how often it refreshes.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Lock Screen date

struct DateAccessoryView: View {
    let entry: DayEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text(entry.date.formatted(.dateTime.weekday(.abbreviated)).uppercased()).font(.system(size: 11, weight: .semibold))
                    Text(entry.date.formatted(.dateTime.day())).font(.system(size: 24, weight: .semibold, design: .rounded))
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text(entry.date.formatted(.dateTime.weekday(.wide))).font(.headline)
                Text(entry.date.formatted(.dateTime.month(.wide).day().year())).font(.caption)
            }.frame(maxWidth: .infinity, alignment: .leading)
        default:
            Text(entry.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
        }
    }
}

struct DateAccessoryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WalloraDate", provider: DayProvider()) { entry in
            DateAccessoryView(entry: entry).containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Date")
        .description("Day and date for your Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
