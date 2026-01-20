# CoTune Go Backend

Production-ready P2P backend для Android приложения CoTune.

## Архитектура

- **libp2p Host**: Полноценный P2P узел с TCP, QUIC, Noise, Identify, AutoNAT, Hole Punching, Relay v2
- **Kademlia DHT**: Распределенная хеш-таблица для provider records (без хранения данных)
- **CTR (Canonical Track Resolution)**: Вычисление CTID из нормализованного PCM аудио
- **Search Service**: Поиск по токенам без flooding
- **Streaming Service**: Chunk-based аудио стриминг
- **Protobuf/gRPC IPC**: IPC сервер для Flutter/Kotlin bridge (localhost TCP или Unix socket)

## Сборка

### Для Linux/разработки

```bash
cd go-backend
go mod download

# Генерация protobuf кода
./generate_proto.sh  # Linux/macOS
# или
generate_proto.bat   # Windows

# Сборка daemon
go build -o cotune-daemon ./cmd/daemon
```

### Для Android

Сборка Go бинарника для Android:

```bash
# Linux/macOS
./build_android.sh

# Windows
build_android.bat
```

Бинарники автоматически копируются в `../flutter-app/android/app/src/main/jniLibs/<arch>/cotune-daemon`.

Архитектуры: `arm64-v8a`, `armeabi-v7a`, `x86_64`

## Запуск

```bash
./cotune-daemon \
  -proto 127.0.0.1:7777 \
  -listen /ip4/0.0.0.0/tcp/0 \
  -data ./cotune_data \
  -bootstrap /ip4/BOOTSTRAP_IP/tcp/BOOTSTRAP_PORT/p2p/BOOTSTRAP_PEER_ID \
  -relay=false
```

Флаги:
- `-proto`: Адрес Protobuf/gRPC сервера (localhost TCP или Unix socket путь)
- `-listen`: libp2p listen адрес
- `-data`: Директория для данных
- `-bootstrap`: Опциональный bootstrap peer (multiaddr)
- `-relay`: Включить relay service

## Protobuf/gRPC API

Протокол определен в `api/cotune.proto`. Основные методы:

- `Status()` — Проверка статуса daemon
- `PeerInfo()` — Информация о пире (ID, адреса)
- `KnownPeers()` — Список известных пиров
- `Connect()` — Подключение к пиру (multiaddr или peer info)
- `Search()` — Поиск треков по запросу
- `SearchProviders()` — Поиск провайдеров для CTID
- `Fetch()` — Скачивание трека из сети
- `Share()` — Раздача трека (объявление в DHT)
- `Announce()` — Ручное объявление (автоматически происходит каждые 4 минуты)
- `Relays()` — Список relay адресов
- `RelayEnable()` — Включить relay service
- `RelayRequest()` — Запрос relay соединения

## CTR (Canonical Track Resolution)

CTR вычисляет Canonical Track ID (CTID) из аудиофайлов:

1. Декодирование аудио в PCM (44.1kHz, 16-bit, mono)
2. Нормализация PCM сэмплов
3. Вычисление SHA256 хеша → CTID

CTID **не зависит от**:
- Битрейта
- Кодека (MP3, AAC, OGG, FLAC, WAV и т.д.)
- Контейнера

Поддерживаемые форматы: MP3, WAV (нативные), FLAC, AAC, OGG, M4A (через FFmpeg fallback).

## DHT Provider Records

В DHT хранятся **ТОЛЬКО** provider records:
- Key: `/ctid/<CTID>`
- Value: PeerID
- TTL: 24 часа (автообновление)

❌ **Запрещено**: аудиофайлы, метаданные, текстовые индексы

## Поиск без Flood

1. Токенизация запроса (разделение по пробелам/знакам препинания)
2. Для каждого токена:
   - Хеширование токена → token hash
   - `FindProviders(/token/<token_hash>)` → получение пиров с этим токеном
   - Запрос локальных индексов у пиров через протокол `/cotune/index/1.0.0` → получение CTID
3. Для каждого CTID:
   - `FindProviders(/ctid/<CTID>)` → получение адресов пиров
4. Возврат результатов с информацией о провайдерах

## Streaming Protocol

Chunk-based streaming через libp2p streams:
- Протокол: `/cotune/stream/1.0.0`
- Размер чанка: 64KB
- Формат: [4 bytes length][JSON chunk data]
- Автоматическое переключение между провайдерами при ошибках

## Репликация

Репликация происходит **ТОЛЬКО** по действию пользователя (лайк):
1. Пользователь нажал "лайк"
2. Трек полностью скачивается (если удаленный)
3. Сохраняется локально
4. Устройство начинает раздавать: `Provide(/ctid/<CTID>)`

Никакой принудительной репликации нет.

## Структура пакетов

- `internal/host/` — libp2p host с полным стеком протоколов
- `internal/dht/` — Kademlia DHT сервис
- `internal/ctr/` — Canonical Track Resolution pipeline
- `internal/search/` — Поиск по токенам с протоколом запроса индексов
- `internal/streaming/` — Chunk-based streaming сервис
- `internal/storage/` — Локальное хранилище (BadgerDB)
- `internal/daemon/` — Главный координатор всех сервисов
- `internal/api/proto/` — Protobuf/gRPC IPC сервер
- `api/` — Protobuf схема (`cotune.proto`)
