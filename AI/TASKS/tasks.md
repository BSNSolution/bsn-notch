# Tasks de Implementação - BSN Notch

**Status Geral**: ⚪ Não Iniciado (planejamento pronto, aguardando OK pra Fase 0)
**Última Atualização**: 15/09/2026 01:46
**Objetivo**: Fork do codenotch → centro de comando de agentes (herdr) com responder pelo notch/celular + widgets de infra. Escopo COMPLETO.

## Legenda de Status
- ⚪ Não Iniciado · 🟡 Em Progresso · 🟢 Concluído · 🔴 Bloqueado

---

## FASE 0: Fork & Build ⚪
### 0.1 Setup ⚪
- [ ] `brew install xcodegen`
- [ ] Fork upstream vinzdg/codenotch → BSNSolution/bsn-notch (gh, com autorização explícita do Cristhyan p/ criar repo)
- [ ] Clonar em ~/Work/BSN Solution/Repositorios/bsn-notch + criar estrutura AI/ (mover este planejamento pra lá)
- [ ] `make run` — validar build no macOS 26.6
- [ ] Rodar `CODENOTCH_DEMO=1` (dados de exemplo) pra ver o notch
- [ ] Rebranding: nome "BSN Notch", glyph/ícone (Lucide), bundle id com.bsnsolution.notch

## FASE 1: HerdrActivityMonitor ⚪
### 1.1 Fonte herdr ⚪
- [ ] Criar `Sources/Sessions/HerdrActivityMonitor.swift` (conforma AgentActivityMonitor)
- [ ] Ler `herdr api snapshot` (JSON): agents[] com agent_status/display_agent/pane_id/tab_id/workspace_id/cwd/focused
- [ ] Mapear agent_status (idle/working/blocked/done/unknown) → AgentSession
- [ ] Detectar protocol mismatch (comparar protocol client vs server em `herdr status`) → status degradado visível
- [ ] Registrar o monitor no dict `monitors` (AppDelegate.swift:638-644)
- [ ] Validar: notch mostra os agentes reais com /nome + workspace + estado

## FASE 2: Resumo por projeto ⚪
- [ ] Agregação por workspace (Trigo/BSN/CREA/Geral): contadores idle/working/blocked
- [ ] Widget "Trigo 3 idle · BSN 1 working · CREA 1 blocked" no notch/tooltip

## FASE 3: Responder pelo notch ⚪
### 3.1 Ler a pergunta ⚪
- [ ] Integrar `moshi-hook context` → prompt.kind/questions[].options quando agente blocked
### 3.2 UI de resposta ⚪
- [ ] Popover ativável (o NotchPanel é canBecomeKey=false — criar painel/popover separado que vira key)
- [ ] Renderizar opções como botões (Lucide, não emoji)
- [ ] Campo de texto livre (fallback p/ resposta aberta)
### 3.3 Enviar ⚪
- [ ] Enviar via `herdr agent prompt <pane> "texto"` (resposta livre)
- [ ] Enviar via `herdr agent send-keys <pane>` (setas+enter p/ escolher opção)
- [ ] `herdr agent focus <pane>` opcional ao responder

## FASE 4: Widgets de infra/pipeline ⚪
- [ ] Provider infra (.localRuntime): Tailscale status (peers on/off)
- [ ] VPN GCOM status (vpn-gcom-up.sh --status) — só status, nunca 2FA cego
- [ ] Workstation sync (tail ~/.publish-workstation.log — última execução)
- [ ] Dev servers locais (`moshi-hook servers`) — clique abre no browser
- [ ] (opcional) Azure DevOps builds em andamento + "avisa quando terminar"
- [ ] (opcional) Dokploy deploys

## FASE 5: Celular ⚪
- [ ] Ligar PhoneLink (PhoneLink.isAvailable = true) — hoje off
- [ ] Endpoint `POST /api/v3/command` no PhoneLinkRequestHandler (auth v3 já cobre)
- [ ] Injetar closure de ação (responder agente do iPhone)
- [ ] Modelo de segurança tailnet-only (herdar do Collie)

## FASE 6: Polish ⚪
- [ ] Alertas/sons por evento (finished/waiting) — respeitar "zero interrupção"
- [ ] Preferências (quais widgets, ordem)
- [ ] `Scripts/sign-local.sh` (grant de keychain estável em dev)
- [ ] Doc + memória (project_bsn_notch)

---

## 📊 Métricas de Progresso
- Total de Tarefas: ~35 · Concluídas: 0 · Em Progresso: 0 · Bloqueadas: 0 · Progresso: 0%

## ⚠️ Nota de escopo
Fases 0-2 = MVP funcional (ver agentes). Fase 3 = o diferencial (responder). Fases 4-5 = centro de comando completo. Dá pra entregar incremental: cada fase é usável por si.

---
## ATUALIZACAO 15/09/2026 03:10 — estado real
### FEITO
- Fase 0 (fork+build) / Fase 1 (GPL+NOTICE+README) / Fase 2 (2 modos topo+lateral + coluna vertical igual foto #138 + hover/clique).
### EM ANDAMENTO (Now Playing)
- Fonte: boring.notch NowPlayingController(426l) + adapter(framework 332k + perl). GAP: empacotar framework binario em bundle SPM (nao-trivial) + portar PlaybackState/NowPlayingUpdate + UI player. Varias horas.
### A FAZER
- Now Playing, Bateria(IOKit facil), Volume(SimplyCoreAudio facil), AirPods(private), Focus, Brilho(private).
- Widgets infra BSN: Tailscale/VPN/sync/dev servers.
- Retheming: MANTER pixel-art por ora. Companion iPhone/Watch: validar/rebrand.
- Rebranding profundo (~/.codeisland): adiado (mexe hooks).
### Realidade
"Fazer tudo" = dezenas de horas; cada feature de sistema = 1 modulo. Base+2modos+coluna ja entregam o core.
