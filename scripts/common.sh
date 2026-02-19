#!/bin/bash

export BACKUP_DIR="$HOME/rudweak_backup"
export steamos_version=$(cat /etc/os-release | grep -i version_id | cut -d "=" -f2 | cut -d "." -f1,2)
export MODEL=$(cat /sys/class/dmi/id/board_name)
export BIOS_VERSION=$(cat /sys/class/dmi/id/bios_version)
export DATE=$(date '+%T %d.%m.%Y')
# ШАГ 1: Даунгрейд версии до релизной 1.1
export RUDWEAK_VERSION="1.1 Z-EDITION" 

export LUA_PATH="/usr/share/gamescope/scripts/00-gamescope/displays/valve.steamdeck.lcd.lua"
export MODIFIED_STRING="58, 59,\n        60, 61, 62, 63, 64, 65, 66, 67, 68, 69,\n        70"
export ORIGINAL_STRING="58, 59,\n        60"
export GRUB="/etc/default/grub"
export GRUB_CFG="/boot/efi/EFI/steamos/grub.cfg"

# ШАГ 2: Импортозамещенная палитра (Цвета Флага РФ + Статусы)
RED='\033[1;31m'
WHITE='\033[1;37m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Функции вывода
msg_info() { echo -e "${BLUE}[ИНФО]${NC} $1"; }
msg_ok()   { echo -e "${GREEN}[УСПЕХ]${NC} $1"; }
msg_warn() { echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"; }
msg_err()  { echo -e "${RED}[ОШИБКА]${NC} $1"; }
log() { echo "[LOG] --- $1"; }

# ШАГ 3: Эпичные ASCII-арты

draw_kremlin() {
    clear
    echo -e "${RED}
             |
           __|__
           |   |${NC}
         ${RED}__|___|__${NC}
        ${RED}|  ${YELLOW}* ${RED} ${YELLOW}* ${RED}  |${NC}   ${WHITE}R U D W E A K${NC}
        ${RED}|_________|${NC}   ${BLUE}v$RUDWEAK_VERSION${NC}
        ${RED}| ${WHITE}_ ${BLUE}_ ${RED}| ${WHITE}_ ${BLUE}_ ${RED}|${NC}   ${RED}ИМПОРТОЗАМЕЩЕНИЕ STEAM DECK${NC}
       ${RED}/|____|____|\ ${NC}
      ${RED}/_____________\ ${NC}
      ${WHITE}|||||||||||||||${NC}
      ${BLUE}|||||||||||||||${NC}
      ${RED}|||||||||||||||${NC}
    "
}

draw_anime_menu() {
    echo -e "${CYAN}
      /\\_/\\  ${YELLOW}(Настройка)${CYAN}
     ( o.o )  ${WHITE}Готов прокачать твой Deck?${CYAN}
      > ^ <   ${WHITE}Выбирай мудро, товарищ!${CYAN}
     /  |  \\ 
    |___|___|
    ${NC}"
}

draw_final_boss() {
    clear
    echo -e "${GREEN}
      🐻 ${RED}RUDWEAK УСТАНОВЛЕН!${GREEN} 🐻

          / 🕶️ \\
        (   💪   )  <-- Лидер Оптимизации
       /|_______|\\
      / /       \ \\
     /_/         \_\ 
    
    ${WHITE}ГОЙДА! СИСТЕМА ОПТИМИЗИРОВАНА!${NC}
    ${BLUE}Перезагрузка неизбежна...${NC}
    "
}

# ШАГ 4: Прогресс-бар "Загрузка Импортозамещения"
# Использование: run_with_bar "Текст" "Команда"
run_with_bar() {
    local text="$1"
    local command="$2"
    local delay=0.1

    # Запускаем команду в фоне, весь вывод в лог
    eval "$command" >> "$LOG_FILE" 2>&1 &
    local pid=$!

    echo -ne "${WHITE}$text${NC} "
    
    # Спиннер пока процесс жив
    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\b${BLUE}${spin:$i:1}${NC}"
        sleep $delay
    done
    wait $pid
    local exit_code=$?

    # Стираем спиннер и пишем статус
    printf "\b"
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}[ГОТОВО]${NC}"
    else
        echo -e "${RED}[СБОЙ]${NC}"
        msg_err "Произошла ошибка. Проверьте лог: $LOG_FILE"
        # Не выходим, чтобы не ломать весь скрипт из-за мелкой ошибки, но предупреждаем
    fi
}

# Root check
check_root() {
if [ "$(id -u)" != "0" ]; then
  msg_err "Этот скрипт должен быть запущен от имени root (sudo)."
  exit 1
fi
}

# Functions for backup (legacy but kept for compatibility)
backup_file() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
      mkdir -p "$BACKUP_DIR"
      cp ./packages/grub-stock "$BACKUP_DIR/grub.bak"
      local backup_path="$BACKUP_DIR/$(basename "$file_path").bak"
      if [[ ! -f "$backup_path" ]]; then
        sudo cp -f "$file_path" "$backup_path"
      fi
    fi
}

restore_file() {
  local file_path="$1"
  local backup_path="$BACKUP_DIR/$(basename "$file_path").bak"

  if [[ -f "$backup_path" ]]; then
    sudo cp -f "$backup_path" "$file_path"
  fi
}

# Localized text fallback
print_logo() {
    draw_kremlin
}
