# Resurrect the original 2003 ER45 site locally from the static snapshot.
#
# The snapshot is a Classic-ASP site (no IIS here), so this server:
#   * serves every original asset (jpg/gif/png/swf/css/mp3/...) byte-for-byte
#   * for .asp pages: recursively inlines <!--#INCLUDE--> directives and strips
#     <% server-side %> blocks, so the original page CHROME (logos, layout, nav,
#     CSS) renders. Dynamic DB lists won't appear -- those are reborn in
#     archive.er45.com (see /archive). Source is decoded from Windows-1250.
#
# Open http://127.0.0.1:8201/  (Ctrl+C to stop)
$ErrorActionPreference = 'Stop'
$port = 8201
$root = 'C:\Users\patri\OneDrive\Backup\ER45\_backup\22012003_www.er45.com'
$cp1250 = [System.Text.Encoding]::GetEncoding(1250)

$mime = @{
  '.html'='text/html'; '.htm'='text/html'; '.css'='text/css'; '.js'='text/javascript'
  '.gif'='image/gif'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.png'='image/png'
  '.ico'='image/x-icon'; '.bmp'='image/bmp'; '.svg'='image/svg+xml'
  '.swf'='application/x-shockwave-flash'; '.mp3'='audio/mpeg'; '.mpeg'='video/mpeg'
  '.txt'='text/plain'; '.zip'='application/zip'
}

# Recursively inline ASP includes and strip server-side code.
function Render-Asp([string]$file, [int]$depth) {
  if ($depth -gt 12 -or -not (Test-Path $file -PathType Leaf)) { return '' }
  $txt = $cp1250.GetString([System.IO.File]::ReadAllBytes($file))
  $dir = Split-Path $file -Parent
  # #INCLUDE FILE="rel/path"  (relative to current file's dir)
  $txt = [regex]::Replace($txt, '(?i)<!--\s*#include\s+file\s*=\s*"([^"]+)"\s*-->', {
    param($m) Render-Asp (Join-Path $dir $m.Groups[1].Value) ($depth+1) })
  # #INCLUDE VIRTUAL="/path"  (relative to site root)
  $txt = [regex]::Replace($txt, '(?i)<!--\s*#include\s+virtual\s*=\s*"([^"]+)"\s*-->', {
    param($m) Render-Asp (Join-Path $root ($m.Groups[1].Value.TrimStart('/','\'))) ($depth+1) })
  # strip <% ... %> server blocks (incl. <%= %> and server.execute)
  $txt = [regex]::Replace($txt, '(?s)<%.*?%>', '')
  return $txt
}

function Asp-Page([string]$file) {
  $body = Render-Asp $file 0
  $banner = '<div style="position:fixed;top:0;left:0;right:0;z-index:9999;background:#111;color:#7fd1ff;font:12px/1.6 monospace;padding:6px 12px;border-bottom:1px solid #333">ER45 ' +
            '&middot; static reconstruction of the 22-Jan-2003 snapshot &middot; page chrome only (no live DB) &middot; ' +
            '<a href="/__index" style="color:#9f9">file index</a></div><div style="height:34px"></div>'
  $head = '<meta charset="utf-8"><base href="/">'
  return "<!doctype html><html><head>$head</head><body>$banner$body</body></html>"
}

function Dir-Index([string]$dir, [string]$urlPath) {
  $items = Get-ChildItem $dir | Sort-Object { -not $_.PSIsContainer }, Name
  $rows = foreach ($it in $items) {
    $name = $it.Name + $(if ($it.PSIsContainer) { '/' } else { '' })
    $href = ($urlPath.TrimEnd('/') + '/' + $it.Name)
    "<li><a href=""$href"">$name</a></li>"
  }
  "<!doctype html><meta charset=utf-8><body style='font:14px monospace;background:#111;color:#ddd;padding:20px'>" +
  "<h2>ER45 snapshot &mdash; $urlPath</h2><ul style='line-height:1.7'>$($rows -join '')</ul></body>"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$port/")
$listener.Start()
Write-Host "ER45 2003 snapshot -> http://127.0.0.1:$port/   (serving $root)" -ForegroundColor Cyan
Write-Host "Ctrl+C to stop." -ForegroundColor DarkGray

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    $rel = [System.Uri]::UnescapeDataString($ctx.Request.Url.LocalPath).TrimStart('/')
    if ($rel -eq '__index') {
      $html = Dir-Index $root '/'
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
      $ctx.Response.ContentType = 'text/html; charset=utf-8'
      $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
    }
    else {
      $target = if ($rel -eq '') { $root } else { Join-Path $root $rel }
      # directory -> default doc or listing
      if (Test-Path $target -PathType Container) {
        $def = $null
        foreach ($d in 'index.asp','index.htm','index.html','default.asp') {
          if (Test-Path (Join-Path $target $d) -PathType Leaf) { $def = Join-Path $target $d; break }
        }
        if ($def) { $target = $def }
        else {
          $html = Dir-Index $target ('/' + $rel)
          $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
          $ctx.Response.ContentType = 'text/html; charset=utf-8'
          $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
          $ctx.Response.Close(); continue
        }
      }
      if (Test-Path $target -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($target).ToLower()
        if ($ext -eq '.asp' -or $ext -eq '.asa') {
          $html = Asp-Page $target
          $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
          $ctx.Response.ContentType = 'text/html; charset=utf-8'
          $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
        } else {
          $bytes = [System.IO.File]::ReadAllBytes($target)
          if ($mime.ContainsKey($ext)) { $ctx.Response.ContentType = $mime[$ext] }
          $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
        }
      } else {
        $ctx.Response.StatusCode = 404
        $msg = [System.Text.Encoding]::UTF8.GetBytes("404: $rel not in snapshot")
        $ctx.Response.OutputStream.Write($msg,0,$msg.Length)
      }
    }
  } catch {
    try { $ctx.Response.StatusCode = 500 } catch {}
  } finally {
    try { $ctx.Response.Close() } catch {}
  }
}
