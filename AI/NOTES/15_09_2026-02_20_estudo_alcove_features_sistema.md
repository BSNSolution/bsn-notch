# Nota - Estudo Alcove: features de sistema no BSN Notch

**Data/Hora**: 15/09/2026 02:20
**Tipo**: Descoberta/Decisão pendente
**Contexto**: escopo "super-notch" (agentes CodeIsland + sistema Alcove)

## 📌 O que
Alcove é FECHADO (US$15, não OSS) → não copiar. Mas boring.notch (TheBoredTeam/boring.notch) é OSS e faz TODAS as features do Alcove = mapa de referência 1:1.

## Viabilidade por feature
- ✅ FÁCEIS (API pública): Volume (CoreAudio/SimplyCoreAudio MIT), Bateria (IOKit IOPowerSources), Calendário (EventKit+permissão), Timers, BT conectado (IOBluetooth), Lock Screen (notif screenIsLocked).
- ⚠️ NOW PLAYING (maior valor): API MediaRemote é PRIVATE e Apple QUEBROU a LEITURA no macOS 15.4+. Solução padrão 2026 = `ungive/mediaremote-adapter` (BSD-3): usa /usr/bin/perl (com.apple.perl5, assinado Apple c/ entitlement) → JSON streaming c/ artwork, sem SIP, testado até macOS 27. Comandos play/pause/next continuam OK. Incluir `test`+fallback AppleScript.
- 🟠 ARRISCADAS (private, feature-flag + degradar sem crash): AirPods battery (IOBluetooth private BatteryPercentLeft/Right/Case — ref Hammerspoon), Brilho (DisplayServices/CoreDisplay via dlsym, só display interno; externo=DDC), Focus (parsear ~/Library/DoNotDisturb/DB/*.json, exige Full Disk Access, formato muda).

## Libs seguras (MIT/BSD) p/ usar direto
- ungive/mediaremote-adapter (BSD-3) — Now Playing
- rnine/SimplyCoreAudio (MIT) — volume
- MrKai77/DynamicNotchKit (MIT) — chrome de notch/live activity (se precisar além do CodeIsland)

## 🤔 DECISÃO PENDENTE (Cristhyan)
Produto PROPRIETÁRIO ou GPL/aberto? boring.notch é GPL-3.0 (copyleft):
- Se proprietário → NÃO copiar código do boring.notch; só referência + reescrever; usar só libs MIT/BSD.
- Se GPL/aberto → pode reaproveitar código do boring.notch direto (acelera muito).

## ✅ Como aplicar (plano de features)
1. Ganhos rápidos (API pública): Volume, Bateria, Calendário, Timers, BT, Lock.
2. Now Playing via mediaremote-adapter (BSD) + test/fallback.
3. Private (AirPods/Brilho/Focus) por último, isoladas atrás de feature-flag.

## 🔗 Relacionado
- PLANS v2 (base CodeIsland), HISTORY 02_15. Repos: boring.notch (GPL), mediaremote-adapter (BSD), SimplyCoreAudio (MIT), DynamicNotchKit (MIT).
