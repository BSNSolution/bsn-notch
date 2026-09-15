import Foundation
import AppKit
import Combine

// BSN Notch — feature de sistema: Now Playing (música/vídeo tocando no Mac).
//
// Lê o "now playing" de TODO o sistema via mediaremote-adapter (ungive, BSD-3):
// um script Perl invocado por `/usr/bin/perl` (bundle com.apple.perl5, assinado
// pela Apple com o entitlement do MediaRemote) que carrega o framework do adapter
// e emite JSON em streaming. É a técnica que sobrevive ao macOS 15.4+ (o
// MRMediaRemoteGetNowPlayingInfo direto foi bloqueado). Testado até macOS 26.
//
// Só LEITURA (título/artista/artwork/estado). Controles (play/pause/next) usam
// `send` do mesmo adapter — a fazer numa próxima iteração.

struct NowPlayingInfo: Equatable {
    var title: String
    var artist: String
    var album: String
    var isPlaying: Bool
    var bundleIdentifier: String?
    var artwork: NSImage?

    static func == (a: NowPlayingInfo, b: NowPlayingInfo) -> Bool {
        a.title == b.title && a.artist == b.artist && a.album == b.album
            && a.isPlaying == b.isPlaying && a.bundleIdentifier == b.bundleIdentifier
    }
}

@MainActor
final class NowPlayingManager: ObservableObject {
    @Published private(set) var info: NowPlayingInfo?
    /// true quando o adapter não pôde ser localizado/rodado (degrada em silêncio).
    @Published private(set) var unavailable = false

    private var process: Process?
    private var readSource: DispatchSourceRead?

    private var perlPath: String { "/usr/bin/perl" }

    /// Caminho do script + framework empacotados em Resources/mediaremote-adapter.
    private var adapterScript: String? {
        Bundle.module.path(forResource: "mediaremote-adapter", ofType: "pl",
                           inDirectory: "Resources/mediaremote-adapter")
            ?? Bundle.module.url(forResource: "mediaremote-adapter", withExtension: "pl")?.path
    }
    private var frameworkPath: String? {
        Bundle.module.url(forResource: "MediaRemoteAdapter", withExtension: "framework",
                          subdirectory: "Resources/mediaremote-adapter")?.path
            ?? Bundle.module.url(forResource: "MediaRemoteAdapter", withExtension: "framework")?.path
    }

    func start() {
        guard process == nil else { return }
        guard let script = adapterScript, let fw = frameworkPath,
              FileManager.default.isExecutableFile(atPath: perlPath) else {
            unavailable = true
            return
        }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: perlPath)
        p.arguments = [script, fw, "stream"]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        do { try p.run() } catch { unavailable = true; return }
        process = p
        readStream(out.fileHandleForReading)
    }

    func stop() {
        readSource?.cancel(); readSource = nil
        process?.terminate(); process = nil
    }

    // MARK: - controles (send) — funcionam mesmo no macOS 15.4+ (só a leitura quebrou)

    /// MRCommand IDs: play=0, pause=1, togglePlayPause=2, next=4, previous=5.
    func togglePlayPause() { sendCommand(2) }
    func nextTrack() { sendCommand(4) }
    func previousTrack() { sendCommand(5) }

    private func sendCommand(_ id: Int) {
        guard let script = adapterScript, let fw = frameworkPath else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: perlPath)
        p.arguments = [script, fw, "send", String(id)]
        p.standardOutput = Pipe(); p.standardError = Pipe()
        try? p.run()
    }

    // MARK: - stream parsing (uma linha JSON por atualização)

    private var buffer = Data()
    private func readStream(_ handle: FileHandle) {
        handle.readabilityHandler = { [weak self] h in
            let chunk = h.availableData
            guard !chunk.isEmpty else { return }
            Task { @MainActor in self?.ingest(chunk) }
        }
    }

    private func ingest(_ chunk: Data) {
        buffer.append(chunk)
        // processa linha a linha
        while let nl = buffer.firstIndex(of: 0x0A) {
            let line = buffer.subdata(in: buffer.startIndex..<nl)
            buffer.removeSubrange(buffer.startIndex...nl)
            handleLine(line)
        }
    }

    private func handleLine(_ data: Data) {
        guard !data.isEmpty,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        // o stream vem como diff — mescla sobre o estado atual
        var cur = info ?? NowPlayingInfo(title: "", artist: "", album: "", isPlaying: false,
                                         bundleIdentifier: nil, artwork: nil)
        if let t = obj["title"] as? String { cur.title = t }
        if let a = obj["artist"] as? String { cur.artist = a }
        if let al = obj["album"] as? String { cur.album = al }
        if let playing = obj["playing"] as? Bool { cur.isPlaying = playing }
        if let bid = obj["bundleIdentifier"] as? String { cur.bundleIdentifier = bid }
        if let b64 = obj["artworkData"] as? String,
           let d = Data(base64Encoded: b64.replacingOccurrences(of: "\\/", with: "/")),
           let img = NSImage(data: d) {
            cur.artwork = img
        }
        // se veio o marcador de "nada tocando", limpa
        if let stopped = obj["stopped"] as? Bool, stopped {
            info = nil
            return
        }
        info = cur
    }
}
