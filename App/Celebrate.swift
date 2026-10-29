import SwiftUI

/// Falling confetti drawn with Canvas. Runs for a few seconds and fades out.
struct ConfettiView: View {
    var duration: Double = 3
    @State private var start = Date()
    private let pieces: [Piece]

    struct Piece {
        var x: Double
        var delay: Double
        var speed: Double
        var drift: Double
        var wobble: Double
        var phase: Double
        var spin: Double
        var size: CGSize
        var color: Color
    }

    init(count: Int = 90, duration: Double = 3) {
        self.duration = duration
        let colors: [Color] = [Theme.accent, Theme.accentText, Theme.good, .white,
                               Color(red: 1, green: 0.78, blue: 0.24), Color(red: 1, green: 0.42, blue: 0.5)]
        var made: [Piece] = []
        for _ in 0..<count {
            let w = Double.random(in: 6...10)
            made.append(Piece(x: Double.random(in: 0...1),
                              delay: Double.random(in: 0...0.5),
                              speed: Double.random(in: 260...520),
                              drift: Double.random(in: -40...40),
                              wobble: Double.random(in: 3...7),
                              phase: Double.random(in: 0...6.28),
                              spin: Double.random(in: -9...9),
                              size: CGSize(width: w, height: w * Double.random(in: 0.4...0.7)),
                              color: colors.randomElement() ?? .white))
        }
        pieces = made
    }

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSince(start)
            Canvas { g, size in
                let fade = t > duration - 0.8 ? max(0, (duration - t) / 0.8) : 1
                g.opacity = fade
                for p in pieces {
                    let local = t - p.delay
                    if local < 0 { continue }
                    let x = p.x * size.width + p.drift * local + sin(local * p.wobble + p.phase) * 14
                    let y = -20 + p.speed * local
                    if y > size.height + 20 { continue }
                    var c = g
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(p.spin * local))
                    let rect = CGRect(x: -p.size.width / 2, y: -p.size.height / 2, width: p.size.width, height: p.size.height)
                    c.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(p.color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Banner shown when you set a record mid-workout.
struct RecordBanner: View {
    let celebration: Store.Celebration
    @State private var bounce = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.accentInk)
                .symbolEffect(.bounce, value: bounce)
            VStack(alignment: .leading, spacing: 1) {
                Text(celebration.title.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1)
                    .opacity(0.85)
                Text(celebration.detail)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(2)
            }
            .foregroundStyle(Theme.accentInk)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Theme.shadow, radius: 16, y: 6)
        .padding(.horizontal, 16)
        .onAppear { bounce.toggle() }
        .accessibilityElement(children: .combine)
    }
}

/// A number that rolls up from zero when it appears.
struct CountUpText: View {
    let value: Double
    var format: (Double) -> String = { $0.formatted(.number.precision(.fractionLength(0))) }
    var delay: Double = 0.15
    @State private var shown: Double = 0

    var body: some View {
        Text(format(shown))
            .contentTransition(.numericText(value: shown))
            .onAppear {
                withAnimation(.snappy(duration: 0.8).delay(delay)) { shown = value }
            }
            .accessibilityLabel(format(value))
    }
}
