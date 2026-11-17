import Combine
import Foundation

/// Reports what every Claude/Codex agent running inside **herdr** is doing.
///
/// herdr (the terminal workspace manager the user drives all their agents from)
/// exposes a socket API through its CLI. `herdr agent list` returns, in one JSON
/// blob, every agent pane with its live status, the display name the user gave it
/// (`/nome`), its workspace, and its `pane_id` — the handle later phases use to
/// answer a blocked agent (`herdr agent prompt|send-keys|focus <pane_id>`).
///
/// This is a *display* monitor like the others (see `AgentActivityMonitor`): it
/// polls, maps herdr's vocabulary onto `AgentSession`, and publishes. It holds no
/// pid — herdr agents are addressed by `pane_id`, not process — so jumping to a
/// window goes through herdr focus rather than `SessionFocus`.
@MainActor
final class HerdrActivityMonitor: ObservableObject, AgentActivityMonitor {
    @Published private(set) var sessions: [AgentSession] = []
    var sessionsPublisher: AnyPublisher<[AgentSession], Never> { $sessions.eraseToAnyPublisher() }

    /// Absolute path: a launchd/GUI-launched app does not inherit the user's
    /// PATH, so `herdr` on it cannot be assumed. Overridable for tests.
    private let herdrPath: String
    private let pollInterval: TimeInterval
    private var timer: Timer?

    init(herdrPath: String? = nil, pollInterval: TimeInterval = 2.0) {
        self.herdrPath = herdrPath ?? Self.resolveHerdrPath()
        self.pollInterval = pollInterval
    }

    func start() {
        poll()
        let t = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        t.tolerance = pollInterval * 0.3
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Polling

    private func poll() {
        // Gotcha (see reference_herdr_nome_sidebar_display): after a herdr binary
        // update, the client/server protocol can mismatch and every socket call
        // fails *silently*. Rather than publish "no agents" (a lie that would
        // stop the notch warning the user), degrade to a single visible marker.
        guard Self.herdrCompatible(herdrPath: herdrPath) else {
            sessions = [AgentSession(
                id: "herdr:incompatible",
                name: "herdr",
                detail: "protocolo incompatível — reinicie o herdr",
                state: .waiting,
                waitingFor: "atualização do herdr",
                since: Date()
            )]
            return
        }
        guard let raw = Self.run(herdrPath, ["agent", "list"]) else {
            // herdr not running / socket down: nothing to show, not an error banner.
            sessions = []
            return
        }
        sessions = Self.parse(raw)
    }

    // MARK: - Parsing

    /// Exposed for tests: maps a `herdr agent list` JSON payload to sessions.
    static func parse(_ data: Data) -> [AgentSession] {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = root["result"] as? [String: Any],
            let agents = result["agents"] as? [[String: Any]]
        else { return [] }

        return agents.compactMap { a -> AgentSession? in
            guard let paneID = a["pane_id"] as? String else { return nil }
            let name = (a["display_agent"] as? String)
                ?? (a["title"] as? String)
                ?? paneID
            let statusRaw = (a["agent_status"] as? String) ?? "unknown"
            let state = mapState(statusRaw)
            let workspace = (a["workspace_id"] as? String) ?? ""
            let cwd = (a["foreground_cwd"] as? String) ?? (a["cwd"] as? String) ?? ""
            let detail = detailLine(cwd: cwd, workspace: workspace)
            return AgentSession(
                id: "herdr:\(paneID)",
                name: name,
                detail: detail,
                state: state,
                waitingFor: state == .waiting ? "resposta" : nil,
                since: Date(),
                processID: nil
            )
        }
    }

    /// herdr's status vocabulary → the notch's four states.
    /// `done` is treated as `success` (finished), `blocked` as `waiting` (needs you).
    static func mapState(_ raw: String) -> AgentSession.State {
        switch raw.lowercased() {
        case "working", "busy", "running": return .busy
        case "blocked", "waiting": return .waiting
        case "done", "success", "finished": return .success
        default: return .idle
        }
    }

    private static func detailLine(cwd: String, workspace: String) -> String {
        let dir = cwd.isEmpty ? "" : (cwd as NSString).lastPathComponent
        switch (workspace.isEmpty, dir.isEmpty) {
        case (false, false): return "\(workspace) · \(dir)"
        case (false, true): return workspace
        case (true, false): return dir
        default: return "herdr"
        }
    }

    // MARK: - herdr process helpers

    private static func resolveHerdrPath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = ["\(home)/.local/bin/herdr", "/opt/homebrew/bin/herdr", "/usr/local/bin/herdr"]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) } ?? "herdr"
    }

    /// True when herdr's client and server agree on the protocol. A `no` (or an
    /// unparseable status) means socket calls would fail silently.
    static func herdrCompatible(herdrPath: String) -> Bool {
        guard let out = run(herdrPath, ["status"]),
              let text = String(data: out, encoding: .utf8) else { return false }
        // `herdr status` prints a `compatible: yes|no` line under `server:`.
        for line in text.split(separator: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("compatible:") {
                return t.hasSuffix("yes")
            }
        }
        // No explicit line (older herdr): fall back to comparing protocol numbers.
        let protos = text.split(separator: "\n")
            .filter { $0.contains("protocol:") }
            .compactMap { $0.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) }
        if protos.count >= 2 { return protos[0] == protos[1] }
        return true // no info to contradict; don't cry wolf
    }

    /// Runs a herdr subcommand, returns stdout on exit 0, nil otherwise.
    @discardableResult
    static func run(_ path: String, _ args: [String]) -> Data? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        do {
            try p.run()
        } catch {
            return nil
        }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return nil }
        return data
    }
}
