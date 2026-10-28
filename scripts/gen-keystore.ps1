# Generates a signing keystore and the base64 blobs for GitHub Actions secrets.
#
# Usage:
#   ./scripts/gen-keystore.ps1              # writes into ./keys
#   ./scripts/gen-keystore.ps1 -OutDir C:\keys

param(
    [string]$OutDir = "keys",
    [string]$Alias = "helium"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    throw "keytool not found. Install a JDK (e.g. Temurin 17) and add it to PATH."
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$jks = Join-Path $OutDir "helium.jks"
$props = Join-Path $OutDir "local.properties"
$jksB64 = "$jks.b64"
$propsB64 = "$props.b64"

if (Test-Path $jks) {
    throw "$jks already exists. Delete it manually if you really want a new key."
}

$chars = ([char[]](48..57 + 65..90 + 97..122))
$pass = -join (1..32 | ForEach-Object { $chars | Get-Random })

keytool -genkeypair `
    -keystore $jks `
    -alias $Alias `
    -keyalg RSA -keysize 2048 -validity 10000 `
    -storepass $pass -keypass $pass `
    -dname "CN=Helium Android, O=Helium, C=US" `
    -noprompt

"keyAlias=$Alias`nkeyPassword=$pass`nstorePassword=$pass" |
    Set-Content -Path $props -NoNewline -Encoding ascii

[Convert]::ToBase64String([IO.File]::ReadAllBytes($jks)) |
    Set-Content -Path $jksB64 -NoNewline -Encoding ascii
[Convert]::ToBase64String([IO.File]::ReadAllBytes($props)) |
    Set-Content -Path $propsB64 -NoNewline -Encoding ascii

Write-Host ""
Write-Host "Created:"
Write-Host "  $jks"
Write-Host "  $props"
Write-Host "  $jksB64"
Write-Host "  $propsB64"
Write-Host ""
Write-Host "Password: $pass"
Write-Host "Keep the keystore and password safe. Without them you cannot ship updates."
Write-Host ""
Write-Host "Add the secrets:"
Write-Host "  gh secret set LOCAL_TEST_JKS < `"$propsB64`""
Write-Host "  gh secret set STORE_TEST_JKS < `"$jksB64`""
