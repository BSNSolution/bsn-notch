#!/usr/bin/env bash
# Gera o instalador .dmg no padrão BSN (aprovado pelo Cristhyan em 05/11/2026): janela com fundo ilustrado,
# ícone do app à esquerda, seta, atalho para Aplicativos à direita, fundo escondido.
#
# Uso: dmg-bsn.sh --app "Caminho/Nome.app" --fundo fundo.png --out "Saida.dmg" [--volume "Nome"]
#   --fundo: arte 3:2 (1536x1024) gerada pelo gpt-image-2 com o prompt da skill instalador-mac.
#            Seta desenhada a ~62% da altura, área inferior direita vazia para os ícones.
# Requer: macOS, uv (uvx). Usa dmgbuild 1.6.7 (fixado).
set -euo pipefail

app="" fundo="" out="" volume=""
while [ $# -gt 0 ]; do
  case "$1" in
    --app) app="$2"; shift 2 ;;
    --fundo) fundo="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    --volume) volume="$2"; shift 2 ;;
    *) echo "dmg-bsn: opção desconhecida: $1" >&2; exit 2 ;;
  esac
done
[ -d "$app" ] || { echo "dmg-bsn: --app precisa ser um .app existente" >&2; exit 2; }
[ -f "$fundo" ] || { echo "dmg-bsn: --fundo não encontrado" >&2; exit 2; }
[ -n "$out" ] || { echo "dmg-bsn: falta --out" >&2; exit 2; }
nome_app="$(basename "$app")"
[ -n "$volume" ] || volume="${nome_app%.app}"
if ! command -v uvx >/dev/null; then
  # Sem uv: DMG simples (app + Aplicativos), para não travar a versão. Instale o uv para o visual BSN.
  echo "dmg-bsn: AVISO: sem uv (brew install uv); gerando DMG sem o visual BSN" >&2
  palco="$(mktemp -d)"; trap 'rm -rf "$palco"' EXIT
  cp -R "$app" "$palco/" && ln -s /Applications "$palco/Applications"
  mkdir -p "$(dirname "$out")"; rm -f "$out"
  hdiutil create -volname "$volume" -srcfolder "$palco" -fs HFS+ -format UDZO -ov "$out" >/dev/null
  echo "dmg-bsn: $out"; exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# Fundo Retina: 660x440 + 1320x880 no mesmo TIFF.
sips -z 880 1320 "$fundo" --out "$tmp/bg@2x.png" >/dev/null
sips -z 440 660 "$fundo" --out "$tmp/bg.png" >/dev/null
tiffutil -cathidpicheck "$tmp/bg.png" "$tmp/bg@2x.png" -out "$tmp/bg.tiff" >/dev/null 2>&1

cat > "$tmp/settings.py" <<'PY'
import os
app = defines["app"]
name = os.path.basename(app)
format = "UDZO"
files = [app]
symlinks = {"Applications": "/Applications"}
background = defines["bg"]
# 530 de altura: no macOS 26+ o Finder mostra barra de ferramentas e de caminho mesmo pedindo para esconder;
# a área útil fica ~440, do tamanho do fundo.
window_rect = ((200, 120), (660, 530))
icon_size = 112
text_size = 13
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
# Fundo e .DS_Store fora da área visível: somem até para quem mostra arquivos ocultos.
icon_locations = {name: (318, 290), "Applications": (588, 290), ".background.tiff": (1500, 1500), ".DS_Store": (1600, 1500)}
PY

mkdir -p "$(dirname "$out")"
rm -f "$out"
uvx --quiet --from dmgbuild==1.6.7 dmgbuild -s "$tmp/settings.py" -D "app=$app" -D "bg=$tmp/bg.tiff" "$volume" "$out" 2>&1 \
  | grep -v "deprecated" || true
[ -f "$out" ] || { echo "dmg-bsn: falhou ao gerar $out" >&2; exit 1; }
echo "dmg-bsn: $out"
