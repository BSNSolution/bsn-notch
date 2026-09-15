# Nota - Formato da herdr API (pro HerdrActivityMonitor)

**Data/Hora**: 15/09/2026 01:50
**Tipo**: Descoberta/Gotcha
**Contexto**: Fase 1 do BSN Notch — implementar HerdrActivityMonitor

## 📌 O que
Comando pra ler agentes: **`herdr agent list`** (retorna JSON, mais direto que `api snapshot`).
Estrutura: `{"id":"cli:agent:list","result":{"agents":[ {...} ]}}`.
Campos por agente:
- `agent_status`: **"idle" | "working" | "blocked" | "done" | "unknown"** → mapear pra AgentSession.State (idle→idle, working→busy, blocked→waiting, done→success)
- `display_agent`: o /nome dado (ex "TRIGO", "Trigo - Gameficacao") → AgentSession.name
- `pane_id` (ex "w1JK:p7") → id do agente (pra `herdr agent prompt/send-keys/focus`)
- `workspace_id` (ex "w1JK") → agregação por projeto
- `title`, `terminal_title`, `cwd`, `foreground_cwd`, `focused`

## Detecção de protocol mismatch (gotcha herdr)
`herdr status` retorna client.protocol e server.protocol + `compatible: yes|no`. Se `compatible: no` (ou protocolos diferentes), TODO comando socket falha silenciosamente → o monitor deve degradar pra status visível ("herdr incompatível"), não fingir 0 agentes. Hoje: protocol 19 ambos, compatible yes.

## 🤔 Por que
`agent list` é o feed principal do monitor. Sem checar compatible, um update do herdr deixaria o notch mostrando "nenhum agente" silenciosamente (mentira).

## ✅ Como aplicar
- Monitor roda `herdr agent list` em polling (~2s) + parse do result.agents.
- Antes, checar `herdr status` compatible; se no → estado degradado.
- Binário: `~/.local/bin/herdr` (PATH pode não ter no launchd — usar caminho absoluto no Process()).
- Responder: `herdr agent prompt <pane_id> "texto"` | `herdr agent send-keys <pane_id> <keys>` | `herdr agent focus <pane_id>`.

## 🔗 Relacionado
- TASKS Fase 1/Fase 3, reference_herdr_nome_sidebar_display (protocol mismatch), inventário do ecossistema.
