#!/bin/bash

# Connect a common script with functions and variables
source ./scripts/common.sh

# Log
sudo rm -f $HOME/RUDWEAK-daemon.log &>/dev/null
LOG_FILE="$HOME/RUDWEAK-daemon.log"
{
log "DATE: $DATE"
log "RUDWEAK $RUDWEAK_VERSION"
log "STEAMOS: $steamos_version"
log "MODEL: $MODEL"
log "BIOS: $BIOS_VERSION"
} >>"$LOG_FILE" 2>&1
green_msg '0%'

# Edit pacman.conf (MINIMAL - offline mode)
if [[ $steamos_version == "3.7" ]]; then
    sudo sed -i "s/main/$steamos_version/g" /etc/pacman.conf &>/dev/null
    sudo sed -i "s/3.5/$steamos_version/g" /etc/pacman.conf &>/dev/null
    sudo sed -i "s/3.6/$steamos_version/g" /etc/pacman.conf &>/dev/null
elif [[ $steamos_version == "3.8" ]]; then
    sudo sed -i "s/3.7/main/g" /etc/pacman.conf &>/dev/null
    sudo sed -i "s/3.5/main/g" /etc/pacman.conf &>/dev/null
    sudo sed -i "s/3.6/main/g" /etc/pacman.conf &>/dev/null
fi

# Disable network operations for pacman
sudo bash -c 'grep -q "^DisableDownloadTimeout" /etc/pacman.conf || sed -i "/^\[options\]/a DisableDownloadTimeout" /etc/pacman.conf'

green_msg '10%'

# OFFLINE MODE - Install from local packages
log "INSTALL DEPS (LOCAL PACKAGES)" >> "$LOG_FILE" 2>&1
sudo pacman -U --noconfirm ./packages/fmt-11.1.1-2-x86_64.pkg.tar.zst >> "$LOG_FILE" 2>&1
green_msg '20%'
sudo pacman -U --noconfirm ./packages/spdlog-1.15.0-2-x86_64.pkg.tar.zst >> "$LOG_FILE" 2>&1
green_msg '30%'

log "GLIBC ALREADY INSTALLED" >> "$LOG_FILE" 2>&1
green_msg '40%'

# Ananicy-cpp install (LOCAL PACKAGES)
log "INSTALL ANANICY-CPP (LOCAL PACKAGE)" >> "$LOG_FILE" 2>&1
sudo systemctl disable --now scx &>/dev/null
sudo systemctl mask scx &>/dev/null
green_msg '50%'
sudo pacman -Rdd --noconfirm ananicy-cpp cachyos-ananicy-rules-git >> "$LOG_FILE" 2>&1
green_msg '60%'
sudo pacman -U --noconfirm ./packages/ananicy-cpp-1.1.1-7-x86_64.pkg.tar.zst >> "$LOG_FILE" 2>&1
green_msg '70%'
sudo systemctl unmask ananicy-cpp &>/dev/null
sudo systemctl enable --now ananicy-cpp >> "$LOG_FILE" 2>&1
green_msg '80%'

# Install ananicy-rules (EXTRACT DIRECTLY - pacman -U hangs)
sudo rm -rf /etc/ananicy.d/{*,.*} &>/dev/null
log "INSTALL RULES ANANICY (EXTRACT DIRECTLY)" >> "$LOG_FILE" 2>&1
CURRENT_DIR=$(pwd)
cd /tmp
tar --use-compress-program=unzstd -xf "$CURRENT_DIR/packages/$ANANICY_PKG" >> "$LOG_FILE" 2>&1
sudo cp -r /tmp/etc/ananicy.d/* /etc/ananicy.d/ >> "$LOG_FILE" 2>&1
rm -rf /tmp/etc >> "$LOG_FILE" 2>&1
cd "$CURRENT_DIR"
green_msg '90%'
sudo systemctl restart ananicy-cpp >> "$LOG_FILE" 2>&1
green_msg '100%'
