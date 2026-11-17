import SwiftUI

struct VerseRow: Codable, Identifiable {
    let k: Int, s: Int, n: Int, t: String
    var id: String { "\(k)-\(s)-\(n)" }
}

enum Kanda: Int, CaseIterable, Identifiable {
    case bala, ayodhya, aranya, kishkindha, sundara, yuddha, uttara
    var id: Int { rawValue }
    var english: String { ["Bala", "Ayodhya", "Aranya", "Kishkindha", "Sundara", "Yuddha", "Uttara"][rawValue] + " Kanda" }
    var devanagari: String { ["बालकाण्ड", "अयोध्याकाण्ड", "अरण्यकाण्ड", "किष्किन्धाकाण्ड", "सुन्दरकाण्ड", "युद्धकाण्ड", "उत्तरकाण्ड"][rawValue] }
}

/// The full text ships inside the app (Resources/ramayana_full.json). Loaded off the main thread.
enum RamayanaText {
    static func load() async -> [VerseRow] {
        await Task.detached(priority: .userInitiated) {
            guard let url = Bundle.main.url(forResource: "ramayana_full", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let rows = try? JSONDecoder().decode([VerseRow].self, from: data) else { return [] }
            return rows
        }.value
    }
}

struct ShlokaOfTheDayCard: View {
    @AppStorage("shlokaLang") private var langRaw = ShlokaLanguage.sanskritEnglish.rawValue
    var body: some View {
        let lang = ShlokaLanguage(rawValue: langRaw) ?? .sanskritEnglish
        let shloka = ShlokaStore.pick(at: .now, rotationHours: 24)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("SHLOKA OF THE DAY", systemImage: "sparkles").font(.caption.weight(.semibold)).tracking(1.1)
                Spacer()
                Menu {
                    Picker("Language", selection: $langRaw) { ForEach(ShlokaLanguage.allCases) { Text($0.title).tag($0.rawValue) } }
                } label: { Image(systemName: "globe") }
            }
            if let s = shloka {
                let lines = ShlokaStore.lines(s, lang)
                ForEach(lines.indices, id: \.self) { i in
                    Text(lines[i]).font(.system(i == 0 ? .title3 : .subheadline, design: .serif, weight: i == 0 ? .semibold : .regular))
                        .foregroundStyle(i == 0 ? .primary : .secondary)
                }
                Text("Valmiki Ramayana · \(s.ref)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(hex: "E8761E").opacity(0.22), Color(hex: "B5460F").opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal)
        .textSelection(.enabled)
    }
}

struct RamayanaReaderView: View {
    @State private var rows: [VerseRow] = []
    @State private var loading = true
    var body: some View {
        List {
            Section {
                ForEach(Kanda.allCases) { k in
                    NavigationLink {
                        SargaListView(kanda: k, rows: rows.filter { $0.k == k.rawValue })
                    } label: {
                        VStack(alignment: .leading) {
                            Text(k.devanagari).font(.headline)
                            Text(k.english).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } footer: {
                Text(loading ? "Loading…" : "\(rows.count) shlokas. Text from the open DharmicData / Valmiki Ramayana dataset (ODbL licence). It may contain typos — check a printed edition for recitation.")
            }
        }
        .navigationTitle("Valmiki Ramayana")
        .task { rows = await RamayanaText.load(); loading = false }
    }
}

struct SargaListView: View {
    let kanda: Kanda
    let rows: [VerseRow]
    var body: some View {
        let sargas = Array(Set(rows.map(\.s))).sorted()
        List(sargas, id: \.self) { s in
            NavigationLink("Sarga \(s)") { VerseListView(kanda: kanda, sarga: s, rows: rows.filter { $0.s == s }) }
        }.navigationTitle(kanda.english)
    }
}

struct VerseListView: View {
    let kanda: Kanda
    let sarga: Int
    let rows: [VerseRow]
    @AppStorage("readerScript") private var gujarati = false
    var body: some View {
        List(rows) { r in
            VStack(alignment: .leading, spacing: 6) {
                Text(gujarati ? Script.gujarati(r.t) : r.t).font(.system(.body, design: .serif))
                Text("\(r.k + 1).\(r.s).\(r.n)").font(.caption2).foregroundStyle(.secondary)
            }.padding(.vertical, 4).textSelection(.enabled)
        }
        .navigationTitle("\(kanda.english) · \(sarga)")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Toggle(isOn: $gujarati) { Text(gujarati ? "ગુ" : "दे") }.toggleStyle(.button) } }
    }
}
