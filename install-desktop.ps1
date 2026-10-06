# FORGESOFTWARE_CLAUDE — installeur 1 clic, version Claude Desktop (Windows)
#
# 1. Installe l'application Claude Desktop si elle manque.
# 2. Lance install.ps1 : caveman, ponytail, Agent Skills, graphify, OmniRoute
#    (l'onglet « Code » de Claude Desktop partage la configuration ~/.claude).
# 3. Configure claude_desktop_config.json (onglets Chat + Code) :
#    - un serveur MCP graphify par projet (-Projet), pour interroger le graphe depuis le Chat ;
#    - le serveur MCP OmniRoute (-OmnirouteMcp, optionnel).
#
# Usage (le plus simple : double-cliquer sur INSTALLER-DESKTOP-WINDOWS.bat) :
#   powershell -ExecutionPolicy Bypass -File install-desktop.ps1
#   powershell -ExecutionPolicy Bypass -File install-desktop.ps1 -Projet C:\code\mon-app,C:\code\autre
#   powershell -ExecutionPolicy Bypass -File install-desktop.ps1 -OmnirouteMcp -Skip omniroute
#   powershell -ExecutionPolicy Bypass -File install-desktop.ps1 -SansApp

param([string[]]$Projet = @(), [string[]]$Skip = @(), [switch]$OmnirouteMcp, [switch]$SansApp)

$ErrorActionPreference = 'Continue'
Set-Location $PSScriptRoot

function Say($m)  { Write-Host "`n==> $m" -ForegroundColor White }
function Ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!]  $m" -ForegroundColor Yellow }
function Err($m)  { Write-Host "  [X]  $m" -ForegroundColor Red }
function Has($c)  { [bool](Get-Command $c -ErrorAction SilentlyContinue) }
function Refresh-Path {
  if ($env:OS -ne 'Windows_NT') { return }
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
              [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
              "$env:USERPROFILE\.local\bin"
}

# ---------------------------------------------------------------- 1. application
Say 'Application Claude Desktop'
function App-Present {
  if (Test-Path "$env:LOCALAPPDATA\AnthropicClaude") { return $true }                       # installeur classique
  if (Get-Command Get-AppxPackage -ErrorAction SilentlyContinue) {                          # version MSIX / Store
    return [bool](Get-AppxPackage -Name '*Claude*' -ErrorAction SilentlyContinue)
  }
  return $false
}
if (App-Present) { Ok 'déjà installée' }
elseif ($SansApp) { Warn "installation de l'application ignorée (-SansApp)" }
else {
  $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
  $exe = Join-Path $env:TEMP 'Claude-Setup.exe'
  try {
    Invoke-WebRequest -UseBasicParsing "https://claude.ai/api/desktop/win32/$arch/setup/latest/redirect" -OutFile $exe
    Start-Process -FilePath $exe -Wait
  } catch { Err $_.Exception.Message }
  if (App-Present) { Ok 'installée' } else { Warn 'à installer depuis https://claude.com/download' }
}

# ---------------------------------------------------------------- 2. outils (onglet Code)
Say "Outils Claude Code (partagés avec l'onglet Code de Claude Desktop)"
& "$PSScriptRoot\install.ps1" -Skip ($Skip -join ',')
$baseRc = $LASTEXITCODE
Refresh-Path

# ---------------------------------------------------------------- 3. serveurs MCP (Chat + Code)
# Installation classique : %APPDATA%\Claude ; version Microsoft Store : dossier virtualisé du paquet
$cfgDirs = @(Get-ChildItem "$env:LOCALAPPDATA\Packages\Claude_*\LocalCache\Roaming\Claude" -Directory -ErrorAction SilentlyContinue | ForEach-Object FullName)
if (Test-Path "$env:APPDATA\Claude") { $cfgDirs += "$env:APPDATA\Claude" }
if ($cfgDirs.Count -eq 0) { $cfgDirs = @("$env:APPDATA\Claude") }
Say ("Serveurs MCP pour Claude Desktop (" + ($cfgDirs -join ', ') + ")")

if ($Projet.Count -eq 0 -and (Has graphify) -and [Environment]::UserInteractive) {
  Write-Host "  Dossier d'un projet à connecter à graphify (glissez-le ici, ou Entrée pour passer) :"
  $p = (Read-Host '  >').Trim().Trim('"').Trim("'")
  if ($p) { $Projet = @($p) }
}

$servers = [ordered]@{}
foreach ($p in ($Projet -join ',').Split(',', [StringSplitOptions]::RemoveEmptyEntries)) {
  $dir = (Resolve-Path $p.Trim() -ErrorAction SilentlyContinue).Path
  if (-not $dir) { Err "dossier introuvable : $p"; continue }
  if (-not (Has graphify-mcp)) { Err "graphify n'est pas installé"; break }
  Write-Host "  Construction du graphe de $dir (analyse locale du code, sans IA)..."
  Push-Location $dir; graphify update . *> $null; Pop-Location
  $graph = Join-Path $dir 'graphify-out\graph.json'
  if (Test-Path $graph) {
    $name = 'graphify-' + ((Split-Path $dir -Leaf) -replace '[^A-Za-z0-9_-]', '-')
    $servers[$name] = [pscustomobject]@{ command = (Get-Command graphify-mcp).Source; args = @("$graph") }
    Ok $name
  } else { Err "graphify : échec sur $dir" }
}

if ($OmnirouteMcp) {
  # le lanceur omniroute.cmd est à côté de node_modules\omniroute dans le dossier global npm
  $omni = ''
  $shim = Get-Command omniroute -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($shim) { $omni = Join-Path (Split-Path $shim.Source) 'node_modules\omniroute\bin\omniroute.mjs' }
  if (-not (Test-Path $omni)) { $omni = Join-Path (npm root -g) 'omniroute\bin\omniroute.mjs' }
  if ((Test-Path $omni) -and (Has node)) {
    $servers['omniroute'] = [pscustomobject]@{ command = (Get-Command node).Source; args = @($omni, '--mcp') }
    Ok 'omniroute'
  } else { Err 'OmniRoute non installé : serveur MCP ignoré' }
}

if ($servers.Count -eq 0) { Warn 'aucun serveur MCP ajouté' }
else {
  foreach ($d in $cfgDirs) {
    $cfgPath = Join-Path $d 'claude_desktop_config.json'
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    $cfg = [pscustomobject]@{}
    if ((Test-Path $cfgPath) -and (Get-Item $cfgPath).Length -gt 0) {
      try { $cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json }
      catch { Err "$cfgPath n'est pas un JSON valide : corrigez-le puis relancez"; continue }
      Copy-Item $cfgPath "$cfgPath.sauvegarde-$(Get-Date -Format yyyyMMdd-HHmmss)"
      Ok 'sauvegarde de l''ancienne configuration'
    }
    # fusion : on garde tout ce qui existe, on ajoute/remplace seulement nos serveurs
    if (-not $cfg.PSObject.Properties['mcpServers']) { $cfg | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([pscustomobject]@{}) }
    foreach ($k in $servers.Keys) { $cfg.mcpServers | Add-Member -Force -NotePropertyName $k -NotePropertyValue $servers[$k] }
    $json = ConvertTo-Json -InputObject $cfg -Depth 32
    [IO.File]::WriteAllText($cfgPath, $json, (New-Object Text.UTF8Encoding $false))
    Ok "configuration écrite : $cfgPath"
  }
}

Write-Host @'

À faire dans Claude Desktop (2 minutes)
  1. Quittez complètement Claude Desktop (icône près de l'horloge → Quitter) puis rouvrez-le.
  2. Paramètres (Settings) → Capacités (Capabilities) : activez « Exécution de code et création de fichiers »
     (les skills PDF / Word / Excel / PowerPoint d'Anthropic y sont déjà inclus).
  3. Pour le Chat et Cowork — Personnaliser (Customize) → Plugins → Ajouter (Add)
     → Ajouter une marketplace → « Ajouter depuis un dépôt », puis entrez un par un :
        JuliusBrussee/caveman
        DietrichGebert/ponytail
     et installez les plugins caveman et ponytail.
  4. Onglet Code : tout est déjà installé (caveman, ponytail, graphify, skills).
  Guide complet : GUIDE-DESKTOP.md
'@
exit $baseRc
