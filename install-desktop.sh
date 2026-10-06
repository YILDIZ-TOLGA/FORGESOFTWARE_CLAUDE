#!/usr/bin/env bash
# FORGESOFTWARE_CLAUDE — installeur 1 clic, version Claude Desktop (macOS / Linux Debian-Ubuntu)
#
# 1. Installe l'application Claude Desktop si elle manque.
# 2. Lance install.sh : caveman, ponytail, Agent Skills, graphify, OmniRoute
#    (l'onglet « Code » de Claude Desktop partage la configuration ~/.claude).
# 3. Configure claude_desktop_config.json (onglets Chat + Code) :
#    - un serveur MCP graphify par projet (--projet), pour interroger le graphe depuis le Chat ;
#    - le serveur MCP OmniRoute (--omniroute-mcp, optionnel).
#
# Usage :
#   ./install-desktop.sh
#   ./install-desktop.sh --projet ~/code/mon-app --projet ~/code/autre
#   ./install-desktop.sh --omniroute-mcp --skip omniroute   # --skip est transmis à install.sh
#   ./install-desktop.sh --sans-app                         # ne pas installer l'application

set -u
cd "$(dirname "$0")"

PROJETS=(); SKIP=""; OMNI_MCP=0; APP=1
while [ $# -gt 0 ]; do
  case "$1" in
    --projet) PROJETS+=("$2"); shift 2 ;;
    --skip) SKIP="$2"; shift 2 ;;
    --omniroute-mcp) OMNI_MCP=1; shift ;;
    --sans-app) APP=0; shift ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "Option inconnue : $1"; exit 1 ;;
  esac
done

if [ -t 1 ]; then G=$'\e[32m'; R=$'\e[31m'; Y=$'\e[33m'; B=$'\e[1m'; N=$'\e[0m'; else G=; R=; Y=; B=; N=; fi
say()  { printf '\n%s==> %s%s\n' "$B" "$*" "$N"; }
ok()   { printf '%s  ✔ %s%s\n' "$G" "$*" "$N"; }
warn() { printf '%s  ! %s%s\n' "$Y" "$*" "$N"; }
err()  { printf '%s  ✘ %s%s\n' "$R" "$*" "$N"; }
has()  { command -v "$1" >/dev/null 2>&1; }
export PATH="$HOME/.local/bin:$PATH"

OS=$(uname -s)
case "$OS" in
  Darwin) CFG_DIR="$HOME/Library/Application Support/Claude" ;;
  Linux)  CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Claude" ;;
  *) err "Système non pris en charge ($OS). Sous Windows : INSTALLER-DESKTOP-WINDOWS.bat"; exit 1 ;;
esac
CFG="$CFG_DIR/claude_desktop_config.json"

# ---------------------------------------------------------------- 1. application
say "Application Claude Desktop"
app_present() {
  if [ "$OS" = Darwin ]; then [ -d "/Applications/Claude.app" ] || [ -d "$HOME/Applications/Claude.app" ]
  else has claude-desktop; fi
}
if app_present; then ok "déjà installée"
elif [ "$APP" -eq 0 ]; then warn "installation de l'application ignorée (--sans-app)"
elif [ "$OS" = Darwin ]; then
  if has brew; then brew install --cask claude
  else
    TMP=$(mktemp -d)
    curl -fL -o "$TMP/Claude.dmg" "https://claude.ai/api/desktop/darwin/universal/dmg/latest/redirect" &&
      MNT=$(hdiutil attach -nobrowse "$TMP/Claude.dmg" | awk -F'\t' '/\/Volumes\//{print $NF}') &&
      cp -R "$MNT/Claude.app" /Applications/ && hdiutil detach "$MNT" >/dev/null
    rm -rf "$TMP"
  fi
  app_present && ok "installée" || err "échec — téléchargez-la sur https://claude.com/download"
elif has apt-get; then
  sudo curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc https://downloads.claude.ai/claude-desktop/key.asc &&
  echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" |
    sudo tee /etc/apt/sources.list.d/claude-desktop.list >/dev/null &&
  sudo apt-get update -qq && sudo apt-get install -y claude-desktop
  app_present && ok "installée" || err "échec — voir https://code.claude.com/docs/en/desktop-linux"
else
  warn "Claude Desktop n'existe que pour Ubuntu/Debian sous Linux : utilisez Claude Code en terminal (install.sh)"
fi

# ---------------------------------------------------------------- 2. outils (onglet Code)
say "Outils Claude Code (partagés avec l'onglet Code de Claude Desktop)"
./install.sh ${SKIP:+--skip "$SKIP"}
BASE_RC=$?

# ---------------------------------------------------------------- 3. serveurs MCP (Chat + Code)
say "Serveurs MCP pour Claude Desktop ($CFG)"

if [ ${#PROJETS[@]} -eq 0 ] && [ -t 0 ] && has graphify; then
  echo "  Dossier d'un projet à connecter à graphify (glissez-le ici, ou Entrée pour passer) :"
  read -r -p "  > " P
  # nettoie un chemin glissé-déposé : espaces finaux, guillemets, « \ », ~
  P=$(printf '%s' "$P" | sed -e 's/[[:space:]]*$//' -e "s/^['\"]//" -e "s/['\"]$//" -e 's/\\ / /g')
  P=${P/#\~/$HOME}
  [ -n "$P" ] && PROJETS+=("$P")
fi

SERVERS="{}"
add_server() { SERVERS=$(printf '%s' "$SERVERS" | uv run --no-project -q python -c '
import json, sys
d = json.load(sys.stdin); d[sys.argv[1]] = {"command": sys.argv[2], "args": sys.argv[3:]}
print(json.dumps(d))' "$@"); }

for P in "${PROJETS[@]}"; do
  P=$(cd "$P" 2>/dev/null && pwd) || { err "dossier introuvable : $P"; continue; }
  if ! has graphify-mcp; then err "graphify n'est pas installé"; break; fi
  echo "  Construction du graphe de $P (analyse locale du code, sans IA)..."
  if (cd "$P" && graphify update . >/dev/null 2>&1) && [ -f "$P/graphify-out/graph.json" ]; then
    NAME="graphify-$(basename "$P" | tr -c 'A-Za-z0-9_\n-' '-')"
    add_server "$NAME" "$(command -v graphify-mcp)" "$P/graphify-out/graph.json"
    ok "$NAME"
  else err "graphify : échec sur $P"; fi
done

if [ "$OMNI_MCP" -eq 1 ]; then
  # chemin réel du script (le lien « omniroute » pointe vers .../omniroute/bin/omniroute.mjs)
  OMNI_BIN=$(command -v omniroute 2>/dev/null)
  if [ -n "$OMNI_BIN" ] && [ -L "$OMNI_BIN" ]; then
    L=$(readlink "$OMNI_BIN"); case "$L" in /*) ;; *) L="$(dirname "$OMNI_BIN")/$L" ;; esac
    OMNI="$(cd "$(dirname "$L")" && pwd)/$(basename "$L")"
  else
    OMNI="$(npm root -g 2>/dev/null)/omniroute/bin/omniroute.mjs"
  fi
  if [ -f "$OMNI" ] && has node; then add_server omniroute "$(command -v node)" "$OMNI" --mcp; ok "omniroute"
  else err "OmniRoute non installé : serveur MCP ignoré"; fi
fi

if [ "$SERVERS" = "{}" ]; then
  warn "aucun serveur MCP ajouté"
else
  mkdir -p "$CFG_DIR"
  [ -f "$CFG" ] && cp "$CFG" "$CFG.sauvegarde-$(date +%Y%m%d-%H%M%S)" && ok "sauvegarde de l'ancienne configuration"
  # fusion : on garde tout ce qui existe, on ajoute/remplace seulement nos serveurs
  printf '%s' "$SERVERS" | uv run --no-project -q python -c '
import json, os, sys
path, new = sys.argv[1], json.load(sys.stdin)
cfg = json.load(open(path, encoding="utf-8")) if os.path.exists(path) and os.path.getsize(path) else {}
cfg.setdefault("mcpServers", {}).update(new)
json.dump(cfg, open(path, "w", encoding="utf-8"), indent=2, ensure_ascii=False)' "$CFG" &&
    ok "configuration écrite" || err "écriture de $CFG impossible"
fi

cat <<EOF

${B}À faire dans Claude Desktop (2 minutes)${N}
  1. Quittez complètement Claude Desktop puis rouvrez-le (pour charger les serveurs MCP).
  2. Paramètres (Settings) → Capacités (Capabilities) : activez « Exécution de code et création de fichiers »
     (les skills PDF / Word / Excel / PowerPoint d'Anthropic y sont déjà inclus).
  3. Pour le Chat et Cowork — Personnaliser (Customize) → Plugins → Ajouter (Add)
     → Ajouter une marketplace → « Ajouter depuis un dépôt », puis entrez un par un :
        JuliusBrussee/caveman
        DietrichGebert/ponytail
     et installez les plugins caveman et ponytail.
  4. Onglet Code : tout est déjà installé (caveman, ponytail, graphify, skills).
  Guide complet : GUIDE-DESKTOP.md
EOF
exit $BASE_RC
