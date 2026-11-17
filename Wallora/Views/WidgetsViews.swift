import SwiftUI
import PhotosUI

private func template(_ name: String, _ kind: WidgetDesign.Kind, _ text: String, _ symbol: String, fg: String, bg: String, font: WidgetDesign.FontStyle) -> WidgetDesign {
    var d = WidgetDesign()
    d.name = name; d.kind = kind; d.text = text; d.symbol = symbol; d.fontStyle = font
    d.foreground = RGB(Color(hex: fg)); d.background = RGB(Color(hex: bg))
    return d
}

struct WidgetsView: View {
    @State private var editing: WidgetDesign?
    private let templates: [WidgetDesign] = [
        template("Focus", .text, "Stay present", "sparkles", fg: "FFFFFF", bg: "111114", font: .rounded),
        template("Daily Quote", .quote, "", "quote.opening", fg: "1B1B1F", bg: "F4F1EC", font: .serif),
        template("Countdown", .countdown, "Trip", "airplane", fg: "FFFFFF", bg: "2D5B6B", font: .rounded),
        template("Today", .date, "", "calendar", fg: "FFFFFF", bg: "6A3FA0", font: .standard)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Button { editing = WidgetDesign() } label: {
                        HStack { Image(systemName: "plus.circle.fill").font(.title2); Text("Create a widget").font(.headline); Spacer(); Image(systemName: "chevron.right") }
                            .padding(18).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }.buttonStyle(.plain).padding(.horizontal)

                    Text("Templates").font(.title2.bold()).padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(templates) { t in
                                Button { editing = t } label: {
                                    VStack(spacing: 8) { WidgetPreview(design: t, size: .small); Text(t.name).font(.footnote.weight(.medium)) }
                                }.buttonStyle(.plain)
                            }
                        }.padding(.horizontal)
                    }

                    Text("Built-in").font(.title2.bold()).padding(.horizontal)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Calendar — small & medium", systemImage: "calendar")
                        Label("Analog Clock — small", systemImage: "clock")
                        Label("Date — Lock Screen circular, rectangular, inline", systemImage: "lock.iphone")
                        Label("Custom Design — every size, Home and Lock Screen", systemImage: "paintpalette")
                    }.font(.subheadline).padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add to your Home Screen").font(.headline)
                        Text("Touch and hold the Home Screen → tap + → search Wallora → pick a widget. For Lock Screen: touch and hold the Lock Screen → Customize → Add Widgets.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Text("Tip: after adding Custom Design, touch and hold it → Edit Widget to choose which design it shows.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }.padding(18).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous)).padding(.horizontal)
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
    private let symbols = ["sparkles", "heart.fill", "star.fill", "moon.fill", "sun.max.fill", "bolt.fill", "leaf.fill", "flame.fill",
                           "airplane", "gift.fill", "graduationcap.fill", "figure.run", "cup.and.saucer.fill", "music.note", "book.fill", "calendar"]

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
                    if design.kind == .text || design.kind == .countdown {
                        TextField(design.kind == .text ? "Your text" : "Event name", text: $design.text, axis: .vertical)
                    }
                    if design.kind == .countdown { DatePicker("Date", selection: $design.targetDate, displayedComponents: .date) }
                }
                Section("Style") {
                    Picker("Font", selection: $design.fontStyle) { ForEach(WidgetDesign.FontStyle.allCases, id: \.self) { Text($0.title).tag($0) } }
                    ColorPicker("Text color", selection: Binding(get: { design.foreground.color }, set: { design.foreground = RGB($0) }), supportsOpacity: false)
                    ColorPicker("Background", selection: Binding(get: { design.background.color }, set: { design.background = RGB($0) }), supportsOpacity: false)
                    PhotosPicker(selection: $pick, matching: .images) { Label("Choose background photo", systemImage: "photo") }
                    if design.backgroundImage != nil { Button("Remove photo", role: .destructive) { design.backgroundImage = nil } }
                }
                Section("Symbol") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 14) {
                        ForEach(symbols, id: \.self) { s in
                            Button { design.symbol = s } label: {
                                Image(systemName: s).font(.title3).frame(width: 34, height: 34)
                                    .background(design.symbol == s ? Color.accentColor.opacity(0.2) : .clear, in: RoundedRectangle(cornerRadius: 8))
                            }.buttonStyle(.plain)
                        }
                    }
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
