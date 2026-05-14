param(
    [switch]$Remote
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    param([string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed: git $($GitArgs -join ' ')"
    }
}

function Get-GitOutput {
    param([string[]]$GitArgs)
    $out = & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed: git $($GitArgs -join ' ')"
    }
    return $out
}

if (-not (Test-Path ".gitmodules")) {
    throw "Please run this script from repository root."
}

Write-Host "==> Syncing submodule config"
Invoke-Git -GitArgs @("submodule", "sync", "--", "openclaw")

$updateArgs = @(
    "-c", "protocol.version=2",
    "submodule", "update",
    "--init",
    "--filter=blob:none"
)

if ($Remote) {
    $updateArgs += "--remote"
}

$shallowArgs = $updateArgs + @("--depth", "1", "--recommend-shallow", "--", "openclaw")
$fallbackArgs = $updateArgs + @("--", "openclaw")

Write-Host "==> Updating openclaw (shallow + blobless)"
try {
    Invoke-Git -GitArgs $shallowArgs
} catch {
    Write-Warning "Shallow submodule update failed."

    if ($Remote) {
        Write-Warning "Fallback: fetch latest remote main with blobless clone."
        Invoke-Git -GitArgs @("-C", "openclaw", "fetch", "--filter=blob:none", "--depth", "1", "origin", "main")
        Invoke-Git -GitArgs @("-C", "openclaw", "checkout", "--detach", "FETCH_HEAD")
    } else {
        Write-Warning "Fallback: fetch pinned commit from superproject."
        $target = (Get-GitOutput -GitArgs @("ls-tree", "HEAD", "openclaw") | Select-Object -First 1).Split()[2]
        if (-not $target) {
            throw "Unable to read pinned openclaw commit from superproject."
        }

        Invoke-Git -GitArgs @("-C", "openclaw", "fetch", "--filter=blob:none", "--depth", "1", "origin", $target)
        Invoke-Git -GitArgs @("-C", "openclaw", "checkout", "--detach", $target)
        Invoke-Git -GitArgs $fallbackArgs
    }
}

Write-Host "==> Done"
Invoke-Git -GitArgs @("submodule", "status", "--", "openclaw")
