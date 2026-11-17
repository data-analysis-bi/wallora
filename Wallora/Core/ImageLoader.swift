import SwiftUI
import CoreImage
import CryptoKit

struct GradientArt: View {
    let hex: [String]
    var body: some View {
        ZStack {
            LinearGradient(colors: hex.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color(hex: hex.last ?? "000000").opacity(0.35), .clear],
                           center: .init(x: 0.75, y: 0.8), startRadius: 0, endRadius: 600)
        }
    }
}

@MainActor
final class ImageLoader {
    static let shared = ImageLoader()
    private let memory = NSCache<NSString, UIImage>()
    private let dir: URL = {
        let u = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("wallpapers")
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }()

    /// `full` = the high-resolution version used for the viewer / saving. Otherwise a light thumbnail.
    func image(for w: Wallpaper, full: Bool) async -> UIImage? {
        let key = "\(w.id)-\(full ? "f" : "t")-\(UserDefaults.standard.string(forKey: "quality") ?? "high")"
        if let hit = memory.object(forKey: key as NSString) { return hit }
        var result: UIImage?
        switch w.source {
        case .bundled(let name):
            if let url = Bundle.main.url(forResource: name, withExtension: "jpg") { result = UIImage(contentsOfFile: url.path) }
        case .gradient(let hex):
            let size = full ? CGSize(width: 1290, height: 2796) : CGSize(width: 330, height: 715)
            let r = ImageRenderer(content: GradientArt(hex: hex).frame(width: size.width, height: size.height))
            r.scale = 1
            result = r.uiImage
        case .remote(let thumb, let regular, let fullURL):
            let ultra = UserDefaults.standard.string(forKey: "quality") == "ultra"
            let url = full ? (ultra ? fullURL : regular) : thumb
            let file = dir.appendingPathComponent("\(SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()).jpg")
            if let d = try? Data(contentsOf: file) { result = UIImage(data: d) }
            else if let (d, _) = try? await URLSession.shared.data(from: url), let img = UIImage(data: d) {
                try? d.write(to: file); result = img
            }
        }
        if let result { memory.setObject(result, forKey: key as NSString) }
        return result
    }

    func clearDiskCache() {
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        memory.removeAllObjects()
    }
}

enum ColorExtractor {
    static func dominant(_ image: UIImage, lightenBy t: Double = 0) -> Color? {
        guard let ci = CIImage(image: image),
              let out = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ci, kCIInputExtentKey: CIVector(cgRect: ci.extent)])?.outputImage
        else { return nil }
        var px = [UInt8](repeating: 0, count: 4)
        CIContext().render(out, toBitmap: &px, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        func mix(_ v: UInt8) -> Double { Double(v) / 255 * (1 - t) + t }
        return Color(red: mix(px[0]), green: mix(px[1]), blue: mix(px[2]))
    }
}
