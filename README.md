# CoTune

CoTune - децентрализованная P2P музыкальная сеть с клиентами на Android и Windows.
Проект работает без централизованного хранилища и аккаунтов: устройства обмениваются треками напрямую через libp2p/DHT.

## Ключевые принципы

- Нет центрального сервера контента.
- Идентификатор трека - `CTID` (SHA256 нормализованного PCM), одинаковый для одного и того же аудио.
- В DHT хранятся только provider-записи, без медиа и глобального текстового индекса.
- Репликация происходит только по действию пользователя (лайк).

## Структура репозитория

- `go-backend/` - Go daemon (P2P, DHT, CTR, search, streaming, IPC).
- `flutter-app/` - Flutter-клиент (Android и Windows).
- `bootstrap/` - bootstrap-peer для initial discovery.
- `docs/` - каноническая документация проекта.

## Документация

- Основной индекс: [docs/README.md](docs/README.md)
- Архитектура: [docs/architecture/architecture.md](docs/architecture/architecture.md)
- IPC API: [docs/api/protobuf-ipc.md](docs/api/protobuf-ipc.md)
- Сборка Android: [docs/guides/android-build.md](docs/guides/android-build.md)
- Сборка Windows: [docs/guides/windows-build.md](docs/guides/windows-build.md)
- Docker тест-сеть: [docs/testing/docker-test-network.md](docs/testing/docker-test-network.md)

## Лицензия

Проект распространяется по лицензии `Apache-2.0`.
См. [LICENSE](LICENSE).
