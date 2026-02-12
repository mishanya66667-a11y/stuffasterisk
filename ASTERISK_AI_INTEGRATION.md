# 🤖 Интеграция Asterisk с AI ассистентом (Ethera)

Как подключить твой голосовой ассистент к Asterisk для приема звонков.

## 🎯 Архитектура

```
Входящий звонок
      ↓
  Asterisk (SIP)
      ↓
  Python скрипт (AGI/AMI)
      ↓
  Groq (транскрипция)
      ↓
  LLM (ответ)
      ↓
  ElevenLabs (TTS)
      ↓
  Asterisk (воспроизведение)
```

---

## 📋 Способы интеграции

### Вариант 1: AGI (Asterisk Gateway Interface)
Простой, синхронный способ.

### Вариант 2: AMI (Asterisk Manager Interface)
Асинхронный, более гибкий.

### Вариант 3: ARI (Asterisk REST Interface)
Современный REST API подход (рекомендуется).

---

## 🚀 Вариант 1: AGI интеграция (самый простой)

### 1. Установить зависимости

```bash
sudo pip install pyst2 --break-system-packages
```

### 2. Создать AGI скрипт

`/var/lib/asterisk/agi-bin/ai_assistant.py`:

```python
#!/usr/bin/env python3
import sys
from asterisk.agi import AGI
import requests
import os
from groq import Groq
import base64

# Инициализация
agi = AGI()
groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))
ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY")
VOICE_ID = "21m00Tcm4TlvDq8ikWAM"

def transcribe_audio(audio_file):
    """Транскрибация через Groq"""
    with open(audio_file, 'rb') as f:
        trans = groq_client.audio.transcriptions.create(
            file=f,
            model="whisper-large-v3",
            language="ru"
        )
    return trans.text

def get_ai_response(text):
    """Получить ответ от LLM"""
    response = groq_client.chat.completions.create(
        messages=[
            {"role": "system", "content": "Ты Эфира - голосовой помощник"},
            {"role": "user", "content": text}
        ],
        model="llama-3.3-70b-versatile",
        temperature=0.8,
        max_tokens=150
    )
    return response.choices[0].message.content

def text_to_speech(text):
    """ElevenLabs TTS"""
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}"
    headers = {
        "xi-api-key": ELEVENLABS_API_KEY,
        "Content-Type": "application/json"
    }
    data = {
        "text": text,
        "model_id": "eleven_turbo_v2_5"
    }
    
    response = requests.post(url, json=data, headers=headers)
    
    # Сохранить аудио
    audio_path = "/tmp/ai_response.wav"
    with open(audio_path, 'wb') as f:
        f.write(response.content)
    
    return audio_path

def main():
    # Ответить на звонок
    agi.answer()
    
    # Приветствие
    agi.stream_file('hello-world')
    
    # Записать речь пользователя (5 секунд тишины = конец)
    agi.exec_command('Record', '/tmp/user_input.wav,5,30')
    
    # Транскрибировать
    user_text = transcribe_audio('/tmp/user_input.wav')
    agi.verbose(f"User said: {user_text}")
    
    # Получить ответ ИИ
    ai_response = get_ai_response(user_text)
    agi.verbose(f"AI response: {ai_response}")
    
    # Синтезировать речь
    audio_file = text_to_speech(ai_response)
    
    # Воспроизвести
    agi.stream_file(audio_file.replace('.wav', ''))
    
    # Завершить звонок
    agi.hangup()

if __name__ == '__main__':
    main()
```

### 3. Сделать исполняемым

```bash
sudo chmod +x /var/lib/asterisk/agi-bin/ai_assistant.py
sudo chown asterisk:asterisk /var/lib/asterisk/agi-bin/ai_assistant.py
```

### 4. Настроить Dialplan

`/etc/asterisk/extensions.conf`:

```ini
[from-pstn]
exten => s,1,Answer()
exten => s,n,Wait(1)
exten => s,n,AGI(ai_assistant.py)
exten => s,n,Hangup()

[from-internal]
exten => 777,1,Answer()
exten => 777,n,AGI(ai_assistant.py)
exten => 777,n,Hangup()
```

### 5. Перезагрузить Asterisk

```bash
sudo asterisk -rx "dialplan reload"
```

---

## 🔥 Вариант 2: Realtime WebSocket (через ARI)

Более продвинутый способ с real-time обработкой.

### 1. Установить библиотеки

```bash
sudo pip install ari websockets --break-system-packages
```

### 2. Включить ARI в Asterisk

`/etc/asterisk/ari.conf`:

```ini
[general]
enabled = yes
pretty = yes

[asterisk]
type = user
read_only = no
password = asterisk123
```

### 3. Создать ARI приложение

`/home/ubuntu/asterisk_ai_bridge.py`:

```python
#!/usr/bin/env python3
import ari
import os
import asyncio
from groq import Groq
import requests

# Подключение к ARI
client = ari.connect('http://localhost:8088', 'asterisk', 'asterisk123')

groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))

def on_start(channel, event):
    """Обработка входящего звонка"""
    print(f"Incoming call from {channel.json['caller']['number']}")
    
    # Ответить
    channel.answer()
    
    # Запись голоса
    recording = channel.record(name='user_recording', format='wav', maxSilenceSeconds=3)
    
def on_recording_finished(channel, event):
    """Когда запись завершена"""
    recording_name = event['recording']['name']
    
    # Транскрибировать
    with open(f'/var/spool/asterisk/recording/{recording_name}.wav', 'rb') as f:
        trans = groq_client.audio.transcriptions.create(
            file=f,
            model="whisper-large-v3",
            language="ru"
        )
    
    user_text = trans.text
    print(f"User: {user_text}")
    
    # Получить ответ ИИ
    response = groq_client.chat.completions.create(
        messages=[
            {"role": "system", "content": "Ты Эфира"},
            {"role": "user", "content": user_text}
        ],
        model="llama-3.3-70b-versatile",
        max_tokens=150
    )
    
    ai_text = response.choices[0].message.content
    print(f"AI: {ai_text}")
    
    # TTS
    # ... (аналогично предыдущему примеру)
    
    # Воспроизвести
    channel.play(media='sound:ai_response')
    
    # Завершить
    channel.hangup()

# Подписаться на события
client.on_channel_event('StasisStart', on_start)
client.on_channel_event('RecordingFinished', on_recording_finished)

# Запустить
client.run(apps='ai-assistant')
```

### 4. Настроить Dialplan для ARI

`/etc/asterisk/extensions.conf`:

```ini
[from-pstn]
exten => s,1,Answer()
exten => s,n,Stasis(ai-assistant)
exten => s,n,Hangup()
```

### 5. Запустить ARI приложение

```bash
python3 /home/ubuntu/asterisk_ai_bridge.py
```

---

## 📞 Настройка SIP транка (для реальных звонков)

### Подключение к SIP провайдеру (например, Twilio)

`/etc/asterisk/pjsip.conf`:

```ini
[twilio]
type=registration
transport=transport-udp
outbound_auth=twilio-auth
server_uri=sip:your-account.pstn.twilio.com
client_uri=sip:your-username@your-account.pstn.twilio.com
retry_interval=60

[twilio-auth]
type=auth
auth_type=userpass
username=your-username
password=your-password

[twilio]
type=endpoint
context=from-twilio
disallow=all
allow=ulaw
outbound_auth=twilio-auth
aors=twilio

[twilio]
type=aor
contact=sip:your-account.pstn.twilio.com
```

`/etc/asterisk/extensions.conf`:

```ini
[from-twilio]
exten => _+1NXXNXXXXXX,1,Answer()
exten => _+1NXXNXXXXXX,n,AGI(ai_assistant.py)
exten => _+1NXXNXXXXXX,n,Hangup()
```

---

## 🧪 Тестирование

### 1. Проверить статус Asterisk

```bash
sudo asterisk -rvvv
pjsip show endpoints
dialplan show
```

### 2. Тестовый звонок

Используй SIP клиент (например, Zoiper, Linphone) и позвони на номер 777.

### 3. Логи

```bash
sudo tail -f /var/log/asterisk/full
```

---

## 🎯 Следующие шаги

1. ✅ Установить Asterisk
2. ✅ Настроить SIP endpoint
3. ✅ Создать AGI скрипт
4. ✅ Протестировать локально
5. ⬜ Подключить SIP транк
6. ⬜ Настроить входящие номера
7. ⬜ Деплой в продакшн

---

Нужна помощь с настройкой? Пиши! 🚀
