<div align="center">

# BSN Notch

**Um super-notch para macOS: comande seus agentes de IA e o seu sistema, direto do notch.**

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-black)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-GPL--3.0-blue)

</div>

---

BSN Notch vive na área do notch (ou na lateral da tela — você escolhe) e reúne, num
só lugar, duas coisas que hoje exigem dois apps:

- **Comando de agentes de IA** — o que cada agente Claude Code / Codex está fazendo em
  tempo real (via **herdr**), com **responder perguntas** e **aprovar/negar permissões**
  sem sair do app atual, pelo notch, por atalho global ou pelo **iPhone / Apple Watch**.
- **Atividades de sistema** — Now Playing (música/vídeo + controles), bateria, AirPods,
  volume/brilho, foco, calendário — no estilo das "live activities".

## Estado

Em desenvolvimento. Fork de [CodeIsland](https://github.com/wxtsky/CodeIsland) (MIT),
incorporando features de sistema de [boring.notch](https://github.com/TheBoredTeam/boring.notch)
(GPL-3.0). Veja o planejamento em [`AI/`](./AI/) (PLANS / TASKS / NOTES / HISTORY).

### Roadmap
1. Base (agentes + herdr) — herdada do CodeIsland ✅
2. Dois modos de visualização configuráveis: topo (island) e lateral direita
3. Retheming para a identidade BSN (ícones de biblioteca, sem pixel-art)
4. Features de sistema (Now Playing, bateria, HUDs…) portadas do boring.notch
5. Widgets de infra do ecossistema BSN (Tailscale, VPN, sync, pipelines)
6. Companion iPhone / Apple Watch (herdado) + publicação

## Build

```sh
swift build            # debug
./.build/debug/CodeIsland
./build.sh             # release universal (.app)
```

macOS 14+. Dependências: Sparkle, Yams (via SPM).

## Licença

**GPL-3.0** — ver [LICENSE](./LICENSE) e as atribuições em [NOTICE.md](./NOTICE.md).

BSN Notch © 2026 BSN Solution / Cristhyan Kohlhase.
