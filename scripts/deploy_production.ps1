# deploy_production.ps1
#
# Builds, deploys, purges the Cloudflare edge cache, and verifies the live
# production bundle for dq_staff (staff.dqstore.in).
#
# WHY THIS EXISTS (2026-07-17 incident):
# A production deploy via `wrangler pages deploy` reported success, and the
# Cloudflare Pages "Production" environment and *.pages.dev subdomain served
# the correct new bundle immediately - but the custom domain (staff.dqstore.in)
# kept serving a stale bundle (still pointing at a decommissioned Azure
# backend) for over an hour afterward, reproducible on completely fresh
# browser profiles with zero cache of their own. Root cause: Cloudflare edge
# PoPs can take an unpredictable amount of time to converge on a new
# deployment for a custom domain. There was no misconfigured Cache Rule/Page
# Rule/Worker (confirmed via direct Cloudflare API audit) - this is a
# platform propagation-timing gap, not a bug in this app.
#
# This script closes that gap structurally: purge the CDN immediately after
# every deploy, then verify the live bundle before declaring success, instead
# of hoping propagation finishes before a customer visits.
#
# REQUIRES:
#   $env:CF_CACHE_PURGE_TOKEN  - scoped to this zone with Zone.Cache Purge:Edit
#   $env:CLOUDFLARE_ZONE_ID    - dqstore.in zone ID
# Neither is stored in this repo. Set them in your shell before running, or
# as CI secrets.
#
# NOTE: this file must stay plain ASCII. Windows PowerShell 5.1 misreads
# UTF-8-without-BOM script files using the system codepage by default, which
# silently corrupts non-ASCII characters (em-dashes, box-drawing glyphs) into
# bytes that break the parser with confusing "unterminated string" errors far
# from the actual problem. Do not reintroduce smart quotes/dashes here.
#
# Usage: .\scripts\deploy_production.ps1

param(
    [string]$ProjectName = "dq-staff",
    [string]$Domain      = "staff.dqstore.in",
    [string]$LegacyHostPatterns = "azurecontainerapps,ca-dq-backend,ashysea"
)

$ErrorActionPreference = "Stop"
$PROJECT_ROOT = Split-Path -Parent $PSScriptRoot

function Write-Step { param($msg) Write-Host "`n$msg" -ForegroundColor Cyan }
function Write-Ok   { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host $msg -ForegroundColor Red }
function Write-Warn { param($msg) Write-Host $msg -ForegroundColor Yellow }

if (-not $env:CF_CACHE_PURGE_TOKEN) {
    Write-Fail "CF_CACHE_PURGE_TOKEN is not set. Cannot purge cache after deploy - aborting."
    Write-Host "Set it with: `$env:CF_CACHE_PURGE_TOKEN = '...'"
    exit 1
}
if (-not $env:CLOUDFLARE_ZONE_ID) {
    Write-Fail "CLOUDFLARE_ZONE_ID is not set. Cannot purge cache after deploy - aborting."
    exit 1
}

Set-Location $PROJECT_ROOT

# --- 1. Build ---------------------------------------------------------------
Write-Step "[1/4] Building $ProjectName for web (prod flavor, release)..."
flutter build web --dart-define=APP_FLAVOR=prod --release
if ($LASTEXITCODE -ne 0) { Write-Fail "Build failed."; exit 1 }
Write-Ok "Build OK"

# --- 2. Deploy (retry - Cloudflare asset upload has shown transient connect-timeout flakiness) ---
Write-Step "[2/4] Deploying to Cloudflare Pages ($ProjectName)..."
$deployed = $false
for ($attempt = 1; $attempt -le 5; $attempt++) {
    Write-Host "  Attempt $attempt/5..."
    npx wrangler pages deploy build/web --project-name=$ProjectName --branch=main --commit-dirty=true
    if ($LASTEXITCODE -eq 0) { $deployed = $true; break }
    Write-Warn "  Upload failed (likely transient network issue), retrying..."
    Start-Sleep -Seconds 5
}
if (-not $deployed) { Write-Fail "Deploy failed after 5 attempts."; exit 1 }
Write-Ok "Deploy OK"

# --- 3. Purge CDN cache - do not wait for passive propagation ---------------
# Uses Invoke-RestMethod (not curl.exe) - PowerShell's native-command argument
# passing mangles embedded double-quotes in JSON bodies handed to external
# executables, which silently corrupted this request during local testing.
Write-Step "[3/4] Purging Cloudflare edge cache for dqstore.in..."
try {
    $purgeResult = Invoke-RestMethod -Method Post `
        -Uri "https://api.cloudflare.com/client/v4/zones/$($env:CLOUDFLARE_ZONE_ID)/purge_cache" `
        -Headers @{ Authorization = "Bearer $($env:CF_CACHE_PURGE_TOKEN)" } `
        -ContentType "application/json" `
        -Body (@{ purge_everything = $true } | ConvertTo-Json)
} catch {
    Write-Fail "Cache purge request failed: $_"
    exit 1
}
if (-not $purgeResult.success) {
    Write-Fail "Cache purge failed: $($purgeResult.errors | ConvertTo-Json -Compress)"
    exit 1
}
Write-Ok "Cache purge OK"

# Give the purge a moment to propagate before verifying.
Start-Sleep -Seconds 10

# --- 4. Verify the live bundle - the actual regression gate -----------------
Write-Step "[4/4] Verifying live bundle at https://$Domain..."
$cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
try {
    $liveJs = Invoke-RestMethod -Method Get -Uri "https://$Domain/main.dart.js?verify=$cacheBust" -TimeoutSec 20
} catch {
    Write-Fail "Could not fetch live bundle from https://$Domain - $_"
    exit 1
}

if ([string]::IsNullOrEmpty($liveJs)) {
    Write-Fail "Live bundle at https://$Domain was empty - aborting verification."
    exit 1
}

$foundLegacy = $false
foreach ($pattern in ($LegacyHostPatterns -split ",")) {
    if ($liveJs -match [regex]::Escape($pattern)) {
        Write-Fail "Legacy host pattern '$pattern' found in the LIVE production bundle."
        $foundLegacy = $true
    }
}

if ($foundLegacy) {
    Write-Fail "DEPLOYMENT VERIFICATION FAILED - live bundle still references a legacy backend."
    Write-Fail "Do not consider this deploy complete. Re-run this script, or purge manually and re-check."
    exit 1
}

Write-Ok "Verified: live bundle at https://$Domain contains none of: $LegacyHostPatterns"
Write-Host "`n===== DEPLOY COMPLETE =====" -ForegroundColor White
Write-Ok "$ProjectName -> https://$Domain (verified clean)"
Write-Host "===========================" -ForegroundColor White
