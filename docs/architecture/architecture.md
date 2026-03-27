# Архитектура CoTune

## Обзор

CoTune - децентрализованная P2P сеть для обмена музыкой без центрального хранилища.
Система состоит из Flutter-клиента (Android/Windows), локального Go daemon и bootstrap-peer для initial discovery.

## Компоненты

### Go daemon (`go-backend/`)

Ключевые подсистемы:

- `internal/host` - libp2p host (TCP/QUIC, Noise, Identify, AutoNAT, Hole Punching).
- `internal/dht` - Kademlia DHT для provider records.
- `internal/ctr` - вычисление `CTID` (SHA256 от нормализованного PCM).
- `internal/search` - token-based поиск без flood.
- `internal/streaming` - chunk-based streaming.
- `internal/storage` - локальное хранилище.
- `internal/api/proto` - gRPC IPC сервер для клиента.
- `internal/api/control` - HTTP control API для server/test режима.

### Flutter-клиент (`flutter-app/`)

- UI-экраны поиска, библиотеки, профиля и плеера.
- gRPC-клиент к daemon (`lib/services/p2p_grpc_service.dart`).
- локальное хранение треков и метаданных.
- аудио-воспроизведение и очередь через `audio_player_service`.

### Bootstrap-peer (`bootstrap/`)

- отдельный libp2p узел с DHT server mode;
- используется для первичного подключения узлов;
- не хранит и не стримит контент.

Подробности: [архитектура bootstrap-peer](bootstrap-peer.md).

## Сетевая модель

- DHT хранит только provider-записи (`/ctid/<CTID>` и token providers).
- Поиск:
  1. токенизация запроса;
  2. `FindProviders` по токенам;
  3. запрос локальных индексов у найденных пиров;
  4. `FindProviders` по `CTID`;
  5. выбор провайдера и получение трека.

## Идентификация контента

- `CTID` вычисляется из нормализованного PCM.
- Один и тот же аудиоматериал должен давать один и тот же `CTID`.
- Репликация запускается только пользовательским действием (лайк), не автоматически.

## IPC и режимы daemon

- IPC между клиентом и daemon: Protobuf/gRPC (`127.0.0.1:7777` по умолчанию).
- `-mode android` - runtime для Android-клиента.
- `-mode server` - режим для Docker/инфраструктурных тестов с Control API.

Подробности по контракту IPC: [docs/api/protobuf-ipc.md](../api/protobuf-ipc.md).
