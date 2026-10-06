# FORGESOFTWARE_CLAUDE

Kit d'optimisation pour **Claude Code** — installation en 1 clic de :

- **caveman** — réponses ultra-concises (~65 % de tokens en moins en sortie)
- **ponytail** — moins de code, réutilisation de l'existant
- **graphify** — graphe de connaissances du projet (beaucoup moins de tokens pour explorer le code)
- **Agent Skills** — skills officiels Anthropic (PDF, Word, Excel, PowerPoint, skill-creator…)
- **OmniRoute** — passerelle IA multi-fournisseurs avec bascule automatique (optionnel)

## Installation en 1 clic — Claude Code (terminal)

| Système | Action |
|---|---|
| Windows | Double-clic sur `INSTALLER-WINDOWS.bat` |
| macOS | Double-clic sur `INSTALLER-MAC.command` |
| Linux / terminal | `./install.sh` |

Options : `./install.sh --skip omniroute,graphify` (Windows : `install.ps1 -Skip omniroute`).

Ensuite, rouvrez votre terminal et lancez `claude`, puis `/graphify .` dans votre projet.

## Installation en 1 clic — Claude Desktop (application)

| Système | Action |
|---|---|
| Windows | Double-clic sur `INSTALLER-DESKTOP-WINDOWS.bat` |
| macOS | Double-clic sur `INSTALLER-DESKTOP-MAC.command` |
| Linux Ubuntu/Debian | `./install-desktop.sh` |

Installe l'application si besoin, tout l'outillage pour l'onglet **Code**, et branche graphify au **Chat** (serveur MCP). Il reste ensuite 2 minutes de clics dans l'application pour le Chat et Cowork.

📖 **Guide Claude Desktop** : [GUIDE-DESKTOP.md](GUIDE-DESKTOP.md)

📖 **Guide complet** (prérequis, installation manuelle, utilisation, dépannage, sécurité) : [GUIDE-INSTALLATION.md](GUIDE-INSTALLATION.md)
