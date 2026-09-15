import Foundation
import IOBluetooth
import Combine

// BSN Notch — feature de sistema: bateria dos AirPods / fones Bluetooth.
//
// ⚠️ Não há API pública para a bateria de AirPods. Usa-se a private API do
// IOBluetooth que lê as chaves BatteryPercent{Single,Left,Right,Case} do device
// pareado (mesma técnica do Hammerspoon / AirpodsBattery-Monitor). Por ser
// private, pode quebrar entre versões do macOS — tudo protegido: se algo falhar,
// o widget simplesmente não aparece (nunca crasha).

struct AirPodsInfo: Equatable {
    var name: String
    var single: Int?    // fones "single-piece" (ex.: caixinha de som BT)
    var left: Int?
    var right: Int?
    var caseLevel: Int?
    var connected: Bool

    var isPresent: Bool { connected && (single != nil || left != nil || right != nil) }
    /// menor bateria entre os fones (o que importa "quando acaba")
    var minLevel: Int? {
        [single, left, right].compactMap { $0 }.min()
    }
}

@MainActor
final class AirPodsManager: ObservableObject {
    @Published private(set) var info: AirPodsInfo?

    private var timer: Timer?

    func start() {
        refresh()
        let t = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        t.tolerance = 20
        timer = t
    }

    func stop() { timer?.invalidate(); timer = nil }

    func refresh() {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            info = nil; return
        }
        // pega o primeiro fone conectado que exponha bateria
        for dev in devices where dev.isConnected() {
            let single = intValue(dev, "BatteryPercentSingle")
            let left = intValue(dev, "BatteryPercentLeft")
            let right = intValue(dev, "BatteryPercentRight")
            let caseL = intValue(dev, "BatteryPercentCase")
            if single != nil || left != nil || right != nil {
                info = AirPodsInfo(
                    name: dev.name ?? "Fone",
                    single: single, left: left, right: right, caseLevel: caseL,
                    connected: true
                )
                return
            }
        }
        info = nil
    }

    /// Lê uma chave de bateria (0–100) via KVC no device.
    /// `value(forKey:)` lança NSUnknownKeyException (Obj-C) se a chave não existir
    /// — e isso NÃO é capturável por try/catch do Swift, derrubando o app. Por
    /// isso usamos um wrapper Obj-C try/catch (ObjCExceptionCatcher) por segurança.
    private func intValue(_ dev: IOBluetoothDevice, _ key: String) -> Int? {
        // ADIADO: leitura via KVC de private API lança NSUnknownKeyException
        // (Obj-C, não capturável pelo Swift) e derruba o app. Reativar quando
        // houver um ObjCExceptionCatcher (helper Obj-C) no target. Por ora, nil.
        return nil
    }
}
