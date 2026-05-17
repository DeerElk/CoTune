# Результаты тестирования CoTune

Дата выполнения агентом: 17.05.2026.

## Выполненные проверки

| Проверка | Команда | Результат |
| --- | --- | --- |
| Go unit/integration tests | `go test ./...` с `GOCACHE` внутри проекта | Успешно, код возврата 0 |
| Flutter tests | `flutter test` | Не завершено в agent-wrapper: запуск Flutter wrapper зависает; у пользователя `flutter --version` и `dart --version` выполняются в обычном PowerShell |
| Docker smoke | `bash docker/test_runner.sh smoke 3` | Не выполнено: Docker Desktop daemon недоступен (`dockerDesktopLinuxEngine` pipe отсутствует) |

## Детали Go-прогона

Для обхода ограничения доступа к пользовательскому Go cache использовался локальный cache:

```powershell
$env:GOCACHE='C:\Users\ellev\Documents\IdeaProjects\CoTune\.gocache'
go test ./...
```

Проверенные пакеты:

- `internal/api/control`
- `internal/ctr`
- `internal/dht`
- `internal/search`
- `internal/storage`

Первичный запуск без локального `GOCACHE` падал из-за доступа к `C:\Users\ellev\AppData\Local\go-build` и Go telemetry в `AppData`, то есть проблема относилась к окружению, а не к тестируемому коду. После настройки `GOCACHE` финальный запуск всех Go-тестов прошел успешно.

## Добавленные автоматизированные тесты

- DHT: стабильность SHA256 token hash, преобразование валидных CTID/token hash в CID, отклонение невалидных значений.
- CTR: little-endian представление PCM и пустой PCM.
- Storage: CRUD треков, поиск по token/title/artist, поиск по CTID, удаление, повторное открытие datastore.
- Search: токенизация, локальный поиск без треков с пустым CTID, обновление локального индекса без дублей.
- Control API: отклонение неверных HTTP-методов, некорректного JSON, пустого search query и неполных connect данных.
- Flutter: сериализация моделей, Hive-хранилище треков/плейлистов, защита от дублей, QR-widget smoke test.

## Ограничения текущего прогона

Flutter-тесты не были подтверждены агентом из-за зависания `flutter.bat` при запуске через инструмент выполнения команд. Пользователь подтвердил, что в обычном PowerShell `flutter --version` и `dart --version` отрабатывают корректно, поэтому команда `flutter test` оставлена как воспроизводимая проверка для локального запуска.

Docker smoke не запускался, потому что Docker Desktop daemon не был активен. После запуска Docker Desktop ожидаемая команда:

```bash
cd go-backend
bash docker/test_runner.sh smoke 3
```

Отчет должен появиться в `go-backend/docker/reports/run_smoke_<timestamp>.json`.
