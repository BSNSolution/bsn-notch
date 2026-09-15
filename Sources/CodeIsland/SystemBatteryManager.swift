import Foundation
import IOKit.ps
import Combine

// BSN Notch — feature de sistema: Bateria.
// Usa IOKit IOPowerSources (API PÚBLICA, sem entitlement) para nível, carga e
// tempo restante. Publica para a UI observar.

struct BatteryInfo: Equatable {
    var level: Int          // 0–100
    var isCharging: Bool
    var isPluggedIn: Bool
    var minutesRemaining: Int?   // nil = calculando / desconhecido
    var isPresent: Bool
}

@MainActor
final class SystemBatteryManager: ObservableObject {
    @Published private(set) var info = BatteryInfo(
        level: 100, isCharging: false, isPluggedIn: false, minutesRemaining: nil, isPresent: false
    )

    private var runLoopSource: CFRunLoopSource?
    private var timer: Timer?

    func start() {
        refresh()
        // notificação nativa quando algo muda de estado de energia
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        if let src = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let me = Unmanaged<SystemBatteryManager>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in me.refresh() }
        }, ctx)?.takeRetainedValue() {
            runLoopSource = src
            CFRunLoopAddSource(CFRunLoopGetMain(), src, .defaultMode)
        }
        // fallback: refresh periódico (tempo restante muda sem evento)
        let t = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        t.tolerance = 15
        timer = t
    }

    func stop() {
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .defaultMode)
            runLoopSource = nil
        }
        timer?.invalidate(); timer = nil
    }

    func refresh() {
        guard
            let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
            let ps = list.first,
            let desc = IOPSGetPowerSourceDescription(blob, ps)?.takeUnretainedValue() as? [String: Any]
        else {
            info = BatteryInfo(level: 100, isCharging: false, isPluggedIn: false, minutesRemaining: nil, isPresent: false)
            return
        }

        let capacity = desc[kIOPSCurrentCapacityKey] as? Int ?? 100
        let max = desc[kIOPSMaxCapacityKey] as? Int ?? 100
        let level = max > 0 ? Int((Double(capacity) / Double(max) * 100).rounded()) : capacity
        let charging = desc[kIOPSIsChargingKey] as? Bool ?? false
        let sourceState = desc[kIOPSPowerSourceStateKey] as? String
        let plugged = sourceState == kIOPSACPowerValue
        let tte = desc[kIOPSTimeToEmptyKey] as? Int
        let ttf = desc[kIOPSTimeToFullChargeKey] as? Int
        // -1 = ainda calculando
        let remaining: Int? = charging ? (ttf.flatMap { $0 > 0 ? $0 : nil })
                                        : (tte.flatMap { $0 > 0 ? $0 : nil })

        info = BatteryInfo(
            level: min(100, Swift.max(0, level)),
            isCharging: charging,
            isPluggedIn: plugged,
            minutesRemaining: remaining,
            isPresent: true
        )
    }
}
