# CoTune Implementation Summary

## Что реализовано

- Go daemon c полноценным libp2p стеком (`TCP`, `QUIC`, `Noise`, `AutoNAT`, `Hole Punching`, `Relay v2`)
- DHT сервис для provider records (`/ctid/<CTID>` и token providers)
- CTR pipeline и базовая аудио-нормализация для вычисления CTID
- Поиск через token providers + локальные индексы
- Chunk-based streaming
- Protobuf/gRPC IPC для Flutter/Kotlin
- Android bridge для запуска daemon отдельным процессом
- Server mode для Docker-тестов (`-mode server`) с control API

## Что добавлено для тестирования в 2026

- Docker test network (`go-backend/docker-compose.yml`)
- Control API endpoint'ы:
  - `/status`, `/peers`, `/providers`, `/addTrack`, `/search`
  - `/replicate`, `/connect`, `/disconnect`, `/shutdown`
  - `/metrics` (Prometheus text format)
- Скрипты:
  - `docker/test_controller.sh`
  - `docker/test_runner.sh` (smoke/full + JSON отчеты)

## Текущий статус

- Кодовая связка peer<->bootstrap рабочая (подтверждено локальным bootstrap тестом)
- Основной риск сейчас — операционный bootstrap deploy (доступность `84.201.172.91:4001`)
- Документация синхронизирована с текущей кодовой базой без ссылок на удаленные legacy-файлы
