# Histórico - 15/09/2026 03:00 - Modo lateral VERTICAL funcional

## ✅ Feito (Fase 2 completa — modo lateral igual foto #138)
- SideColumnView.swift criada: coluna vertical de agentes (mascote + anel de estado por AgentStatus), fundo escuro com cantos arredondados só do lado interno (SideColumnShape), colada na borda direita.
- Ligada no NotchPanelView.body: if notchEdge=="right" → AnyView(SideColumnView), senão horizontalBody (comportamento original preservado).
- import CodeIslandCore (AgentStatus/SessionSnapshot vivem la). MascotAgentStatus = AgentStatus (typealias) → MascotView aceita session.status direto.
- ForEach sobre (id,snap) de appState.sessions (SessionSnapshot NAO e Identifiable — usar a chave do dict como id).
- panelSize(right) e SideColumnView com MESMOS valores (item 40, spacing 12, vPad 12, width 68) → caixa ABRAÇA os itens (nao estica). activeSessionCountForLayout() = appState.sessions.count.
- INTERATIVIDADE: SideColumnItem tem onHover (destaque + scale + tooltip do nome p/ esquerda) e onTapGesture → TerminalActivator.activate(session:sessionId:) (pula pro pane herdr). contentShape(Circle).
- VALIDADO AO VIVO: 3 agentes empilhados, anel verde=ativo, cinza+Zz=idle, caixa compacta colada na direita. = foto #138.

## ⚠️ A validar/refinar
- Hover/clique: adicionados no codigo, mas nao testei o clique fisico (screenshot nao move mouse). Cristhyan deve testar: passar mouse (destaca+nome) e clicar (pula pra sessao).
- Descompasso: herdr tem 12 agentes mas CodeIsland ve só os que dispararam hook (3 no teste). Normal — CodeIsland depende de hook por sessao. Se quiser TODOS do herdr sempre, o HerdrActivityMonitor (que fiz no fork codenotch) traria isso; avaliar portar depois.
- Expandir a coluna no hover (mostrar detalhes/tooltip maior) — hoje só mostra o nome. Refinar depois.

## ▶️ Próximo passo IMEDIATO
Cristhyan testar hover+clique no modo lateral. Depois: retheming (pixel-art→BSN) OU features de sistema (Now Playing via boring.notch).

## Arquivos tocados
Sources/CodeIsland/SideColumnView.swift (novo), NotchPanelView.swift (early-return), PanelWindowController.swift (panelSize+panelFrame+activeSessionCountForLayout), Settings.swift (notchEdge), SettingsView.swift (Picker Posição). Tudo builda (swift build exit 0).

## ADENDO 03:25 — Features de sistema (Bateria + Volume) FEITAS
- SystemBatteryManager.swift (IOKit IOPowerSources, API publica): level/charging/plugged/minutesRemaining, notif nativa + timer 60s.
- SystemVolumeManager.swift (CoreAudio + AudioToolbox p/ kAudioHardwareServiceDeviceProperty_VirtualMainVolume): volume/mute, listener + setVolume.
- SystemFooter na SideColumnView: bateria (icone+% real) + volume (icone por nivel), abaixo dos agentes, com divisor. panelSize(right) somou footerH.
- VALIDADO AO VIVO: rodape mostrou "80%" (bateria real do Mac) + icone de volume. = super-notch (agentes + sistema Alcove) tomando forma.
- Managers usam APIs PUBLICAS (zero private, zero dep nova). Now Playing (private/framework) fica pro proximo bloco.

## ADENDO 03:45 — Now Playing + Hide from capture FEITOS
- NowPlayingManager.swift: roda /usr/bin/perl + mediaremote-adapter (BSD, empacotado em Resources/mediaremote-adapter/) em modo 'stream', parseia JSON diff (titulo/artista/album/playing/artworkData base64). VALIDADO ao vivo: adapter retornou musica real (Vivaldi/YouTube) com artwork no macOS 26 — a tecnica sobrevive ao bloqueio 15.4+.
- Package.swift ja tinha resources:[.copy("Resources")] → adapter empacota automatico. Bundle.module acha o .pl e .framework.
- SystemFooter mostra capa da musica + selo play/pause quando algo toca.
- HIDE FROM CAPTURE: applySharingType() → no modo lateral (right) panel.sharingType=.none (some de screenshots/gravacoes, igual Alcove); no topo .readOnly. Aplica na criacao e no rebuild (troca de modo). VALIDADO: screenshot no modo lateral NAO capturou a coluna.
- NOTICE.md atualizado (adapter BSD + bateria/volume codigo proprio).

## Estado: SUPER-NOTCH FUNCIONAL
Agentes(herdr) + Now Playing + Bateria + Volume numa coluna, modo topo OU lateral configuravel, lateral some de prints. Tudo builda (swift build exit 0), APIs publicas exceto Now Playing (adapter BSD).

## ADENDO 04:00 — Widgets de infra BSN FEITOS
- BSNInfraManager.swift: le Tailscale (peers online via `tailscale status`), VPN GCOM (interface ppp0), workstation sync (mtime ~/.publish-workstation.log). So status, NUNCA segredos. Timer 45s, leituras nonisolated fora do main.
- SystemFooter: linha de infra (icone Tailscale verde/cinza + VPN lock). Validado fontes reais: 11 peers tailscale, VPN down (esperado).
- GOTCHA util: como o modo lateral agora some de prints (.none), nao da mais pra capturar a coluna via screenshot — o que PROVA que o hide funciona. Validacao passa a ser visual (Cristhyan) + build + fontes.

## SUPER-NOTCH — features entregues nesta sessao
Agentes(herdr, hover/click) + Now Playing(adapter BSD) + Bateria(IOKit) + Volume(CoreAudio) + Infra BSN(Tailscale/VPN/sync) numa coluna lateral OU topo, lateral some de prints. Tudo builda.

## ADENDO 04:20 — Lateral REUSA conteudo nativo (RESOLVE clique/perguntas)
- PROBLEMA: minha SideColumnView simplista reinventou (mal) o que o topo ja faz — clique nao funcionava, sem perguntas/aprovacoes, sem ultima acao/thinking.
- SOLUCAO (decisao Cristhyan: "tudo do topo deve funcionar no lateral"): a coluna lateral EXPANDIDA agora reusa o SessionListView NATIVO (tornei ele nao-private) + abas ALL/STA/CLI + contador + waveform. Colapsada = mascotes+anel+icones sistema.
- Com isso o lateral HERDA automaticamente: clique (pula herdr), QuestionBar (responder pergunta com opcoes/SKIP), ApprovalBar (aprovar/negar), ultima acao, thinking, tempo, badge herdr, branch, #id.
- Footer de sistema reescrito com row(icon+label): Bateria 80% / Volume 68% / Tailscale 10 online / VPN GCOM desligada — alinhado quando expande.
- Hide from capture virou CONFIG (SettingsKey.hideFromCapture, toggle nas Settings; default OFF=aparece em prints).
- VALIDADO AO VIVO (img #145): lateral expandido = identico ao topo + sistema/infra. Colapsado limpo.

## ADENDO 04:30 — Compacto + cantos concavos (estilo notch)
- itemSize 40→26, collapsedW 72→46: coluna colapsada bem mais discreta (pedido Cristhyan).
- SideColumnShape: adicionados cantos CONCAVOS (addQuadCurve) na juncao topo-direita e base-direita = efeito notch do MacBook (img ref #147). notchCurve=14. Corpo (esquerda) segue arredondado convexo.
- VALIDADO (img compact): coluna estreita + cantos concavos suaves onde funde com a borda.

## ADENDO 04:40 — Cantos concavos v2 + remove VPN GCOM
- SideColumnShape virou InsettableShape com curvas concavas GRANDES (notchCurve=26) conectando o corpo arredondado (radius 22) a borda direita, topo e base — igual ref #147. padding vertical 30(colapsado)/20(exp) p/ respiro das curvas.
- Removido widget VPN GCOM (pedido Cristhyan — nao serve). Footer agora: NowPlaying/Bateria/Volume/Tailscale.
- VALIDADO (img concavo2): cantos concavos visiveis no topo e base, coluna compacta.

## ADENDO 04:50 — Cantos "S" corrigidos (igual ref #151)
- ERRO anterior: pus curvas nos cantos DIREITOS e a barra desgrudou da borda.
- CORRETO (img #151): borda direita 100% COLADA e reta; curva em "S" concava nos cantos do lado ESQUERDO (topo e base) — a barra faz barriga e curva pra dentro fundindo com o fundo. SideColumnShape refeito com addCurve (control1 na direita, control2 na esquerda).
- VALIDADO (img s3): identico a ref #151. Colado na borda + S concavo.

## ADENDO 05:00 — Fluidez maior + AirPods adiado (crash)
- notchCurve 26→48 (curva "S" mais ampla/fluida, pedido Cristhyan). padding vertical 44(colapsado)/26(exp) p/ acomodar. VALIDADO (img fluido3): curva suave se fundindo com o fundo, colado na borda.
- AirPods: criado AirPodsManager (IOBluetooth private, BatteryPercentLeft/Right/Case). CRASHOU: value(forKey:) de private API lança NSUnknownKeyException (Obj-C, nao capturavel pelo Swift). NEUTRALIZADO: intValue retorna nil + start desativado. REATIVAR so com ObjCExceptionCatcher (helper Obj-C no target). Feature adiada com seguranca — nao crasha.
- Confirmado: sem o KVC do AirPods, app roda ESTAVEL.

## ADENDO 05:10 — Controles Now Playing
- NowPlayingManager: metodos togglePlayPause/nextTrack/previousTrack via adapter `send` (MRCommand: toggle=2, next=4, prev=5). Funciona no 15.4+ (so a LEITURA quebrou, comandos OK).
- SideColumnView: clique na capa da musica = toca/pausa; selo mostra a acao (pause se tocando); modo expandido tem setas << >>. row() ganhou parametro trailing (@ViewBuilder).
- App roda estavel.

## RESUMO SUPER-NOTCH (features nesta sessao)
Modo topo (island) + lateral direita (S concavo fluido colado na borda, compacto, some de prints via config). Agentes herdr (cards ricos nativos: nome/branch/id/tempo/herdr/ultima acao/thinking + clique + perguntas/aprovacoes) reusando SessionListView. Abas ALL/STA/CLI + contador. Sistema: NowPlaying(adapter BSD + controles + waveform) / Bateria / Volume / Tailscale. AirPods adiado (KVC crash). Tudo GPL-3.0, builda.

## ADENDO 05:20 — Curva menor no expandido
- PROBLEMA (img #153): no expandido (340px largo) a curva "S" de 48 ficava deformada/grande nos cantos esquerdos.
- FIX: SideColumnShape recebe notchCurve por estado — colapsado=48 (fluido), expandido=12 (cantos esquerdos so levemente curvos). radius=22 nos dois. padding expandido ajustado (18v/16h).
- Shape limpo (removido codigo duplicado das tentativas). Precisa Cristhyan validar o expandido ao vivo (hover).

## ADENDO 05:30 — Expandido = retangulo arredondado limpo
- PROBLEMA (#154): a curva "S" no expandido dava bico/reentrancia feia nos cantos esquerdos.
- FIX: background condicional — EXPANDIDO usa RoundedRectangle(cornerRadius:22,.continuous) LIMPO (4 cantos normais); COLAPSADO usa SideColumnShape (curva "S" fluida notchCurve 48). Melhor dos dois: fluido discreto colapsado, limpo/legivel expandido.

## ADENDO 05:40 — Shape S revertido (limita curva)
- Tentativa de S na direita deu "meia-lua" (recorte grande, #157) — descartada.
- Revertido pro SideColumnShape que gerou o #156 bom (S concavo na esquerda), com n limitado a height/3 (antes height/2.2) p/ nao deformar no expandido. Mesmo shape nos 2 estados.
- 🚫 NAO repetir: S na borda direita com addQuadCurve (vira meia-lua); notchCurve grande em barra alta (deforma).
- Pendente: Cristhyan validar expandido ao vivo (hover) e mandar print p/ ajuste fino do valor da curva.

## ADENDO 05:45 — Shape FINAL aprovado (img #158)
- SideColumnShape com S concavo na esquerda + n=min(notchCurve, height/3) ficou bom nos DOIS estados: colapsado fluido/discreto (#156), expandido suave sem deformar (#158). APROVADO pelo Cristhyan.
- Formato do lateral: FECHADO.

## ADENDO 06:00 — Fix: icone da barra de menu SEMPRE visivel (fechar o app)
- BUG herdado: StatusItemController.syncVisibility so mostrava o icone se hideWhenNoSession estava LIGADO (default off) → usuario nunca via como fechar/abrir settings.
- FIX: syncVisibility sempre chama showStatusItem(). Icone (pilula com 2 olhos) na barra de menu com menu Configuracoes + Sair.
- 3 formas de fechar: (1) icone barra de menu → Sair, (2) botao power vermelho no notch expandido (modo topo), (3) pkill CodeIsland.
