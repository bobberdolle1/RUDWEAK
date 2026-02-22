#!/usr/bin/env bash
#===============================================================================
# RUDWEAK - Network Test Utility
# Утилита для тестирования качества интернет-соединения
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# ANSI Colors
#-------------------------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
readonly NETWORK_TIMEOUT=5
readonly TEST_URLS=("https://github.com" "https://1.1.1.1" "https://8.8.8.8")

#-------------------------------------------------------------------------------
# Main Test Function
#-------------------------------------------------------------------------------
test_network() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${CYAN}RUDWEAK - Network Diagnostics${NC}                         ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} curl не установлен."
        echo -e "${YELLOW}[INFO]${NC} Установите curl: sudo pacman -S curl"
        return 1
    fi
    
    echo -e "${CYAN}[INFO]${NC} Тестирование соединения с таймаутом ${NETWORK_TIMEOUT}s..."
    echo ""
    
    local success_count=0
    local total_tests=${#TEST_URLS[@]}
    
    # Test each URL
    for url in "${TEST_URLS[@]}"; do
        echo -ne "${WHITE}Проверка ${url}...${NC} "
        
        local start_time=$(date +%s%3N)
        
        if curl --silent --fail --connect-timeout "$NETWORK_TIMEOUT" \
                --max-time "$NETWORK_TIMEOUT" --head "$url" &> /dev/null; then
            local end_time=$(date +%s%3N)
            local response_time=$((end_time - start_time))
            
            echo -e "${GREEN}[OK]${NC} (${response_time}ms)"
            ((success_count++))
        else
            echo -e "${RED}[FAIL]${NC}"
        fi
    done
    
    echo ""
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}Результаты: ${GREEN}${success_count}${NC}/${total_tests} успешных подключений${NC}"
    echo ""
    
    # Final verdict
    if [ $success_count -eq $total_tests ]; then
        echo -e "${GREEN}[ОТЛИЧНО]${NC} Интернет-соединение стабильно!"
        echo -e "${CYAN}[INFO]${NC} Рекомендуется: Онлайн-установка"
        return 0
    elif [ $success_count -gt 0 ]; then
        echo -e "${YELLOW}[ПРЕДУПРЕЖДЕНИЕ]${NC} Соединение нестабильно."
        echo -e "${CYAN}[INFO]${NC} Рекомендуется: Оффлайн-установка"
        return 1
    else
        echo -e "${RED}[ОШИБКА]${NC} Интернет недоступен."
        echo -e "${CYAN}[INFO]${NC} Требуется: Оффлайн-установка"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# Entry Point
#-------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}RUDWEAK${NC} Network Test Utility v1.0"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

test_network
exit_code=$?

echo ""
echo -e "${CYAN}[INFO]${NC} Тест завершен. Exit code: $exit_code"
echo ""

exit $exit_code
