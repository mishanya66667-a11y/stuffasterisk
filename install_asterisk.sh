#!/bin/bash

#############################################
# Скрипт установки Asterisk 22
# Автоматическая установка на Ubuntu/Debian
#############################################

set -e  # Остановка при ошибке

echo "=========================================="
echo "  Установка Asterisk 22"
echo "=========================================="
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для логирования
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Проверка sudo прав
if [ "$EUID" -ne 0 ]; then 
    error "Запустите скрипт с sudo!"
    echo "Используйте: sudo bash install_asterisk.sh"
    exit 1
fi

log "Обновление системы..."
apt-get update
apt-get upgrade -y

log "Установка базовых зависимостей..."
apt-get install -y wget build-essential git curl

log "Создание директории для установки..."
cd /usr/src
mkdir -p asterisk-install
cd asterisk-install

log "Скачивание Asterisk 22..."
wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz

log "Распаковка архива..."
tar -xvzf asterisk-22-current.tar.gz
cd asterisk-22*/

log "Установка зависимостей Asterisk..."
./contrib/scripts/install_prereq install

log "Конфигурация Asterisk с PJPROJECT..."
./configure --with-pjproject-bundled

log "Выбор модулей для установки..."
# Автоматический выбор базовых модулей
make menuselect.makeopts
menuselect/menuselect \
    --enable CORE-SOUNDS-EN-GSM \
    --enable MOH-OPSOUND-GSM \
    --enable EXTRA-SOUNDS-EN-GSM \
    menuselect.makeopts

log "Компиляция Asterisk (это может занять 10-20 минут)..."
make -j$(nproc)

log "Установка Asterisk..."
make install

log "Установка примеров конфигурации..."
make samples

log "Установка скриптов инициализации..."
make config

log "Создание пользователя asterisk..."
useradd -r -d /var/lib/asterisk -s /bin/bash asterisk 2>/dev/null || warning "Пользователь asterisk уже существует"

log "Настройка прав доступа..."
chown -R asterisk:asterisk /etc/asterisk
chown -R asterisk:asterisk /var/{lib,log,spool}/asterisk
chown -R asterisk:asterisk /usr/lib/asterisk

log "Настройка systemd для запуска от пользователя asterisk..."
sed -i 's/#User=asterisk/User=asterisk/' /lib/systemd/system/asterisk.service
sed -i 's/#Group=asterisk/Group=asterisk/' /lib/systemd/system/asterisk.service

log "Перезагрузка systemd..."
systemctl daemon-reload

log "Включение автозапуска Asterisk..."
systemctl enable asterisk

log "Запуск Asterisk..."
systemctl start asterisk

sleep 3

log "Проверка статуса Asterisk..."
systemctl status asterisk --no-pager

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Установка завершена!${NC}"
echo "=========================================="
echo ""
echo "Полезные команды:"
echo ""
echo "  Консоль Asterisk:    sudo asterisk -rvvv"
echo "  Статус:              sudo systemctl status asterisk"
echo "  Перезапуск:          sudo systemctl restart asterisk"
echo "  Остановка:           sudo systemctl stop asterisk"
echo "  Логи:                sudo tail -f /var/log/asterisk/messages"
echo ""
echo "Конфигурационные файлы: /etc/asterisk/"
echo ""
echo -e "${YELLOW}Важно:${NC} Asterisk запущен с базовой конфигурацией."
echo "Настройте /etc/asterisk/ под свои нужды!"
echo ""
