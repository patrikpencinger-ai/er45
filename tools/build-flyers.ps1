# Thumbnail the original event flyers into archive/assets/flyers/ and emit flyers.json.
# Keeps the repo light (480px JPEGs) while giving the archive real imagery.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$srcDir = 'C:\Users\patri\OneDrive\Backup\ER45\Flyeri'
$repo   = 'C:\Users\patri\OneDrive\CLAUDE\ER45'
$outDir = Join-Path $repo 'archive\assets\flyers'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$maxW = 480
$flyers = New-Object System.Collections.Generic.List[object]
$files = Get-ChildItem $srcDir -File | Where-Object { $_.Extension -match '(?i)\.(jpg|jpeg|gif|png)$' } | Sort-Object Name

# JPEG encoder at quality 82
$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]82)

$i = 0
foreach ($f in $files) {
  try {
    $img = [System.Drawing.Image]::FromFile($f.FullName)
    $scale = [Math]::Min(1.0, $maxW / $img.Width)
    $w = [int]($img.Width * $scale); $h = [int]($img.Height * $scale)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, 0, 0, $w, $h)
    $outName = ('flyer{0:D3}.jpg' -f $i)
    $bmp.Save((Join-Path $outDir $outName), $enc, $ep)
    $g.Dispose(); $bmp.Dispose(); $img.Dispose()

    # parse date prefix  NNN.MM.DD  (000=2000 ... 003=2003)
    $date = $null
    if ($f.Name -match '^(\d{2,3})\.(\d{2})\.(\d{2})') {
      $yy = [int]$matches[1]; $mm = $matches[2]; $dd = $matches[3]
      $year = 2000 + ($yy % 100)
      $date = '{0}-{1}-{2}' -f $year, $mm, $dd
    }
    # title: drop date prefix + extension, tidy
    $title = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    $title = $title -replace '^\d{2,3}\.\d{2}\.\d{2}\s*', ''
    $title = $title -replace '[_]+', ' ' -replace '\s+', ' '
    $title = ($title -replace '(?i)\b(fl|fl1|fl2|plak|plakat|str1|str2|prev|copy)\b', '').Trim()
    if ($title -eq '') { $title = 'Flyer' }

    $flyers.Add([ordered]@{ file = "assets/flyers/$outName"; title = $title; date = $date })
    $i++
  } catch { Write-Host "skip $($f.Name): $($_.Exception.Message)" }
}
($flyers | ConvertTo-Json -Depth 4) | Set-Content -Path (Join-Path $repo 'archive\flyers.json') -Encoding UTF8
$bytes = (Get-ChildItem $outDir -File | Measure-Object Length -Sum).Sum
Write-Host ("Wrote {0} flyer thumbs ({1:N1} MB) + flyers.json" -f $i, ($bytes/1MB))
