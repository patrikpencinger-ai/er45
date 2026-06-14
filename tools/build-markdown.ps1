# Build readable Markdown lists (PARTIES.md, ARTICLES.md) from the parsed DB.
# Dot-sources parse-db.ps1 which populates $global:ER45.
$ErrorActionPreference = 'Stop'
$repo = 'C:\Users\patri\OneDrive\CLAUDE\ER45'
. (Join-Path $repo 'tools\parse-db.ps1')

$parties  = $global:ER45.parties
$articles = $global:ER45.articles

function Cell([string]$s, [int]$max=0) {
  if ($null -eq $s) { return '' }
  $t = ($s -replace "[\r\n]+", ' ') -replace '\s+', ' '
  $t = $t.Trim() -replace '\|', '/'
  if ($max -gt 0 -and $t.Length -gt $max) { $t = $t.Substring(0,$max).Trim() + '...' }
  $t
}
function DatePart([string]$d) { if ($d -and $d.Length -ge 10) { $d.Substring(0,10) } else { $d } }
function Yr([string]$d) { if ($d -and $d.Length -ge 4 -and $d.Substring(0,4) -match '^\d{4}$' -and $d.Substring(0,4) -ne '0000') { $d.Substring(0,4) } else { '(undated)' } }

# ---------- PARTIES.md ----------
$valid = $parties | Where-Object { $_.date -and (DatePart $_.date) -ne '0000-00-00' }
$sorted = $parties | Sort-Object @{ E = { $d = DatePart $_.date; if ($d -and $d -ne '0000-00-00') { $d } else { '9999-99-99' } } }, id
$years  = $sorted | Group-Object { Yr $_.date } | Sort-Object Name

# stats
$venueCounts = $parties | Where-Object { $_.venue } | Group-Object { $_.venue } | Sort-Object Count -Descending
$genreCounts = $parties | Where-Object { $_.genre } |
  ForEach-Object { $_.genre -split '[,/]' | ForEach-Object { $_.Trim().ToLower() } } |
  Where-Object { $_ -ne '' } | Group-Object | Sort-Object Count -Descending
$dates = $valid | ForEach-Object { DatePart $_.date } | Sort-Object
$cancelled = ($parties | Where-Object { $_.cancelled }).Count

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# ER45 -- Party Chronology')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("Decoded from the original ``chrono`` table (MySQL ``er45`` DB, MySQL-Front dump, Windows-1250), venues resolved against the ``lokacije`` table. This is the live party calendar of the ER45 portal -- the backbone of the site.")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## At a glance')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("- **$($parties.Count) parties** logged ($cancelled marked cancelled).")
[void]$sb.AppendLine("- **Date range:** $($dates[0]) to $($dates[-1]).")
[void]$sb.AppendLine("- **$($venueCounts.Count) distinct venues.**")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('**Parties per year:**')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Year | Parties |')
[void]$sb.AppendLine('|------|--------:|')
foreach ($y in $years) { [void]$sb.AppendLine("| $($y.Name) | $($y.Count) |") }
[void]$sb.AppendLine('')
[void]$sb.AppendLine('**Top 15 venues:**')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| # | Venue | Parties |')
[void]$sb.AppendLine('|--:|-------|--------:|')
$rank=0; foreach ($v in ($venueCounts | Select-Object -First 15)) { $rank++; [void]$sb.AppendLine("| $rank | $(Cell $v.Name) | $($v.Count) |") }
[void]$sb.AppendLine('')
[void]$sb.AppendLine('**Top 15 genres (as tagged):**')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Genre | Count |')
[void]$sb.AppendLine('|-------|------:|')
foreach ($g in ($genreCounts | Select-Object -First 15)) { [void]$sb.AppendLine("| $(Cell $g.Name) | $($g.Count) |") }
[void]$sb.AppendLine('')
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Timeline')
[void]$sb.AppendLine('')
foreach ($y in $years) {
  [void]$sb.AppendLine("### $($y.Name) &nbsp;<sub>($($y.Count) parties)</sub>")
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('| Date | Party | Venue | Lineup | Genre |')
  [void]$sb.AppendLine('|------|-------|-------|--------|-------|')
  foreach ($p in $y.Group) {
    $name = Cell $p.name
    if ($p.cancelled) { $name = "~~$name~~ _(cancelled)_" }
    $lu = Cell (($p.lineup) -join ', ') 70
    [void]$sb.AppendLine("| $(DatePart $p.date) | $name | $(Cell $p.venue) | $lu | $(Cell $p.genre 28) |")
  }
  [void]$sb.AppendLine('')
}
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('*Generated from `data/parties.json`. Full lineups, prices and comments are in the JSON.*')
[System.IO.File]::WriteAllText((Join-Path $repo 'PARTIES.md'), $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Wrote PARTIES.md ($($parties.Count) rows)"

# ---------- ARTICLES.md ----------
$catOrder = 'interviewz','artists','report','tech stuff','fetish'
$byCat = $articles | Group-Object { $_.category }
$ab = New-Object System.Text.StringBuilder
[void]$ab.AppendLine('# ER45 -- Article Index')
[void]$ab.AppendLine('')
[void]$ab.AppendLine("Decoded from the ``clanci`` table (MySQL ``er45`` DB). $($articles.Count) articles -- DJ interviews, artist bios, party reports, gear/tech pieces and editorial. Category labels are the site's own (``kategorije`` table).")
[void]$ab.AppendLine('')
[void]$ab.AppendLine('## By category')
[void]$ab.AppendLine('')
[void]$ab.AppendLine('| Category | Articles |')
[void]$ab.AppendLine('|----------|---------:|')
foreach ($c in ($byCat | Sort-Object Count -Descending)) { [void]$ab.AppendLine("| $(Cell $c.Name) | $($c.Count) |") }
[void]$ab.AppendLine('')
$authors = $articles | Where-Object { $_.author } | Group-Object { $_.author } | Sort-Object Count -Descending | Select-Object -First 10
[void]$ab.AppendLine('**Top authors:** ' + (($authors | ForEach-Object { "$($_.Name) ($($_.Count))" }) -join ', ') + '.')
[void]$ab.AppendLine('')
[void]$ab.AppendLine('---')
[void]$ab.AppendLine('')
$ordered = @()
foreach ($cn in $catOrder) { $g = $byCat | Where-Object { $_.Name -eq $cn }; if ($g) { $ordered += $g } }
$ordered += ($byCat | Where-Object { $catOrder -notcontains $_.Name })
foreach ($c in $ordered) {
  $title = if ($c.Name) { $c.Name } else { '(uncategorised)' }
  [void]$ab.AppendLine("## $title &nbsp;<sub>($($c.Count))</sub>")
  [void]$ab.AppendLine('')
  [void]$ab.AppendLine('| Date | Title | Author | Lead |')
  [void]$ab.AppendLine('|------|-------|--------|------|')
  foreach ($a in ($c.Group | Sort-Object @{E={ DatePart $_.date }})) {
    [void]$ab.AppendLine("| $(DatePart $a.date) | **$(Cell $a.title)** | $(Cell $a.author) | $(Cell $a.lead 100) |")
  }
  [void]$ab.AppendLine('')
}
[void]$ab.AppendLine('---')
[void]$ab.AppendLine('*Generated from `data/articles.json`. Full article text is in the JSON.*')
[System.IO.File]::WriteAllText((Join-Path $repo 'ARTICLES.md'), $ab.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Wrote ARTICLES.md ($($articles.Count) rows)"
