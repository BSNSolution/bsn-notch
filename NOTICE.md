# BSN Notch — Attributions

**BSN Notch** is licensed under the **GNU General Public License v3.0** (see [LICENSE](./LICENSE)).

It is built on and incorporates code from the following open-source projects:

## Base
- **CodeIsland** by wxtsky — https://github.com/wxtsky/CodeIsland — **MIT License**
  (original MIT text preserved in [LICENSE-CodeIsland-MIT](./LICENSE-CodeIsland-MIT)).
  BSN Notch is a fork of CodeIsland; the AI-agent notch, herdr integration, Unix-socket
  IPC, permission/question answering and the iPhone/Watch companion originate here.

## System features (ported / adapted)
- **boring.notch** by TheBoredTeam — https://github.com/TheBoredTeam/boring.notch — **GPL-3.0**
  (system-level notch features: Now Playing, battery, HUDs, Bluetooth/AirPods, calendar,
  lock-screen widgets). Incorporating GPL-3.0 code is why BSN Notch as a whole is GPL-3.0.

## Third-party libraries
- **mediaremote-adapter** by ungive — https://github.com/ungive/mediaremote-adapter — BSD-3-Clause
  (Now Playing on macOS 15.4+ via the Apple-signed Perl bridge).
- **SimplyCoreAudio** by rnine — MIT (system volume).
- **DynamicNotchKit** by MrKai77 — MIT (notch chrome / live activities), if used.
- **Sparkle** (auto-update) and **Yams** (YAML) — as declared in `Package.swift`.

---
BSN Notch © 2026 BSN Solution / Cristhyan Kohlhase. Distributed under GPL-3.0.

## Adicionado (features de sistema)
- **mediaremote-adapter** (ungive, BSD-3) empacotado em Sources/CodeIsland/Resources/mediaremote-adapter/ (script Perl + MediaRemoteAdapter.framework) — Now Playing no macOS 15.4+.
- Bateria (IOKit IOPowerSources) e Volume (CoreAudio/AudioToolbox) — APIs publicas, codigo proprio BSN.
