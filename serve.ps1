param(
  [int]$Port = 8000,
  [string]$Root = (Get-Location).Path
)

$prefix = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
try {
  $listener.Start()
  Write-Host "Static server started at $prefix (root: $Root)"
} catch {
  Write-Host "Failed to start server: " $_.Exception.Message
  exit 1
}

function Get-MimeType($path) {
  switch ([System.IO.Path]::GetExtension($path).ToLower()) {
    '.html' { 'text/html' }
    '.htm' { 'text/html' }
    '.css' { 'text/css' }
    '.js' { 'application/javascript' }
    '.json' { 'application/json' }
    '.png' { 'image/png' }
    '.jpg' { 'image/jpeg' }
    '.jpeg' { 'image/jpeg' }
    '.svg' { 'image/svg+xml' }
    '.webp' { 'image/webp' }
    '.ico' { 'image/x-icon' }
    default { 'application/octet-stream' }
  }
}

while ($true) {
  try {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    $urlPath = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($urlPath)) { $urlPath = 'index.html' }

    $filePath = Join-Path $Root $urlPath
    if (Test-Path $filePath) {
      $item = Get-Item $filePath
      if ($item.PsIsContainer) { $filePath = Join-Path $filePath 'index.html' }
    }

    if (Test-Path $filePath -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $response.ContentType = Get-MimeType $filePath
      $response.ContentLength64 = $bytes.Length
      $response.OutputStream.Write($bytes, 0, $bytes.Length)
      $response.OutputStream.Close()
    } else {
      $response.StatusCode = 404
      $buffer = [Text.Encoding]::UTF8.GetBytes("Not Found")
      $response.ContentLength64 = $buffer.Length
      $response.OutputStream.Write($buffer, 0, $buffer.Length)
      $response.OutputStream.Close()
    }
  } catch {
    Write-Host $_.Exception.Message
  }
}