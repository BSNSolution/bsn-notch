import Foundation
import CoreAudio
import AudioToolbox
import Combine

// BSN Notch — feature de sistema: Volume.
// CoreAudio público (kAudioHardwareServiceDeviceProperty_VirtualMainVolume) no
// device de saída default. Lê, observa mudanças e permite ajustar.

@MainActor
final class SystemVolumeManager: ObservableObject {
    @Published private(set) var volume: Float = 0.5   // 0…1
    @Published private(set) var isMuted: Bool = false

    private var deviceID: AudioObjectID = kAudioObjectUnknown
    private var listenerBlock: AudioObjectPropertyListenerBlock?

    func start() {
        deviceID = Self.defaultOutputDevice()
        refresh()
        installListener()
    }

    func stop() {
        removeListener()
    }

    func setVolume(_ v: Float) {
        let clamped = min(1, max(0, v))
        var value = clamped
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        guard deviceID != kAudioObjectUnknown else { return }
        AudioObjectSetPropertyData(deviceID, &addr, 0, nil,
                                   UInt32(MemoryLayout<Float>.size), &value)
        volume = clamped
    }

    func refresh() {
        guard deviceID != kAudioObjectUnknown else { return }
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        var value: Float = 0
        var size = UInt32(MemoryLayout<Float>.size)
        if AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &size, &value) == noErr {
            volume = value
        }
        // mute
        var muteAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        var muted: UInt32 = 0
        var msize = UInt32(MemoryLayout<UInt32>.size)
        if AudioObjectHasProperty(deviceID, &muteAddr),
           AudioObjectGetPropertyData(deviceID, &muteAddr, 0, nil, &msize, &muted) == noErr {
            isMuted = muted != 0
        }
    }

    // MARK: - helpers

    private static func defaultOutputDevice() -> AudioObjectID {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var dev = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &dev)
        return dev
    }

    private func installListener() {
        guard deviceID != kAudioObjectUnknown else { return }
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor in self?.refresh() }
        }
        listenerBlock = block
        AudioObjectAddPropertyListenerBlock(deviceID, &addr, DispatchQueue.main, block)
    }

    private func removeListener() {
        guard deviceID != kAudioObjectUnknown, let block = listenerBlock else { return }
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        AudioObjectRemovePropertyListenerBlock(deviceID, &addr, DispatchQueue.main, block)
        listenerBlock = nil
    }
}
