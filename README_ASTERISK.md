# 📞 Asterisk 22 - Автоматическая установка

Полный скрипт установки Asterisk 22 на Ubuntu/Debian сервер.

## 🚀 Быстрый старт ()

### 1. Скачать скрипт

```bash
wget https://your-server.com/install_asterisk.sh
# Или скопировать файл на сервер
```

### 2. Сделать исполняемым

```bash
chmod +x install_asterisk.sh
```

### 3. Запустить установку

```bash
sudo ./install_asterisk.sh
```

⏱️ **Время установки:** 15-30 минут (зависит от сервера)

---

## 📋 Что делает скрипт

1. ✅ Обновляет систему
2. ✅ Устанавливает зависимости
3. ✅ Скачивает Asterisk 22
4. ✅ Компилирует с PJPROJECT (для SIP/VoIP)
5. ✅ Устанавливает примеры конфигурации
6. ✅ Создает пользователя asterisk
7. ✅ Настраивает systemd
8. ✅ Запускает Asterisk
9. ✅ Включает автозапуск при перезагрузке

---

## 🔧 Управление Asterisk

### Базовые команды

```bash
# Статус
sudo systemctl status asterisk

# Запуск
sudo systemctl start asterisk

# Остановка
sudo systemctl stop asterisk

# Перезапуск
sudo systemctl restart asterisk

# Автозапуск при перезагрузке
sudo systemctl enable asterisk

# Отключить автозапуск
sudo systemctl disable asterisk
```

### Консоль Asterisk

```bash
# Подключиться к консоли (CLI)
sudo asterisk -rvvv

# Команды в консоли:
core show version       # Версия
core show channels      # Активные каналы
pjsip show endpoints    # SIP точки
core reload             # Перезагрузить конфиг
core restart now        # Перезапуск
exit                    # Выход (Ctrl+C)
```

### Логи

```bash
# Основные логи
sudo tail -f /var/log/asterisk/messages

# Все логи
sudo tail -f /var/log/asterisk/full

# Debug
sudo tail -f /var/log/asterisk/debug
```

---

## 📁 Важные директории

```
/etc/asterisk/          # Конфигурационные файлы
/var/lib/asterisk/      # Звуковые файлы, база данных
/var/log/asterisk/      # Логи
/var/spool/asterisk/    # Временные файлы, voicemail
/usr/lib/asterisk/      # Модули
```

---

## ⚙️ Основные конфигурационные файлы

```
/etc/asterisk/pjsip.conf         # SIP настройки
/etc/asterisk/extensions.conf    # Диалплан (логика звонков)
/etc/asterisk/voicemail.conf     # Голосовая почта
/etc/asterisk/manager.conf       # AMI (API для управления)
/etc/asterisk/http.conf          # HTTP/WebSocket (для WebRTC)
/etc/asterisk/rtp.conf           # RTP медиа настройки
```

---

## 🔥 Быстрая настройка SIP

### 1. Создать SIP endpoint

Редактируй `/etc/asterisk/pjsip.conf`:

```ini
[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060

[6001]
type=endpoint
context=from-internal
disallow=all
allow=ulaw
allow=alaw
auth=6001
aors=6001

[6001]
type=auth
auth_type=userpass
password=secret123
username=6001

[6001]
type=aor
max_contacts=1
```

### 2. Создать диалплан

Редактируй `/etc/asterisk/extensions.conf`:

```ini
[from-internal]
exten => 100,1,Answer()
exten => 100,n,Playback(hello-world)
exten => 100,n,Hangup()

exten => _6XXX,1,Dial(PJSIP/${EXTEN},30)
exten => _6XXX,n,Hangup()
```

### 3. Перезагрузить конфиг

```bash
sudo asterisk -rx "core reload"
```

---

## 🌐 WebRTC настройка

### 1. Включить HTTP/WebSocket

Редактируй `/etc/asterisk/http.conf`:

```ini
[general]
enabled=yes
bindaddr=0.0.0.0
bindport=8088
tlsenable=yes
tlsbindaddr=0.0.0.0:8089
tlscertfile=/etc/asterisk/keys/asterisk.pem
tlsprivatekey=/etc/asterisk/keys/asterisk.key
```

### 2. Настроить WebRTC endpoint

В `/etc/asterisk/pjsip.conf`:

```ini
[transport-wss]
type=transport
protocol=wss
bind=0.0.0.0:8089

[webrtc-client]
type=endpoint
context=from-internal
disallow=all
allow=opus
allow=ulaw
webrtc=yes
auth=webrtc-client
aors=webrtc-client

[webrtc-client]
type=auth
auth_type=userpass
password=webrtc123
username=webrtc-client

[webrtc-client]
type=aor
max_contacts=5
remove_existing=yes
```

---

## 🛠️ Решение проблем

### Asterisk не запускается

```bash
# Проверить логи
sudo journalctl -u asterisk -n 50

# Проверить ошибки в конфиге
sudo asterisk -cvvv
```

### Порты заняты

```bash
# Проверить порты
sudo netstat -tulpn | grep asterisk

# Освободить порты
sudo systemctl stop asterisk
sudo killall asterisk
sudo systemctl start asterisk
```

### Проблемы с правами

```bash
sudo chown -R asterisk:asterisk /etc/asterisk
sudo chown -R asterisk:asterisk /var/{lib,log,spool}/asterisk
```

---

## 🔐 Безопасность

### Firewall (UFW)

```bash
# Разрешить SIP
sudo ufw allow 5060/udp

# Разрешить RTP (медиа)
sudo ufw allow 10000:20000/udp

# Разрешить WebRTC
sudo ufw allow 8088/tcp
sudo ufw allow 8089/tcp
```

### Fail2Ban для защиты от брутфорса

```bash
sudo apt-get install fail2ban
```

Создай `/etc/fail2ban/jail.local`:

```ini
[asterisk]
enabled = true
port = 5060,5061
filter = asterisk
logpath = /var/log/asterisk/messages
maxretry = 5
bantime = 3600
```

---

## 📊 Системные требования

- **OS:** Ubuntu 20.04/22.04/24.04, Debian 10/11/12
- **RAM:** Минимум 1GB, рекомендуется 2GB+
- **CPU:** 1 core минимум, 2+ рекомендуется
- **Диск:** 2GB свободного места

---

## 🆘 Полезные ссылки

- [Официальная документация Asterisk](https://docs.asterisk.org/)
- [Asterisk Wiki](https://wiki.asterisk.org/)
- [PJSIP Configuration](https://wiki.asterisk.org/wiki/display/AST/Configuring+res_pjsip)
- [WebRTC Tutorial](https://wiki.asterisk.org/wiki/display/AST/WebRTC+tutorial+using+SIPML5)

---

## 📝 Лицензия

Asterisk распространяется под GPLv2 лицензией.

---

**Удачи с Asterisk! 🚀**
