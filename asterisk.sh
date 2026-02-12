#!/bin/bash

#############################################
# Asterisk - Управление сервером
# Быстрые команды для работы с Asterisk
#############################################

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Asterisk - Управление${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Использование: $0 [команда]"
    echo ""
    echo "Команды:"
    echo ""
    echo -e "  ${GREEN}start${NC}          Запустить Asterisk"
    echo -e "  ${RED}stop${NC}           Остановить Asterisk"
    echo -e "  ${YELLOW}restart${NC}        Перезапустить Asterisk"
    echo -e "  ${BLUE}status${NC}         Показать статус"
    echo -e "  ${GREEN}console${NC}        Открыть консоль (CLI)"
    echo -e "  ${BLUE}logs${NC}           Показать логи в реальном времени"
    echo -e "  ${GREEN}reload${NC}         Перезагрузить конфигурацию"
    echo -e "  ${YELLOW}version${NC}        Показать версию"
    echo -e "  ${GREEN}enable${NC}         Включить автозапуск"
    echo -e "  ${RED}disable${NC}        Отключить автозапуск"
    echo -e "  ${BLUE}info${NC}           Показать информацию о системе"
    echo ""
}

start_asterisk() {
    echo -e "${GREEN}[•] Запуск Asterisk...${NC}"
    sudo systemctl start asterisk
    sleep 2
    if sudo systemctl is-active --quiet asterisk; then
        echo -e "${GREEN}[✓] Asterisk запущен${NC}"
    else
        echo -e "${RED}[✗] Ошибка запуска${NC}"
    fi
}

stop_asterisk() {
    echo -e "${RED}[•] Остановка Asterisk...${NC}"
    sudo systemctl stop asterisk
    sleep 2
    if ! sudo systemctl is-active --quiet asterisk; then
        echo -e "${GREEN}[✓] Asterisk остановлен${NC}"
    else
        echo -e "${RED}[✗] Ошибка остановки${NC}"
    fi
}

restart_asterisk() {
    echo -e "${YELLOW}[•] Перезапуск Asterisk...${NC}"
    sudo systemctl restart asterisk
    sleep 2
    if sudo systemctl is-active --quiet asterisk; then
        echo -e "${GREEN}[✓] Asterisk перезапущен${NC}"
    else
        echo -e "${RED}[✗] Ошибка перезапуска${NC}"
    fi
}

show_status() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    sudo systemctl status asterisk --no-pager
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

open_console() {
    echo -e "${GREEN}[•] Открытие консоли Asterisk...${NC}"
    echo -e "${YELLOW}Для выхода нажмите Ctrl+C${NC}"
    echo ""
    sudo asterisk -rvvv
}

show_logs() {
    echo -e "${GREEN}[•] Логи Asterisk (Ctrl+C для выхода)${NC}"
    echo ""
    sudo tail -f /var/log/asterisk/messages
}

reload_config() {
    echo -e "${YELLOW}[•] Перезагрузка конфигурации...${NC}"
    sudo asterisk -rx "core reload"
    echo -e "${GREEN}[✓] Конфигурация перезагружена${NC}"
}

show_version() {
    echo -e "${BLUE}[•] Версия Asterisk:${NC}"
    sudo asterisk -rx "core show version"
}

enable_autostart() {
    echo -e "${GREEN}[•] Включение автозапуска...${NC}"
    sudo systemctl enable asterisk
    echo -e "${GREEN}[✓] Автозапуск включен${NC}"
}

disable_autostart() {
    echo -e "${RED}[•] Отключение автозапуска...${NC}"
    sudo systemctl disable asterisk
    echo -e "${GREEN}[✓] Автозапуск отключен${NC}"
}

show_info() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Информация о системе${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Версия
    echo -e "${YELLOW}Версия Asterisk:${NC}"
    sudo asterisk -rx "core show version" 2>/dev/null | head -1
    echo ""
    
    # Статус
    echo -e "${YELLOW}Статус:${NC}"
    if sudo systemctl is-active --quiet asterisk; then
        echo -e "${GREEN}● Запущен${NC}"
    else
        echo -e "${RED}○ Остановлен${NC}"
    fi
    echo ""
    
    # Автозапуск
    echo -e "${YELLOW}Автозапуск:${NC}"
    if sudo systemctl is-enabled --quiet asterisk 2>/dev/null; then
        echo -e "${GREEN}Включен${NC}"
    else
        echo -e "${RED}Отключен${NC}"
    fi
    echo ""
    
    # Активные каналы
    echo -e "${YELLOW}Активные каналы:${NC}"
    sudo asterisk -rx "core show channels" 2>/dev/null | grep "active channel" || echo "0"
    echo ""
    
    # SIP endpoints
    echo -e "${YELLOW}SIP endpoints:${NC}"
    sudo asterisk -rx "pjsip show endpoints" 2>/dev/null | grep "Endpoint:" | wc -l
    echo ""
    
    # Использование ресурсов
    echo -e "${YELLOW}Использование памяти:${NC}"
    ps aux | grep asterisk | grep -v grep | awk '{print $6/1024 " MB"}'
    echo ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Основная логика
case "$1" in
    start)
        start_asterisk
        ;;
    stop)
        stop_asterisk
        ;;
    restart)
        restart_asterisk
        ;;
    status)
        show_status
        ;;
    console|cli)
        open_console
        ;;
    logs)
        show_logs
        ;;
    reload)
        reload_config
        ;;
    version)
        show_version
        ;;
    enable)
        enable_autostart
        ;;
    disable)
        disable_autostart
        ;;
    info)
        show_info
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}Неизвестная команда: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
