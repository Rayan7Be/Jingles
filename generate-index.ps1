$ErrorActionPreference = 'Stop'

function Normalize-Token([string]$token) {
  $t = $token.ToLowerInvariant()
  switch ($t) {
    'pokemon' { return 'pok(?:e|\x{00E9})mon' }
    'and' { return '(?:and|&|n)' }
    '&' { return '(?:and|&|n)' }
    'n' { return '(?:and|&|n)' }
    'bros' { return '(?:bros|brothers)' }
    'bros.' { return '(?:bros|brothers)' }
    'vs' { return '(?:vs|versus)' }
    'jr' { return '(?:jr|junior)' }
    'jr.' { return '(?:jr|junior)' }
    'dr' { return '(?:dr|doctor)' }
    'dr.' { return '(?:dr|doctor)' }
    default {
      $roman = @{
        'i'='(?:i|1|one)'; 'ii'='(?:ii|2|two)'; 'iii'='(?:iii|3|three)'; 'iv'='(?:iv|4|four)';
        'v'='(?:v|5|five)'; 'vi'='(?:vi|6|six)'; 'vii'='(?:vii|7|seven)'; 'viii'='(?:viii|8|eight)';
        'ix'='(?:ix|9|nine)'; 'x'='(?:x|10|ten)'; 'xi'='(?:xi|11|eleven)'; 'xii'='(?:xii|12|twelve)'
      }
      if ($roman.ContainsKey($t)) { return $roman[$t] }
      if ($t -match '^[0-9]+$') {
        $romanNum = switch ($t) {
          '1' { 'i' }
          '2' { 'ii' }
          '3' { 'iii' }
          '4' { 'iv' }
          '5' { 'v' }
          '6' { 'vi' }
          '7' { 'vii' }
          '8' { 'viii' }
          '9' { 'ix' }
          '10' { 'x' }
          '11' { 'xi' }
          '12' { 'xii' }
          default { $null }
        }
        if ($romanNum) { return '(?:' + [regex]::Escape($t) + '|' + $romanNum + ')' }
      }
      return [regex]::Escape($t)
    }
  }
}

function Get-Tokens([string]$baseName) {
  $normalized = $baseName.ToLowerInvariant()
  $normalized = $normalized -replace '&', ' and '
  $normalized = $normalized -replace '[\._\-\+]', ' '
  $normalized = $normalized -replace '[^a-z0-9'' ]', ' '
  $normalized = $normalized -replace '\s+', ' '
  return @($normalized.Trim() -split ' ' | Where-Object { $_ })
}

function Get-SignificantTokens([string[]]$tokens) {
  $stop = @('the','a','an','of','for','to','in','on','at','by','with','from','edition','version')
  return @($tokens | Where-Object { $_ -and ($_ -notin $stop) })
}

function Get-AcronymTokens([string[]]$tokens) {
  $skip = @('the','a','an','of','for','to','in','on','at','by','with','from','edition','version','super','new','legend','pokemon','mario','zelda','kirby','sonic','fire','emblem','final','fantasy','dragon','quest','mega','man','animal','crossing','paper','professor','layton')
  return @($tokens | Where-Object { $_ -and ($_ -notin $skip) })
}

function Join-Separators([string[]]$tokens) {
  return (@($tokens | ForEach-Object { Normalize-Token $_ })) -join '[^a-z0-9]*'
}

function Add-Pattern($list, [string]$value) {
  if ($value -and -not $list.Contains($value)) { [void]$list.Add($value) }
}

function Get-Compact([string[]]$tokens) {
  return ($tokens -join '')
}

function Get-DisplayName([string]$baseName) {
    $displayOverrides = @{
    'arc-raiders' = 'ARC Raiders'
      'airride' = 'Kirby Air Ride'
      'alliance-alive-the' = 'The Alliance Alive'
      'battlefield1' = 'Battlefield 1'
      'battlefield1-(1)' = 'Battlefield 1'
      'blackknight' = 'Sonic and the Black Knight'
      'bombrushcyberfunk' = 'Bomb Rush Cyberfunk'
      'boxboy' = 'BOXBOY!'
      'brawl' = 'Super Smash Bros. Brawl'
      'batman_-arkham-city-armored-edition' = 'Batman: Arkham City Armored Edition'
      'call-of-duty-black-ops' = 'Call of Duty: Black Ops'
      'call-of-duty-black-ops-ii' = 'Call of Duty: Black Ops II'
      'callofdutymodernwarfare2019' = 'Call of Duty: Modern Warfare (2019)'
      'call-of-duty-modern-warfare-3' = 'Call of Duty: Modern Warfare 3'
    'chuchu' = 'ChuChu Rocket!'
    'colors' = 'Sonic Colors'
    'ffix' = 'Final Fantasy IX'
    'ffvi' = 'Final Fantasy VI'
    'ffviadvance' = 'Final Fantasy VI Advance'
    'ffx' = 'Final Fantasy X'
    'f-zero-climax' = 'F-Zero Climax'
    'f-zero-gp-legends' = 'F-Zero GP Legend'
    'f-zero-maximum-velocity' = 'F-Zero: Maximum Velocity'
    'f-zero-x' = 'F-Zero X'
    'golftoad' = 'Mario Golf: Toadstool Tour'
    'gx' = 'F-Zero GX'
    'holocure' = 'HoloCure'
    'jsr' = 'Jet Set Radio'
    'jurrasic-park-builder' = 'Jurassic Park Builder'
    'klonoa---the-door-to-phantomile' = 'Klonoa: Door to Phantomile'
    'last-story-the' = 'The Last Story'
    'legend-of-legacy-the' = 'The Legend of Legacy'
    'legend-of-zelda-the-the-wind-waker-hd' = 'The Legend of Zelda: The Wind Waker HD'
    'legend-of-zelda-the-breath-of-the-wild' = 'The Legend of Zelda: Breath of the Wild'
    'legend-of-zelda-the-twilight-princess-hd' = 'The Legend of Zelda: Twilight Princess HD'
      'mario-kart-wii' = 'Mario Kart Wii'
      'minecraftbedrockedition' = 'Minecraft Bedrock Edition'
      'minecraftjavaedition' = 'Minecraft Java Edition'
      'mp6' = 'Mario Party 6'
    'munchables-the' = 'The Munchables'
    'parappa' = 'PaRappa the Rapper'
    'parappa2' = 'PaRappa the Rapper 2'
    'pikmin2' = 'Pikmin 2'
    'pokemon-bdsp' = 'Pokemon Brilliant Diamond / Shining Pearl'
    'pokemon-bw' = 'Pokemon Black / White'
    'pokemon-dp' = 'Pokemon Diamond / Pearl'
      'pokemon-hgss' = 'Pokemon HeartGold / SoulSilver'
      'pacmanchampionshipdx' = 'Pac-Man Championship Edition DX'
      'pacmanforever' = 'Pac-Man Forever'
      'powertennis' = 'Mario Power Tennis'
    'puyo-puyo-puyopuyo-20th-anniversary' = 'Puyo Puyo!! 20th Anniversary'
    'puyopuyo-tetris' = 'Puyo Puyo Tetris'
    'resident-evil-archives-resident-evil' = 'Resident Evil Archives: Resident Evil'
      'resident-evil-archives-resident-evil-zero' = 'Resident Evil Archives: Resident Evil Zero'
      'raymanorigins' = 'Rayman Origins'
      'riders' = 'Sonic Riders'
      'roblox' = 'Roblox'
      'roblox-death-sound-1' = 'Roblox Death Sound'
      'sa1' = 'Sonic Adventure'
      'sa2' = 'Sonic Adventure 2'
      'secretrings' = 'Sonic and the Secret Rings'
      'sm64' = 'Super Mario 64'
      'sonic-robo-blast-2-kart' = 'Sonic Robo Blast 2 Kart'
      'ssbu' = 'Super Smash Bros. Ultimate'
    'strikers' = 'Mario Strikers'
    'strikerscharged' = 'Mario Strikers Charged'
    'sunshine' = 'Super Mario Sunshine'
    'superbaseball' = 'Mario Superstar Baseball'
    'superpapermario' = 'Super Paper Mario'
      'taxi' = 'Crazy Taxi'
      'taxi2' = 'Crazy Taxi 2'
      'tearsofthekingdom' = 'Tears of the Kingdom'
      'supermariogalaxy' = 'Super Mario Galaxy'
      'supermarioworld' = 'Super Mario World'
      'tetris-effect' = 'Tetris Effect'
      'the-finals' = 'THE FINALS'
      'toree' = 'TOREE'
      'unleashed' = 'Sonic Unleashed'
      'vividlope' = 'VIVIDLOPE'
      'welcome-to-osu-1' = 'Welcome to osu!'
      'wario-land-the-shake-dimension' = 'Wario Land: The Shake Dimension'
      'yoshis-woolly-world' = "Yoshi's Woolly World"
    'zelda-twillight-princess' = 'The Legend of Zelda: Twilight Princess'
    'zombiu' = 'ZombiU'
    'zombi-u' = 'ZombiU'
    'new-super-mario-bros-wii' = 'New Super Mario Bros. Wii'
    'batman-arkham-city-armored-edition' = 'Batman: Arkham City Armored Edition'
  }
  $overrideKey = $baseName.ToLowerInvariant()
  $overrideKey = $overrideKey -replace '[ _]+', '-'
  $overrideKey = $overrideKey -replace '-+', '-'
  if ($displayOverrides.ContainsKey($overrideKey)) { return $displayOverrides[$overrideKey] }
  if ($baseName -cmatch '[A-Z]' -and $baseName -match ' ') { return $baseName }
  $text = $baseName -replace '[-_]+', ' '
  $text = $text -creplace '([a-z])([A-Z])', '$1 $2'
  $text = $text -replace '\s+', ' '
  $text = $text.Trim()
  $words = $text -split ' '
  $small = @('and','of','the','a','an','to','in','on','for','vs')
  $out = for ($i = 0; $i -lt $words.Count; $i++) {
    $w = $words[$i]
    if ($w -match '^[0-9]+([+][0-9]+)?(d)?$') { $w.ToUpperInvariant() }
    elseif ($w.Length -le 4 -and $w -cmatch '^[a-z0-9]+$' -and $w -in @('gba','gbc','nds','3ds','wii','wiiu','hd','dx','usa','gc','nes','snes','n64','psx','ps1','ps2','psp','psv','pc98','cdi','msx')) { $w.ToUpperInvariant() }
    elseif ($i -gt 0 -and $w.ToLowerInvariant() -in $small) { $w.ToLowerInvariant() }
    elseif ($w -cmatch '^[a-z]+$') { (Get-Culture).TextInfo.ToTitleCase($w) }
    else { $w }
  }
  return ($out -join ' ')
}

function Get-SystemLabel([string]$system) {
  $labels = @{
    'gb' = 'GB'
    'nes' = 'NES'
    'snes' = 'SNES'
    'n64' = 'N64'
    'gbc' = 'GBC'
    'gba' = 'GBA'
    'gc' = 'GC'
    'nds' = 'DS'
    'wii' = 'Wii'
    'n3ds' = '3DS'
    'wiiu' = 'Wii U'
    'switch' = 'Switch'
    'megadrive' = 'Mega Drive'
    'segacd' = 'Sega CD'
    'saturn' = 'Saturn'
    'dreamcast' = 'Dreamcast'
    'psx' = 'PS1'
    'ps2' = 'PS2'
    'psp' = 'PSP'
    'psv' = 'PS Vita'
    'xbox360' = 'Xbox 360'
    'steam' = 'Steam'
    'pc98' = 'PC-98'
    'ngpc' = 'NGPC'
    'cdi' = 'CD-i'
    'msx' = 'MSX'
  }
  return $labels[$system]
}

function Get-Aliases([string]$normalizedName) {
  $aliases = @{
    'tomodachi life' = @('^tomodachi[^a-z0-9]*life(?![^a-z0-9]*(?:living|livin|live|dream))$')
    'tomodachi life living the dream' = @(
      '^tomodachi[^a-z0-9]*life[^a-z0-9]*(?:living|livin|live)[^a-z0-9]*(?:the[^a-z0-9]*)?dream$',
      '^tomodachilifelivingthedream$',
      '^tlld$'
    )
    'pokemon mystery dungeon' = @('^pokemon[^a-z0-9]*myst(?:ery|e?ry)[^a-z0-9]*d(?:ungeon|ungn)$', '^pmd$')
    'pokemon mystery dungeon red rescue team' = @('^pmd[^a-z0-9]*red$', '^red[^a-z0-9]*rescue[^a-z0-9]*team$')
    'pokemon mystery dungeon explorers of sky' = @('^pmd[^a-z0-9]*explorers[^a-z0-9]*sky$', '^eos$')
    'pokemon mystery dungeon gates to infinity' = @('^pmd[^a-z0-9]*gates[^a-z0-9]*infinity$', '^gti$')
    'mario kart ds' = @('^mkds$')
    'mario kart 64' = @('^mk64$')
    'mario kart 7' = @('^mk7$')
    'mario kart 8' = @('^mk8$')
    'mario kart 8 deluxe' = @('^mk8d$')
    'mario kart double dash' = @('^mkdd$')
    'super mario kart' = @('^smk$')
    'the legend of zelda ocarina of time 3d' = @('^oot3d$|^ocarina[^a-z0-9]*time[^a-z0-9]*3d$')
    'the legend of zelda majoras mask 3d' = @('^mm3d$|^majoras[^a-z0-9]*mask[^a-z0-9]*3d$')
    'the legend of zelda a link between worlds' = @('^albw$|^link[^a-z0-9]*between[^a-z0-9]*worlds$')
    'the legend of zelda a link to the past' = @('^alttp$|^link[^a-z0-9]*to[^a-z0-9]*past$')
    'the legend of zelda breath of the wild' = @('^botw$|^breath[^a-z0-9]*wild$')
    'tears of the kingdom' = @('^totk$|^tears[^a-z0-9]*kingdom$')
    'super smash bros melee' = @('^ssbm$')
    'super smash bros remix' = @('^ssbr$')
    'ssbu' = @('^ssbu$|^super[^a-z0-9]*smash[^a-z0-9]*bros[^a-z0-9]*ultimate$')
    'super smash bros' = @('^ssb$')
  }
  if ($aliases.ContainsKey($normalizedName)) { return $aliases[$normalizedName] }
  return @()
}

function Get-SplitEntries($entry) {
  $splitMap = @{
    'jingles/nds/pokemon-bw.wav' = @('Pokemon Black', 'Pokemon White')
    'jingles/nds/pokemon-dp.wav' = @('Pokemon Diamond', 'Pokemon Pearl')
    'jingles/nds/pokemon-hgss.wav' = @('Pokemon HeartGold', 'Pokemon SoulSilver')
    'jingles/switch/pokemon-bdsp.wav' = @('Pokemon Brilliant Diamond', 'Pokemon Shining Pearl')
  }

  if (-not $splitMap.ContainsKey($entry.File)) { return @() }

  return @($splitMap[$entry.File] | ForEach-Object {
    $splitTokens = Get-Tokens $_
    $splitSignificant = Get-SignificantTokens $splitTokens
    if (-not $splitSignificant.Count) { $splitSignificant = $splitTokens }
    [pscustomobject]@{
      System = $entry.System
      Name = $_
      File = $entry.File
      Tokens = $splitTokens
      Significant = $splitSignificant
      Normalized = ($splitSignificant -join ' ')
      RawBase = $entry.RawBase
      IsSplit = $true
    }
  })
}

$systems = @('gb','nes','snes','n64','gbc','gba','gc','nds','wii','n3ds','wiiu','switch','megadrive','segacd','saturn','dreamcast','psx','ps2','psp','psv','xbox360','steam','pc98','ngpc','cdi','msx')
$entries = New-Object System.Collections.Generic.List[object]

foreach ($system in $systems) {
  Get-ChildItem -LiteralPath (Join-Path 'jingles' $system) -File | Sort-Object Name | ForEach-Object {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $tokens = Get-Tokens $baseName
    $significant = Get-SignificantTokens $tokens
    if (-not $significant.Count) { $significant = $tokens }
    $normalizedName = ($significant -join ' ')
    $entries.Add([pscustomobject]@{
      System = $system
      Name = Get-DisplayName $baseName
      File = 'jingles/' + $system + '/' + $_.Name
      Tokens = $tokens
      Significant = $significant
      Normalized = $normalizedName
      RawBase = $baseName
    })
  }
}

$splitEntries = New-Object System.Collections.Generic.List[object]
foreach ($entry in $entries) {
  foreach ($splitEntry in Get-SplitEntries $entry) {
    $splitEntries.Add($splitEntry)
  }
}

# Build prefix families so base titles can exclude longer siblings.
$familyMap = @{}
foreach ($entry in $entries) {
  $familyMap[$entry.File] = New-Object System.Collections.Generic.List[string]
}

foreach ($entry in $entries) {
  foreach ($other in $entries) {
    if ($entry.File -eq $other.File) { continue }
    if (-not $other.Normalized.StartsWith($entry.Normalized + ' ')) { continue }

    $parts = $other.Normalized -split ' '
    $baseParts = $entry.Normalized -split ' '
    if ($parts.Count -le $baseParts.Count) { continue }

    $nextToken = $parts[$baseParts.Count]
    if ($nextToken) {
      [void]$familyMap[$entry.File].Add($nextToken)
    }
  }
}

$root = [ordered]@{ name = 'Ultimate Video Game Jingles' }
foreach ($system in $systems) {
  $root[$system] = New-Object System.Collections.Generic.List[object]
}

foreach ($entry in $entries) {
  $patterns = New-Object 'System.Collections.Generic.List[string]'
  $titlePattern = Join-Separators $entry.Tokens
  $significantPattern = Join-Separators $entry.Significant
  $displayName = $entry.Name

  $excludeTokens = @($familyMap[$entry.File] | Sort-Object -Unique)
  if ($excludeTokens.Count -gt 0) {
    $displayName = '{0} ({1})' -f $entry.Name, (Get-SystemLabel $entry.System)
    $excludePattern = '(?:' + ((@($excludeTokens | ForEach-Object { Normalize-Token $_ })) -join '|') + ')'
    Add-Pattern $patterns ('^' + $titlePattern + '(?![^a-z0-9]*(?:' + $excludePattern + '))$')
    if ($significantPattern -ne $titlePattern) {
      Add-Pattern $patterns ('^' + $significantPattern + '(?![^a-z0-9]*(?:' + $excludePattern + '))$')
    }
  } else {
    Add-Pattern $patterns ('^' + $titlePattern + '$')
    if ($significantPattern -ne $titlePattern) {
      Add-Pattern $patterns ('^' + $significantPattern + '$')
    }
  }

  $compact = Get-Compact $entry.Tokens
  if ($compact.Length -le 28) {
    Add-Pattern $patterns ('^' + [regex]::Escape($compact) + '$')
  }

  $acronymTokens = Get-AcronymTokens $entry.Significant
  if ($acronymTokens.Count -ge 2 -and $acronymTokens.Count -le 6) {
    $acro = ($acronymTokens | ForEach-Object { if ($_ -match '^[0-9]+d?$') { $_ } else { $_[0] } }) -join ''
    if ($acro.Length -ge 3) { Add-Pattern $patterns ('^' + [regex]::Escape($acro) + '$') }
  }

  foreach ($alias in Get-Aliases $entry.Normalized) {
    Add-Pattern $patterns $alias
  }

  if ($entry.Normalized -like 'pokemon *') {
    Add-Pattern $patterns ('^' + $titlePattern + '(?:[^a-z0-9]*(?:version))?$')
    if ($significantPattern -ne $titlePattern) {
      Add-Pattern $patterns ('^' + $significantPattern + '(?:[^a-z0-9]*(?:version))?$')
    }
  }

  $root[$entry.System].Add([ordered]@{
    name = $displayName
    file = $entry.File
    regex = ($patterns -join '|')
  })
}

foreach ($entry in $splitEntries) {
  $patterns = New-Object 'System.Collections.Generic.List[string]'
  $titlePattern = Join-Separators $entry.Tokens
  $significantPattern = Join-Separators $entry.Significant

  Add-Pattern $patterns ('^' + $titlePattern + '$')
  if ($significantPattern -ne $titlePattern) {
    Add-Pattern $patterns ('^' + $significantPattern + '$')
  }

  $compact = Get-Compact $entry.Tokens
  if ($compact.Length -le 28) {
    Add-Pattern $patterns ('^' + [regex]::Escape($compact) + '$')
  }

  foreach ($alias in Get-Aliases $entry.Normalized) {
    Add-Pattern $patterns $alias
  }

  if ($entry.Normalized -like 'pokemon *') {
    Add-Pattern $patterns ('^' + $titlePattern + '(?:[^a-z0-9]*(?:version))?$')
    if ($significantPattern -ne $titlePattern) {
      Add-Pattern $patterns ('^' + $significantPattern + '(?:[^a-z0-9]*(?:version))?$')
    }
  }

  $root[$entry.System].Add([ordered]@{
    name = $entry.Name
    file = $entry.File
    regex = ($patterns -join '|')
  })
}

$json = $root | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText((Join-Path (Get-Location) 'index.json'), $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
Write-Output 'index.json regenerated'
