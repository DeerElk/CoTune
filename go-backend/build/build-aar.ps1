$ErrorActionPreference = "Stop"

# Пути
$GO_BACKEND = Resolve-Path "$PSScriptRoot\.."
$ROOT = Resolve-Path "$GO_BACKEND\.."
$AAR_OUTPUT = "$ROOT\flutter-app\android\app\libs"
$env:ANDROID_NDK_HOME="C:\Users\ellev\AppData\Local\Android\Sdk\ndk\21.4.7075529"

Write-Host "Building cotune.aar..."
Write-Host "Go backend dir: $GO_BACKEND"
Write-Host "AAR output dir: $AAR_OUTPUT"

# Переменные окружения
$env:CGO_ENABLED = "1"
$env:CGO_LDFLAGS = "-Wl,-z,max-page-size=16384"

# КЛЮЧЕВОЙ МОМЕНТ
Push-Location $GO_BACKEND

try {
  gomobile bind `
        -target=android `
        -ldflags="-checklinkname=0" `
        -o "$AAR_OUTPUT\cotune.aar" `
        ./api
}
finally {
  Pop-Location
}

Write-Host "Done. AAR successfully built and copied."
