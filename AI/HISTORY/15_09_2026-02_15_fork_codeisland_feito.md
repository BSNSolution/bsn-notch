# Histórico - 15/09/2026 02:15 - Fork CodeIsland feito

## ✅ O Que Foi Feito
- Estudo completo dos 4 apps (codenotch, CodeIsland, codex-island + Alcove em andamento).
- Comparativo dos 3 de agentes (1 subagente cada): CodeIsland vence (fit 8.5/10).
- **Base validada AO VIVO**: rodei o CodeIsland original, detectou os agentes herdr reais (Session/backend/videos-tutorial) + uso de LLM. Merge de hooks preservou moshi/supacode/tmux. Restaurei settings.json 100% (backup) e limpei ~/.codeisland.
- **Fork trocado**: deletado BSNSolution/bsn-notch (era fork do codenotch) → recriado como fork LIMPO do wxtsky/CodeIsland v1.0.33. Clonado em ~/Work/BSN Solution/Repositorios/bsn-notch, AI/ restaurado, upstream=wxtsky/CodeIsland.
- Clone antigo em ~/Work/BSN Solution/Repositorios/bsn-notch-OLD-codenotch (remover depois com OK).

## 🔧 Decisões
- Base = CodeIsland (herdr first-class, responder/aprovar via socket, iPhone+Watch ação remota).
- Escopo AMPLIADO pelo Cristhyan: incorporar TAMBÉM as features do Alcove (Now Playing/mídia, bateria, AirPods, foco, calendário) = "super-notch" (agentes + sistema). Estudo técnico do Alcove/APIs em andamento (subagente af8c3bf).
- 2 modos de visualização configuráveis (topo/island + lateral direita) — usuário escolhe.
- Retheming: remover pixel-art → estilo BSN/ícones lib (nunca emoji).

## ▶️ Próximo passo IMEDIATO
Aguardar estudo do Alcove (viabilidade das features de sistema — atenção: Now Playing usa MediaRemote PRIVATE, restrito no macOS 15.4+). Depois: definir NOME do produto (não é só "notch de agentes" agora) + rebranding + build da base no fork.

## 🚫 Abordagens descartadas
- codenotch como base (read-only, sem herdr) e codex-island (só uso LLM). Ver comparativo em PLANS v2.
- HerdrActivityMonitor.swift que escrevi no fork codenotch: descartado (CodeIsland já tem herdr melhor); serve de referência.
