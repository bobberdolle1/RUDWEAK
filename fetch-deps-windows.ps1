# Download SteamOS packages directly from repository (Windows)

$PACKAGES_DIR = ".\packages"
New-Item -ItemType Directory -Force -Path $PACKAGES_DIR | Out-Null

$REPO_BASE = "https://archive.archlinux.org/packages"

# Package names for Arch Archive
$PACKAGES = @{
    "clang" = "c/clang/clang-18.1.8-4-x86_64.pkg.tar.zst"
    "clang-libs" = "c/clang/clang-libs-18.1.8-4-x86_64.pkg.tar.zst"
    "compiler-rt" = "c/compiler-rt/compiler-rt-18.1.8-1-x86_64.pkg.tar.zst"
    "gcc" = "g/gcc/gcc-14.2.1+r134+gab884fffe3fc-2-x86_64.pkg.tar.zst"
    "libisl" = "l/libisl/libisl-0.27-1-x86_64.pkg.tar.zst"
    "libmpc" = "l/libmpc/libmpc-1.3.1-2-x86_64.pkg.tar.zst"
    "lld" = "l/lld/lld-18.1.8-1-x86_64.pkg.tar.zst"
    "llvm" = "l/llvm/llvm-18.1.8-5-x86_64.pkg.tar.zst"
    "pahole" = "p/pahole/pahole-1.27-2-x86_64.pkg.tar.zst"
    "polly" = "p/polly/polly-18.1.8-1-x86_64.pkg.tar.zst"
}

Write-Host "==> Downloading Arch Linux packages to $PACKAGES_DIR..." -ForegroundColor Green

foreach ($pkg in $PACKAGES.GetEnumerator()) {
    $filename = Split-Path $pkg.Value -Leaf
    $url = "$REPO_BASE/$($pkg.Value)"
    $output = Join-Path $PACKAGES_DIR $filename
    
    if (Test-Path $output) {
        Write-Host "  [SKIP] $filename (already exists)" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "  [DOWN] $filename" -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $url -OutFile $output -ErrorAction Stop
        Write-Host "  [OK]   $filename" -ForegroundColor Green
    } catch {
        Write-Host "  [FAIL] $filename - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==> Download complete" -ForegroundColor Green
$count = (Get-ChildItem "$PACKAGES_DIR\*.pkg.tar.zst" | Measure-Object).Count
$size = (Get-ChildItem "$PACKAGES_DIR\*.pkg.tar.zst" | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "Total packages: $count" -ForegroundColor White
Write-Host "Total size: $([math]::Round($size, 2)) MB" -ForegroundColor White
