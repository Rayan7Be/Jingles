$ErrorActionPreference = 'Stop'

function Normalize-Token([string]$token) {
  $t = $token.ToLowerInvariant()
  switch ($t) {
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
  if ($baseName -cmatch '[A-Z]' -and $baseName -match ' ') { return $baseName }
  $text = $baseName -replace '[-_]+', ' '
  $text = $text -replace '\s+', ' '
  $text = $text.Trim()
  $words = $text -split ' '
  $small = @('and','of','the','a','an','to','in','on','for','vs')
  $out = for ($i = 0; $i -lt $words.Count; $i++) {
    $w = $words[$i]
    if ($w -match '^[0-9]+([+][0-9]+)?(d)?$') { $w.ToUpperInvariant() }
    elseif ($w.Length -le 4 -and $w -cmatch '^[a-z0-9]+$' -and $w -in @('gba','gbc','nds','3ds','wii','wiiu','hd','dx','usa','gc','nes','snes','n64')) { $w.ToUpperInvariant() }
    elseif ($i -gt 0 -and $w.ToLowerInvariant() -in $small) { $w.ToLowerInvariant() }
    elseif ($w -cmatch '^[a-z]+$') { (Get-Culture).TextInfo.ToTitleCase($w) }
    else { $w }
  }
  return ($out -join ' ')
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

$systems = @('nes','snes','n64','gbc','gba','gc','nds','wii','n3ds','wiiu','switch')
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

$root = [ordered]@{ name = 'Ultimate Nintendo Jingles' }
foreach ($system in $systems) {
  $root[$system] = New-Object System.Collections.Generic.List[object]
}

foreach ($entry in $entries) {
  $patterns = New-Object 'System.Collections.Generic.List[string]'
  $titlePattern = Join-Separators $entry.Tokens
  $significantPattern = Join-Separators $entry.Significant

  $excludeTokens = @($familyMap[$entry.File] | Sort-Object -Unique)
  if ($excludeTokens.Count -gt 0) {
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

  $root[$entry.System].Add([ordered]@{
    name = $entry.Name
    file = $entry.File
    regex = ($patterns -join '|')
  })
}

$json = $root | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText((Join-Path (Get-Location) 'index.json'), $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
Write-Output 'index.json regenerated'
