# Parse the ER45 MySQL-Front dumps (CP1250) into clean JSON + readable Markdown.
# Source of truth: the "ER45 baze hrvatski fontovi" dumps (full DB, Croatian charset).
#   dump1.sql -> chrono (parties)
#   dump2.sql -> lokacije (venues), clanci (articles), kategorije (article categories)
$ErrorActionPreference = 'Stop'
$src  = 'C:\Users\patri\OneDrive\Backup\ER45\ER45 baze hrvatski fontovi'
$repo = 'C:\Users\patri\OneDrive\CLAUDE\ER45'
$enc  = [System.Text.Encoding]::GetEncoding(1250)

function Read-Cp1250([string]$path) { $enc.GetString([System.IO.File]::ReadAllBytes($path)) }

# articles.mdb stores CP1250 bytes mis-decoded as CP1252 (c-caron shows as e-grave).
# Reverse it: re-encode the string to CP1252 bytes, decode as CP1250.
$cp1252 = [System.Text.Encoding]::GetEncoding(1252)
function Fix-Mojibake($s) { if ($null -eq $s -or $s -eq '') { return $s }; $enc.GetString($cp1252.GetBytes([string]$s)) }

# Tokenize MySQL-Front "INSERT INTO <table> VALUES(...);" rows into string[] arrays.
function Parse-Rows([string]$text, [string]$table) {
  $marker = "INSERT INTO $table VALUES("
  $rows = New-Object System.Collections.Generic.List[object]
  $idx = 0
  while (($idx = $text.IndexOf($marker, $idx)) -ge 0) {
    $i = $idx + $marker.Length
    $len = $text.Length
    $vals = New-Object System.Collections.Generic.List[object]
    $sb = New-Object System.Text.StringBuilder
    $inStr = $false; $isString = $false; $done = $false
    while ($i -lt $len -and -not $done) {
      $c = $text[$i]
      if ($inStr) {
        if ($c -eq '\') {
          $n = $text[$i+1]
          switch ($n) {
            '"' { [void]$sb.Append('"') }
            '\' { [void]$sb.Append('\') }
            'n' { [void]$sb.Append("`n") }
            'r' { [void]$sb.Append("`r") }
            't' { [void]$sb.Append("`t") }
            '0' { }            # NUL terminator artifact -> drop
            "'" { [void]$sb.Append("'") }
            default { [void]$sb.Append($n) }
          }
          $i += 2; continue
        } elseif ($c -eq '"') { $inStr = $false; $i++; continue }
        else { [void]$sb.Append($c); $i++; continue }
      } else {
        if ($c -eq '"') { [void]$sb.Clear(); $inStr = $true; $isString = $true; $i++; continue }
        elseif ($c -eq ',') {
          if ($isString) { $vals.Add($sb.ToString()) }
          else { $t = $sb.ToString().Trim(); if ($t -eq 'NULL' -or $t -eq '') { $vals.Add($null) } else { $vals.Add($t) } }
          [void]$sb.Clear(); $isString = $false; $i++; continue
        }
        elseif ($c -eq ')') {
          if ($isString) { $vals.Add($sb.ToString()) }
          else { $t = $sb.ToString().Trim(); if ($t -eq 'NULL' -or $t -eq '') { $vals.Add($null) } else { $vals.Add($t) } }
          $done = $true; $i++; continue
        }
        else { if (-not $isString) { [void]$sb.Append($c) }; $i++; continue }
      }
    }
    $rows.Add($vals.ToArray())
    $idx = $i
  }
  ,$rows
}

# Strip HTML to plain text (lineups/comments are full of <br> and <a> tags).
function Html-ToText([string]$s) {
  if ($null -eq $s) { return '' }
  $s = $s -replace '(?i)<br\s*/?>', "`n"
  $s = $s -replace '(?i)</p>', "`n"
  $s = $s -replace '<[^>]+>', ''
  $s = $s -replace '&nbsp;', ' ' -replace '&amp;', '&' -replace '&quot;', '"' -replace '&lt;', '<' -replace '&gt;', '>' -replace '&#39;', "'"
  $s = $s -replace "`r", ''
  # collapse 3+ newlines, trim each line
  ($s -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }) -join "`n"
}
function OneLine([string]$s, [int]$max) {
  $t = (Html-ToText $s) -replace "`n", ', '
  $t = $t -replace '\s+', ' '
  $t = $t.Trim().TrimEnd(',').Trim()
  if ($max -gt 0 -and $t.Length -gt $max) { $t = $t.Substring(0, $max).Trim() + '...' }
  $t
}

Write-Host "Reading dumps..."
$d1 = Read-Cp1250 (Join-Path $src 'dump1.sql')
$d2 = Read-Cp1250 (Join-Path $src 'dump2.sql')

# --- Lookups ---
$locRows = Parse-Rows $d2 'lokacije'
$loc = @{}
foreach ($r in $locRows) { $loc[[string]$r[0]] = @{ name=$r[1]; address=$r[2]; web=$r[5] } }
Write-Host "lokacije: $($locRows.Count)"

# kategorije + clanci are sourced from Access (articles.mdb) below -- the dump2.sql
# clanci TEXT is corrupted (c-with-caron stored as ASCII 'e'); the .mdb is intact.

# --- Parties (chrono) ---
$chronoRows = Parse-Rows $d1 'chrono'
Write-Host "chrono: $($chronoRows.Count)"
$parties = New-Object System.Collections.Generic.List[object]
foreach ($r in $chronoRows) {
  $locId = [string]$r[4]
  $venue = if ($loc.ContainsKey($locId)) { $loc[$locId] } else { $null }
  $lineup = Html-ToText $r[6]
  $parties.Add([ordered]@{
    id        = [int]$r[0]
    name      = $r[1]
    date      = $r[3]
    venue     = if ($venue) { $venue.name } else { $null }
    address   = if ($venue) { $venue.address } else { $null }
    venueWeb  = if ($venue) { $venue.web } else { $null }
    lineup    = ($lineup -split "`n" | Where-Object { $_ -ne '' })
    price     = $r[7]
    comment   = (Html-ToText $r[8])
    genre     = $r[9]
    cancelled = ($r[12] -eq '1')
    addedBy   = $r[13]
  })
}

# --- Articles (clanci) + categories from Access (articles.mdb: intact Croatian) ---
$mdb = 'C:\Users\patri\OneDrive\Backup\ER45\ER45 baze\baze\articles.mdb'
$cn = New-Object System.Data.OleDb.OleDbConnection("Provider=Microsoft.ACE.OLEDB.12.0;Data Source=$mdb;")
$cn.Open()
function Cv($v) { if ($v -is [System.DBNull]) { $null } else { $v } }

$cat = @{}
$cmd = $cn.CreateCommand(); $cmd.CommandText = "SELECT KATEGORIJA_ID, KATEGORIJA_NAZIV FROM KATEGORIJE"
$rd = $cmd.ExecuteReader()
while ($rd.Read()) { $cat[[string]([int]$rd['KATEGORIJA_ID'])] = Fix-Mojibake ([string]$rd['KATEGORIJA_NAZIV']) }
$rd.Close()

$articles = New-Object System.Collections.Generic.List[object]
$cmd = $cn.CreateCommand(); $cmd.CommandText = "SELECT * FROM CLANCI ORDER BY ID"
$rd = $cmd.ExecuteReader()
while ($rd.Read()) {
  $pics = @((Cv $rd['PIC01']),(Cv $rd['PIC02']),(Cv $rd['PIC03'])) | Where-Object { $_ -and "$_".Trim() -ne '' }
  $dt = Cv $rd['DATUM']
  $datestr = if ($dt) { Get-Date $dt -Format 'yyyy-MM-dd HH:mm:ss' } else { $null }
  $kid = Cv $rd['KATEGORIJA_ID']
  $catName = if ($null -ne $kid -and $cat.ContainsKey([string][int]$kid)) { $cat[[string][int]$kid] } else { $null }
  $articles.Add([ordered]@{
    id       = [int]$rd['ID']
    title    = (Fix-Mojibake (Cv $rd['NASLOV']))
    lead     = (Html-ToText (Fix-Mojibake (Cv $rd['LEAD'])))
    author   = (Fix-Mojibake (Cv $rd['AUTOR']))
    category = $catName
    date     = $datestr
    pics     = $pics
    text     = (Html-ToText (Fix-Mojibake (Cv $rd['TEKST'])))
  })
}
$rd.Close(); $cn.Close()
Write-Host "clanci (from articles.mdb): $($articles.Count)"

# --- Write JSON (feeds archive.er45.com) ---
$dataDir = Join-Path $repo 'data'
function Save-Json($obj, $file) {
  ($obj | ConvertTo-Json -Depth 6) | Set-Content -Path (Join-Path $dataDir $file) -Encoding UTF8
}
Save-Json $parties 'parties.json'
Save-Json $articles 'articles.json'
$locOut = $locRows | ForEach-Object { [ordered]@{ id=[int]$_[0]; name=$_[1]; address=$_[2]; web=$_[5] } }
Save-Json $locOut 'locations.json'
Write-Host "Wrote JSON to $dataDir"

# Return objects for the markdown builder (dot-source usage)
$global:ER45 = @{ parties=$parties; articles=$articles; locations=$loc; categories=$cat }
Write-Host "Done parsing."
