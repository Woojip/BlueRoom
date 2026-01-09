# Simple HTTP Server for BlueRoom VR
# Run this script, then open http://localhost:8080 in your browser

$port = 8080
$root = $PSScriptRoot

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Prefixes.Add("http://127.0.0.1:$port/")

try {
    # Try to add network-accessible prefix (requires admin, will silently fail if not)
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne "127.0.0.1" } | Select-Object -First 1).IPAddress
    if ($ip) {
        Write-Host "For Quest 2, use: http://${ip}:$port" -ForegroundColor Cyan
    }
} catch {}

$listener.Start()

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  BlueRoom VR Server Started!" -ForegroundColor Green  
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Open in browser: http://localhost:$port" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
Write-Host ""

$mimeTypes = @{
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
    ".glb"  = "model/gltf-binary"
    ".gltf" = "model/gltf+json"
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $localPath = $request.Url.LocalPath
    if ($localPath -eq "/") { $localPath = "/index.html" }
    
    $filePath = Join-Path $root $localPath.TrimStart("/")
    
    if (Test-Path $filePath -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
        $contentType = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
        
        $content = [System.IO.File]::ReadAllBytes($filePath)
        $response.ContentType = $contentType
        $response.ContentLength64 = $content.Length
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.OutputStream.Write($content, 0, $content.Length)
        
        Write-Host "[200] $localPath" -ForegroundColor Green
    } else {
        $response.StatusCode = 404
        $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
        $response.OutputStream.Write($msg, 0, $msg.Length)
        Write-Host "[404] $localPath" -ForegroundColor Red
    }
    
    $response.Close()
}
