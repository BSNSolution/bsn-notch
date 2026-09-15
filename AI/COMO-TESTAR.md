# Como testar o BSN Notch (build atual)

Build pronto em `.build/debug/CodeIsland`. macOS 14+.

## Rodar
```sh
cd ~/Work/BSN\ Solution/Repositorios/bsn-notch
./.build/debug/CodeIsland
```
O app é menu-bar/notch (sem janela). Aparece no topo (modo island) por padrão.

## Alternar TOPO ↔ LATERAL DIREITA
- Pelas **Settings** do app (ícone na barra) → seção General → **Posição: Topo (island) / Lateral direita**.
- OU por linha de comando (com o app fechado):
  ```sh
  defaults write -g notchEdge right    # lateral direita
  defaults write -g notchEdge top      # topo (island)
  ```
  (depois reabra o app)

## O que testar
1. **Agentes (herdr):** a coluna mostra seus agentes com mascote + anel colorido
   (verde=rodando, cinza=idle, laranja=aguardando aprovação, amarelo=pergunta).
   - **Hover** num agente: destaca + mostra o nome à esquerda.
   - **Clique** num agente: pula pro pane dele no herdr.
2. **Rodapé de sistema (features tipo Alcove):**
   - **Now Playing:** toque uma música/vídeo (Spotify, YouTube, Apple Music) → aparece a capa + play/pause.
   - **Bateria:** ícone + % real.
   - **Volume:** ícone por nível.
   - **Infra BSN:** ícone Tailscale (verde se online) + VPN GCOM (cadeado verde se conectada).
3. **Modo lateral some de prints:** com o app no modo lateral, tire um screenshot (Cmd+Shift+4) — a coluna NÃO deve aparecer na imagem. No modo topo, aparece normalmente.

## Reverter o ambiente depois do teste (importante)
O app injeta um hook no `~/.claude/settings.json` (por merge, preserva os seus) e cria `~/.codeisland/`. Para limpar:
```sh
pkill -f CodeIsland
defaults delete -g notchEdge 2>/dev/null
python3 - <<'PY'
import json, os
p=os.path.expanduser('~/.claude/settings.json'); d=json.load(open(p)); h=d.get('hooks',{})
for ev in list(h.keys()):
    if isinstance(h[ev],list):
        h[ev]=[b for b in h[ev] if 'codeisland' not in json.dumps(b)]
        if not h[ev]: del h[ev]
json.dump(d,open(p,'w'),indent=2,ensure_ascii=False)
print('limpo')
PY
rm -rf ~/.codeisland
```
(No rebranding profundo — fase futura — isso vira `~/.bsnnotch` e não mexe no seu settings.)

## Feedback pra me passar
- Layout lateral: tamanho, espaçamento, posição — ok?
- Hover/clique funcionam?
- Now Playing aparece quando toca música?
- Algo cortando/estranho?
