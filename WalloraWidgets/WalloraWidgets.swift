import WidgetKit
import SwiftUI
import AppIntents

@main
struct WalloraWidgetBundle: WidgetBundle {
    var body: some Widget {
        DesignWidget()
        CalendarWidget()
        AnalogClockWidget()
        DateAccessoryWidget()
    }
}

// MARK: - Configurable widget (uses designs made in the Studio)

struct DesignEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Design"
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
    static var title: LocalizedStringResource = "Choose design"
    static var description = IntentDescription("Pick one of the designs you made in Wallora.")
    @Parameter(title: "Design") var design: DesignEntity?
}

struct DesignEntry: TimelineEntry {
    let date: Date
    let design: WidgetDesign
}

struct DesignProvider: AppIntentTimelineProvider {
    private func resolve(_ c: SelectDesignIntent) -> WidgetDesign {
        let all = DesignStore.load()
        return all.first { $0.id.uuidString == c.design?.id } ?? all.first ?? .sample
    }
    func placeholder(in context: Context) -> DesignEntry { DesignEntry(date: .now, design: .sample) }
    func snapshot(for configuration: SelectDesignIntent, in context: Context) async -> DesignEntry {
        DesignEntry(date: .now, design: resolve(configuration))
    }
    func timeline(for configuration: SelectDesignIntent, in context: Context) async -> Timeline<DesignEntry> {
        let next = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        return Timeline(entries: [DesignEntry(date: .now, design: resolve(configuration))], policy: .after(next))
    }
}

struct DesignWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "WalloraDesign", intent: SelectDesignIntent.self, provider: DesignProvider()) { entry in
            DesignWidgetView(design: entry.design)
        }
        .configurationDisplayName("Custom Design")
        .description("Text, quote, countdown or date widget styled in the Wallora Studio.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct DesignWidgetView: View {
    let design: WidgetDesign
    @Environment(\.widgetFamily) private var family
    var body: some View {
        DesignContent(design: design, family: family)
            .containerBackground(for: .widget) { DesignBackground(design: design) }
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
