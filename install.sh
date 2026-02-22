#!/bin/bash

# Переходим в директорию скрипта, откуда бы он ни был запущен
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Проверка структуры файлов
if [ ! -f "./packages/lang.sh" ] || [ ! -f "./scripts/common.sh" ]; then
    echo "ОШИБКА: Неправильная структура файлов!"
    echo "Убедитесь, что вы распаковали архив полностью и запускаете install.sh из корневой папки RUDWEAK."
    echo ""
    echo "Ожидаемая структура:"
    echo "  RUDWEAK/"
    echo "  ├── install.sh"
    echo "  ├── packages/"
    echo "  │   └── lang.sh"
    echo "  └── scripts/"
    echo "      └── common.sh"
    exit 1
fi

# Подключаем языки (формально, для совместимости)
source ./packages/lang.sh

# Подключаем базу (цвета, функции, ASCII)
source ./scripts/common.sh

# --- PACKAGES CONFIGURATION (НЕ ТРОГАТЬ!) ---
KERNEL_PKG="linux-charcoal-611-6.11.11.valve27-1-x86_64.pkg.tar.zst"
HEADERS_PKG="linux-charcoal-611-headers-6.11.11.valve27-1-x86_64.pkg.tar.zst"
GAMESCOPE_PKG="gamescope-3.16.14.5-1-SDWEAK.pkg.tar.zst"
VULKAN_PKG="vulkan-radeon-24.3.0-SDWEAK.pkg.tar.zst"
ANANICY_PKG="cachyos-ananicy-rules-git-latest-plus-SDWEAK.pkg.tar.zst"
# --------------------------------------------

# Проверка интернета и версии
msg_info "Проверка обновлений..."
if ping -c 1 8.8.8.8 &>/dev/null || ping -c 1 1.1.1.1 &>/dev/null; then
    LATEST_RELEASE=$(curl -s --max-time 5 https://api.github.com/repos/bobberdolle1/RUDWEAK/releases/latest)
    LATEST_VERSION=$(echo "$LATEST_RELEASE" | grep -m 1 '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    LOCAL_VERSION=$(echo "$RUDWEAK_VERSION" | awk '{print $1}')
    
    if [ ! -z "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "$LOCAL_VERSION" ]; then
        echo -e "${YELLOW}Доступна новая версия RUDWEAK: $LATEST_VERSION! У вас: $LOCAL_VERSION${NC}"
        read -p "Желаете скачать новую версию? [y/N]: " update_ans
        if [[ "$update_ans" =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Открываю ссылку на скачивание...${NC}"
            if command -v xdg-open &>/dev/null; then
                sudo -u $SUDO_USER xdg-open "https://github.com/bobberdolle1/RUDWEAK/releases/latest" 2>/dev/null || xdg-open "https://github.com/bobberdolle1/RUDWEAK/releases/latest" 2>/dev/null
            fi
            echo -e "${WHITE}Если браузер не открылся, перейдите по ссылке: https://github.com/bobberdolle1/RUDWEAK/releases/latest${NC}"
            echo -e "${RED}Завершение текущей установки.${NC}"
            exit 0
        fi
    else
        msg_ok "У вас актуальная версия."
    fi
else
    msg_warn "Нет интернета. Проверка обновлений пропущена."
fi

# Проверка прав суперпользователя
check_root
sudo steamos-readonly disable

# Проверка места (Защита от дурака)
check_disk_space() {
  local available_space=$(df /home | awk 'NR==2 {print $4}')
  if [ "$available_space" -lt 512000 ]; then
    msg_err "Мало места! Нужно минимум 500 МБ в /home."
    exit 1
  fi
}
check_disk_space

# Логирование
sudo rm -f "$HOME/RUDWEAK-install.log"
LOG_FILE="$HOME/RUDWEAK-install.log"

# --- ИНТЕРФЕЙС ---

draw_kremlin
echo -e "${BLUE}Добро пожаловать в установщик RUDWEAK v$RUDWEAK_VERSION${NC}"
echo -e "${WHITE}Дата сборки: $DATE${NC}"
echo -e "${WHITE}Устройство: ${YELLOW}$MODEL${NC}"

# Проверка совместимости
if [[ "$MODEL" != "Jupiter" && "$MODEL" != "Galileo" ]]; then
  msg_err "Устройство не опознано или не поддерживается!"
  sleep 5
  exit 1
fi

# Инициализация Pacman
echo ""
msg_info "Подготовка плацдарма..."
echo -ne "${WHITE}Настройка Pacman (Оффлайн режим)...${NC} "
sudo bash -c 'grep -q "^DisableDownloadTimeout" /etc/pacman.conf || sed -i "/^\[options\]/a DisableDownloadTimeout" /etc/pacman.conf' >> "$LOG_FILE" 2>&1 && echo -e "${GREEN}[ГОТОВО]${NC}" || echo -e "${RED}[СБОЙ]${NC}"

echo -ne "${WHITE}Инициализация ключей Pacman...${NC} "
(sudo pacman-key --init && sudo pacman-key --populate) >> "$LOG_FILE" 2>&1 && echo -e "${GREEN}[ГОТОВО]${NC}" || echo -e "${YELLOW}[ПРОПУЩЕНО]${NC}"

echo -ne "${WHITE}Очистка кэша от мусора...${NC} "
sudo rm -rf /home/.steamos/offload/var/cache/pacman/pkg/{*,.*} >> "$LOG_FILE" 2>&1 && echo -e "${GREEN}[ГОТОВО]${NC}" || echo -e "${YELLOW}[ПРОПУЩЕНО]${NC}"

echo -ne "${WHITE}Удаление блокировки БД...${NC} "
sudo rm -f /usr/lib/holo/pacmandb/db.lck >> "$LOG_FILE" 2>&1 && echo -e "${GREEN}[ГОТОВО]${NC}" || echo -e "${YELLOW}[ПРОПУЩЕНО]${NC}"

msg_info "Режим: ПОЛНОСТЬЮ ОФФЛАЙН (без загрузки из репозиториев)"

# Yet-tweak
echo ""
msg_info "Применяем базовые твики..."
echo -ne "${WHITE}Настройка прав доступа...${NC} "
sudo chmod 775 ./scripts/yet-tweak.sh >> "$LOG_FILE" 2>&1 && echo -e "${GREEN}[ГОТОВО]${NC}" || echo -e "${RED}[СБОЙ]${NC}"

echo -ne "${WHITE}Запуск скрипта оптимизации...${NC} "
sudo --preserve-env=HOME ./scripts/yet-tweak.sh >> "$LOG_FILE" 2>&1 && echo -e "${GREEN}[ГОТОВО]${NC}" || echo -e "${RED}[СБОЙ]${NC}"

# Ananicy-cpp (Демон)
echo ""
msg_info "Установка планировщика процессов..."
echo -ne "${WHITE}Подготовка демона Ananicy...${NC} "
sudo chmod 775 ./scripts/daemon-install.sh >> "$LOG_FILE" 2>&1 && echo -e "${GREEN}[ГОТОВО]${NC}" || echo -e "${RED}[СБОЙ]${NC}"

echo -ne "${WHITE}Инъекция правил приоритета...${NC} "
sudo --preserve-env=HOME ANANICY_PKG="$ANANICY_PKG" ./scripts/daemon-install.sh >> "$LOG_FILE" 2>&1 && echo -e "${GREEN}[ГОТОВО]${NC}" || echo -e "${RED}[СБОЙ]${NC}"

# Sysctl & Services
echo ""
msg_info "Конфигурация ядра..."
sudo rm -f $HOME/.local/tweak/RUDWEAK.sh
sudo mkdir -p $HOME/.local/tweak/
sudo cp -f ./packages/RUDWEAK.sh $HOME/.local/tweak/RUDWEAK.sh
sudo cp -f ./packages/tweak.service /etc/systemd/system/tweak.service
sudo chmod 777 $HOME/.local/tweak/RUDWEAK.sh

echo -ne "${WHITE}Активация RUDWEAK сервиса...${NC} "
sudo systemctl enable --now tweak.service >> "$LOG_FILE" 2>&1 && echo -e "${GREEN}[ГОТОВО]${NC}" || echo -e "${RED}[СБОЙ]${NC}"

# I/O Schedulers
sudo cp ./packages/60-ioschedulers.rules /etc/udev/rules.d/60-ioschedulers.rules
msg_ok "I/O планировщики обновлены"

# ZRAM (SKIP INSTALL - just copy config)
sudo cp -f ./packages/zram-generator.conf /usr/lib/systemd/zram-generator.conf &>/dev/null || true
sudo systemctl restart systemd-zram-setup@zram0 &>/dev/null || true
msg_ok "ZRAM конфигурация обновлена"

# --- ИНТЕРАКТИВНОЕ МЕНЮ ---
clear
draw_anime_menu

# Frametime Fix (ТОЛЬКО LCD/JUPITER)
if [ "$MODEL" = "Jupiter" ]; then
    echo -e "${YELLOW}>> ФИКС ФРЕЙМТАЙМА (LCD)${NC}"
    read -p "Установить Gamescope фикс? [Y/n]: " answer
    if [[ "$answer" =~ ^[Yy]$ || -z "$answer" ]]; then
        echo -ne "${WHITE}Установка Gamescope...${NC} "
        if sudo pacman -U --noconfirm ./packages/$GAMESCOPE_PKG >> "$LOG_FILE" 2>&1; then
            echo -e "${GREEN}[ГОТОВО]${NC}"
        else
            echo -e "${RED}[СБОЙ]${NC}"
        fi
        
        echo -ne "${WHITE}Установка Vulkan драйверов...${NC} "
        if sudo pacman -U --noconfirm ./packages/$VULKAN_PKG >> "$LOG_FILE" 2>&1; then
            echo -e "${GREEN}[ГОТОВО]${NC}"
        else
            echo -e "${RED}[СБОЙ]${NC}"
        fi
        
        msg_info "lib32-vulkan-radeon пропущен (оффлайн режим)"
    else
        msg_warn "Пропущено пользователем."
    fi
    
    echo -e "${YELLOW}>> РАЗГОН ЭКРАНА 70Hz (LCD)${NC}"
    read -p "Активировать 70Hz? [Y/n]: " answer
    if [[ "$answer" =~ ^[Nn]$ ]]; then
        msg_warn "Оставлено 60Hz."
    else
        if ! grep -q "68, 69," "$LUA_PATH"; then
            sudo sed -z -i.bak "s/$ORIGINAL_STRING/$MODIFIED_STRING/" "$LUA_PATH"
        fi
        msg_ok "Экран разогнан до 70Hz!"
    fi
else
    msg_info "Steam Deck OLED (Galileo) обнаружен. Фиксы экрана пропущены (не требуются)."
fi

# Power Efficiency
echo -e "${YELLOW}>> ЭНЕРГОЭФФЕКТИВНОСТЬ CPU${NC}"
echo "Y = Экономия батареи (Инди/Эмуляторы) [по умолчанию]"
echo "N = Макс. производительность (AAA игры)"
read -p "Включить эконом-режим? [Y/n]: " answer
if [[ "$answer" =~ ^[Nn]$ ]]; then
    sudo systemctl disable --now energy.timer >> "$LOG_FILE" 2>&1 && msg_ok "Режим максимальной мощности" || msg_ok "Режим максимальной мощности (уже активен)"
else
    if [ -f "./packages/energy.service" ] && [ -f "./packages/energy.timer" ]; then
        sudo cp -f ./packages/energy.service /etc/systemd/system/energy.service
        sudo cp -f ./packages/energy.timer /etc/systemd/system/energy.timer
        sudo systemctl enable --now energy.timer >> "$LOG_FILE" 2>&1 && msg_ok "Режим экономии включен" || msg_err "Ошибка активации"
    else
        msg_err "Файлы energy.service/timer не найдены"
    fi
fi

# ЯДРО (Самое важное)
echo -e "${RED}>> ЯДРО LINUX CHARCOAL${NC}"
read -p "Установить оптимизированное ядро? [Y/n]: " answer
if [[ "$answer" =~ ^[Yy]$ || -z "$answer" ]]; then
    echo -ne "${WHITE}Удаление старого ядра...${NC} "
    sudo pacman -Rdd --noconfirm linux-neptune-611 >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[ГОТОВО]${NC}"
    else
        echo -e "${YELLOW}[ПРОПУЩЕНО]${NC}"
    fi
    
    echo -ne "${WHITE}Установка ядра Charcoal...${NC} "
    if sudo pacman -U --noconfirm --nodeps --overwrite '*' ./packages/$KERNEL_PKG >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}[ГОТОВО]${NC}"
        # Create proper mkinitcpio preset for charcoal kernel and fix line endings
        sudo cp -f ./packages/linux-charcoal-611.preset /etc/mkinitcpio.d/linux-charcoal-611.preset >> "$LOG_FILE" 2>&1
        sudo sed -i 's/\r$//' /etc/mkinitcpio.d/linux-charcoal-611.preset >> "$LOG_FILE" 2>&1
    else
        echo -e "${RED}[СБОЙ]${NC}"
        msg_err "Проверьте лог: $LOG_FILE"
    fi
    
    echo -ne "${WHITE}Установка Headers...${NC} "
    # Extract headers directly - pacman tries to download pahole dependency
    CURRENT_DIR=$(pwd)
    cd /tmp
    tar --use-compress-program=unzstd -xf "$CURRENT_DIR/packages/$HEADERS_PKG" >> "$LOG_FILE" 2>&1
    if [ -d "/tmp/usr/src" ]; then
        sudo cp -r /tmp/usr/src/* /usr/src/ >> "$LOG_FILE" 2>&1
        sudo cp -r /tmp/usr/lib/modules/*/build /usr/lib/modules/*/ >> "$LOG_FILE" 2>&1 || true
        rm -rf /tmp/usr >> "$LOG_FILE" 2>&1
        echo -e "${GREEN}[ГОТОВО]${NC}"
    else
        echo -e "${YELLOW}[ПРОПУЩЕНО]${NC}"
    fi
    cd "$CURRENT_DIR"
    
    echo -ne "${WHITE}Обновление GRUB...${NC} "
    if sudo grub-mkconfig -o $GRUB_CFG >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}[ГОТОВО]${NC}"
    else
        echo -e "${RED}[СБОЙ]${NC}"
    fi
    
    sudo cp -f ./packages/thp-shrinker.conf /usr/lib/tmpfiles.d/thp-shrinker.conf
else
    msg_warn "Оставлено стоковое ядро."
fi

# GPU Optimizations
echo -e "${RED}>> GPU ОПТИМИЗАЦИИ${NC}"
read -p "Применить твики видеокарты? [Y/n]: " answer
if [[ "$answer" =~ ^[Yy]$ || -z "$answer" ]]; then
    echo "options gpu_sched sched_policy=0" | sudo tee /etc/modprobe.d/amdgpu.conf &>/dev/null
    echo "options amdgpu mes=1 moverate=128 uni_mes=1 lbpw=0 mes_kiq=1" | sudo tee -a /etc/modprobe.d/amdgpu.conf &>/dev/null
    msg_ok "GPU разогнан (программно)."
fi

# Финал
echo ""
echo -ne "${WHITE}Генерация initramfs...${NC} "
# Only run if charcoal kernel is installed and preset exists
if [ -d "/usr/lib/modules/6.11.11-valve27-1-charcoal-611-g60ef8556a811-dirty" ] && [ -f "/etc/mkinitcpio.d/linux-charcoal-611.preset" ]; then
    if sudo mkinitcpio -p linux-charcoal-611 >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}[ГОТОВО]${NC}"
    else
        echo -e "${YELLOW}[ПРОПУЩЕНО - есть ошибки]${NC}"
    fi
else
    echo -e "${YELLOW}[ПРОПУЩЕНО - preset не найден]${NC}"
fi

echo -ne "${WHITE}Финализация GRUB...${NC} "
if sudo grub-mkconfig -o $GRUB_CFG >> "$LOG_FILE" 2>&1; then
    echo -e "${GREEN}[ГОТОВО]${NC}"
else
    echo -e "${RED}[СБОЙ]${NC}"
fi

echo -ne "${WHITE}Уборка мусора...${NC} "
if sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1; then
    echo -e "${GREEN}[ГОТОВО]${NC}"
else
    echo -e "${RED}[СБОЙ]${NC}"
fi

# Создание ярлыка для удаления
msg_info "Создание ярлыка удаления на Рабочем столе..."
UNINSTALL_DESKTOP="$HOME/Desktop/Удалить-RUDWEAK.desktop"
RUDWEAK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/Desktop" 2>/dev/null
cat <<EOF > "$UNINSTALL_DESKTOP"
[Desktop Entry]
Name=Удалить RUDWEAK
Comment=Удаление RUDWEAK и возврат к стоку
Exec=konsole -e bash -c 'cd "$RUDWEAK_DIR" && chmod +x ./uninstall.sh && sudo bash ./uninstall.sh; read -p "Нажмите Enter для выхода..."'
Icon=steamdeck-gaming-return
Terminal=false
Type=Application
Categories=System;Settings;
EOF
chmod +x "$UNINSTALL_DESKTOP" 2>/dev/null

clear
echo -e "${GREEN}"
echo "       __         __"
echo "      /  \.-\"\"\"-./  \\"
echo "           -   -    "
echo "     /|   o   o   |\\"
echo "      \  .-'''-.  /"
echo "       '-\__Y__/-'"
echo "         \`---\`"
echo ""
echo -e "${RED}RUDWEAK УСТАНОВЛЕН!${NC}"
echo -e "${WHITE}Система оптимизирована.${NC}"
echo -e "${BLUE}Перезагрузка...${NC}"
echo ""

read -p "Нажмите ENTER для перезагрузки в НОВЫЙ МИР..."
sudo reboot
