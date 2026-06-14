# Local static server for the ER45 memorial site.
# Run from this project; preview at http://127.0.0.1:8200/
# (port 8200 so it never clashes with daily-dashboard on 8100)
$port = 8200
$root = "C:\Users\patri\OneDrive\CLAUDE\ER45"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$port/")
$listener.Start()
$mime = @{ '.html'='text/html; charset=utf-8'; '.json'='application/json'; '.js'='text/javascript'; '.css'='text/css'; '.svg'='image/svg+xml'; '.mp3'='audio/mpeg'; '.png'='image/png'; '.jpg'='image/jpeg'; '.gif'='image/gif' }
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    $path = [System.Uri]::UnescapeDataString($ctx.Request.Url.LocalPath).TrimStart('/')
    if ($path -eq '') { $path = 'er45.html' }   # memorial is the root document
    $file = Join-Path $root $path
    if (Test-Path $file -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      if ($mime.ContainsKey($ext)) { $ctx.Response.ContentType = $mime[$ext] }
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
  } catch {
    $ctx.Response.StatusCode = 500
  } finally {
    $ctx.Response.Close()
  }
}
