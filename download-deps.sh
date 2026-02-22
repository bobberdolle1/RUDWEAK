#!/bin/bash
# Download all dependencies for offline installation on Steam Deck

PACKAGES_DIR="./packages"
mkdir -p "$PACKAGES_DIR"

# Headers dependencies (142 MB total)
DEPS=(
    "clang-18.1.8-4.2"
    "clang-libs-18.1.8-4.2"
    "compiler-rt-18.1.8-1"
    "gcc-14.2.1+r134+gab884fffe3fc-2"
    "libisl-0.27-1"
    "libmpc-1.3.1-2"
    "lld-18.1.8-1"
    "llvm-18.1.8-5"
    "pahole-1:1.28-3"
    "polly-18.1.8-1"
)

echo "==> Downloading dependencies to $PACKAGES_DIR..."

cd "$PACKAGES_DIR" || exit 1

for pkg in "${DEPS[@]}"; do
    echo "Downloading: $pkg"
    sudo pacman -Sw --noconfirm "$pkg" 2>&1 | grep -v "warning:"
done

echo ""
echo "==> Download complete"
ls -lh *.pkg.tar.zst 2>/dev/null | tail -n +2 | wc -l | xargs echo "Total packages:"
du -sh . | cut -f1 | xargs echo "Total size:"

