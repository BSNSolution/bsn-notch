import Foundation
import Combine

// BSN Notch — widgets de infra do ecossistema BSN (o diferencial: nenhum outro
// notch tem isto). Status de relance da infra de que o trabalho depende:
//  - Tailscale: quantos peers online (a malha que liga Mac/servidores/celular)
//  - VPN GCOM: conectada? (os MCPs Oracle dependem dela)
//  - Workstation sync: há quanto tempo rodou o último publish
// Tudo por leitura de comando/arquivo — só status, NUNCA segredos na tela.

struct BSNInfraInfo: Equatable {
    var tailscaleUp: Bool
    var tailscalePeersOnline: Int
    var vpnGcomConnected: Bool
    var lastSyncMinutesAgo: Int?   // nil = desconhecido
}

@MainActor
final class BSNInfraManager: ObservableObject {
    @Published private(set) var info = BSNInfraInfo(
        tailscaleUp: false, tailscalePeersOnline: 0, vpnGcomConnected: false, lastSyncMinutesAgo: nil
    )

    private var timer: Timer?
    private let tailscaleBin = "/usr/local/bin/tailscale"

    func start() {
        refresh()
        let t = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        t.tolerance = 10
        timer = t
    }

    func stop() { timer?.invalidate(); timer = nil }

    func refresh() {
        Task.detached { [tailscaleBin] in
            let ts = Self.tailscaleStatus(bin: tailscaleBin)
            let vpn = Self.vpnGcomUp()
            let sync = Self.lastSyncMinutes()
            await MainActor.run { [weak self] in
                self?.info = BSNInfraInfo(
                    tailscaleUp: ts.up,
                    tailscalePeersOnline: ts.online,
                    vpnGcomConnected: vpn,
                    lastSyncMinutesAgo: sync
                )
            }
        }
    }

    // MARK: - leituras (nonisolated helpers, rodam fora do main)

    private nonisolated static func run(_ path: String, _ args: [String], timeout: TimeInterval = 5) -> String? {
        guard FileManager.default.isExecutableFile(atPath: path) else { return nil }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let out = Pipe(); p.standardOutput = out; p.standardError = Pipe()
        do { try p.run() } catch { return nil }
        // guard de timeout simples
        let deadline = Date().addingTimeInterval(timeout)
        while p.isRunning && Date() < deadline { usleep(50_000) }
        if p.isRunning { p.terminate(); return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }

    private nonisolated static func tailscaleStatus(bin: String) -> (up: Bool, online: Int) {
        guard let out = run(bin, ["status"]) else { return (false, 0) }
        if out.lowercased().contains("stopped") || out.isEmpty { return (false, 0) }
        // conta linhas de peer que NÃO estão "offline"
        var online = 0
        for line in out.split(separator: "\n") {
            let l = line.trimmingCharacters(in: .whitespaces)
            guard l.hasPrefix("100.") else { continue }
            if !l.lowercased().contains("offline") { online += 1 }
        }
        return (true, online)
    }

    private nonisolated static func vpnGcomUp() -> Bool {
        // ppp0 presente = VPN GCOM conectada (não roda o script, só checa interface)
        guard let out = run("/sbin/ifconfig", ["ppp0"]) else { return false }
        return out.contains("inet ")
    }

    private nonisolated static func lastSyncMinutes() -> Int? {
        let path = NSHomeDirectory() + "/.publish-workstation.log"
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let mod = attrs[.modificationDate] as? Date else { return nil }
        return Int(Date().timeIntervalSince(mod) / 60)
    }
}
