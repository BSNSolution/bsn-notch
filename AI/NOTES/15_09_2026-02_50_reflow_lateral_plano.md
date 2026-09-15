# Nota - Plano do reflow lateral (coluna vertical, foto #138)

**Data/Hora**: 15/09/2026 02:50
**Tipo**: Decisão/Plano técnico
**Contexto**: Fase 2 — modo lateral direita

## 📌 O que já está FEITO e funcionando
- Setting notchEdge ("top"|"right") + UI Picker "Posição" + observer BSNNotchEdgeChanged → reposiciona ao vivo.
- panelFrame(right): cola na borda direita (x=maxX-width, y abaixo do menu bar). panelSize(right): estreito (76pt) + alto (coluna). Buildou e testado ao vivo: o painel VAI pra direita e fica estreito+alto.
- FALTA: o CONTEUDO interno ainda é horizontal (NotchPanelView 3372 linhas, pensado p/ topo) → fica espremido. Precisa empilhar vertical (anéis um sob o outro, tooltip p/ esquerda) = igual foto #138.

## 🧭 Decisão (Cristhyan): PORTAR a view lateral do codenotch
O codenotch tem arquitetura de layout AGNOSTICA DE BORDA, pronta p/ coluna vertical:
- Sources/Notch/NotchPlacement.swift (point/rect along+across por edge: top/right/left/bottom)
- NotchEdge.swift, SideNotchShape.swift (a forma com cantos internos), NotchGeometry.swift, NotchLayout.swift, NotchFleet.swift, NotchHostingView.swift
- codenotch é MIT → compativel com nosso GPL, pode portar.

## ⚠️ Gotcha da portabilidade (IMPORTANTE)
A view do codenotch desenha a partir do modelo DELE (UsageProvider/uso de LLM). O CodeIsland usa SessionSnapshot/agentes. Portar = LIGAR a view lateral do codenotch ao modelo do CodeIsland (adaptar camada de apresentação a outra fonte). NÃO é copiar 1 arquivo — é integração (algumas horas de Swift). 

## ✅ Como aplicar (passos do reflow lateral)
1. Copiar Sources/Notch/{NotchPlacement,NotchEdge,SideNotchShape,NotchGeometry} do codenotch p/ o fork (namespace BSN p/ nao colidir).
2. Criar uma SideColumnView (SwiftUI) que, dado [SessionSnapshot] do CodeIsland, desenha a coluna vertical (item = anel/mascote + %/estado, empilhados via NotchPlacement.edge=.right).
3. No NotchPanelView.body (ou no PanelWindowController que monta a hosting view), quando notchEdge=="right" → usar SideColumnView em vez do layout horizontal.
4. Tooltip/expansão sai p/ ESQUERDA (across inward).
5. SideNotchShape: cantos arredondados só do lado interno (grudado na borda).

## 🔗 Relacionado
- HISTORY 02_40, PLANS v2. Repos: scratchpad/codenotch (fonte da view lateral, MIT).
