# Creates a GitHub repository and pushes this branch to it.
#
# Requires a GitHub token with the "repo" scope:
#   $env:GITHUB_TOKEN = "ghp_..."
#
# Usage:
#   ./scripts/publish.ps1                  # private repo "helium-android"
#   ./scripts/publish.ps1 -Public          # public repo
#   ./scripts/publish.ps1 -Repo my-name

param(
    [string]$Repo = "helium-android",
    [string]$Token = $env:GITHUB_TOKEN,
    [switch]$Public
)

$ErrorActionPreference = "Stop"

if (-not $Token) {
    throw "Set GITHUB_TOKEN (repo scope) or pass -Token."
}
if (-not (Test-Path .git)) {
    throw "Run this from the repository root."
}

$headers = @{
    Authorization          = "Bearer $Token"
    Accept                 = "application/vnd.github+json"
    "User-Agent"           = "helium-android-publish"
    "X-GitHub-Api-Version" = "2022-11-28"
}

$user = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
$owner = $user.login
Write-Host "GitHub user: $owner"

$body = @{
    name        = $Repo
    private     = -not $Public
    description = "Unofficial Helium browser for Android with extension support"
} | ConvertTo-Json

try {
    $null = Invoke-RestMethod -Method Post `
        -Uri "https://api.github.com/user/repos" `
        -Headers $headers -ContentType "application/json" -Body $body
    Write-Host "Created repository $owner/$Repo"
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 422) {
        Write-Host "Repository $owner/$Repo already exists, pushing to it."
    } else {
        throw
    }
}

$url = "https://github.com/$owner/$Repo.git"
if ((git remote) -contains "origin") {
    git remote set-url origin $url
} else {
    git remote add origin $url
}

$basic = [Convert]::ToBase64String(
    [Text.Encoding]::ASCII.GetBytes("x-access-token:$Token"))
git -c "http.extraheader=AUTHORIZATION: basic $basic" push -u origin HEAD:main

# Never leave the token in .git/config.
git remote set-url origin $url

Write-Host ""
Write-Host "Pushed to $url"
Write-Host "Next: add signing secrets, then run the Build workflow."
Write-Host "See docs/BUILD_ANDROID.md"
