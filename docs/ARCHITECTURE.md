# CoTune Architecture

## Обзор

CoTune — полностью децентрализованная P2P сеть для обмена музыкой без централизованных серверов хранения, трекеров и глобального состояния.

## Слои системы

### 1) Go daemon (`go-backend/`)

Ключевые пакеты:

- `internal/host` — libp2p host (TCP, QUIC, Noise, Identify, AutoNAT, Hole Punching, Relay v2)
- `internal/dht` — Kademlia DHT только для provider records
- `internal/ctr` — CTID (SHA256 от нормализованного PCM)
- `internal/search` — token-based поиск без flooding
- `internal/streaming` — chunk-based streaming
- `internal/storage` — локальное хранилище (Badger)
- `internal/daemon` — координация lifecycle и сервисов
- `internal/api/proto` — gRPC IPC API
- `internal/api/control` — HTTP control API для server-mode тестов

### 2) Android bridge + Flutter

- Flutter UI вызывает нативный канал `cotune_node`
- Kotlin bridge поднимает `cotune-daemon` отдельным процессом
- IPC с daemon: Protobuf/gRPC (`127.0.0.1:7777`)

### 3) Bootstrap peer (`bootstrap/`)

- Отдельный libp2p узел для initial discovery
- DHT server mode без хранения контента
- Не является централизованным data-node

## Поиск и DHT

- DHT содержит только provider records (`/ctid/<CTID>` и token providers)
- Поиск:
  1. tokenization
  2. `FindProviders(/token/<hash>)`
  3. запрос локальных индексов у пиров (`/cotune/index/1.0.0`)
  4. `FindProviders(/ctid/<CTID>)`

## Streaming

- Протокол `/cotune/stream/1.0.0`
- Chunk size 64KB
- Поддержка failover между провайдерами

## Режимы daemon

- `-mode android` — mobile runtime
- `-mode server` — docker/server тестирование
  - structured logs в stdout
  - control API (`/status`, `/peers`, `/providers`, `/addTrack`, `/search`, `/replicate`, `/connect`, `/disconnect`, `/shutdown`, `/metrics`)

## Масштабируемость

- O(log N) операции через DHT
- eventual consistency
- отсутствие global shared state между узлами
- репликация только по пользовательскому действию (лайк)
