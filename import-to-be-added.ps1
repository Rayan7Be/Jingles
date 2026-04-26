$ErrorActionPreference = 'Stop'

function Normalize-Text([string]$text) {
  $normalized = $text
  $replacements = @{
    [char]0x2160 = 'I'
    [char]0x2161 = 'II'
    [char]0x2162 = 'III'
    [char]0x2163 = 'IV'
    [char]0x2164 = 'V'
    [char]0x2165 = 'VI'
    [char]0x2166 = 'VII'
    [char]0x2167 = 'VIII'
    [char]0x2168 = 'IX'
    [char]0x2169 = 'X'
    [char]0x29F8 = '/'
    [char]0xFF1A = ':'
  }

  foreach ($key in $replacements.Keys) {
    $normalized = $normalized.Replace([string]$key, $replacements[$key])
  }

  return $normalized
}

function Get-BaseName([string]$name) {
  return Normalize-Text([System.IO.Path]::GetFileNameWithoutExtension($name))
}

function Ensure-SystemFolder([string]$system) {
  $path = Join-Path (Join-Path (Get-Location) 'jingles') $system
  if (-not (Test-Path -LiteralPath $path)) {
    New-Item -ItemType Directory -Path $path | Out-Null
  }
}

function Copy-IntoSystem([System.IO.FileInfo]$file, [string]$system, [hashtable]$stats) {
  Ensure-SystemFolder $system
  $target = Join-Path (Join-Path (Get-Location) "jingles\$system") $file.Name
  if (Test-Path -LiteralPath $target) {
    $stats.skipped++
    return
  }

  Copy-Item -LiteralPath $file.FullName -Destination $target
  $stats.added++
  if (-not $stats.bySystem.ContainsKey($system)) {
    $stats.bySystem[$system] = 0
  }
  $stats.bySystem[$system]++
}

function Resolve-SystemFromBracket([string]$baseName) {
  if ($baseName -match '\[(?<tag>[^\]]+)\]') {
    switch ($matches.tag.ToUpperInvariant()) {
      'NES' { return 'nes' }
      'SNES' { return 'snes' }
      'GBC' { return 'gbc' }
      'GB' { return 'gb' }
      'GBA' { return 'gba' }
      'DS' { return 'nds' }
      '3DS' { return 'n3ds' }
      'PS1' { return 'psx' }
      'PS2' { return 'ps2' }
      'PSP' { return 'psp' }
      'GC' { return 'gc' }
      'N64' { return 'n64' }
      'WII' { return 'wii' }
      'WII U' { return 'wiiu' }
      'SWITCH' { return 'switch' }
      'ANDROID' { return 'androidgames' }
      'ANDROID GAMES' { return 'androidgames' }
      'DREAMCAST' { return 'dreamcast' }
      'SATURN' { return 'saturn' }
      'MEGADRIVE' { return 'megadrive' }
      'GENESIS' { return 'megadrive' }
      'SEGA CD' { return 'segacd' }
    }
  }

  if ($baseName -match '\((?<tag>DS|3DS|PS1|PS2|PSP|WII|SWITCH|ANDROID|GC|N64|SNES|NES|GBA|GBC)\)') {
    switch ($matches.tag.ToUpperInvariant()) {
      'DS' { return 'nds' }
      '3DS' { return 'n3ds' }
      'PS1' { return 'psx' }
      'PS2' { return 'ps2' }
      'PSP' { return 'psp' }
      'WII' { return 'wii' }
      'SWITCH' { return 'switch' }
      'ANDROID' { return 'androidgames' }
      'GC' { return 'gc' }
      'N64' { return 'n64' }
      'SNES' { return 'snes' }
      'NES' { return 'nes' }
      'GBA' { return 'gba' }
      'GBC' { return 'gbc' }
    }
  }

  return $null
}

function Resolve-DragonQuestSystem([string]$baseName) {
  $system = Resolve-SystemFromBracket $baseName
  if ($system) { return $system }
  if ($baseName -match 'VII Reimagined') { return 'n3ds' }
  if ($baseName -match 'XI') { return 'switch' }
  return 'switch'
}

function Resolve-AceAttorneySystem([string]$baseName) {
  return 'switch'
}

function Resolve-MegaManSystem([string]$baseName) {
  if ($baseName -match 'Battle Network') { return 'gba' }
  if ($baseName -match 'Command Mission') { return 'gc' }
  if ($baseName -match 'Legends') { return 'psx' }
  if ($baseName -match 'Maverick Hunter X|Powered Up') { return 'psp' }
  if ($baseName -match 'Star Force') { return 'nds' }
  if ($baseName -match 'Xtreme') { return 'gbc' }
  if ($baseName -match 'BattleNFighters|Battle ?N ?Fighters') { return 'ngpc' }
  if ($baseName -match 'X7|X8') { return 'ps2' }
  if ($baseName -match 'X3') { return 'snes' }
  if ($baseName -match 'Zero') { return 'gba' }
  if ($baseName -match 'Mega Man 11|Mega Man 9 10') { return 'switch' }
  return 'switch'
}

function Resolve-GracieSonicSystem([string]$baseName) {
  if ($baseName -match 'Shadow the Hedgehog') { return 'gc' }
  if ($baseName -match '3 AIR|Triple Trouble') { return 'steam' }
  if ($baseName -match 'Advance') { return 'gba' }
  if ($baseName -match 'Adventure 2|Adventure$') { return 'dreamcast' }
  if ($baseName -match 'Battle') { return 'gba' }
  if ($baseName -match 'Sonic CD') { return 'segacd' }
  if ($baseName -match 'Colors \(DS\)') { return 'nds' }
  if ($baseName -match 'Mania') { return 'switch' }
  if ($baseName -match 'Pocket Adventure') { return 'ngpc' }
  if ($baseName -match 'Rush') { return 'nds' }
  if ($baseName -match '2006') { return 'xbox360' }
  if ($baseName -match 'Unleashed') { return 'wii' }
  if ($baseName -match 'Generations') { return 'steam' }
  return 'steam'
}

function Resolve-ZeldaSystem([string]$baseName) {
  if ($baseName -match 'Majora') { return 'n64' }
  if ($baseName -match 'Ocarina') { return 'n64' }
  if ($baseName -match 'TearsOfTheKingdom|Breath of the Wild|Echoes of Wisdom|Cadence of Hyrule') { return 'switch' }
  if ($baseName -match "Tri Force Heroes") { return 'n3ds' }
  if ($baseName -match "A Link to the Past") { return 'snes' }
  if ($baseName -match "Link's Awakening Switch") { return 'switch' }
  if ($baseName -match "Link's Awakening") { return 'gb' }
  if ($baseName -match 'Minish Cap') { return 'gba' }
  if ($baseName -match 'Oracle') { return 'gbc' }
  if ($baseName -match 'Phantom Hourglass|Spirit Tracks') { return 'nds' }
  if ($baseName -match 'Skyward Sword') { return 'wii' }
  if ($baseName -match 'Twilight Princess') { return 'gc' }
  if ($baseName -match 'Wind Waker HD') { return 'wiiu' }
  if ($baseName -match 'Wind Waker') { return 'gc' }
  if ($baseName -match 'Four Swords Adventures') { return 'gc' }
  if ($baseName -match 'Four Swords') { return 'gba' }
  return 'switch'
}

function Resolve-KingdomHeartsSystem([string]$baseName) {
  if ($baseName -match '358/2 Days') { return 'nds' }
  if ($baseName -match '3D Dream Drop Distance') { return 'n3ds' }
  if ($baseName -match 'Birth by Sleep') { return 'psp' }
  if ($baseName -match 'Chain of Memories') { return 'gba' }
  if ($baseName -match 'Melody of Memory') { return 'switch' }
  if ($baseName -match 'Recoded') { return 'nds' }
  if ($baseName -match 'Kingdom Hearts II|Kingdom Hearts 2') { return 'ps2' }
  if ($baseName -match 'Kingdom Hearts III|Kingdom Hearts 3') { return 'steam' }
  return 'ps2'
}

function Resolve-NatalieSystem([string]$baseName) {
  if ($baseName -match '^Mario 64$') { return 'n64' }
  if ($baseName -match '^Xenoblade Chronicles( 2| 3)?$') { return 'switch' }
  if ($baseName -match 'Theatrhythm Final Bar Line') { return 'switch' }
  if ($baseName -match '^Gnosia$') { return 'switch' }
  if ($baseName -match '^Persona 5$') { return 'switch' }
  if ($baseName -match '^Prince of Persia') { return 'ps2' }
  if ($baseName -match '^Tetris CD-I$') { return 'cdi' }
  if ($baseName -match '^2Ship$|Ship Of Harkanian') { return 'steam' }
  return 'steam'
}

function Resolve-ResidentEvilSystem([string]$baseName) {
  if ($baseName -match '1 Remake') { return 'gc' }
  if ($baseName -match 'Code Veronica') { return 'dreamcast' }
  return 'psx'
}

function Resolve-SilentHillSystem([string]$baseName) {
  if ($baseName -match 'Shattered Memories') { return 'wii' }
  if ($baseName -match ' 3| 4|3$|4$') { return 'ps2' }
  return 'psx'
}

function Resolve-SonicSeriesSystem([string]$baseName) {
  if ($baseName -match 'Sonic & Knuckles|Sonic 3 & Knuckles|Sonic the Hedgehog 2|Sonic the Hedgehog 3|Sonic the Hedgehog Spinball|Sonic the Hedgehog$') { return 'megadrive' }
  if ($baseName -match 'Sonic Advance|Sonic Battle') { return 'gba' }
  if ($baseName -match 'Adventure 2|Adventure$') { return 'dreamcast' }
  if ($baseName -match 'Black Knight|Secret Rings|Sonic Colors$|Sonic Unleashed') { return 'wii' }
  if ($baseName -match 'Sonic Generations|Sonic Racing CrossWorlds') { return 'steam' }
  if ($baseName -match 'Sonic Heroes|Sonic Riders') { return 'gc' }
  if ($baseName -match '^Sonic R$') { return 'saturn' }
  if ($baseName -match 'Rivals') { return 'psp' }
  if ($baseName -match 'Rush') { return 'nds' }
  if ($baseName -match 'Superstars') { return 'switch' }
  if ($baseName -match 'Sonic the Hedgehog CD') { return 'segacd' }
  if ($baseName -match 'Shadow the Hedgehog') { return 'gc' }
  return 'steam'
}

function Resolve-SuperMarioSystem([string]$baseName) {
  if ($baseName -match 'New Super Mario Bros Wii') { return 'wii' }
  if ($baseName -match '^New Super Mario Bros$') { return 'nds' }
  if ($baseName -match '3D Land') { return 'n3ds' }
  if ($baseName -match '3D World') { return 'wiiu' }
  if ($baseName -match '^Super Mario 64$') { return 'n64' }
  if ($baseName -match 'Bros\.? 2|Bros\.? 3|Bros\.$') { return 'nes' }
  if ($baseName -match 'Wonder|Odyssey') { return 'switch' }
  if ($baseName -match 'Galaxy') { return 'wii' }
  if ($baseName -match "Yoshi's Island|Super Mario World$") { return 'snes' }
  if ($baseName -match 'Land 2|Land$') { return 'gb' }
  if ($baseName -match 'RPG') { return 'snes' }
  if ($baseName -match 'Sunshine') { return 'gc' }
  if ($baseName -match 'Super Princess Peach') { return 'nds' }
  return 'switch'
}

function Resolve-YuGiOhSystem([string]$baseName) {
  if ($baseName -match 'Tag Force') { return 'psp' }
  if ($baseName -match 'Reshef of Destruction') { return 'gba' }
  return 'nds'
}

function Resolve-MiscSystem([string]$path, [string]$name) {
  $baseName = Get-BaseName $name
  $system = Resolve-SystemFromBracket $baseName
  if ($system) { return $system }

  switch -Regex ($path) {
    'Dragon Quest Series' { return Resolve-DragonQuestSystem $baseName }
    'GracieFailfox\\Ace Attorney' { return Resolve-AceAttorneySystem $baseName }
    'GracieFailfox\\Mega Man' { return Resolve-MegaManSystem $baseName }
    'GracieFailfox\\Other' { return 'switch' }
    'GracieFailfox\\Sonic' { return Resolve-GracieSonicSystem $baseName }
    'GracieFailfox\\Zelda' { return Resolve-ZeldaSystem $baseName }
    'Kingdom Hearts Series' { return Resolve-KingdomHeartsSystem $baseName }
    'natalie' { return Resolve-NatalieSystem $baseName }
    'Resident Evil Series' { return Resolve-ResidentEvilSystem $baseName }
    'Silent Hill Series' { return Resolve-SilentHillSystem $baseName }
    'Sonic The Hedgehog Series' { return Resolve-SonicSeriesSystem $baseName }
    'Super Mario Series' { return Resolve-SuperMarioSystem $baseName }
    'Yu-Gi-Oh!' { return Resolve-YuGiOhSystem $baseName }
  }

  return 'steam'
}

function Resolve-MultiSystem([string]$name) {
  $baseName = Get-BaseName $name

  switch -Regex ($baseName) {
    '^Apollo Justice - Ace Attorney$' { return 'nds' }
    '^Archibald''s Adventures$' { return 'psp' }
    '^Assassin''s Creed IV Black Flag$' { return 'wiiu' }
    '^Bully$' { return 'ps2' }
    '^Castlevania - Symphony of the Night$' { return 'psx' }
    '^Cave Story$' { return 'switch' }
    '^Chrono Trigger$' { return 'snes' }
    '^Dead Cells$' { return 'switch' }
    '^Deltarune$' { return 'switch' }
    '^Devil Summoner - Raidou Kuzunoha vs\. the Soulless Army$' { return 'ps2' }
    '^Devil Summoner - Soul Hackers$' { return 'saturn' }
    '^Dokapon Kingdom$' { return 'wii' }
    '^Earthworm Jim( 2)?$' { return 'megadrive' }
    '^Ghost Trick - Phantom Detective$' { return 'nds' }
    '^God of War \(2005\)$' { return 'ps2' }
    '^Grand Theft Auto - Chinatown Wars$' { return 'nds' }
    '^Gurumin - A Monstrous Adventure$' { return 'psp' }
    '^Hyperdevotion Noire$' { return 'psv' }
    '^Hyperdimension Neptunia ReBirth( 2| 3)?$' { return 'psv' }
    '^Hyperdimension Neptunia U - Action Unleashed$' { return 'psv' }
    '^Jak and Daxter - The Lost Frontier$' { return 'psp' }
    '^Klonoa -  The Door to Phantomile$' { return 'psx' }
    '^Klonoa 2 - Lunatea''s Veil$' { return 'ps2' }
    '^Makai Kingdom$' { return 'ps2' }
    '^Mega Man$' { return 'nes' }
    '^Mega Man 2$' { return 'nes' }
    '^Mega Man 3$' { return 'nes' }
    '^Mega Man 4$' { return 'nes' }
    '^Mega Man 5$' { return 'nes' }
    '^Mega Man 6$' { return 'nes' }
    '^Mega Man 7$' { return 'snes' }
    '^Mega Man 8$' { return 'psx' }
    '^Mega Man 9$' { return 'switch' }
    '^Mega Man 10$' { return 'switch' }
    '^Mega Man 11$' { return 'switch' }
    '^Mega Man and Bass$' { return 'snes' }
    '^Mega Man Legends( 2)?$' { return 'psx' }
    '^Mega Man X DiVE Offline$' { return 'steam' }
    '^Mega Man X4|Mega Man X5|Mega Man X6$' { return 'psx' }
    '^Mega Man X7|Mega Man X8$' { return 'ps2' }
    '^Mega Man Zero( 2| 3| 4)?$' { return 'gba' }
    '^Mega Man ZX( Advent)?$' { return 'nds' }
    '^Metal Gear 2$' { return 'msx' }
    '^Metal Gear$' { return 'msx' }
    '^Metal Gear Rising - Revengeance$' { return 'steam' }
    '^Metal Gear Solid$' { return 'psx' }
    '^Metal Gear Solid VR Missions$' { return 'psx' }
    '^Metal Gear Solid 2 - Sons of Liberty$' { return 'ps2' }
    '^Metal Gear Solid 3 - Snake Eater$' { return 'ps2' }
    '^Mighty Flip Champs$' { return 'nds' }
    '^Minecraft$' { return 'switch' }
    '^Muse Dash$' { return 'switch' }
    '^N Plus$' { return 'nds' }
    '^Neon White$' { return 'switch' }
    '^Okami$' { return 'ps2' }
    '^Pac-Man Championship Edition$' { return 'psp' }
    '^Persona 2 - Eternal Punishment$' { return 'psx' }
    '^Persona 2 - Innocent Sin$' { return 'psp' }
    '^Persona 3 Portable$' { return 'psp' }
    '^Persona 4 Golden$' { return 'psv' }
    '^Persona 5 Royal$' { return 'switch' }
    '^Persona 5 Strikers$' { return 'switch' }
    '^Persona 5 Tactica$' { return 'switch' }
    '^Phoenix Wright - Ace Attorney$' { return 'nds' }
    '^Phoenix Wright - Ace Attorney - Justice for All$' { return 'nds' }
    '^Phoenix Wright - Ace Attorney - Trials and Tribulations$' { return 'nds' }
    '^Prince of Persia - The Sands of Time$' { return 'ps2' }
    '^Professor Layton and Pandora''s Box$' { return 'nds' }
    '^Professor Layton and the Curious Village$' { return 'nds' }
    '^Professor Layton and the Lost Future$' { return 'nds' }
    '^Psychonauts$' { return 'ps2' }
    '^Revelations - Persona$' { return 'psx' }
    '^Secret Agent Clank$' { return 'psp' }
    '^Shin Megami Tensei - Nocturne$' { return 'ps2' }
    '^Shin Megami Tensei - Strange Journey$' { return 'nds' }
    '^Shin Megami Tensei 2$' { return 'snes' }
    '^Shin Megami Tensei If\.\.\.$' { return 'snes' }
    '^Shin Megami Tensei IV Apocalypse$' { return 'n3ds' }
    '^Shin Megami Tensei IV$' { return 'n3ds' }
    '^Shin Megami Tensei V$' { return 'switch' }
    '^Sihn Megami Tensei - Devil Summoner$' { return 'saturn' }
    '^Snake''s Revenge$' { return 'nes' }
    '^Sonic Adventure 2$' { return 'dreamcast' }
    '^Soulcalibur 2$' { return 'gc' }
    '^Suikoden I & II HD Remaster - Gate Rune & Dunan Unification Wars$' { return 'switch' }
    '^Tales of the Abyss$' { return 'ps2' }
    '^The Binding of Isaac$' { return 'switch' }
    '^The Legend of Zelda - Majora''s Mask$' { return 'n64' }
    '^The Legend of Zelda - Ocarina of Time$' { return 'n64' }
    '^The Legend of Zelda - Skyward Sword$' { return 'wii' }
    '^The Legend of Zelda - The Wind Waker$' { return 'gc' }
    '^The Legend of Zelda - Twilight Princess$' { return 'gc' }
    '^Theme Hospital$' { return 'psx' }
    '^TimeSplitters$' { return 'ps2' }
    '^TimeSplitters 2$' { return 'ps2' }
    '^TimeSplitters - Future Perfect$' { return 'ps2' }
    '^Undertale$' { return 'switch' }
    '^Valkyria Chronicles$' { return 'steam' }
    '^XIII$' { return 'gc' }
  }

  return 'steam'
}

function Resolve-TouhouSystem([string]$name) {
  $baseName = Get-BaseName $name

  switch -Regex ($baseName) {
    '^Touhou - Highly Responsive to Prayers$' { return 'pc98' }
    '^Touhou 2 - Story of Eastern Wonderland$' { return 'pc98' }
    '^Touhou 3 - Phantasmagoria of Dim Dream$' { return 'pc98' }
    '^Touhou 4 - Lotus Land Story$' { return 'pc98' }
    '^Touhou 5 - Mystic Square$' { return 'pc98' }
    '^Touhou Puppet Dance Performance$' { return 'gba' }
    '^Touhou Puppet Play Enhanced$' { return 'gba' }
    '^Touhou Puppet Play World Link Version Revised$' { return 'gba' }
    '^Touhoumon Another World Version Revised$' { return 'gba' }
  }

  return 'steam'
}

$stats = @{
  added = 0
  skipped = 0
  bySystem = @{}
}

$directFolderMap = @{
  '3ds' = 'n3ds'
  'dreamcast' = 'dreamcast'
  'megadrive' = 'megadrive'
  'nds' = 'nds'
  'nes' = 'nes'
  'ps2' = 'ps2'
  'psp' = 'psp'
  'psv' = 'psv'
  'psx' = 'psx'
  'saturn' = 'saturn'
  'steam' = 'steam'
  'switch' = 'switch'
  'androidgames' = 'androidgames'
}

foreach ($folder in $directFolderMap.Keys) {
  $source = Join-Path 'to be added' $folder
  if (-not (Test-Path -LiteralPath $source)) { continue }
  Get-ChildItem -LiteralPath $source -Recurse -File | Where-Object { $_.Extension -ne '.gitkeep' } | ForEach-Object {
    Copy-IntoSystem $_ $directFolderMap[$folder] $stats
  }
}

$miscPath = Join-Path 'to be added' '1. misc'
if (Test-Path -LiteralPath $miscPath) {
  Get-ChildItem -LiteralPath $miscPath -Recurse -File | Where-Object { $_.Name -ne '.gitkeep' } | ForEach-Object {
    $system = Resolve-MiscSystem $_.FullName $_.Name
    Copy-IntoSystem $_ $system $stats
  }
}

$multiPath = Join-Path 'to be added' '2. multi'
if (Test-Path -LiteralPath $multiPath) {
  Get-ChildItem -LiteralPath $multiPath -Recurse -File | ForEach-Object {
    $system = Resolve-MultiSystem $_.Name
    Copy-IntoSystem $_ $system $stats
  }
}

$touhouPath = Join-Path 'to be added' '3. touhou'
if (Test-Path -LiteralPath $touhouPath) {
  Get-ChildItem -LiteralPath $touhouPath -Recurse -File | ForEach-Object {
    $system = Resolve-TouhouSystem $_.Name
    Copy-IntoSystem $_ $system $stats
  }
}

[pscustomobject]@{
  Added = $stats.added
  Skipped = $stats.skipped
  BySystem = ($stats.bySystem.GetEnumerator() | Sort-Object Name | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value }) -join ', '
} | Format-List
