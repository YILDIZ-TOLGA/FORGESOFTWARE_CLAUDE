# Guide d'installation complet — Optimiser Claude Code

Ce guide installe et configure 5 outils qui rendent Claude Code **moins cher, plus rapide et plus précis** :

| Outil | Rôle | Gain principal | Type |
|---|---|---|---|
| **caveman** | Claude répond en style télégraphique (sans politesses ni blabla) | ~65 % de tokens de sortie en moins | Plugin Claude Code |
| **ponytail** | Claude réutilise l'existant (stdlib, code du projet, fonctions natives) au lieu d'écrire du code inutile | ~54 % de code en moins, ~20 % moins cher | Plugin Claude Code |
| **graphify** | Transforme le projet en graphe de connaissances que Claude interroge au lieu de relire tous les fichiers | jusqu'à 70× moins de tokens par question sur un gros projet | Skill + CLI Python |
| **Agent Skills** | Compétences officielles Anthropic : PDF, Word, Excel, PowerPoint, création de skills, design… | Nouvelles capacités | Plugins Claude Code |
| **OmniRoute** | Passerelle IA locale : un seul point d'accès vers des centaines de fournisseurs/modèles, avec bascule automatique | Continuer à coder quand une limite est atteinte, modèles moins chers | Serveur Node.js (optionnel) |

> 🖥️ Vous utilisez l'**application Claude Desktop** ? Voir [GUIDE-DESKTOP.md](GUIDE-DESKTOP.md).
>
> Les quatre premiers s'ajoutent à Claude Code sans rien changer à votre abonnement.
> OmniRoute est **optionnel** : il ne s'active que si vous lancez Claude Code via `omniroute launch`.

---

## Sommaire

1. [Prérequis](#1-prérequis)
2. [Installation en 1 clic](#2-installation-en-1-clic)
3. [Installation manuelle, outil par outil](#3-installation-manuelle-outil-par-outil)
   - [caveman](#31-caveman)
   - [ponytail](#32-ponytail)
   - [graphify](#33-graphify)
   - [Agent Skills](#34-agent-skills)
   - [OmniRoute](#35-omniroute)
4. [Vérifier l'installation](#4-vérifier-linstallation)
5. [Méthode de travail recommandée](#5-méthode-de-travail-recommandée)
6. [Dépannage](#6-dépannage)
7. [Mise à jour et désinstallation](#7-mise-à-jour-et-désinstallation)
8. [Sécurité et bonnes pratiques](#8-sécurité-et-bonnes-pratiques)

---

## 1. Prérequis

| Logiciel | Version | Pour quoi | Installation |
|---|---|---|---|
| **Claude Code** | récente | tout | `curl -fsSL https://claude.ai/install.sh \| bash` (Windows : `irm https://claude.ai/install.ps1 \| iex`) |
| **Git** | toute | marketplaces de plugins | https://git-scm.com/downloads |
| **uv** (gère Python tout seul) | toute | graphify | `curl -LsSf https://astral.sh/uv/install.sh \| sh` (Windows : `irm https://astral.sh/uv/install.ps1 \| iex`) |
| **Node.js** | **24 LTS** (ou ≥ 22.22.2) | OmniRoute | https://nodejs.org |

L'installeur 1 clic installe automatiquement Claude Code et uv s'ils manquent. Sous Windows, il installe aussi Git et Node.js via `winget`.

Un compte Claude (Pro, Max, Team ou clé API) est nécessaire pour utiliser Claude Code : lancez `claude` une première fois pour vous connecter.

---

## 2. Installation en 1 clic

Téléchargez ce dépôt (bouton **Code → Download ZIP** sur GitHub, puis décompressez), ou :

```bash
git clone https://github.com/YILDIZ-TOLGA/FORGESOFTWARE_CLAUDE.git
cd FORGESOFTWARE_CLAUDE
```

| Système | Action |
|---|---|
| **Windows** | Double-cliquez sur **`INSTALLER-WINDOWS.bat`** |
| **macOS** | Double-cliquez sur **`INSTALLER-MAC.command`** (si macOS bloque : clic droit → Ouvrir) |
| **Linux / macOS (terminal)** | `./install.sh` |

L'installeur :

1. vérifie / installe les prérequis ;
2. installe caveman, ponytail, les Agent Skills Anthropic, graphify et OmniRoute ;
3. affiche un résumé ✔ / ✘ pour chaque outil.

Il est **relançable sans risque** : relancez-le pour tout mettre à jour.

**Ignorer certains outils :**

```bash
./install.sh --skip omniroute                 # Linux / macOS
./install.sh --skip omniroute,graphify
```

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -Skip omniroute    # Windows
```

Noms acceptés : `caveman`, `ponytail`, `skills`, `graphify`, `omniroute`.

Ensuite : **fermez et rouvrez votre terminal**, puis lancez `claude`.

---

## 3. Installation manuelle, outil par outil

Les plugins Claude Code s'installent soit depuis le terminal (`claude plugin …`), soit **dans** Claude Code avec la commande `/plugin …`. Les deux méthodes sont équivalentes.

### 3.1 caveman

Dépôt : https://github.com/JuliusBrussee/caveman

**Installation (plugin, démarre automatiquement à chaque session) :**

```bash
claude plugin marketplace add JuliusBrussee/caveman
claude plugin install caveman@caveman
```

Alternative multi-agents (Claude Code, Cursor, Codex, Gemini…) : `npx skills add JuliusBrussee/caveman -g`

**Utilisation :**

| Commande | Effet |
|---|---|
| `/caveman` | Active le mode (niveaux : `lite`, `full` par défaut, `ultra`) |
| `/caveman status` / `/caveman off` | Affiche le mode / désactive (ou dites « stop caveman ») |
| `/caveman-commit` | Message de commit en une ligne (Conventional Commits) |
| `/caveman-review` | Revue de code, un problème par ligne |
| `/caveman-compress <fichier>` | Compresse un fichier mémoire (ex. `CLAUDE.md`), avec sauvegarde |
| `/caveman-stats` | Consommation réelle de tokens de la session |
| `/caveman-help` | Toutes les commandes |

> **Conseil :** `lite` pour du travail où vous voulez encore des explications, `full` au quotidien, `ultra` pour les longues sessions d'exécution.

**Option avancée — proxy caveman** (réduit aussi ce que Claude *lit* : logs, sorties de tests, JSON…) :

```bash
npm install -g @caveman-ai/cli && caveman setup --install
caveman claude        # lance Claude Code à travers le proxy
```

Le CLI envoie des statistiques d'usage anonymes par défaut ; désactivez-les avec `caveman telemetry off` ou `DO_NOT_TRACK=1`.

### 3.2 ponytail

Dépôt : https://github.com/DietrichGebert/ponytail

**Installation :**

```bash
claude plugin marketplace add DietrichGebert/ponytail
claude plugin install ponytail@ponytail
```

(ou dans Claude Code : `/plugin marketplace add DietrichGebert/ponytail` puis `/plugin install ponytail@ponytail`)

Avant d'écrire du code, Claude s'arrête au premier échelon qui suffit :
*Est-ce nécessaire ? → Existe déjà dans le projet ? → Bibliothèque standard ? → Fonction native ? → Dépendance déjà installée ? → Une ligne ? → Sinon, le strict minimum.*

**Utilisation :**

| Commande | Effet |
|---|---|
| `/ponytail [lite\|full\|ultra\|off]` | Règle l'intensité ou désactive |
| `/ponytail-review` | Revue du diff actuel : liste de ce qu'on peut supprimer |
| `/ponytail-audit` | Audit de tout le dépôt contre la sur-ingénierie |
| `/ponytail-debt` | Rassemble les raccourcis `ponytail:` laissés « pour plus tard » |
| `/ponytail-help` | Aide |

> Installez ponytail uniquement depuis `DietrichGebert/ponytail` (GitHub) ou `@dietrichgebert/ponytail` (npm) : des copies malveillantes circulent.

### 3.3 graphify

Site : https://graphify.com — Dépôt : https://github.com/Graphify-Labs/graphify

**Installation :**

```bash
uv tool install graphifyy      # attention : deux « y » — c'est le paquet officiel
graphify install               # enregistre le skill dans Claude Code
```

(Alternative : `pipx install graphifyy`. Évitez `pip install` simple sur Mac/Windows.)

**Utilisation, dans Claude Code :**

```
/graphify .                         # construit le graphe du dossier courant
/graphify . --update                # ne retraite que les fichiers modifiés
/graphify query "comment l'auth est reliée à la base ?"
/graphify path "UserService" "Database"
/graphify explain "PaymentController"
```

Résultat dans `graphify-out/` :

- `graph.html` — graphe interactif à ouvrir dans le navigateur ;
- `GRAPH_REPORT.md` — concepts clés, connexions surprenantes, questions suggérées ;
- `graph.json` — graphe complet, réutilisé par Claude sans relire les fichiers.

**Options utiles :**

```bash
graphify hook install               # reconstruit le graphe à chaque commit git
graphify install --project --strict # dans un projet : force Claude à consulter le graphe d'abord
```

Le code est analysé **localement** (tree-sitter, sans appel réseau) ; seuls les documents/PDF/images passent par le modèle de votre session Claude. Ajoutez `graphify-out/` à votre `.gitignore` si vous ne voulez pas le versionner.

### 3.4 Agent Skills

Les **Agent Skills** sont des dossiers contenant un fichier `SKILL.md` : des instructions et scripts que Claude charge automatiquement quand la tâche s'y prête.

**a) Skills officiels Anthropic** (installés par l'installeur 1 clic) — https://github.com/anthropics/skills

```bash
claude plugin marketplace add anthropics/skills
claude plugin install document-skills@anthropic-agent-skills   # PDF, Word, Excel, PowerPoint
claude plugin install example-skills@anthropic-agent-skills    # skill-creator, design, MCP builder, tests web…
```

Utilisation : demandez simplement, par ex. *« Utilise le skill PDF pour extraire les champs du formulaire de facture.pdf »*.

**b) Le gestionnaire universel `npx skills`** — https://skills.sh (nécessite Node ≥ 22.20)

```bash
npx skills add vercel-labs/agent-skills -g -a claude-code       # installer un pack (choix interactif)
npx skills add vercel-labs/agent-skills --list                  # voir les skills d'un dépôt
npx skills add <dépôt> --skill <nom> -g -a claude-code -y       # un skill précis, sans question
```

`-g` = pour tous vos projets ; sans `-g` = seulement le projet courant (dossier `.claude/skills/`).

**c) Créer vos propres skills** : avec `example-skills` installé, demandez à Claude *« crée un skill pour … »* (skill-creator). Un skill personnel se place dans `~/.claude/skills/<nom>/SKILL.md`, un skill de projet dans `.claude/skills/<nom>/SKILL.md`.

### 3.5 OmniRoute

Dépôt : https://github.com/diegosouzapw/OmniRoute — **Node.js 24 LTS requis.**

OmniRoute est une passerelle locale (`http://localhost:20128`) qui expose une API unique vers des centaines de fournisseurs (Anthropic, OpenAI, Gemini, DeepSeek, Kimi, GLM, modèles locaux…), avec bascule automatique quand un fournisseur atteint sa limite, et compression des requêtes.

**Installation :**

```bash
npm install -g omniroute
```

(ou Docker : `docker run -d --name omniroute --restart unless-stopped -p 127.0.0.1:20128:20128 -v omniroute-data:/app/data diegosouzapw/omniroute:latest`)

**Premier démarrage — définissez un mot de passe** (sinon le mot de passe du tableau de bord est `CHANGEME`) :

```bash
INITIAL_PASSWORD='VotreMotDePasseSolide' omniroute          # Linux / macOS
```

```powershell
$env:INITIAL_PASSWORD='VotreMotDePasseSolide'; omniroute     # Windows
```

Puis :

1. Ouvrez **http://localhost:20128** → **Providers** : connectez vos fournisseurs (clés API ou comptes).
2. **Endpoints** : copiez votre clé d'accès OmniRoute.
3. Lancez Claude Code à travers OmniRoute :

```bash
omniroute launch                    # configure tout automatiquement et lance claude
omniroute setup-claude              # optionnel : crée un profil par modèle
omniroute launch --profile <nom>    # lance Claude Code avec un modèle précis
```

**Configuration manuelle** (si vous préférez `claude` directement) — dans `~/.claude/settings.json` :

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:20128",
    "ANTHROPIC_AUTH_TOKEN": "<votre clé OmniRoute>",
    "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "1"
  }
}
```

> ⚠️ Avec ce bloc, **toutes** vos sessions Claude Code passent par OmniRoute (le serveur doit tourner). Retirez-le pour revenir au fonctionnement normal. `omniroute launch` est plus sûr : il n'affecte que la session lancée.

**Commandes utiles :**

| Commande | Effet |
|---|---|
| `omniroute` | Démarre le serveur + tableau de bord |
| `omniroute serve --daemon` | Démarre en arrière-plan |
| `omniroute autostart enable` | Démarrage automatique au boot (Linux) |
| `omniroute doctor` | Diagnostic (ports, fournisseurs, dépendances) |
| `omniroute-reset-password` | Réinitialise le mot de passe du tableau de bord |

**Optionnel — piloter OmniRoute depuis Claude (MCP)**, serveur démarré :

```bash
claude mcp add --transport http omniroute http://localhost:20128/api/mcp/stream
```

---

## 4. Vérifier l'installation

```bash
claude plugin list          # doit afficher caveman, ponytail, document-skills, example-skills
graphify --version
omniroute --version         # si installé
```

Dans Claude Code, tapez `/` : les commandes `/caveman`, `/ponytail`, `/graphify` doivent apparaître. Lancez `/caveman-stats` après quelques échanges pour mesurer le gain.

---

## 5. Méthode de travail recommandée

1. **Nouveau projet ou projet inconnu** → `/graphify .` puis lisez `GRAPH_REPORT.md`. Claude s'appuie ensuite sur le graphe au lieu d'explorer fichier par fichier.
2. **Au quotidien** → caveman (`full`) + ponytail (`full`) actifs : réponses courtes, code minimal.
3. **Avant un commit** → `/ponytail-review` (ce qu'on peut supprimer) puis `/caveman-commit`.
4. **Après de gros changements** → `/graphify . --update` (ou `graphify hook install` pour l'automatiser).
5. **Documents** (PDF, Excel, Word, PowerPoint) → demandez-le simplement, les Agent Skills prennent le relais.
6. **Limite d'abonnement atteinte ou tâche simple et répétitive** → `omniroute launch` pour basculer sur un autre modèle.
7. **Besoin d'explications détaillées** (apprentissage, revue d'architecture) → `/caveman lite` ou `/caveman off` temporairement.

---

## 6. Dépannage

| Problème | Solution |
|---|---|
| `claude: command not found` après installation | Fermez et rouvrez le terminal. Vérifiez que `~/.local/bin` (Windows : `%USERPROFILE%\.local\bin`) est dans le PATH. |
| `graphify: command not found` | `uv tool update-shell` puis rouvrez le terminal. |
| `/graphify` n'apparaît pas | Relancez `graphify install`, puis redémarrez Claude Code. |
| Les commandes `/caveman` ou `/ponytail` n'apparaissent pas | `claude plugin list` ; si absent, relancez l'installeur. Redémarrez Claude Code. |
| Échec « marketplace add » | Vérifiez Git et l'accès à github.com (proxy d'entreprise ?). |
| OmniRoute ignoré par l'installeur | Installez Node.js 24 LTS puis relancez l'installeur. |
| `EACCES` avec `npm install -g` (Linux/macOS) | Utilisez un gestionnaire de versions Node (nvm, fnm) plutôt que `sudo`. |
| Port 20128 déjà utilisé | `omniroute serve --port 20129` (et adaptez `ANTHROPIC_BASE_URL`). |
| Windows : « l'exécution de scripts est désactivée » | Utilisez `INSTALLER-WINDOWS.bat` (il contourne la restriction pour ce script uniquement). |
| macOS : « impossible d'ouvrir l'application » | Clic droit sur `INSTALLER-MAC.command` → Ouvrir, ou lancez `./install.sh` dans le Terminal. |

---

## 7. Mise à jour et désinstallation

**Tout mettre à jour :** relancez l'installeur.

**Désinstaller :**

```bash
claude plugin uninstall caveman@caveman
claude plugin uninstall ponytail@ponytail
claude plugin uninstall document-skills@anthropic-agent-skills
claude plugin uninstall example-skills@anthropic-agent-skills
graphify uninstall && uv tool uninstall graphifyy
npm uninstall -g omniroute
```

Pensez à retirer le bloc `env` OmniRoute de `~/.claude/settings.json` si vous l'aviez ajouté.

---

## 8. Sécurité et bonnes pratiques

- **Sources officielles uniquement** : les plugins s'exécutent avec vos droits. Les dépôts utilisés ici sont `JuliusBrussee/caveman`, `DietrichGebert/ponytail`, `Graphify-Labs/graphify` (paquet PyPI `graphifyy`), `anthropics/skills` et `diegosouzapw/OmniRoute`.
- **OmniRoute** : changez le mot de passe par défaut, laissez-le écouter sur `127.0.0.1` uniquement, ne partagez jamais votre clé d'accès. Il voit passer tout votre code et vos prompts.
- **Conditions d'utilisation** : OmniRoute propose de réutiliser des abonnements (Claude, ChatGPT…) et des offres gratuites de tiers. Utiliser un abonnement Claude Pro/Max à travers un outil tiers peut être contraire aux conditions d'Anthropic et entraîner la suspension du compte. Privilégiez vos **clés API** officielles et lisez les conditions de chaque fournisseur.
- **Télémétrie** : le skill caveman n'envoie rien ; seul le CLI/proxy caveman envoie des statistiques (désactivables : `caveman telemetry off`).
- **graphify** : le code reste local ; les documents/images sont envoyés au modèle de votre session Claude comme n'importe quel fichier lu par Claude.

---

### Sources

- caveman — https://github.com/JuliusBrussee/caveman
- ponytail — https://github.com/DietrichGebert/ponytail
- graphify — https://github.com/Graphify-Labs/graphify · https://pypi.org/project/graphifyy/
- Agent Skills — https://github.com/anthropics/skills · https://github.com/vercel-labs/skills
- OmniRoute — https://github.com/diegosouzapw/OmniRoute · [Configuration Claude Code](https://github.com/diegosouzapw/OmniRoute/blob/main/docs/guides/CLAUDE-CODE-CONFIGURATION.md)
- Claude Code — https://code.claude.com/docs
