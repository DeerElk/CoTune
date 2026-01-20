# CoTune Backend Architecture

## Обзор

CoTune - полностью децентрализованное P2P приложение для обмена музыкой без серверов, трекеров и регистрации.

## Компоненты

### 1. Go Backend (`go-backend/`)

#### Основные пакеты:

- **`internal/host`**: libp2p host с TCP, QUIC, Noise, Identify, AutoNAT, Hole Punching, Relay v2
- **`internal/dht`**: Kademlia DHT для provider records (только CTID → PeerID)
- **`internal/ctr`**: Canonical Track Resolution - вычисление CTID из аудио
- **`internal/search`**: Поиск через токены без flooding
- **`internal/streaming`**: Chunk-based streaming протокол
- **`internal/storage`**: Локальное хранилище треков
- **`internal/daemon`**: Главный координатор всех сервисов
- **`internal/api`**: HTTP REST API (deprecated)
- **`internal/api/proto`**: Protobuf/gRPC IPC сервер для Flutter/Kotlin

#### Ключевые особенности:

- **CTID (Canonical Track ID)**: SHA256 от нормализованного PCM
  - Не зависит от битрейта, кодека, контейнера
  - Одинаковый трек → одинаковый CTID

- **DHT Provider Records**:
  - Key: `/ctid/<CTID>`
  - Value: PeerID
  - TTL: 24 часа (автообновление)
  - **ЗАПРЕЩЕНО** хранить: аудио, метаданные, текстовые индексы

- **Поиск**:
  1. Токенизация запроса
  2. Для каждого токена: FindProviders(`/token/<hash>`)
  3. Запрос локальных индексов у пиров через протокол `/cotune/index/1.0.0` → получение CTID
  4. FindProviders(`/ctid/<CTID>`) → адреса пиров

- **Стриминг**:
  - Протокол: `/cotune/stream/1.0.0`
  - Chunk size: 64KB
  - Формат: [4 bytes length][JSON chunk]

### 2. Kotlin Bridge (`flutter-app/android/app/src/main/kotlin/`)

- **`CotuneNodePlugin.kt`**: Flutter MethodChannel handler
  - `startNode`: Запуск Go daemon
  - `stopNode`: Остановка daemon
  - `getPeerInfoQrNative`: Генерация QR кода

- **`CotuneNodeService.kt`**: Android foreground service для daemon

- **`MainActivity.kt`**: Главная активность Flutter

### 3. Flutter Services

- **`p2p_service.dart`**: Управление через gRPC API (по умолчанию)
  - Использует `p2p_grpc_service.dart` по умолчанию (`useGrpc = true`)
  - Автоматический fallback на HTTP при необходимости
  - Полная совместимость с существующим кодом

- **`p2p_grpc_service.dart`**: gRPC клиент для Protobuf IPC
  - Полностью реализован с использованием сгенерированного protobuf кода
  - Все методы API работают через gRPC
  - Используется `CotuneServiceClient` из `lib/generated/cotune.pbgrpc.dart`

- **`storage_service.dart`**: Локальное хранилище (Hive)
  - Поддержка CTID реализована
  - Сохранение треков с метаданными

## Протоколы

### libp2p Stack

- **Transport**: TCP, QUIC (приоритет)
- **Security**: Noise
- **Muxer**: yamux, mplex
- **Protocols**:
  - `/ipfs/id/1.0.0` - Identify
  - `/libp2p/autonat/1.0.0` - AutoNAT
  - `/libp2p/circuit/relay/0.2.0/hop` - Relay v2
  - `/ipfs/kad/1.0.0` - Kademlia DHT
  - `/cotune/stream/1.0.0` - Streaming
  - `/cotune/index/1.0.0` - Index query (запрос локальных индексов)

### Protobuf/gRPC IPC

Основной протокол IPC через `127.0.0.1:7777` (localhost TCP) или Unix socket.

### HTTP API (Deprecated)

HTTP API помечен как deprecated, но все еще работает для обратной совместимости на `http://127.0.0.1:7777`:

- `GET /status` - Health check
- `GET /peerinfo?format=json` - Peer информация
- `GET /known_peers` - Список известных пиров
- `POST /connect` - Подключение к пиру
- `GET /search?q=QUERY&max=20` - Поиск
- `GET /search_providers?id=CTID&max=12` - Поиск провайдеров
- `GET /fetch?peer=PEER_ID&id=CTID` - Скачать трек
- `POST /share` - Поделиться треком
- `POST /announce` - Ручной announce
- `GET /relays` - Список relay
- `POST /relay/enable` - Включить relay
- `POST /relay_request` - Запрос relay соединения

## Жизненный цикл

### Запуск приложения

1. Flutter вызывает `P2PService.ensureNodeRunning()`
2. Kotlin bridge запускает Go daemon через `CotuneNodePlugin`
3. Go daemon инициализирует:
   - libp2p host
   - DHT
   - CTR service
   - Search service
   - Streaming service
   - HTTP API server
4. Daemon начинает периодический announce (каждые 4 минуты)

### Добавление трека

1. Пользователь выбирает файл в `my_music_screen`
2. Файл копируется в хранилище приложения
3. Создается Track с `recognized = false`
4. Пользователь вводит название и исполнителя
5. `recognized = true`
6. Трек ставится в очередь CTR
7. CTR вычисляет CTID
8. Трек объявляется в DHT (`Provide(CTID)`)

### Поиск

1. Пользователь вводит запрос в `search_screen`
2. Flutter вызывает `P2PService.search(query)`
3. Go backend:
   - Токенизирует запрос
   - Ищет локально
   - Ищет в сети через DHT
4. Возвращает результаты с CTID и провайдерами

### Стриминг/Скачивание

1. Пользователь кликает на трек
2. Flutter вызывает `P2PService.fetchFromNetwork(ctid)`
3. Go backend:
   - Находит провайдеров через DHT
   - Подключается к пиру
   - Открывает stream `/cotune/stream/1.0.0`
   - Скачивает чанки
4. Файл сохраняется локально
5. При лайке трек объявляется в DHT

## Масштабируемость

- **O(log N)** сложность поиска в DHT
- **Нет flooding** - только targeted DHT queries
- **Eventual consistency** - допускает задержки
- **No global state** - каждый пир независим
- **Organic replication** - только по лайкам

## NAT Traversal

- **AutoNAT**: Определение типа NAT
- **Hole Punching**: Прямое соединение через NAT
- **Relay v2**: Fallback для сложных NAT
- **QUIC**: Лучшая работа через NAT

## TODO / Известные ограничения

1. **Audio Decoding**: CTR требует интеграции с ffmpeg или аналогичной библиотекой
2. **Mobile Build**: Go binary нужно собрать для Android (gomobile)
3. **IPC**: Текущая реализация использует HTTP, можно оптимизировать через Unix socket
4. **Search Protocol**: Нужен протокол для запроса локальных индексов у пиров
5. **Streaming Protocol**: Упрощенная реализация, можно улучшить с protobuf

## Сборка

### Go Backend (Linux)

```bash
cd go-backend
go mod download
go build -o cotune-node main.go
```

### Android

1. Собрать Go binary для Android
2. Включить в APK как native library
3. Kotlin bridge запускает через ProcessBuilder

## Тестирование

1. Запустить 2+ экземпляра daemon
2. Подключить через QR/peer info
3. Добавить треки
4. Выполнить поиск
5. Скачать треки
