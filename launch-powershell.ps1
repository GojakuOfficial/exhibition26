# LUMINA CITY — Standalone Zero-Dependency Windows PowerShell HTTP Server
# Runs natively on Windows 10 and Windows 11 without Node.js or Python required.

$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

$distDir = Join-Path $scriptDir "dist"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " 🏙️  LUMINA CITY — Autonomous Intelligent City Showcase" -ForegroundColor Cyan
Write-Host "     Windows Native Offline Server" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. If dist does not exist, try building with npm if available
if (-not (Test-Path (Join-Path $distDir "index.html"))) {
    Write-Host "[!] Production build not found at $distDir" -ForegroundColor Yellow
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Write-Host "Detected npm. Running build..." -ForegroundColor Cyan
        npm.cmd run build
    } else {
        Write-Host "[X] 'dist' folder is missing and npm is not installed." -ForegroundColor Red
        Write-Host "Please ensure the dist folder is included in the project export." -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to exit..."
        exit 1
    }
}

# 2. Find available port starting from 8080
$port = 8080
$listener = $null
$maxRetries = 10

while ($maxRetries -gt 0) {
    try {
        $listener = New-Object System.Net.HttpListener
        $prefix = "http://localhost:$port/"
        $listener.Prefixes.Add($prefix)
        $listener.Start()
        break
    } catch {
        Write-Host "Port $port is in use. Trying $($port + 1)..." -ForegroundColor Yellow
        $port++
        $maxRetries--
        if ($listener) { $listener.Close() }
    }
}

if (-not $listener.IsListening) {
    Write-Host "[X] Unable to bind to an open local port." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}

$localUrl = "http://localhost:$port/"
Write-Host "  Local Server:  $localUrl" -ForegroundColor Green
Write-Host "  Serving From:  $distDir" -ForegroundColor Gray
Write-Host ""
Write-Host "  Features active:" -ForegroundColor Cyan
Write-Host "  ✔ Three.js 3D City & Procedural Canvases" -ForegroundColor White
Write-Host "  ✔ Web Audio Synthesizer (Zero External Dependencies)" -ForegroundColor White
Write-Host "  ✔ Crisis Commander Game, Pointer Lock & Fullscreen" -ForegroundColor White
Write-Host "  ✔ All 5 AI Protocols & Urban Simulation Suite" -ForegroundColor White
Write-Host ""
Write-Host "  Opening default browser..." -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop the server anytime." -ForegroundColor Gray
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Open default browser
try {
    Start-Process $localUrl
} catch {
    Write-Host "Could not automatically launch browser. Please open $localUrl manually." -ForegroundColor Yellow
}

# MIME Types dictionary
$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".mjs"  = "application/javascript; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".svg"  = "image/svg+xml"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".webp" = "image/webp"
    ".ico"  = "image/x-icon"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
    ".ttf"  = "font/ttf"
    ".map"  = "application/json"
}

# 3. Main server loop
try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $relPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($relPath)) {
            $relPath = "index.html"
        }

        # Resolve path safely inside dist
        $targetFile = [System.IO.Path]::GetFullPath((Join-Path $distDir $relPath))
        if (-not $targetFile.StartsWith($distDir, [System.StringComparison]::OrdinalIgnoreCase)) {
            $response.StatusCode = 403
            $response.Close()
            continue
        }

        # If directory, find index.html
        if (Test-Path $targetFile -PathType Container) {
            $targetFile = Join-Path $targetFile "index.html"
        }

        # SPA fallback
        if (-not (Test-Path $targetFile -PathType Leaf)) {
            $ext = [System.IO.Path]::GetExtension($relPath)
            if ([string]::IsNullOrEmpty($ext) -or $ext -eq ".html") {
                $targetFile = Join-Path $distDir "index.html"
            }
        }

        if (Test-Path $targetFile -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($targetFile).ToLower()
            $contentType = $mimeTypes[$ext]
            if (-not $contentType) { $contentType = "application/octet-stream" }

            $bytes = [System.IO.File]::ReadAllBytes($targetFile)
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.AddHeader("Cache-Control", "no-cache")
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
        }
        $response.Close()
    }
} finally {
    if ($listener) {
        $listener.Stop()
        $listener.Close()
    }
}
