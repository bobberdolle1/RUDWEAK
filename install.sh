#!/bin/bash

# Переходим в директорию скрипта, откуда бы он ни был запущен
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

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
run_with_bar "Инициализация ключей Pacman..." "sudo pacman-key --init && sudo pacman-key --populate"
run_with_bar "Очистка кэша от мусора..." "sudo rm -rf /home/.steamos/offload/var/cache/pacman/pkg/{*,.*}"
# Оффлайн режим - фейковый синк для галочки, ошибки игнорируем
run_with_bar "Проверка локальных репозиториев..." "sudo pacman -Sy || true"

# Установка зависимостей
run_with_bar "Установка системных утилит..." "sudo pacman -S --noconfirm sed"

# Yet-tweak
echo ""
msg_info "Применяем базовые твики..."
run_with_bar "Настройка прав доступа..." "sudo chmod 775 ./scripts/yet-tweak.sh"
run_with_bar "Запуск скрипта оптимизации..." "sudo --preserve-env=HOME ./scripts/yet-tweak.sh"

# Ananicy-cpp (Демон)
echo ""
msg_info "Установка планировщика процессов..."
run_with_bar "Подготовка демона Ananicy..." "sudo chmod 775 ./scripts/daemon-install.sh"
# Передаем переменную ANANICY_PKG внутрь скрипта
run_with_bar "Инъекция правил приоритета..." "sudo --preserve-env=HOME ANANICY_PKG=\"$ANANICY_PKG\" ./scripts/daemon-install.sh"

# Sysctl & Services
echo ""
msg_info "Конфигурация ядра..."
sudo rm -f $HOME/.local/tweak/RUDWEAK.sh
sudo mkdir -p $HOME/.local/tweak/
sudo cp -f ./packages/RUDWEAK.sh $HOME/.local/tweak/RUDWEAK.sh
sudo cp -f ./packages/tweak.service /etc/systemd/system/tweak.service
sudo chmod 777 $HOME/.local/tweak/RUDWEAK.sh
run_with_bar "Активация RUDWEAK сервиса..." "sudo systemctl enable --now tweak.service"

# I/O Schedulers
sudo cp ./packages/60-ioschedulers.rules /etc/udev/rules.d/60-ioschedulers.rules
msg_ok "I/O планировщики обновлены"

# ZRAM
run_with_bar "Накачка ZRAM генератора..." "sudo pacman -S --noconfirm --needed holo-zram-swap zram-generator && sudo cp -f ./packages/zram-generator.conf /usr/lib/systemd/zram-generator.conf && sudo systemctl restart systemd-zram-setup@zram0"

# --- ИНТЕРАКТИВНОЕ МЕНЮ ---
clear
draw_anime_menu

# Frametime Fix (ТОЛЬКО LCD/JUPITER)
if [ "$MODEL" = "Jupiter" ]; then
    echo -e "${YELLOW}>> ФИКС ФРЕЙМТАЙМА (LCD)${NC}"
    read -p "Установить Gamescope фикс? [Y/n]: " answer
    if [[ "$answer" =~ ^[Yy]$ || -z "$answer" ]]; then
        run_with_bar "Установка Gamescope..." "sudo pacman -U --noconfirm ./packages/$GAMESCOPE_PKG"
        run_with_bar "Установка Vulkan драйверов..." "sudo pacman -U --noconfirm ./packages/$VULKAN_PKG"
        run_with_bar "Библиотеки 32-bit..." "sudo pacman -S --noconfirm --needed lib32-vulkan-radeon"
    else
        msg_warn "Пропущено пользователем."
    fi
    
    echo -e "${YELLOW}>> РАЗГОН ЭКРАНА 70Hz (LCD)${NC}"
    read -p "Активировать 70Hz? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        if ! grep -q "68, 69," "$LUA_PATH"; then
            sudo sed -z -i.bak "s/$ORIGINAL_STRING/$MODIFIED_STRING/" "$LUA_PATH"
        fi
        msg_ok "Экран разогнан!"
    else
        msg_warn "Оставлено 60Hz."
    fi
else
    msg_info "Steam Deck OLED (Galileo) обнаружен. Фиксы экрана пропущены (не требуются)."
fi

# Power Efficiency
echo -e "${YELLOW}>> ЭНЕРГОЭФФЕКТИВНОСТЬ CPU${NC}"
echo "N = Макс. производительность (AAA игры)"
echo "Y = Экономия батареи (Инди/Эмуляторы)"
read -p "Включить эконом-режим? [y/N]: " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    run_with_bar "Включение режима экономии..." "sudo systemctl enable --now energy.timer"
else
    run_with_bar "Включение режима МАКСИМАЛЬНОЙ МОЩНОСТИ..." "sudo systemctl disable --now energy.timer"
fi

# ЯДРО (Самое важное)
echo -e "${RED}>> ЯДРО LINUX CHARCOAL${NC}"
read -p "Установить оптимизированное ядро? [Y/n]: " answer
if [[ "$answer" =~ ^[Yy]$ || -z "$answer" ]]; then
    run_with_bar "Удаление старого ядра..." "sudo pacman -R --noconfirm linux-neptune-611 linux-neptune-611-headers || true"
    run_with_bar "Установка ядра Charcoal..." "sudo pacman -U --noconfirm ./packages/$KERNEL_PKG"
    run_with_bar "Установка Headers..." "sudo pacman -U --noconfirm ./packages/$HEADERS_PKG"
    run_with_bar "Обновление GRUB..." "sudo grub-mkconfig -o $GRUB_CFG"
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
run_with_bar "Генерация initramfs..." "sudo mkinitcpio -P"
run_with_bar "Финализация GRUB..." "sudo grub-mkconfig -o $GRUB_CFG"
run_with_bar "Уборка мусора..." "sudo systemctl daemon-reload"

draw_final_boss

read -p "Нажмите ENTER для перезагрузки в НОВЫЙ МИР..."
sudo reboot
