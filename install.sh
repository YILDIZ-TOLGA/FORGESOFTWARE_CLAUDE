#!/usr/bin/env bash
# FORGESOFTWARE_CLAUDE — installeur 1 clic (Linux / macOS)
# Installe pour Claude Code : caveman, ponytail, graphify, Agent Skills (Anthropic), OmniRoute.
#
# Usage :
#   ./install.sh                         # tout installer
#   ./install.sh --skip omniroute        # ignorer un ou plusieurs outils (séparés par des virgules)
#   ./install.sh --skip caveman,graphify
#
# Le script est relançable sans risque : ce qui est déjà installé est simplement mis à jour.

set -u

SKIP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --skip) SKIP="${2:-}"; shift 2 ;;
    --skip=*) SKIP="${1#--skip=}"; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "Option inconnue : $1"; exit 1 ;;
  esac
done

if [ -t 1 ]; then G=$'\e[32m'; R=$'\e[31m'; Y=$'\e[33m'; B=$'\e[1m'; N=$'\e[0m'; else G=; R=; Y=; B=; N=; fi
say()  { printf '\n%s==> %s%s\n' "$B" "$*" "$N"; }
ok()   { printf '%s  ✔ %s%s\n' "$G" "$*" "$N"; }
warn() { printf '%s  ! %s%s\n' "$Y" "$*" "$N"; }
err()  { printf '%s  ✘ %s%s\n' "$R" "$*" "$N"; }

RESULTS=()
record() { RESULTS+=("$1|$2"); }   # nom|OK / ÉCHEC / IGNORÉ ...
skipped() { case ",$SKIP," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }
has() { command -v "$1" >/dev/null 2>&1; }

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ---------------------------------------------------------------- prérequis
say "Vérification des prérequis"

has git || { err "git est requis (https://git-scm.com/downloads)"; exit 1; }
ok "git $(git --version | awk '{print $3}')"

if ! has claude; then
  warn "Claude Code absent — installation officielle"
  curl -fsSL https://claude.ai/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
fi
has claude || { err "Impossible d'installer Claude Code. Voir https://code.claude.com/docs"; exit 1; }
ok "Claude Code $(claude --version 2>/dev/null | awk '{print $1}')"

if ! has uv; then
  warn "uv absent (nécessaire pour graphify) — installation"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
has uv && ok "uv $(uv --version | awk '{print $2}')" || warn "uv indisponible : graphify sera ignoré"

# OmniRoute exige Node >=22.22.2 <23 ou >=24 <27
NODE_OK=0
if has node; then
  v=$(node -p 'process.versions.node')
  IFS=. read -r MA MI PA <<<"$v"
  if { [ "$MA" -eq 22 ] && { [ "$MI" -gt 22 ] || { [ "$MI" -eq 22 ] && [ "$PA" -ge 2 ]; }; }; } ||
     { [ "$MA" -ge 24 ] && [ "$MA" -lt 27 ]; }; then
    NODE_OK=1; ok "Node.js $v"
  else
    warn "Node.js $v trop ancien pour OmniRoute (Node 24 LTS recommandé : https://nodejs.org)"
  fi
else
  warn "Node.js absent : OmniRoute sera ignoré (installez Node 24 LTS : https://nodejs.org)"
fi

# ---------------------------------------------------------------- plugins Claude Code
# install_plugin <nom affiché> <dépôt marketplace> <plugin@marketplace>...
install_plugin() {
  local label="$1" repo="$2"; shift 2
  if ! claude plugin marketplace add "$repo" >/dev/null 2>&1; then
    err "$label : ajout de la marketplace $repo impossible"; record "$label" "ÉCHEC"; return
  fi
  claude plugin marketplace update "${1#*@}" >/dev/null 2>&1 || true   # rafraîchit si déjà présente
  local p
  for p in "$@"; do
    if claude plugin install "$p" >/dev/null 2>&1; then
      claude plugin update "$p" >/dev/null 2>&1 || true   # déjà installé : mise à jour
      ok "$p"
    else err "$p"; record "$label" "ÉCHEC"; return; fi
  done
  record "$label" "OK"
}

if skipped caveman; then record caveman IGNORÉ; else
  say "caveman — réponses ultra-concises (moins de tokens en sortie)"
  install_plugin caveman JuliusBrussee/caveman caveman@caveman
fi

if skipped ponytail; then record ponytail IGNORÉ; else
  say "ponytail — moins de code, réutilisation de l'existant"
  install_plugin ponytail DietrichGebert/ponytail ponytail@ponytail
fi

if skipped skills; then record "agent-skills" IGNORÉ; else
  say "Agent Skills officiels Anthropic (PDF, Word, Excel, PowerPoint, skill-creator...)"
  install_plugin "agent-skills" anthropics/skills \
    document-skills@anthropic-agent-skills example-skills@anthropic-agent-skills
fi

# ---------------------------------------------------------------- graphify
if skipped graphify; then record graphify IGNORÉ
elif ! has uv; then record graphify "ÉCHEC (uv manquant)"
else
  say "graphify — graphe de connaissances du projet"
  if uv tool install --upgrade 'graphifyy[mcp]' >/dev/null 2>&1 && graphify install >/dev/null 2>&1; then
    ok "$(graphify --version 2>/dev/null | tail -1)"; record graphify OK
  else
    err "graphify : échec (relancez : uv tool install graphifyy && graphify install)"; record graphify ÉCHEC
  fi
fi

# ---------------------------------------------------------------- OmniRoute
if skipped omniroute; then record omniroute IGNORÉ
elif [ "$NODE_OK" -ne 1 ]; then record omniroute "IGNORÉ (Node 24 requis)"
else
  say "OmniRoute — passerelle IA multi-fournisseurs (localhost:20128)"
  LOG=$(mktemp)
  # sans sudo d'abord ; avec sudo seulement si le dossier global npm est protégé
  if npm install -g omniroute@latest >"$LOG" 2>&1 ||
     { has sudo && grep -q EACCES "$LOG" && sudo npm install -g omniroute@latest >"$LOG" 2>&1; }; then
    ok "$(npm ls -g omniroute --depth=0 2>/dev/null | grep -o "omniroute@[0-9.]*")"; record omniroute OK
  else
    tail -5 "$LOG"; err "omniroute : échec de npm install -g omniroute"; record omniroute ÉCHEC
  fi
  rm -f "$LOG"
fi

# ---------------------------------------------------------------- résumé
say "Résumé"
FAIL=0
for r in "${RESULTS[@]}"; do
  name=${r%%|*}; st=${r#*|}
  case "$st" in OK) ok "$name";; ÉCHEC*) err "$name — $st"; FAIL=1;; *) warn "$name — $st";; esac
done

cat <<EOF

${B}Prochaines étapes${N}
  1. Redémarrez Claude Code (ou ouvrez un nouveau terminal) puis lancez : claude
  2. Dans un projet : /graphify .        → construit le graphe du code
  3. Commandes utiles : /caveman lite|full|ultra · /ponytail · /ponytail-review
  4. OmniRoute (optionnel) : omniroute   → tableau de bord http://localhost:20128
     puis : omniroute launch              → Claude Code via OmniRoute
  Guide complet : GUIDE-INSTALLATION.md
EOF
exit $FAIL
