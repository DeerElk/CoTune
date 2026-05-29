# Результаты тестирования CoTune

Дата актуализации: 18.05.2026.

## Выполненные проверки

| Проверка | Команда | Результат |
| --- | --- | --- |
| Go unit/integration tests | `go test ./...` с `GOCACHE` внутри проекта | Успешно, код возврата 0 |
| Flutter tests | `flutter test` | Успешно, 7 тестов пройдены |
| Docker smoke runner | `bash docker/test_runner.sh smoke 3` | Успешно, создан отчет `go-backend/docker/reports/run_smoke_20260517_175421.json` |
| Docker full runner | `bash docker/test_runner.sh full 20` | Успешно, создан отчет `go-backend/docker/reports/run_full_20260518_005106.json` |

## Детали Go-прогона

Проверенные пакеты:

- `internal/api/control`
- `internal/ctr`
- `internal/dht`
- `internal/search`
- `internal/storage`

## Добавленные автоматизированные тесты

- DHT: стабильность SHA256 token hash, преобразование валидных CTID/token hash в CID, отклонение невалидных значений.
- CTR: little-endian представление PCM и пустой PCM.
- Storage: CRUD треков, поиск по token/title/artist, поиск по CTID, удаление, повторное открытие datastore.
- Search: токенизация, локальный поиск без треков с пустым CTID, обновление локального индекса без дублей.
- Control API: отклонение неверных HTTP-методов, некорректного JSON, пустого search query и неполных connect данных.
- Flutter: сериализация моделей, Hive-хранилище треков/плейлистов, защита от дублей, QR-widget smoke test.

## Детали Flutter-прогона

Команда:

```powershell
cd flutter-app
flutter test
```

Результат: `All tests passed`, всего 7 тестов. Проверены сериализация моделей, значения по умолчанию, Hive-хранилище треков и плейлистов, защита от дублей по `id`/`ctid`, QR-widget.

## Детали Docker-прогона

Команда smoke:

```bash
cd go-backend
bash docker/test_runner.sh smoke 3
```

завершилась с кодом 0 и создала отчет:

```text
go-backend/docker/reports/run_smoke_20260517_175421.json
```

Фактические результаты smoke:

- `avg_connected_before=2.00`, `avg_connected_after=2.00`;
- `avg_routing_before=2.00`, `avg_routing_after=2.00`;
- `mass-add`: по 2/2 трека на каждый peer;
- `mass-search load_track`: по 20 результатов на каждый peer;
- итоговая `convergence`: `routing=2`, `connected=2`, provider-count увеличился после добавления треков.

Команда full:

```bash
cd go-backend
bash docker/test_runner.sh full 20
```

создала отчет:

```text
go-backend/docker/reports/run_full_20260518_005106.json
```

Фактические результаты full:

- количество peer: `20`;
- `avg_connected_before=19.00`, `avg_connected_after=19.00`;
- `avg_routing_before=19.00`, `avg_routing_after=19.00`;
- `mass-add`: по 2/2 трека на каждый peer, всего 40 тестовых треков;
- `mass-search load_track`: результаты получены на каждом peer, от 20 до 31 результата;
- churn выполнил 3 остановки и повторных запуска peer;
- latency применил и снял `netem delay 50ms loss 1%` на 20 peer;
- после churn/latency сеть сохранила связность: для каждого peer `routing=19`, `connected=19`.

## Исправления по результатам проверки

- Docker runner был доработан ожиданием готовности Control API перед выполнением сценариев.
- JSON-отчеты Docker runner были исправлены: многострочные выводы команд теперь экранируются как JSON-строки, поэтому отчеты открываются без ошибки `Unexpected end of string`.
