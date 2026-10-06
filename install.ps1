# FORGESOFTWARE_CLAUDE — installeur 1 clic (Windows)
# Installe pour Claude Code : caveman, ponytail, graphify, Agent Skills (Anthropic), OmniRoute.
#
# Usage (le plus simple : double-cliquer sur INSTALLER-WINDOWS.bat) :
#   powershell -ExecutionPolicy Bypass -File install.ps1
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Skip omniroute,graphify
#
# Relançable sans risque : ce qui est déjà installé est simplement mis à jour.

param([string[]]$Skip = @())

$ErrorActionPreference = 'Continue'
$Results = [ordered]@{}

function Say($m)  { Write-Host "`n==> $m" -ForegroundColor White }
function Ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!]  $m" -ForegroundColor Yellow }
function Err($m)  { Write-Host "  [X]  $m" -ForegroundColor Red }
function Has($c)  { [bool](Get-Command $c -ErrorAction SilentlyContinue) }
function Skipped($n) { ($Skip -join ',').Split(',') -contains $n }
function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
              [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
              "$env:USERPROFILE\.local\bin"
}
Refresh-Path

# ---------------------------------------------------------------- prérequis
Say 'Vérification des prérequis'

if (-not (Has git)) {
  if (Has winget) {
    Warn 'Git absent — installation via winget'
    winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
    Refresh-Path
  }
  if (-not (Has git)) { Err 'Git est requis : https://git-scm.com/download/win'; Read-Host 'Entrée pour quitter'; exit 1 }
}
Ok (git --version)

if (-not (Has claude)) {
  Warn 'Claude Code absent — installation officielle'
  Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
  Refresh-Path
}
if (-not (Has claude)) { Err "Impossible d'installer Claude Code : https://code.claude.com/docs"; Read-Host 'Entrée pour quitter'; exit 1 }
Ok ("Claude Code " + (claude --version))

if (-not (Has uv)) {
  Warn 'uv absent (nécessaire pour graphify) — installation'
  Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
  Refresh-Path
}
if (Has uv) { Ok (uv --version) } else { Warn 'uv indisponible : graphify sera ignoré' }

# OmniRoute exige Node >=22.22.2 <23 ou >=24 <27
function Node-Ok {
  if (-not (Has node)) { return $false }
  $v = [version](node -p 'process.versions.node')
  return (($v.Major -eq 22 -and $v -ge [version]'22.22.2') -or ($v.Major -ge 24 -and $v.Major -lt 27))
}
if (-not (Node-Ok) -and -not (Skipped 'omniroute') -and (Has winget)) {
  Warn 'Node.js 24 LTS absent ou trop ancien — installation via winget'
  winget install --id OpenJS.NodeJS.LTS -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
  Refresh-Path
}
$NodeOk = Node-Ok
if ($NodeOk) { Ok ("Node.js " + (node -v)) } else { Warn 'Node.js 24 LTS requis pour OmniRoute : https://nodejs.org' }

# ---------------------------------------------------------------- plugins Claude Code
function Install-Plugin($label, $repo, [string[]]$plugins) {
  claude plugin marketplace add $repo *> $null
  if ($LASTEXITCODE -ne 0) { Err "$label : ajout de la marketplace $repo impossible"; $Results[$label] = 'ÉCHEC'; return }
  claude plugin marketplace update ($plugins[0].Split('@')[1]) *> $null   # rafraîchit si déjà présente
  foreach ($p in $plugins) {
    claude plugin install $p *> $null
    if ($LASTEXITCODE -ne 0) { Err $p; $Results[$label] = 'ÉCHEC'; return }
    claude plugin update $p *> $null   # déjà installé : mise à jour
    Ok $p
  }
  $Results[$label] = 'OK'
}

if (Skipped 'caveman') { $Results['caveman'] = 'IGNORÉ' } else {
  Say 'caveman — réponses ultra-concises (moins de tokens en sortie)'
  Install-Plugin 'caveman' 'JuliusBrussee/caveman' @('caveman@caveman')
}

if (Skipped 'ponytail') { $Results['ponytail'] = 'IGNORÉ' } else {
  Say "ponytail — moins de code, réutilisation de l'existant"
  Install-Plugin 'ponytail' 'DietrichGebert/ponytail' @('ponytail@ponytail')
}

if (Skipped 'skills') { $Results['agent-skills'] = 'IGNORÉ' } else {
  Say 'Agent Skills officiels Anthropic (PDF, Word, Excel, PowerPoint, skill-creator...)'
  Install-Plugin 'agent-skills' 'anthropics/skills' @('document-skills@anthropic-agent-skills', 'example-skills@anthropic-agent-skills')
}

# ---------------------------------------------------------------- graphify
if (Skipped 'graphify') { $Results['graphify'] = 'IGNORÉ' }
elseif (-not (Has uv)) { $Results['graphify'] = 'ÉCHEC (uv manquant)' }
else {
  Say 'graphify — graphe de connaissances du projet'
  uv tool install --upgrade graphifyy *> $null
  Refresh-Path
  if ($LASTEXITCODE -eq 0 -and (Has graphify)) {
    graphify install --platform windows *> $null
  }
  if ($LASTEXITCODE -eq 0 -and (Has graphify)) { Ok (graphify --version | Select-Object -Last 1); $Results['graphify'] = 'OK' }
  else { Err 'graphify : échec (relancez : uv tool install graphifyy ; graphify install)'; $Results['graphify'] = 'ÉCHEC' }
}

# ---------------------------------------------------------------- OmniRoute
if (Skipped 'omniroute') { $Results['omniroute'] = 'IGNORÉ' }
elseif (-not $NodeOk) { $Results['omniroute'] = 'IGNORÉ (Node 24 requis)' }
else {
  Say 'OmniRoute — passerelle IA multi-fournisseurs (localhost:20128)'
  $log = npm install -g omniroute@latest 2>&1
  if ($LASTEXITCODE -eq 0) { Ok 'omniroute'; $Results['omniroute'] = 'OK' }
  else { $log | Select-Object -Last 5 | Write-Host; Err 'omniroute : échec de npm install -g omniroute'; $Results['omniroute'] = 'ÉCHEC' }
}

# ---------------------------------------------------------------- résumé
Say 'Résumé'
$fail = 0
foreach ($k in $Results.Keys) {
  $s = $Results[$k]
  if ($s -eq 'OK') { Ok $k } elseif ($s -like 'ÉCHEC*') { Err "$k — $s"; $fail = 1 } else { Warn "$k — $s" }
}

Write-Host @'

Prochaines étapes
  1. Fermez puis rouvrez votre terminal, puis lancez : claude
  2. Dans un projet : /graphify .        -> construit le graphe du code
  3. Commandes utiles : /caveman lite|full|ultra · /ponytail · /ponytail-review
  4. OmniRoute (optionnel) : omniroute   -> tableau de bord http://localhost:20128
     puis : omniroute launch              -> Claude Code via OmniRoute
  Guide complet : GUIDE-INSTALLATION.md
'@
exit $fail
