import SwiftUI
import CodeIslandCore

// BSN Notch — modo lateral direita.
// Coluna vertical GRUDADA na borda direita da tela: um item por agente,
// empilhados de cima para baixo (mascote + anel de estado), no estilo do
// codenotch (a foto de referência #138). Os cantos são arredondados só do lado
// interno (esquerdo); o lado colado na borda é reto.

/// Forma "notch": a barra preta é um retângulo arredondado que FLUTUA colado na
/// borda direita, e nas junções topo/base com a borda há uma curva CÔNCAVA grande
/// (como a base do notch do MacBook / o print de referência). Desenhada como o
/// corpo arredondado + duas "abas" côncavas que preenchem o vão até a borda.
struct SideColumnShape: InsettableShape {
    var radius: CGFloat = 22        // arredondamento do corpo
    var notchCurve: CGFloat = 48    // tamanho da curva côncava (topo e base) — quanto maior, mais fluido
    var inset: CGFloat = 0

    func inset(by amount: CGFloat) -> some InsettableShape {
        var s = self; s.inset += amount; return s
    }

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: inset, dy: inset)
        // Curva "S" côncava nos cantos ESQUERDOS (a barra funde com o fundo,
        // ref #156). `n` é limitado por valor absoluto para não deformar quando a
        // barra é alta (expandido). Borda direita reta (colada na tela).
        let n = min(notchCurve, rect.height / 3)
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))                 // topo-direita
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + n),         // "S" topo-esquerdo
                   control1: CGPoint(x: rect.maxX, y: rect.minY + n * 0.55),
                   control2: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - n))          // desce esquerda
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),             // "S" base-esquerdo
                   control1: CGPoint(x: rect.minX, y: rect.maxY),
                   control2: CGPoint(x: rect.maxX, y: rect.maxY - n * 0.55))
        p.closeSubpath()                                               // sobe borda direita
        return p
    }
}

/// Cor do anel por estado do agente.
private func ringColor(for status: AgentStatus) -> Color {
    switch status {
    case .idle:            return Color.white.opacity(0.28)
    case .processing,
         .running:         return Color.green
    case .waitingApproval: return Color.orange
    case .waitingQuestion: return Color.yellow
    }
}

/// Um item da coluna: mascote do agente dentro de um anel de estado.
/// Interativo: hover destaca + mostra o nome; clique pula para a sessão (herdr).
private struct SideColumnItem: View {
    let sessionId: String
    let session: SessionSnapshot
    let size: CGFloat
    var expanded: Bool = false
    @State private var hovering = false

    private var ring: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.10), lineWidth: 3)
            Circle()
                .trim(from: 0, to: session.status == .idle ? 1 : 0.85)
                .stroke(ringColor(for: session.status),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            MascotView(source: session.source, status: session.status, size: size * 0.56)
        }
        .frame(width: size, height: size)
    }

    private var statusText: String {
        switch session.status {
        case .idle: return "ocioso"
        case .processing, .running: return "trabalhando"
        case .waitingApproval: return "aguardando aprovação"
        case .waitingQuestion: return "fez uma pergunta"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ring
            if expanded {
                VStack(alignment: .leading, spacing: 1) {
                    Text(session.displayName)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.white).lineLimit(1)
                    Text(statusText)
                        .font(.system(size: 10.5))
                        .foregroundStyle(ringColor(for: session.status)).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(hovering && expanded ? 0.08 : 0))
        )
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeOut(duration: 0.12)) { hovering = h } }
        .onTapGesture {
            TerminalActivator.activate(session: session, sessionId: sessionId)
        }
        .help(session.displayName)
    }
}

/// Onda de áudio animada (barras pulsando) — aparece quando algo está tocando.
private struct AudioWaveform: View {
    var color: Color = .white
    var barCount: Int = 4
    var height: CGFloat = 16
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 2.5, height: barHeight(i))
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }

    private func barHeight(_ i: Int) -> CGFloat {
        // cada barra com fase diferente → efeito de onda
        let base: [CGFloat] = [0.4, 0.9, 0.6, 1.0, 0.5]
        let f = base[i % base.count]
        let min = height * 0.28
        return min + (height - min) * (phase * f + (1 - phase) * (1 - f))
    }
}

/// Rodapé de sistema da coluna: now playing + bateria + volume (features tipo Alcove).
private struct SystemFooter: View {
    @ObservedObject var battery: SystemBatteryManager
    @ObservedObject var volume: SystemVolumeManager
    @ObservedObject var nowPlaying: NowPlayingManager
    @ObservedObject var infra: BSNInfraManager
    @ObservedObject var airpods: AirPodsManager
    let size: CGFloat
    var expanded: Bool = false

    private var batterySymbol: String {
        if battery.info.isCharging { return "battery.100.bolt" }
        switch battery.info.level {
        case ..<15:  return "battery.0"
        case ..<40:  return "battery.25"
        case ..<70:  return "battery.50"
        case ..<95:  return "battery.75"
        default:     return "battery.100"
        }
    }
    private var batteryColor: Color {
        if battery.info.isCharging { return .green }
        return battery.info.level < 15 ? .red : (battery.info.level < 40 ? .yellow : .white)
    }
    private var volumeSymbol: String {
        if volume.isMuted || volume.volume <= 0.001 { return "speaker.slash.fill" }
        switch volume.volume {
        case ..<0.34: return "speaker.wave.1.fill"
        case ..<0.67: return "speaker.wave.2.fill"
        default:      return "speaker.wave.3.fill"
        }
    }

    /// Uma linha de sistema: ícone (na coluna do tamanho do mascote) + label
    /// quando expandido — alinhada igual aos itens de agente.
    @ViewBuilder
    private func row<Icon: View, Trailing: View>(
        @ViewBuilder icon: () -> Icon,
        title: String, subtitle: String, subtitleColor: Color = .white.opacity(0.55),
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) -> some View {
        HStack(spacing: 10) {
            icon().frame(width: size, height: size)
            if expanded {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.white).lineLimit(1)
                    if !subtitle.isEmpty {
                        Text(subtitle).font(.system(size: 10.5))
                            .foregroundStyle(subtitleColor).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                trailing()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        VStack(spacing: 10) {
            Rectangle().fill(Color.white.opacity(0.12))
                .frame(maxWidth: expanded ? .infinity : size * 0.6).frame(height: 1)

            // Now Playing — clique toca/pausa; setas (expandido) trocam faixa
            if let np = nowPlaying.info, !np.title.isEmpty {
                row(icon: {
                    ZStack(alignment: .bottomTrailing) {
                        Group {
                            if let art = np.artwork {
                                Image(nsImage: art).resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "music.note").font(.system(size: size * 0.4))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .frame(width: size * 0.82, height: size * 0.82)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        // selo: mostra o que o clique VAI fazer (pause se tocando)
                        Image(systemName: np.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: size * 0.2)).foregroundStyle(.white)
                            .padding(2.5).background(Circle().fill(Color.black.opacity(0.7)))
                            .offset(x: 3, y: 3)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { nowPlaying.togglePlayPause() }
                }, title: np.title, subtitle: np.artist, subtitleColor: .white.opacity(0.6),
                   trailing: {
                    if expanded {
                        HStack(spacing: 10) {
                            Button { nowPlaying.previousTrack() } label: {
                                Image(systemName: "backward.fill").foregroundStyle(.white.opacity(0.8))
                            }.buttonStyle(.plain)
                            Button { nowPlaying.nextTrack() } label: {
                                Image(systemName: "forward.fill").foregroundStyle(.white.opacity(0.8))
                            }.buttonStyle(.plain)
                        }.font(.system(size: 12))
                    }
                })
            }

            // Bateria
            if battery.info.isPresent {
                row(icon: {
                    Image(systemName: batterySymbol).font(.system(size: size * 0.42))
                        .foregroundStyle(batteryColor)
                }, title: "Bateria \(battery.info.level)%",
                   subtitle: battery.info.isCharging ? "carregando" : "")
            }

            // Volume: onda animada quando toca; senão ícone
            row(icon: {
                if let np = nowPlaying.info, np.isPlaying, !np.title.isEmpty {
                    AudioWaveform(color: .white.opacity(0.9), barCount: 4, height: size * 0.42)
                } else {
                    Image(systemName: volumeSymbol).font(.system(size: size * 0.38))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }, title: "Volume \(Int(volume.volume * 100))%", subtitle: "")

            // AirPods / fone BT (só quando conectado com bateria)
            if let ap = airpods.info, ap.isPresent {
                row(icon: {
                    Image(systemName: "airpods")
                        .font(.system(size: size * 0.4))
                        .foregroundStyle((ap.minLevel ?? 100) < 20 ? .red : .white.opacity(0.85))
                }, title: ap.name,
                   subtitle: airpodsSubtitle(ap))
            }

            // Infra: Tailscale
            row(icon: {
                Image(systemName: infra.info.tailscaleUp ? "network" : "network.slash")
                    .font(.system(size: size * 0.36))
                    .foregroundStyle(infra.info.tailscaleUp ? .green : .white.opacity(0.35))
            }, title: "Tailscale",
               subtitle: infra.info.tailscaleUp ? "\(infra.info.tailscalePeersOnline) online" : "desligado",
               subtitleColor: infra.info.tailscaleUp ? .green : .white.opacity(0.4))
        }
    }

    private func airpodsSubtitle(_ ap: AirPodsInfo) -> String {
        if let s = ap.single { return "\(s)%" }
        var parts: [String] = []
        if let l = ap.left { parts.append("E \(l)%") }
        if let r = ap.right { parts.append("D \(r)%") }
        if let c = ap.caseLevel { parts.append("◱ \(c)%") }
        return parts.joined(separator: " · ")
    }
}

struct SideColumnView: View {
    var appState: AppState
    /// Largura total do painel lateral (a coluna usa a parte direita dela).
    var panelWidth: CGFloat = 76

    @StateObject private var battery = SystemBatteryManager()
    @StateObject private var volume = SystemVolumeManager()
    @StateObject private var nowPlaying = NowPlayingManager()
    @StateObject private var infra = BSNInfraManager()
    @StateObject private var airpods = AirPodsManager()

    /// (id da sessão, snapshot) ordenados por prioridade de atenção.
    private var sessions: [(id: String, snap: SessionSnapshot)] {
        func rank(_ s: AgentStatus) -> Int {
            switch s {
            case .waitingApproval, .waitingQuestion: return 0
            case .processing, .running: return 1
            case .idle: return 2
            }
        }
        return appState.sessions
            .map { (id: $0.key, snap: $0.value) }
            .sorted { a, b in
                let ra = rank(a.snap.status), rb = rank(b.snap.status)
                return ra != rb ? ra < rb : a.snap.lastActivity > b.snap.lastActivity
            }
    }

    private let itemSize: CGFloat = 26
    @State private var expanded = false
    private let collapsedW: CGFloat = 46
    private let expandedW: CGFloat = 340
    @AppStorage(SettingsKey.sessionGroupingMode) private var groupingMode = SettingsDefaults.sessionGroupingMode

    // abas ALL/STA/CLI (mesma lógica do topo)
    private var tabsBar: some View {
        HStack(spacing: 1) {
            ForEach([("all", "ALL"), ("status", "STA"), ("cli", "CLI")], id: \.0) { tag, label in
                let selected = groupingMode == tag
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { groupingMode = tag }
                } label: {
                    Text(label)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(selected ? Color(red: 0.3, green: 0.85, blue: 0.4) : .white.opacity(0.35))
                        .padding(.horizontal, 7).padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 5).fill(selected ? .white.opacity(0.1) : .clear))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
            // contador e waveform (igual topo)
            if let np = nowPlaying.info, np.isPlaying, !np.title.isEmpty {
                AudioWaveform(color: .white.opacity(0.85), barCount: 3, height: 12)
            }
            Text("\(sessions.filter { $0.snap.status != .idle }.count)/\(sessions.count)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.3, green: 0.85, blue: 0.4))
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0).allowsHitTesting(false)   // vazio à esquerda passa o mouse
            VStack(alignment: .leading, spacing: 8) {
                if expanded {
                    tabsBar
                    // lista rica NATIVA (nome/branch/id/tempo/herdr/última ação/thinking + CLIQUE)
                    SessionListView(appState: appState, onlySessionId: nil)
                } else {
                    // colapsado: só os mascotes com anel de estado
                    ForEach(sessions, id: \.id) { entry in
                        SideColumnItem(sessionId: entry.id, session: entry.snap,
                                       size: itemSize, expanded: false)
                    }
                    if sessions.isEmpty {
                        MascotView(source: "claude", status: .idle, size: itemSize * 0.56)
                            .frame(width: itemSize, height: itemSize).opacity(0.5)
                    }
                }
                Divider().overlay(Color.white.opacity(0.12))
                SystemFooter(battery: battery, volume: volume, nowPlaying: nowPlaying,
                             infra: infra, airpods: airpods, size: itemSize, expanded: expanded)
            }
            .padding(.vertical, expanded ? 16 : 44)
            .padding(.horizontal, expanded ? 16 : 10)
            .frame(width: expanded ? expandedW : collapsedW)
            // COLAPSADO: forma "notch" com curva "S" côncava fluida (discreto).
            // EXPANDIDO: card com cantos esquerdos ARREDONDADOS normais; a direita
            // fica reta pois já está colada na borda da tela.
            .background(Group {
                if expanded {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 22, bottomLeadingRadius: 22,
                        bottomTrailingRadius: 0, topTrailingRadius: 0,
                        style: .continuous
                    ).fill(Color.black.opacity(0.92))
                } else {
                    SideColumnShape(radius: 22, notchCurve: 48).fill(Color.black.opacity(0.92))
                }
            })
            .contentShape(Rectangle())
            .onHover { h in withAnimation(.easeOut(duration: 0.16)) { expanded = h } }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .onAppear { battery.start(); volume.start(); nowPlaying.start(); infra.start(); /* airpods.start() (adiado: KVC private) */ }
        .onDisappear { battery.stop(); volume.stop(); nowPlaying.stop(); infra.stop(); /* airpods.stop() */ }
    }
}
