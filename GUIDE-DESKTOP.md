# Guide Claude Desktop — Optimiser l'application Claude

Version **application de bureau** du kit (macOS, Windows, Linux Ubuntu/Debian en bêta).
Pour Claude Code en terminal, voir [GUIDE-INSTALLATION.md](GUIDE-INSTALLATION.md).

---

## 1. Comprendre les 3 onglets de Claude Desktop

| Onglet | À quoi il sert | D'où viennent ses outils |
|---|---|---|
| **Chat** | Conversations | Votre compte claude.ai (**Personnaliser**, synchronisé) + serveurs MCP de `claude_desktop_config.json` |
| **Cowork** | Tâches longues et autonomes | Votre compte claude.ai (**Personnaliser**, synchronisé) |
| **Code** | Développement (même moteur que Claude Code) | Le dossier `~/.claude` de l'ordinateur (comme le terminal) + `claude_desktop_config.json` + votre compte claude.ai |

Conséquence : l'onglet **Code** est configuré **automatiquement** par l'installeur. Pour **Chat** et **Cowork**, il reste deux minutes de clics dans l'application, parce que leurs plugins sont liés à votre compte.

### Ce que chaque outil apporte, selon l'onglet

| Outil | Chat | Cowork | Code |
|---|---|---|---|
| **caveman** (réponses concises) | ✅ plugin (à ajouter dans Personnaliser) | ✅ plugin | ✅ automatique |
| **ponytail** (moins de code) | ✅ plugin (à ajouter dans Personnaliser) | ✅ plugin | ✅ automatique |
| **Agent Skills** (PDF, Word, Excel, PowerPoint…) | ✅ intégrés (à activer dans Paramètres) | ✅ intégrés | ✅ automatique |
| **graphify** (graphe du projet) | ✅ via serveur MCP (automatique avec `--projet`) | — | ✅ automatique (`/graphify .`) |
| **OmniRoute** (passerelle multi-modèles) | ⚙️ pilotage via MCP (optionnel) | — | ✅ `omniroute launch` dans le terminal intégré |

---

## 2. Prérequis

- Un **abonnement payant** Claude (Pro, Max, Team ou Enterprise) : les plugins et les skills l'exigent.
- **macOS**, **Windows** (x64 ou ARM64) ou **Linux Ubuntu 22.04+ / Debian 12+** (bêta).
- Le reste (Claude Code, uv, Git, Node.js) est installé par l'installeur, comme dans la version terminal.

---

## 3. Installation en 1 clic

Téléchargez ce dépôt (**Code → Download ZIP** sur GitHub, puis décompressez), puis :

| Système | Action |
|---|---|
| **Windows** | Double-clic sur **`INSTALLER-DESKTOP-WINDOWS.bat`** |
| **macOS** | Double-clic sur **`INSTALLER-DESKTOP-MAC.command`** (si macOS bloque : clic droit → Ouvrir) |
| **Linux (Ubuntu/Debian)** | `./install-desktop.sh` |

L'installeur :

1. **installe l'application Claude Desktop** si elle manque (Homebrew ou image officielle sur macOS, installeur officiel sur Windows, dépôt apt officiel d'Anthropic sur Linux) ;
2. **installe caveman, ponytail, les Agent Skills, graphify et OmniRoute** pour l'onglet Code (il appelle `install.sh` / `install.ps1`) ;
3. **vous demande un dossier de projet** (glissez-déposez-le dans la fenêtre, ou Entrée pour passer). Il construit alors le graphe graphify de ce projet, en local et sans IA, puis le branche au Chat via un serveur MCP ;
4. **met à jour `claude_desktop_config.json`** : il sauvegarde d'abord l'ancienne version, puis ajoute ses serveurs sans toucher à vos réglages existants.

### Options (terminal)

```bash
./install-desktop.sh --projet ~/code/mon-app --projet ~/code/autre   # plusieurs projets graphify
./install-desktop.sh --omniroute-mcp                                  # ajoute le serveur MCP OmniRoute
./install-desktop.sh --skip omniroute                                 # ignorer un outil
./install-desktop.sh --sans-app                                       # ne pas installer l'application
```

```powershell
powershell -ExecutionPolicy Bypass -File install-desktop.ps1 -Projet C:\code\mon-app,C:\code\autre -OmnirouteMcp
powershell -ExecutionPolicy Bypass -File install-desktop.ps1 -Skip omniroute -SansApp
```

L'installeur est **relançable** : relancez-le pour tout mettre à jour ou pour ajouter un projet.

---

## 4. Les 2 minutes de clics dans l'application

Les plugins de Chat et Cowork sont liés à votre compte : ils ne peuvent pas être installés par un script.

**Étape 1 — redémarrer l'application.** Quittez complètement Claude Desktop (macOS : `Cmd+Q` ; Windows : icône près de l'horloge → Quitter), puis rouvrez-le. C'est indispensable pour charger les serveurs MCP.

**Étape 2 — activer les skills.** **Paramètres (Settings) → Capacités (Capabilities)** :

- activez **Exécution de code et création de fichiers** ;
- vérifiez que les skills Anthropic (PDF, Word, Excel, PowerPoint…) sont activés.

**Étape 3 — ajouter caveman et ponytail au Chat et à Cowork.** Dans la barre latérale : **Personnaliser (Customize) → Plugins → Ajouter (Add) → Ajouter une marketplace → Ajouter depuis un dépôt**. Entrez :

```
JuliusBrussee/caveman
```

Recommencez avec :

```
DietrichGebert/ponytail
```

Ouvrez ensuite chaque marketplace et installez les plugins **caveman** et **ponytail**. Vous pouvez aussi ajouter `anthropics/skills` pour avoir `skill-creator` et les autres skills d'exemple.

> Dans le Chat, les *hooks* des plugins ne s'exécutent pas (seulement dans Cowork et Code). caveman et ponytail ne démarrent donc pas tout seuls : tapez **`/caveman`** ou **`/ponytail`** en début de conversation.

---

## 5. Utilisation, onglet par onglet

### Onglet Chat

| Besoin | Comment |
|---|---|
| Réponses courtes | `/caveman` (ou `/caveman lite`), `/caveman off` pour arrêter |
| Revue « moins de code » d'un extrait collé | `/ponytail-review` |
| Questions sur un projet | Demandez naturellement : *« Avec graphify-mon-app, quels modules dépendent de l'authentification ? »*. Claude utilise les outils du serveur MCP (`query_graph`, `get_node`, `get_neighbors`, `shortest_path`, `god_nodes`…) |
| Documents | *« Crée un tableau Excel à partir de… »*, *« Résume ce PDF »* : les skills Anthropic prennent le relais |

Pour voir les serveurs MCP actifs : bouton **+** sous la zone de saisie → **Connecteurs**, ou **Paramètres → Développeur**.

### Onglet Cowork

caveman, ponytail et les skills fonctionnent comme dans le Chat, et les hooks y sont actifs (caveman démarre automatiquement). Sous Linux, Cowork exige la virtualisation KVM (voir le dépannage).

### Onglet Code

C'est exactement Claude Code. Tout ce qui est décrit dans [GUIDE-INSTALLATION.md](GUIDE-INSTALLATION.md) s'applique :

- `/graphify .` pour construire ou mettre à jour le graphe du projet ouvert ;
- `/caveman`, `/ponytail-review`, `/caveman-commit`… ;
- bouton **+ → Plugins** pour voir, activer ou désactiver les plugins ;
- OmniRoute : dans le terminal intégré, `omniroute` puis `omniroute launch`.

> Si une commande apparaît **en double** dans l'onglet Code (une fois installée localement, une fois synchronisée depuis votre compte), désactivez l'une des deux dans **+ → Plugins → Gérer les plugins**.

---

## 6. graphify dans le Chat : garder le graphe à jour

Le graphe est une photo du code au moment de sa construction. Pour le rafraîchir :

```bash
cd ~/code/mon-app && graphify update .          # rapide, local, sans IA
```

Vous pouvez aussi l'automatiser à chaque commit :

```bash
cd ~/code/mon-app && graphify hook install
```

Inutile de redémarrer Claude Desktop pour une simple mise à jour du graphe. En revanche, pour **ajouter un nouveau projet**, relancez l'installeur avec `--projet` (ou `-Projet`), puis redémarrez l'application.

---

## 7. OmniRoute avec Claude Desktop

- **Chat et Cowork** utilisent toujours les modèles Claude de votre abonnement : l'application ne permet pas de les rediriger vers une autre passerelle (sauf configuration entreprise).
- **Serveur MCP OmniRoute** (`--omniroute-mcp`) : permet de piloter OmniRoute depuis le Chat (fournisseurs, coûts, quotas, combos…). Il ajoute **plus de 100 outils**, ce qui alourdit chaque conversation. Ne l'activez que si vous gérez OmniRoute activement.
- **Onglet Code** : lancez `omniroute`, puis `omniroute launch` depuis le terminal intégré. Pour que **toutes** les sessions de l'onglet Code passent par OmniRoute, ajoutez le bloc `env` décrit dans [GUIDE-INSTALLATION.md §3.5](GUIDE-INSTALLATION.md#35-omniroute) à `~/.claude/settings.json`. Le serveur OmniRoute doit alors tourner en permanence (`omniroute serve --daemon`).

Les avertissements de sécurité du guide principal s'appliquent : changez le mot de passe `CHANGEME`, et n'utilisez pas votre abonnement Claude à travers un outil tiers (risque de suspension). Privilégiez des clés API.

---

## 8. Emplacements utiles

| | macOS | Windows | Linux |
|---|---|---|---|
| Configuration MCP | `~/Library/Application Support/Claude/claude_desktop_config.json` | `%APPDATA%\Claude\claude_desktop_config.json` (version Store : `%LOCALAPPDATA%\Packages\Claude_*\LocalCache\Roaming\Claude\`) | `~/.config/Claude/claude_desktop_config.json` |
| Journaux MCP | `~/Library/Logs/Claude/` | `%APPDATA%\Claude\logs\` | `~/.config/Claude/logs/` |
| Plugins / skills de l'onglet Code | `~/.claude/` | `%USERPROFILE%\.claude\` | `~/.claude/` |

Pour ouvrir la configuration depuis l'application : **Paramètres → Développeur → Modifier la configuration**.

---

## 9. Dépannage

| Problème | Solution |
|---|---|
| Le serveur `graphify-…` n'apparaît pas | Quittez **complètement** l'application et rouvrez-la. Vérifiez **Paramètres → Développeur**. |
| Serveur MCP « en échec » | Consultez `mcp-server-graphify-….log` dans le dossier des journaux. Le plus souvent, le graphe a été supprimé ou déplacé : relancez `graphify update .` dans le projet. |
| Configuration cassée après une modification manuelle | Une sauvegarde `claude_desktop_config.json.sauvegarde-AAAAMMJJ-HHMMSS` est à côté : renommez-la en `claude_desktop_config.json`. |
| « Ajouter une marketplace » absent | Fonction réservée aux abonnements payants. Sur Team/Enterprise, l'administrateur peut l'avoir désactivée. |
| Les skills ne fonctionnent pas dans le Chat | Activez **Exécution de code et création de fichiers** dans Paramètres → Capacités. |
| Linux : « Cowork requires hardware virtualization (KVM) » | Activez la virtualisation dans le BIOS, puis `sudo usermod -aG kvm $USER`, déconnectez-vous et reconnectez-vous. |
| Linux : l'application refuse de démarrer en root | Lancez-la avec votre utilisateur normal. |
| macOS : « impossible d'ouvrir l'application » | Clic droit sur `INSTALLER-DESKTOP-MAC.command` → Ouvrir. |

Pour les problèmes propres à chaque outil (PATH, Node.js, ports…), voir la section dépannage de [GUIDE-INSTALLATION.md](GUIDE-INSTALLATION.md#6-dépannage).

---

## 10. Désinstallation

1. **Chat / Cowork** : **Personnaliser → Plugins**, désinstallez caveman et ponytail, puis supprimez les marketplaces.
2. **Serveurs MCP** : **Paramètres → Développeur → Modifier la configuration**, supprimez les entrées `graphify-…` et `omniroute` de `mcpServers`, puis redémarrez l'application.
3. **Onglet Code et outils** : voir [GUIDE-INSTALLATION.md §7](GUIDE-INSTALLATION.md#7-mise-à-jour-et-désinstallation).
4. **Application** : comme n'importe quelle application (Linux : `sudo apt remove claude-desktop`).

---

### Sources

- Claude Desktop, onglet Code : https://code.claude.com/docs/en/desktop
- Claude Desktop sous Linux : https://code.claude.com/docs/en/desktop-linux
- Plugins dans Claude (Chat, Cowork, Code) : https://support.claude.com/en/articles/13837440-use-plugins-in-cowork
- Skills dans Claude : https://support.claude.com/en/articles/12512180-using-skills-in-claude
- graphify (serveur MCP) : https://github.com/Graphify-Labs/graphify
- OmniRoute (MCP, Claude Code) : https://github.com/diegosouzapw/OmniRoute
