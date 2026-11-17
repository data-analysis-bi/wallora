import SwiftUI
import SwiftData
import Photos

enum PreviewMode: String, CaseIterable, Identifiable {
    case clean = "Clean", lock = "Lock", home = "Home"
    var id: String { rawValue }
}

struct ViewerView: View {
    let wallpaper: Wallpaper
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @Query private var favorites: [FavoriteWallpaper]
    @State private var mode: PreviewMode = .clean
    @State private var image: UIImage?
    @State private var tint: Color = .white
    @State private var busy = false
    @State private var message: String?
    @State private var showGuide = false
    @State private var saved = false

    private var favorite: FavoriteWallpaper? { favorites.first { $0.wallpaperID == wallpaper.id } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Color.clear.ignoresSafeArea().overlay {
                if let image { Image(uiImage: image).resizable().scaledToFill() } else { ProgressView().tint(.white) }
            }.clipped().ignoresSafeArea()

            switch mode {
            case .clean: EmptyView()
            case .lock: LockOverlay()
            case .home: HomeOverlay()
            }

            VStack {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "xmark").font(.headline).frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle()) }
                    Spacer()
                    Picker("Preview", selection: $mode.animation(.snappy)) {
                        ForEach(PreviewMode.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented).frame(width: 210)
                    Spacer()
                    Button { toggleFavorite() } label: {
                        Image(systemName: favorite == nil ? "heart" : "heart.fill").font(.headline)
                            .foregroundStyle(favorite == nil ? .white : .pink)
                            .frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle())
                    }
                }.padding(.horizontal)

                Spacer()

                VStack(spacing: 10) {
                    if let a = wallpaper.attribution {
                        Text(a).font(.caption2).padding(.horizontal, 10).padding(.vertical, 4).background(.ultraThinMaterial, in: Capsule())
                    }
                    if let message { Text(message).font(.footnote).padding(10).background(.ultraThinMaterial, in: Capsule()) }
                    HStack(spacing: 12) {
                        Button { Task { await setWallpaper() } } label: {
                            HStack { if busy { ProgressView() } else { Image(systemName: "iphone.gen3") }; Text(saved ? "Show steps" : "Set as Wallpaper") }
                                .font(.headline).frame(maxWidth: .infinity).frame(height: 54)
                                .background(tint.opacity(0.9), in: Capsule()).foregroundStyle(.black)
                        }.disabled(image == nil || busy)
                        if let image {
                            ShareLink(item: Image(uiImage: image), preview: SharePreview(wallpaper.title, image: Image(uiImage: image))) {
                                Image(systemName: "square.and.arrow.up").font(.headline).frame(width: 54, height: 54).background(.ultraThinMaterial, in: Circle())
                            }
                        }
                    }
                }.padding(.horizontal).padding(.bottom, 8)
            }
            .foregroundStyle(.white)
        }
        .task {
            image = await ImageLoader.shared.image(for: wallpaper, full: true)
            if let image, let c = ColorExtractor.dominant(image, lightenBy: 0.6) { tint = c }
        }
        .sheet(isPresented: $showGuide) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Saved to Photos ✓").font(.title2.bold())
                Text("Apple doesn't allow any app to change your wallpaper directly. Finish in 3 taps:").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Label("Tap Open Photos — your wallpaper is the newest photo (last in Recents)", systemImage: "1.circle.fill")
                    Label("Open it, tap the Share button, then Use as Wallpaper", systemImage: "2.circle.fill")
                    Label("Tap Add, then Set as Wallpaper Pair (or Customize Home Screen)", systemImage: "3.circle.fill")
                }.font(.subheadline)
                Button { openURL(URL(string: "photos-redirect://")!) } label: {
                    Text("Open Photos").font(.headline).frame(maxWidth: .infinity).frame(height: 52).background(.tint, in: Capsule()).foregroundStyle(.white)
                }
                Text("Alternative: Settings → Wallpaper → Add New Wallpaper → Photos.").font(.footnote).foregroundStyle(.secondary)
            }.padding(24).presentationDetents([.medium])
        }
        .statusBarHidden(mode == .clean)
    }

    private func toggleFavorite() {
        if let f = favorite { context.delete(f) } else { context.insert(FavoriteWallpaper(wallpaperID: wallpaper.id)) }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func setWallpaper() async {
        guard let image else { return }
        if saved { showGuide = true; return }
        busy = true; defer { busy = false }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { message = "Allow Photos access in Settings → Wallora to save."; return }
        do {
            try await PHPhotoLibrary.shared().performChanges { PHAssetChangeRequest.creationRequestForAsset(from: image) }
            context.insert(DownloadRecord(wallpaperID: wallpaper.id, title: wallpaper.title))
            if let loc = wallpaper.downloadLocation, let key = Keychain.get("unsplash") { await UnsplashProvider(accessKey: key).trackDownload(loc) }
            message = nil; saved = true; showGuide = true
        } catch { message = "Couldn't save: \(error.localizedDescription)" }
    }
}

private struct LockOverlay: View {
    var body: some View {
        VStack(spacing: 2) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month().day())).font(.title3.weight(.medium))
            Text(Date.now, style: .time).font(.system(size: 92, weight: .thin, design: .rounded)).monospacedDigit()
            Spacer()
        }
        .foregroundStyle(.white).shadow(radius: 6).padding(.top, 110).allowsHitTesting(false)
    }
}

private struct HomeOverlay: View {
    var body: some View {
        VStack {
            Spacer().frame(height: 120)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 26) {
                ForEach(0..<16, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial).aspectRatio(1, contentMode: .fit)
                }
            }.padding(.horizontal, 24)
            Spacer()
            RoundedRectangle(cornerRadius: 30, style: .continuous).fill(.ultraThinMaterial).frame(height: 84).padding(.horizontal, 14).padding(.bottom, 130)
        }.allowsHitTesting(false)
    }
}
