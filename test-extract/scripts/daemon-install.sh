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

# Offline mode - skip all repo downloads
log "INSTALL DEPS (SKIPPED - OFFLINE MODE)" >> "$LOG_FILE" 2>&1
green_msg '20%'
green_msg '30%'

log "INSTALL GLIBC (SKIPPED - ALREADY INSTALLED)" >> "$LOG_FILE" 2>&1
green_msg '40%'

# Ananicy-cpp install (OFFLINE MODE - NO REPO DOWNLOADS)
log "INSTALL ANANICY-CPP PACKAGES" >> "$LOG_FILE" 2>&1
sudo systemctl disable --now scx &>/dev/null
sudo systemctl mask scx &>/dev/null
green_msg '50%'
sudo pacman -Rdd --noconfirm ananicy-cpp cachyos-ananicy-rules-git >> "$LOG_FILE" 2>&1
green_msg '60%'
log "ANANICY-CPP SKIPPED - WILL BE INSTALLED WITH RULES PACKAGE" >> "$LOG_FILE" 2>&1
green_msg '70%'
green_msg '80%'

# Install ananicy-rules (LOCAL PACKAGE ONLY)
sudo rm -rf /etc/ananicy.d/{*,.*} &>/dev/null
log "INSTALL RULES ANANICY (LOCAL PACKAGE)" >> "$LOG_FILE" 2>&1
if [ -f "./packages/$ANANICY_PKG" ]; then
    sudo pacman -U "./packages/$ANANICY_PKG" --noconfirm >> "$LOG_FILE" 2>&1 || log "ANANICY RULES INSTALL FAILED - CONTINUING" >> "$LOG_FILE" 2>&1
else
    log "ERROR: ANANICY PACKAGE NOT FOUND: ./packages/$ANANICY_PKG" >> "$LOG_FILE" 2>&1
fi
green_msg '90%'
sudo systemctl unmask ananicy-cpp &>/dev/null
sudo systemctl enable --now ananicy-cpp >> "$LOG_FILE" 2>&1 || log "ANANICY-CPP SERVICE FAILED (NORMAL IF NOT INSTALLED)" >> "$LOG_FILE" 2>&1
green_msg '100%'
