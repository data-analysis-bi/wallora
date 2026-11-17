import SwiftUI

struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: Int) { state = UInt64(truncatingIfNeeded: seed) &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct RidgeShape: Shape {
    var seed: Int, baseline: CGFloat, amplitude: CGFloat
    func path(in rect: CGRect) -> Path {
        var rng = SeededRNG(seed: seed)
        let p1 = Double.random(in: 0..<6.28, using: &rng), p2 = Double.random(in: 0..<6.28, using: &rng), p3 = Double.random(in: 0..<6.28, using: &rng)
        let f1 = Double.random(in: 0.8...1.6, using: &rng), f2 = Double.random(in: 2.0...3.4, using: &rng), f3 = Double.random(in: 4.5...7.0, using: &rng)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        let steps = 120
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let n = sin(t * f1 * .pi * 2 + p1) * 0.55 + sin(t * f2 * .pi * 2 + p2) * 0.3 + sin(t * f3 * .pi * 2 + p3) * 0.15
            path.addLine(to: CGPoint(x: rect.width * CGFloat(t), y: rect.height * (baseline - amplitude * CGFloat(n))))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct WaveShape: Shape {
    var seed: Int, baseline: CGFloat, amplitude: CGFloat
    func path(in rect: CGRect) -> Path {
        var rng = SeededRNG(seed: seed)
        let ph = Double.random(in: 0..<6.28, using: &rng), fr = Double.random(in: 0.7...1.5, using: &rng), ph2 = Double.random(in: 0..<6.28, using: &rng)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        for i in 0...100 {
            let t = Double(i) / 100
            let n = sin(t * fr * .pi * 2 + ph) * 0.7 + sin(t * fr * 2.3 * .pi * 2 + ph2) * 0.3
            path.addLine(to: CGPoint(x: rect.width * CGFloat(t), y: rect.height * (baseline - amplitude * CGFloat(n))))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct StarShape: Shape {
    var seed: Int, count: Int, size: CGFloat
    func path(in rect: CGRect) -> Path {
        var rng = SeededRNG(seed: seed)
        var p = Path()
        for _ in 0..<count {
            let x = CGFloat.random(in: 0...1, using: &rng) * rect.width
            let y = CGFloat.random(in: 0...1, using: &rng) * rect.height
            let r = size * rect.width * CGFloat.random(in: 0.5...1, using: &rng)
            p.addEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
        }
        return p
    }
}

struct RingShape: Shape {
    var count: Int
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.height * 0.6)
        for i in 1...count {
            let r = rect.width * 0.09 * CGFloat(i)
            p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
        }
        return p
    }
}

struct GridShape: Shape {
    var cols: Int
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let step = rect.width / CGFloat(cols)
        var x: CGFloat = 0
        while x <= rect.width { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: rect.height)); x += step }
        var y: CGFloat = 0
        while y <= rect.height { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: rect.width, y: y)); y += step }
        return p
    }
}

/// Code-generated wallpapers. Rendered at any resolution, no image files, no licensing issues.
struct ProceduralArt: View {
    let style: String
    let seed: Int
    let palette: [String]
    private var c: [Color] { palette.map { Color(hex: $0) } }

    var body: some View {
        switch style {
        case "ridges": RidgesArt(seed: seed, c: c)
        case "stars": StarsArt(seed: seed, c: c)
        case "waves": WavesArt(seed: seed, c: c)
        case "orbs": OrbsArt(c: c)
        case "grid": GridArt(c: c)
        default: RingsArt(c: c)
        }
    }
}

private struct RidgesArt: View {
    let seed: Int; let c: [Color]
    private var layers: [Color] { Array(c.dropFirst(2)) }
    var body: some View {
        ZStack {
            LinearGradient(colors: [c[0], c[1]], startPoint: .top, endPoint: .bottom)
            ForEach(layers.indices, id: \.self) { i in
                RidgeShape(seed: seed &+ i * 17, baseline: 0.36 + 0.55 * CGFloat(i) / CGFloat(max(layers.count, 1)), amplitude: 0.07)
                    .fill(layers[i])
            }
        }
    }
}

private struct WavesArt: View {
    let seed: Int; let c: [Color]
    private var layers: [Color] { Array(c.dropFirst(2)) }
    var body: some View {
        ZStack {
            LinearGradient(colors: [c[0], c[1]], startPoint: .top, endPoint: .bottom)
            ForEach(layers.indices, id: \.self) { i in
                WaveShape(seed: seed &+ i * 31, baseline: 0.42 + 0.14 * CGFloat(i), amplitude: 0.06)
                    .fill(layers[i])
            }
        }
    }
}

private struct StarsArt: View {
    let seed: Int; let c: [Color]
    var body: some View {
        GeometryReader { g in
            ZStack {
                LinearGradient(colors: [c[0], c[1]], startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [c[2].opacity(0.55), .clear], center: UnitPoint(x: 0.3, y: 0.78), startRadius: 0, endRadius: g.size.height * 0.45)
                RadialGradient(colors: [c[2].opacity(0.25), .clear], center: UnitPoint(x: 0.85, y: 0.2), startRadius: 0, endRadius: g.size.height * 0.3)
                StarShape(seed: seed, count: 260, size: 0.0014).fill(.white.opacity(0.85))
                StarShape(seed: seed &+ 1, count: 70, size: 0.0026).fill(.white.opacity(0.7))
                StarShape(seed: seed &+ 2, count: 12, size: 0.0042).fill(.white)
            }
        }
    }
}

private struct OrbsArt: View {
    let c: [Color]
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                c[0]
                orb(d: w * 1.9, x: w * 0.85, y: h * 0.1)
                orb(d: w * 1.5, x: w * 0.2, y: h * 0.9)
            }
        }
    }
    private func orb(d: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(colors: [c[0], c[1].opacity(0.55), c[2]], center: .center, startRadius: d * 0.22, endRadius: d * 0.5))
            .frame(width: d, height: d)
            .position(x: x, y: y)
    }
}

private struct GridArt: View {
    let c: [Color]
    var body: some View {
        GeometryReader { g in
            ZStack {
                LinearGradient(colors: [c[0], c[1]], startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [c[2].opacity(0.4), .clear], center: UnitPoint(x: 0.5, y: 0.9), startRadius: 0, endRadius: g.size.height * 0.5)
                GridShape(cols: 10).stroke(c[2].opacity(0.28), lineWidth: g.size.width * 0.002)
            }
        }
    }
}

private struct RingsArt: View {
    let c: [Color]
    var body: some View {
        GeometryReader { g in
            ZStack {
                LinearGradient(colors: [c[0], c[1]], startPoint: .top, endPoint: .bottom)
                RingShape(count: 14).stroke(c[2].opacity(0.45), lineWidth: g.size.width * 0.0016)
            }
        }
    }
}
