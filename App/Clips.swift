import AVFoundation
import AVKit
import SwiftUI
import WebKit

/// Where an exercise's form video comes from.
/// 1. A clip bundled in the app (Videos/<exercise id>.mp4), played natively.
/// 2. A YouTube video (yours if you picked one, otherwise the default), played muted and looping in the app.
/// 3. Nothing yet.
enum ClipSource {
    case local(URL)
    case youtube(String)
    case none
}

enum Clips {
    /// Exercise ID → YouTube video ID. Short demos, mostly from exercise-library channels and Shorts.
    static let youtube: [String: String] = [
        "db_bench": "SmXGLciX4zg",
        "smith_bench": "7Gbtgzlnnoc",
        "cable_press": "wvnNxJOVH14",
        "incline_pushup": "-9S9gdRwwak",
        "db_incline": "JHFd-e2_M8E",
        "smith_incline": "iydsebllPzQ",
        "cable_low_high": "BwqlWtr3v10",
        "db_fly": "VrfO5Jg9nFk",
        "lat_wide": "U3Y_NsyDq60",
        "lat_close": "23ZlW450jjg",
        "cable_pulldown": "XYaRsWoXs-s",
        "straight_arm": "70Ajji0V9vk",
        "db_pullover": "8yjVS5xyR5A",
        "cable_row": "q4boNkB4uaM",
        "cs_db_row": "h2Xafysr43E",
        "one_arm_row": "2AUbzsDCgaQ",
        "smith_row": "GVr3ainxgig",
        "db_curl": "I60ELkQ0GRg",
        "hammer": "EalSIzmNPEQ",
        "cable_curl": "W0Wz4wXIIrQ",
        "incline_curl": "V8H4k8lquiU",
        "pushdown": "tev4QScR30s",
        "db_skull": "lFHcw45fvhQ",
        "smith_cgp": "GlGpVz5nPSQ",
        "bench_dip": "zSzrmJhVseY",
        "cable_lat_raise": "qghfvzcoS2I",
        "db_lat_raise": "oegJjVzGScs",
        "face_pull": "7z65m-qWJrA",
        "legpress": "rmgarxeHzjQ",
        "legpress_high": "tY2uGI4EzCQ",
        "smith_squat": "YoFT00akxjc",
        "goblet": "4YVgTSY2E38",
        "db_rdl": "gMHKINEpe2c",
        "smith_rdl": "XXM_ihF8aKU",
        "pullthrough": "j8F2mzCmZOs",
        "db_bss": "-IpkZv8tZYM",
        "db_lunge": "3pekGdX2RcU",
        "step_up": "ddMydIUCXCI",
        "smith_split": "NkAlwfIbsa0",
        "leg_ext": "3pOsjZGe10k",
        "leg_curl": "5fgcQPIGt5w",
        "db_sl_rdl": "3ed_5PmwLMU",
        "smith_thrust": "IlnDgR4I9yY",
        "db_thrust": "rrylL1KKItA",
        "kickback": "NJh3bPtpcaE",
        "legmachine_calf": "B9_myFjUb5E",
        "smith_calf": "cJs1Q4IuPdY",
        "lp_calf": "kVZWSKyVDzk",
        "db_calf": "_rKgZMP1X5o",
        "bw_calf": "2tvsvCRCQZY",
        "ab_crunch": "zDSvdyyxH4w",
        "cable_crunch": "kc0PRn372lo",
        "plank": "96WRjQrUeXQ",
    ]

    static func source(for id: String, overrides: [String: String] = [:]) -> ClipSource {
        for ext in ["mp4", "mov", "m4v"] {
            if let url = Bundle.main.url(forResource: id, withExtension: ext, subdirectory: "Videos") {
                return .local(url)
            }
        }
        if let yt = overrides[id] ?? youtube[id] { return .youtube(yt) }
        return .none
    }

    /// Pulls a video ID out of any YouTube link: watch?v=, /shorts/, youtu.be/, /embed/.
    static func videoID(from url: URL?) -> String? {
        guard let url, let host = url.host?.lowercased(), host.contains("youtube.com") || host.contains("youtu.be") else { return nil }
        var candidate: String?
        if host.contains("youtu.be") {
            candidate = url.pathComponents.dropFirst().first
        } else if let v = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "v" })?.value {
            candidate = v
        } else {
            let parts = url.pathComponents
            if let i = parts.firstIndex(where: { $0 == "shorts" || $0 == "embed" }), i + 1 < parts.count {
                candidate = parts[i + 1]
            }
        }
        guard let id = candidate, id.count == 11,
              id.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else { return nil }
        return id
    }

    /// YouTube search limited to videos under 4 minutes.
    static func searchURL(for exercise: Exercise) -> URL? {
        var c = URLComponents(string: "https://m.youtube.com/results")
        c?.queryItems = [
            URLQueryItem(name: "search_query", value: exercise.name + " demo"),
            URLQueryItem(name: "sp", value: "EgIYAQ=="),
        ]
        return c?.url
    }

    /// Lets clips play without stopping the music you're already listening to.
    static func configureAudio() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }
}

// MARK: - Clip box inside the exercise card

struct ClipBox: View {
    @EnvironmentObject private var store: Store
    let exercise: Exercise
    @State private var showPlayer = false

    var body: some View {
        let source = Clips.source(for: exercise.id, overrides: store.data.videoOverrides)
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
            ClipPlayerSheet(exercise: exercise)
        }
    }

    private func isLocal(_ source: ClipSource) -> Bool {
        if case .local = source { return true }
        return false
    }

    private func label(for source: ClipSource) -> String {
        switch source {
        case .local: return "Form clip · tap for full screen"
        case .youtube: return "Form demo"
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

// MARK: - Player sheet

struct ClipPlayerSheet: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise
    @State private var embedFailed = false
    @State private var picking = false

    var body: some View {
        let source = Clips.source(for: exercise.id, overrides: store.data.videoOverrides)
        let custom = store.data.videoOverrides[exercise.id] != nil
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                switch source {
                case .local(let url):
                    VideoPlayer(player: AVPlayer(url: url))
                case .youtube(let id):
                    if embedFailed {
                        unavailable("This video can't play inside Ironlog.")
                    } else {
                        YouTubePlayer(videoID: id, onError: { embedFailed = true })
                            .id(id)
                    }
                case .none:
                    unavailable("No video for this exercise yet.")
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    Button {
                        picking = true
                    } label: {
                        Label("Pick a different video", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(OutlineButtonStyle())
                    if custom {
                        Button("Reset") {
                            store.data.videoOverrides[exercise.id] = nil
                            embedFailed = false
                        }
                        .buttonStyle(OutlineButtonStyle())
                        .frame(width: 96)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .sheet(isPresented: $picking) {
                VideoPicker(exercise: exercise) { id in
                    store.data.videoOverrides[exercise.id] = id
                    embedFailed = false
                    picking = false
                }
            }
        }
    }

    private func unavailable(_ text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "play.slash")
                .font(.system(size: 34))
            Text(text)
                .font(.system(size: 15, weight: .semibold))
            Text("Tap Pick a different video to choose one.")
                .font(.system(size: 13))
                .opacity(0.7)
        }
        .foregroundStyle(Color.white)
        .multilineTextAlignment(.center)
        .padding(24)
    }
}

// MARK: - Picking your own video

struct VideoPicker: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise
    var onPick: (String) -> Void
    @State private var currentID: String?

    var body: some View {
        NavigationStack {
            Group {
                if let url = Clips.searchURL(for: exercise) {
                    YouTubeBrowser(start: url, currentID: $currentID)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Pick a video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 6) {
                    if let id = currentID {
                        Button("Use this video for \(exercise.name)") { onPick(id) }
                            .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Text("Search shows videos under 4 minutes. Open one to use it.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.sub)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
        }
    }
}

struct YouTubeBrowser: UIViewRepresentable {
    let start: URL
    @Binding var currentID: String?

    func makeCoordinator() -> Coordinator { Coordinator(currentID: $currentID) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let web = WKWebView(frame: .zero, configuration: config)
        web.allowsBackForwardNavigationGestures = true
        context.coordinator.observe(web)
        web.load(URLRequest(url: start))
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject {
        var currentID: Binding<String?>
        private var observation: NSKeyValueObservation?

        init(currentID: Binding<String?>) {
            self.currentID = currentID
        }

        func observe(_ web: WKWebView) {
            // YouTube's mobile site changes pages without full loads, so watch the URL itself.
            observation = web.observe(\.url, options: [.new]) { [weak self] web, _ in
                let id = Clips.videoID(from: web.url)
                DispatchQueue.main.async { self?.currentID.wrappedValue = id }
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

/// Embedded YouTube player: starts muted, autoplays, and loops like a GIF.
/// Tap the player's speaker icon for sound.
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
            playerVars: { playsinline: 1, autoplay: 1, mute: 1, loop: 1, playlist: '\(videoID)', rel: 0, modestbranding: 1 },
            events: {
              onReady: function(e) { e.target.mute(); e.target.playVideo(); },
              onStateChange: function(e) { if (e.data === 0) { e.target.seekTo(0); e.target.playVideo(); } },
              onError: function(e) { window.webkit.messageHandlers.yt.postMessage(String(e.data)); }
            }
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
