# Nota - DECISÃO: BSN Notch será GPL-3.0 (aberto)

**Data/Hora**: 15/09/2026 02:30
**Tipo**: Decisão (Combinado com o usuário)
**Contexto**: licença do produto BSN Notch

## 📌 O que
Cristhyan decidiu: **BSN Notch = OPEN-SOURCE, licença GPL-3.0**.

## 🤔 Por que
Destrava reaproveitar código do **boring.notch (GPL-3.0)** direto — ele já implementa TODAS as features de sistema do Alcove (Now Playing, bateria, HUD, AirPods, calendário, lock screen). Acelera muito vs. reescrever.

## Compatibilidade de licenças (confirmada)
- Base **CodeIsland = MIT** → MIT é compatível, pode ser incorporado em projeto GPL.
- **boring.notch = GPL-3.0** (confirmado no LICENSE do repo — NÃO é CC-BY-NC como uma fonte sugeriu).
- Ao misturar GPL-3.0 → **o projeto combinado BSN Notch DEVE ser GPL-3.0**. Trocar o LICENSE do fork (hoje MIT do CodeIsland) por GPL-3.0, preservando atribuição a wxtsky (CodeIsland/MIT) + TheBoredTeam (boring.notch/GPL) num THIRD_PARTY/NOTICE.

## ✅ Como aplicar
- Pode COPIAR/PORTAR código do boring.notch (módulos NowPlaying/Battery/HUD/Bluetooth) para o BSN Notch.
- Libs MIT/BSD (mediaremote-adapter, SimplyCoreAudio, DynamicNotchKit) seguem OK.
- Ao publicar: LICENSE = GPL-3.0; creditar CodeIsland (MIT) e boring.notch (GPL) nas atribuições.
- repos clonados p/ portar: scratchpad/boring.notch (GPL), scratchpad/CodeIsland (base MIT).

## 🔗 Relacionado
- [[project_bsn_notch]], NOTE estudo_alcove_features_sistema, PLANS v2.
