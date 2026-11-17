import SwiftUI
import PhotosUI

private func template(_ name: String, _ kind: WidgetDesign.Kind, _ text: String, _ symbol: String, theme: WalloraTheme, font: WidgetDesign.FontStyle, lang: ShlokaLanguage = .sanskritEnglish) -> WidgetDesign {
    var d = WidgetDesign()
    d.name = name; d.kind = kind; d.text = text; d.symbol = symbol; d.fontStyle = font; d.language = lang
    d.apply(theme: theme)
    return d
}

struct WidgetsView: View {
    @Environment(DesignLibrary.self) private var library
    @State private var editing: WidgetDesign?
    private let templates: [WidgetDesign] = [
        template("Saffron Shloka", .shloka, "", "sparkles", theme: .saffron, font: .serif),
        template("Midnight Hindi", .shloka, "", "moon.stars.fill", theme: .midnight, font: .serif, lang: .hindi),
        template("Parchment Gujarati", .shloka, "", "book.fill", theme: .parchment, font: .serif, lang: .gujarati),
        template("Countdown", .countdown, "Diwali", "flame.fill", theme: .lotus, font: .rounded),
        template("Focus", .text, "Stay present", "leaf.fill", theme: .forest, font: .rounded)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Add a widget in 4 steps", systemImage: "rectangle.3.group.fill").font(.headline)
                        Text("1. Touch and hold an empty spot on your Home Screen (or Lock Screen → Customize).\n2. Tap + and search “Wallora”.\n3. Pick “Ramayana & Custom”, choose a size, tap Add Widget.\n4. Touch and hold the widget → Edit Widget → choose language, theme, font, symbol and how often the shloka changes.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text("Can't find Wallora in the + list? The widget extension didn't install — re-sideload without “Remove app extensions”.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }.padding(18).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous)).padding(.horizontal)

                    NavigationLink { RamayanaReaderView() } label: {
                        HStack { Image(systemName: "book.closed.fill").font(.title2); VStack(alignment: .leading) { Text("Valmiki Ramayana").font(.headline); Text("All 7 kandas · Sanskrit in Devanagari or Gujarati script").font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right") }
                            .padding(18).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }.buttonStyle(.plain).padding(.horizontal)

                    Text("Preview & design").font(.title2.bold()).padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(templates) { t in
                                Button { editing = t } label: {
                                    VStack(spacing: 8) { WidgetPreview(design: t, size: .small); Text(t.name).font(.footnote.weight(.medium)) }
                                }.buttonStyle(.plain)
                            }
                        }.padding(.horizontal)
                    }
                    Button { editing = WidgetDesign() } label: {
                        Label("Create a design", systemImage: "plus.circle.fill").font(.headline).frame(maxWidth: .infinity).frame(height: 50)
                            .background(.tint, in: Capsule()).foregroundStyle(.white)
                    }.padding(.horizontal)

                    Text("Built-in widgets").font(.title2.bold()).padding(.horizontal)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Ramayana & Custom — all sizes, Home + Lock Screen", systemImage: "sparkles")
                        Label("Calendar — small & medium", systemImage: "calendar")
                        Label("Analog Clock — small", systemImage: "clock")
                        Label("Date — Lock Screen", systemImage: "lock.iphone")
                    }.font(.subheadline).padding(.horizontal)
                }.padding(.vertical)
            }
            .navigationTitle("Widgets")
            .sheet(item: $editing) { StudioView(design: $0) }
        }
    }
}

struct StudioView: View {
    @Environment(DesignLibrary.self) private var library
    @Environment(\.dismiss) private var dismiss
    @State private var design: WidgetDesign
    @State private var size: PreviewSize = .small
    @State private var pick: PhotosPickerItem?
    private let symbols = ["sparkles", "heart.fill", "star.fill", "moon.stars.fill", "sun.max.fill", "bolt.fill", "leaf.fill", "flame.fill",
                           "airplane", "gift.fill", "book.fill", "music.note"]

    init(design: WidgetDesign) { _design = State(initialValue: design) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Size", selection: $size.animation()) { ForEach(PreviewSize.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                    HStack { Spacer(); WidgetPreview(design: design, size: size); Spacer() }
                        .listRowBackground(Color.clear).padding(.vertical, 6)
                }
                Section("Content") {
                    TextField("Design name", text: $design.name)
                    Picker("Type", selection: $design.kind) { ForEach(WidgetDesign.Kind.allCases, id: \.self) { Text($0.title).tag($0) } }
                    if design.kind == .shloka {
                        Picker("Language", selection: $design.language) { ForEach(ShlokaLanguage.allCases) { Text($0.title).tag($0) } }
                    }
                    if design.kind == .text || design.kind == .countdown {
                        TextField(design.kind == .text ? "Your text" : "Event name", text: $design.text, axis: .vertical)
                    }
                    if design.kind == .countdown { DatePicker("Date", selection: $design.targetDate, displayedComponents: .date) }
                }
                Section("Theme") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(WalloraTheme.allCases) { t in
                                Button { design.apply(theme: t) } label: {
                                    Circle().fill(LinearGradient(colors: [Color(hex: t.colors.bg), Color(hex: t.colors.bg2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 38, height: 38).overlay(Circle().stroke(.secondary.opacity(0.4)))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    Picker("Font", selection: $design.fontStyle) { ForEach(WidgetDesign.FontStyle.allCases, id: \.self) { Text($0.title).tag($0) } }
                    ColorPicker("Text color", selection: Binding(get: { design.foreground.color }, set: { design.foreground = RGB($0) }), supportsOpacity: false)
                    ColorPicker("Background", selection: Binding(get: { design.background.color }, set: { design.background = RGB($0); design.background2 = nil }), supportsOpacity: false)
                    PhotosPicker(selection: $pick, matching: .images) { Label("Choose background photo", systemImage: "photo") }
                    if design.backgroundImage != nil { Button("Remove photo", role: .destructive) { design.backgroundImage = nil } }
                }
                Section("Symbol") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
                        ForEach(symbols, id: \.self) { s in
                            Button { design.symbol = s } label: {
                                Image(systemName: s).font(.title3).frame(width: 40, height: 40)
                                    .background(design.symbol == s ? Color.accentColor.opacity(0.2) : .clear, in: RoundedRectangle(cornerRadius: 8))
                            }.buttonStyle(.plain)
                        }
                    }
                }
                Section {
                    LabeledContent("Shared with widgets", value: AppGroup.isShared ? "Yes" : "No")
                } footer: {
                    Text(AppGroup.isShared
                         ? "Saved designs appear in the widget's Edit Widget → Saved design."
                         : "Your sideload setup doesn't share data with widgets, so saved designs can't reach them. The widget's own Edit Widget panel (language, theme, font…) always works.")
                }
            }
            .navigationTitle("Studio").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { library.upsert(design); dismiss() }.bold() }
            }
            .onChange(of: pick) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                        design.backgroundImage = DesignStore.saveBackground(ui, id: design.id)
                    }
                }
            }
        }
    }
}
