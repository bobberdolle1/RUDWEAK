#!/bin/bash

# Переходим в директорию скрипта, откуда бы он ни был запущен
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Connect a common script with functions and variables
source ./scripts/common.sh

# Root check
check_root
sudo steamos-readonly disable

clear
# Logo
print_logo

# Compatibility check
if [[ "$MODEL" != "Jupiter" && "$MODEL" != "Galileo" ]]; then
  msg_err "RUDWEAK совместим только со Steam Deck!"
  sleep 5
  exit 1
fi

msg_warn "Удаление RUDWEAK..."
echo ""

# Ananicy-cpp
echo -ne "${WHITE}Удаление Ananicy-cpp...${NC} "
sudo systemctl disable --now ananicy-cpp &>/dev/null
sudo pacman -Rdd --noconfirm ananicy-cpp cachyos-ananicy-rules-git &>/dev/null
sudo rm -rf /etc/ananicy.d/{*,.*} &>/dev/null
echo -e "${GREEN}[ГОТОВО]${NC}"

# Sysctl Tweaks
echo -ne "${WHITE}Удаление системных твиков...${NC} "
sudo systemctl disable --now tweak.service &>/dev/null
sudo rm -f $HOME/.local/tweak/RUDWEAK.sh &>/dev/null
sudo rm -f /etc/systemd/system/tweak.service &>/dev/null
sudo rm -rf $HOME/.local/tweak/ &>/dev/null
echo -e "${GREEN}[ГОТОВО]${NC}"

# I/O schedulers
echo -ne "${WHITE}Восстановление I/O планировщиков...${NC} "
sudo rm -f /etc/udev/rules.d/60-ioschedulers.rules &>/dev/null
echo -e "${GREEN}[ГОТОВО]${NC}"

# ZRAM Tweaks
echo -ne "${WHITE}Восстановление ZRAM...${NC} "
sudo rm -f /usr/lib/systemd/zram-generator.conf &>/dev/null
sudo systemctl restart systemd-zram-setup@zram0 &>/dev/null
echo -e "${GREEN}[ГОТОВО]${NC}"

# Overclock LCD to 70Hz
echo -ne "${WHITE}Восстановление частоты экрана...${NC} "
LUA_BAK_PATH="${LUA_PATH}.bak"
if [ -f "$LUA_BAK_PATH" ]; then
  sudo mv "$LUA_BAK_PATH" "$LUA_PATH" &>/dev/null
else
  sudo sed -z -i "s/$MODIFIED_STRING/$ORIGINAL_STRING/" "$LUA_PATH" &>/dev/null
fi
echo -e "${GREEN}[ГОТОВО]${NC}"

# Power efficiency priority
echo -ne "${WHITE}Удаление энергосбережения...${NC} "
sudo systemctl disable --now energy.timer &>/dev/null
sudo rm -f /etc/systemd/system/energy.service &>/dev/null
sudo rm -f /etc/systemd/system/energy.timer &>/dev/null
echo -e "${GREEN}[ГОТОВО]${NC}"

# Kernel
echo -ne "${WHITE}Удаление ядра Charcoal...${NC} "
sudo pacman -Rdd --noconfirm linux-charcoal-611 linux-charcoal-611-headers &>/dev/null
sudo rm -f /usr/lib/tmpfiles.d/thp-shrinker.conf &>/dev/null
sudo rm -f /etc/mkinitcpio.d/linux-charcoal-611.preset &>/dev/null
sudo rm -f /etc/mkinitcpio-charcoal.conf &>/dev/null
echo -e "${GREEN}[ГОТОВО]${NC}"

# AMDGPU optimization
echo -ne "${WHITE}Удаление GPU твиков...${NC} "
sudo rm -f /etc/modprobe.d/amdgpu.conf &>/dev/null
echo -e "${GREEN}[ГОТОВО]${NC}"

# Yet-tweak restore
echo -ne "${WHITE}Восстановление конфигов...${NC} "
restore_file "$GRUB" &>/dev/null
sudo rm -f /etc/tmpfiles.d/mglru.conf &>/dev/null
sudo rm -f /etc/security/limits.d/memlock.conf &>/dev/null
sudo sed -i -e 's/,noatime//' /etc/fstab &>/dev/null
sudo rm -f /etc/modprobe.d/usbhid.conf &>/dev/null
restore_file /usr/lib/sysctl.d/50-coredump.conf &>/dev/null
restore_file /usr/lib/sysctl.d/20-sched.conf &>/dev/null
restore_file /usr/lib/sysctl.d/60-crash-hook.conf &>/dev/null
echo -e "${GREEN}[ГОТОВО]${NC}"

# Final
echo ""
echo -ne "${WHITE}Обновление GRUB...${NC} "
sudo grub-mkconfig -o "$GRUB_CFG" &>/dev/null && echo -e "${GREEN}[ГОТОВО]${NC}" || echo -e "${YELLOW}[ПРОПУЩЕНО]${NC}"

echo -ne "${WHITE}Обновление initramfs...${NC} "
sudo mkinitcpio -P &>/dev/null && echo -e "${GREEN}[ГОТОВО]${NC}" || echo -e "${YELLOW}[ПРОПУЩЕНО]${NC}"

echo -ne "${WHITE}Перезагрузка демонов...${NC} "
sudo systemctl daemon-reload &>/dev/null && echo -e "${GREEN}[ГОТОВО]${NC}"

# Remove desktop shortcut
rm -f "$HOME/Desktop/Удалить-RUDWEAK.desktop" &>/dev/null

echo ""
msg_ok "RUDWEAK удален!"
msg_warn "Требуется перезагрузка для применения изменений."
read -p "Перезагрузить сейчас? [Y/n]: " answer
if [[ "$answer" =~ ^[Yy]$ || -z "$answer" ]]; then
    sudo reboot
fi
