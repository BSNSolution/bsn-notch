# Plano - BSN Notch (fork do codenotch → centro de comando de agentes)

**Status**: 🟡 Em elaboração
**Criado**: 15/09/2026  ·  **Última Atualização**: 15/09/2026
**Objetivo**: Fork do codenotch (MIT, Swift/macOS) transformado num "centro de comando" dos agentes do Cristhyan — mostra status dos agentes (herdr), permite responder perguntas de sessão pelo notch e pelo celular, e traz widgets de infra/pipeline. Mantém os anéis de uso de LLM originais.

## 🎯 Contexto e Motivação
Cristhyan roda MUITAS sessões Claude simultâneas (12 agentes no herdr no momento do estudo) em projetos diferentes (Trigo/BSN/CREA/Geral), alta troca de contexto, trabalha de madrugada, espera pipelines/builds. Dores: (1) "qual terminal faz o quê agora", (2) espera cega de build/deploy, (3) sessão que ficou muda/esperando input, (4) perder contexto. O codenotch já resolve parcialmente (detecta busy/waiting/done + som + traz app à frente) mas só lê `~/.claude/sessions` e foca em uso de LLM. Todas as fontes de dados/ações que faltam JÁ EXISTEM no ecossistema (herdr socket API, moshi-hook, sessões nativas) — falta só o app consumir.

## 🧭 Abordagem Escolhida
Fork próprio em **BSNSolution/bsn-notch** (mantém upstream vinzdg/codenotch pra puxar melhorias). Estender via os 2 pontos de extensão do codenotch:
- **AgentActivityMonitor** (protocolo ~10 linhas): criar `HerdrActivityMonitor` que lê `herdr api snapshot` → publica `[AgentSession]`. Liga notch + som + peek automaticamente.
- **UsageProvider** (`.localRuntime`, molde OllamaLocalProvider): providers de infra (Tailscale/VPN/workstation) e pipeline.
- **Responder**: novo popover ATIVÁVEL (o notch é read-only/canBecomeKey=false por design) que mostra opções da pergunta (`moshi-hook context` → prompt.questions[].options) como botões e responde via `herdr agent prompt`/`send-keys`.
- **Celular**: ligar o PhoneLink (hoje off, read-only) + adicionar endpoint `POST /api/v3/command` pra responder do iPhone (a cripto AES-GCM v3 já cobre request bodies). Já existe precedente: Collie (PWA herdr).

### Regras de design herdadas do gosto do Cristhyan
- Ícones Lucide/Iconify, NUNCA emoji (mesmo em widget).
- Zero interrupção: informação passiva "de relance"; ação só sob clique.
- NUNCA exibir segredo na tela (só status tipo "VPN up"). Device token Moshi/creds herdr ficam nos arquivos, nunca no bundle.
- Denso, aproveita espaço. Estado persistente (não localStorage isolado).
- Segurança: "responder agente" = poder de digitar no terminal (root-equivalente, igual Collie) → herdar modelo tailnet-only/confiança local.

## 🪜 Etapas / Fases
1. **Fase 0 — Fork & build**: fork BSNSolution/bsn-notch, `brew install xcodegen`, `make run` (validar que builda e roda no macOS 26.6), rodar com `CODENOTCH_DEMO=1`. Renomear branding (BSN Notch, glyph).
2. **Fase 1 — HerdrActivityMonitor**: ler `herdr api snapshot` (idle/working/blocked/done + /nome + workspace + pane_id). Detectar protocol mismatch (gotcha herdr). Notch passa a mostrar os agentes reais.
3. **Fase 2 — Resumo por projeto/workspace**: agregação Trigo/BSN/CREA/Geral (contadores por estado).
4. **Fase 3 — Responder pelo notch**: popover ativável; ler pergunta+opções (`moshi-hook context`); botões; enviar via `herdr agent prompt`/`send-keys`. Fallback: campo de texto livre.
5. **Fase 4 — Widgets de infra/pipeline**: Tailscale, VPN GCOM, workstation sync, dev servers locais (moshi-hook servers), (opcional) Azure DevOps builds + Dokploy deploys com "avisa quando terminar".
6. **Fase 5 — Celular**: ligar PhoneLink + endpoint de comando; responder agente do iPhone.
7. **Fase 6 — Polish**: alertas, sons, preferências, assinar local (Scripts/sign-local.sh), doc, memória.

## ⚠️ Riscos, Dependências e Pontos em Aberto
- **Responder pelo notch** é o maior trabalho (notch é read-only por design — precisa painel ativável + canal de escrita). Maior risco de escopo.
- **Protocol mismatch do herdr**: ao atualizar binário herdr, todo comando socket falha silenciosamente — o app precisa detectar (comparar protocol client vs server em `herdr status`).
- **App Sandbox OFF** (codenotch já é assim — precisa ler arquivos de outros apps). OK.
- **Segurança do canal de resposta** (notch/celular escrevendo no terminal) — tailnet-only, confiança local.
- **Upstream muda**: manter fork rebaseável (mudanças isoladas em arquivos novos, wiring mínimo no AppDelegate).
- Falta `xcodegen` (instalar). macOS 26.6 OK. gh logado como CristhyanKo OK.

## 🔄 Histórico de Mudanças do Plano
- 15/09/2026 — criado. Escopo definido pelo Cristhyan: COMPLETO (agentes + responder + infra + celular), repo = fork próprio BSN.

## 🔗 Relacionado
- Estudo: 3 subagentes (codenotch técnico, ecossistema, modus operandi) — resultados no HISTORY.
- Memórias: reference_herdr_setup_ghostty, reference_herdr_nome_sidebar_display, project_herdr_remote_cloud_mobile, reference_collie_mobile_herdr, user_perfil_cristhyan, feedback_ui_lib_icones_tela_cheia.
- Fontes de dados/ações: `herdr api snapshot`, `moshi-hook context/servers`, `~/.claude/sessions/*.json`, `~/.claude/raycast/index.json`.
- Upstream: github.com/vinzdg/codenotch (MIT).
