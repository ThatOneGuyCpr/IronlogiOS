import AVFoundation
import AVKit
import SafariServices
import SwiftUI
import WebKit

/// Where an exercise's form video comes from.
/// 1. A clip bundled in the app (Videos/<exercise id>.mp4), played natively.
/// 2. A curated YouTube video, played in an embedded in-app player.
/// 3. Nothing yet.
enum ClipSource {
    case local(URL)
    case youtube(String)
    case none
}

enum Clips {
    /// Exercise ID → YouTube video ID for the in-app player.
    static let youtube: [String: String] = [
        "db_bench": "5Y3VZsLb1Ys",
        "smith_bench": "7FyJdsXeta8",
        "cable_press": "UsFdYBcvHEs",
        "incline_pushup": "Oy1AzohemMc",
        "db_incline": "OC7Qs_SAO2E",
        "smith_incline": "PbROfDSbK4s",
        "cable_low_high": "uPiDTAvW0Yo",
        "db_fly": "QENKPHhQVi4",
        "lat_wide": "7JnP8dFbS14",
        "lat_close": "IjoFCmLX7z0",
        "cable_pulldown": "SALxEARiMkw",
        "straight_arm": "mvgQs3CkgGQ",
        "db_pullover": "fZGhnNhfRBs",
        "cable_row": "f_r95UajQcg",
        "cs_db_row": "llFTFDwmGcw",
        "one_arm_row": "Qx2f4YwJAu4",
        "smith_row": "ZFNLCpj8e-o",
        "db_curl": "6DeLZ6cbgWQ",
        "hammer": "8_BFFLUDu5Q",
        "cable_curl": "_hRnRorKRWs",
        "incline_curl": "PAnypqTfEuU",
        "pushdown": "ChbWX35gD44",
        "db_skull": "uXOm7MpK4HQ",
        "smith_cgp": "z8UWdGwtzRM",
        "bench_dip": "e5Gyc1D_BxM",
        "cable_lat_raise": "nMCQuV6HE3A",
        "db_lat_raise": "Y29xKcze8Ik",
        "face_pull": "0Po47vvj9g4",
        "legpress": "tg-jOYwhI5w",
        "legpress_high": "OIq-tsCx_9k",
        "smith_squat": "iAcRGCsG_PY",
        "goblet": "JO7D6GJ98wY",
        "db_rdl": "hQgFixeXdZo",
        "smith_rdl": "pwGLw2xJCGw",
        "pullthrough": "4oZ_0_bQcOg",
        "db_bss": "VPhhE6bBzZE",
        "db_lunge": "I34ysEkPK7w",
        "step_up": "MZitRhrqZRE",
        "smith_split": "NkAlwfIbsa0",
        "leg_ext": "xAUvXdHu1sI",
        "leg_curl": "Z5pRnXaCjpM",
        "db_sl_rdl": "gPE_sXiQHrs",
        "smith_thrust": "ADgWjz9i42Y",
        "db_thrust": "ETnhBWeWK74",
        "kickback": "VSgMyiOu0uE",
        "legmachine_calf": "B9_myFjUb5E",
        "smith_calf": "FNdI5TynYxs",
        "lp_calf": "OMUvfMZOcSA",
        "db_calf": "1D7s-VyLq0Y",
        "bw_calf": "4HQ8Am9IuME",
        "ab_crunch": "0kLWho-pEdQ",
        "cable_crunch": "0KEP6A1deBE",
        "plank": "6LqqeBtFn9M",
    ]

    static func source(for id: String) -> ClipSource {
        for ext in ["mp4", "mov", "m4v"] {
            if let url = Bundle.main.url(forResource: id, withExtension: ext, subdirectory: "Videos") {
                return .local(url)
            }
        }
        if let yt = youtube[id] { return .youtube(yt) }
        return .none
    }

    /// Lets clips play without stopping the music you're already listening to.
    static func configureAudio() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }
}

// MARK: - Clip box inside the exercise card

struct ClipBox: View {
    let exercise: Exercise
    @State private var showPlayer = false

    var body: some View {
        let source = Clips.source(for: exercise.id)
        Button {
            showPlayer = true
        } label: {
            ZStack(alignment: .bottomLeading) {
                switch source {
                case .local(let url):
                    LoopingVideo(url: url)
                case .youtube(let id):
                    AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Theme.video
                    }
                case .none:
                    ZStack {
                        Theme.video
                        Stripes().opacity(0.5)
                    }
                }

                if !isLocal(source) {
                    Circle()
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 52, height: 52)
                        .overlay(Image(systemName: "play.fill").font(.system(size: 20)).foregroundStyle(Color(red: 0.04, green: 0.11, blue: 0.18)))
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Text(label(for: source))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                    .padding(10)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play form clip for \(exercise.name)")
        .sheet(isPresented: $showPlayer) {
            ClipPlayerSheet(exercise: exercise, source: source)
        }
    }

    private func isLocal(_ source: ClipSource) -> Bool {
        if case .local = source { return true }
        return false
    }

    private func label(for source: ClipSource) -> String {
        switch source {
        case .local: return "Form clip · tap for full screen"
        case .youtube: return "Form video"
        case .none: return "No clip yet"
        }
    }
}

private struct Stripes: View {
    var body: some View {
        Canvas { ctx, size in
            var path = Path()
            var x: CGFloat = -size.height
            while x < size.width {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += 15
            }
            ctx.stroke(path, with: .color(.white.opacity(0.12)), lineWidth: 1)
        }
    }
}

// MARK: - Full player sheet

struct ClipPlayerSheet: View {
    let exercise: Exercise
    let source: ClipSource
    @Environment(\.dismiss) private var dismiss
    @State private var embedFailed = false

    var body: some View {
        NavigationStack {
            Group {
                switch source {
                case .local(let url):
                    VideoPlayer(player: AVPlayer(url: url))
                        .ignoresSafeArea(edges: .bottom)
                case .youtube(let id):
                    if embedFailed, let url = exercise.videoURL {
                        SafariView(url: url)
                            .ignoresSafeArea(edges: .bottom)
                    } else {
                        YouTubePlayer(videoID: id, onError: { embedFailed = true })
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .frame(maxHeight: .infinity)
                            .background(Color.black)
                    }
                case .none:
                    if let url = exercise.videoURL {
                        SafariView(url: url)
                            .ignoresSafeArea(edges: .bottom)
                    }
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Players

final class LoopingPlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }
    private let player = AVQueuePlayer()
    private var looper: AVPlayerLooper?

    func configure(url: URL) {
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: player, templateItem: item)
        player.isMuted = true
        playerLayer?.player = player
        playerLayer?.videoGravity = .resizeAspectFill
        player.play()
    }
}

struct LoopingVideo: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        let view = LoopingPlayerUIView()
        view.configure(url: url)
        return view
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {}
}

struct YouTubePlayer: UIViewRepresentable {
    let videoID: String
    /// Called when YouTube refuses to play the video here (embedding turned off, removed, etc.).
    var onError: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onError: onError) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(context.coordinator, name: "yt")
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .black
        web.scrollView.isScrollEnabled = false
        let html = """
        <html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>html,body{margin:0;height:100%;background:#000}#p{position:absolute;inset:0;width:100%;height:100%}</style></head>
        <body><div id="p"></div>
        <script src="https://www.youtube.com/iframe_api"></script>
        <script>
        function onYouTubeIframeAPIReady() {
          new YT.Player('p', {
            width: '100%', height: '100%', videoId: '\(videoID)',
            host: 'https://www.youtube-nocookie.com',
            playerVars: { playsinline: 1, autoplay: 1, rel: 0, modestbranding: 1 },
            events: { onError: function(e) { window.webkit.messageHandlers.yt.postMessage(String(e.data)); } }
          });
        }
        </script></body></html>
        """
        web.loadHTMLString(html, baseURL: URL(string: "https://thatoneguycpr.github.io/"))
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "yt")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onError: () -> Void
        init(onError: @escaping () -> Void) { self.onError = onError }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            DispatchQueue.main.async { self.onError() }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
