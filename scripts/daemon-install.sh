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
msg_ok '0%'

# Edit pacman.conf
if [[ $steamos_version == "3.7" ]]; then
    sudo sed -i "s/main/$steamos_version/g" /etc/pacman.conf &>/dev/null
    sudo sed -i "s/3.5/$steamos_version/g" /etc/pacman.conf &>/dev/null
    sudo sed -i "s/3.6/$steamos_version/g" /etc/pacman.conf &>/dev/null
elif [[ $steamos_version == "3.8" ]]; then
    sudo sed -i "s/3.7/main/g" /etc/pacman.conf &>/dev/null
    sudo sed -i "s/3.5/main/g" /etc/pacman.conf &>/dev/null
    sudo sed -i "s/3.6/main/g" /etc/pacman.conf &>/dev/null
fi

# Увеличиваем таймауты для pacman (сервера SteamOS в РФ работают очень медленно)
sudo sed -i 's/^#DisableDownloadTimeout/DisableDownloadTimeout/' /etc/pacman.conf &>/dev/null
sudo sed -i 's/^#XferCommand = \/usr\/bin\/curl -C - -f %u > %o/XferCommand = \/usr\/bin\/curl -C - -f --retry 3 --retry-delay 3 --speed-time 30 --speed-limit 1 -L %u > %o/' /etc/pacman.conf &>/dev/null
sudo pacman-key --init &>/dev/null
sudo pacman-key --populate &>/dev/null

msg_ok '10%'

# Install packages
log "INSTALL DEPS" >> "$LOG_FILE" 2>&1
sudo pacman -Sy --noconfirm spdlog fmt &>/dev/null
msg_ok '20%'
sudo pacman -S --noconfirm spdlog fmt >> "$LOG_FILE" 2>&1
msg_ok '30%'

log "INSTALL GLIBC" >> "$LOG_FILE" 2>&1
sudo pacman -S --noconfirm --needed glibc lib32-glibc holo-glibc-locales >> "$LOG_FILE" 2>&1
msg_ok '40%'

# Ananicy-cpp install
log "INSTALL ANANICY-CPP PACKAGES" >> "$LOG_FILE" 2>&1
sudo systemctl disable --now scx &>/dev/null
sudo systemctl mask scx &>/dev/null
msg_ok '50%'
sudo pacman -Rdd --noconfirm ananicy-cpp cachyos-ananicy-rules-git >> "$LOG_FILE" 2>&1
msg_ok '60%'
sudo pacman -S --noconfirm ananicy-cpp >> "$LOG_FILE" 2>&1
msg_ok '70%'
sudo systemctl unmask ananicy-cpp &>/dev/null
sudo systemctl enable --now ananicy-cpp >> "$LOG_FILE" 2>&1
msg_ok '80%'

# Install ananicy-rules
sudo rm -rf /etc/ananicy.d/{*,.*} &>/dev/null
log "INSTALL RULES ANANICY" >> "$LOG_FILE" 2>&1
sudo pacman -U "./packages/$ANANICY_PKG" --noconfirm >> "$LOG_FILE" 2>&1
msg_ok '90%'
sudo pacman -U "./packages/$ANANICY_PKG" --noconfirm >> "$LOG_FILE" 2>&1
sudo systemctl restart ananicy-cpp >> "$LOG_FILE" 2>&1
msg_ok '100%'
