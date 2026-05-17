# План тестирования CoTune

## Цель

Проверить, что CoTune выполняет заявленные функциональные и нефункциональные требования: запуск локального узла, P2P-подключение, импорт и публикацию треков, поиск, получение provider-записей, воспроизведение, локальные избранные/плейлисты, QR-представление peer-info и сетевую диагностику.

## Виды тестирования

1. Unit-тестирование Go backend: DHT-идентификаторы, CTID-представление PCM, локальный поиск и HTTP validation.
2. Интеграционное тестирование локального хранилища Go: сохранение, поиск, удаление и повторное открытие datastore.
3. Unit/widget-тестирование Flutter: модели, Hive-хранилище, QR-widget.
4. API/IPC smoke-тестирование: проверка REST Control API и gRPC-контракта через существующие daemon endpoints.
5. Docker P2P smoke/full-тестирование: проверка сходимости сети, массового добавления, поиска, churn и latency через `docker/test_runner.sh`.
6. Полуавтоматическое пользовательское тестирование: импорт аудио, воспроизведение, QR-подключение, лайки и плейлисты в Android/Windows-клиенте.

## Матрица покрытия

| Требование | Проверка |
| --- | --- |
| ФТ-1: запуск локального узла и статус | Go Control API tests, Docker `list-peers`, ручная проверка экрана диагностики |
| ФТ-2: подключение к bootstrap-peer и пирам | Docker `convergence`, `connect`, QR/manual connect |
| ФТ-3: импорт трека | Go storage tests, Docker `mass-add`, ручной импорт в Flutter |
| ФТ-4: вычисление CTID | Go `ctr` и `dht` unit tests |
| ФТ-5: публикация provider-записей | Docker `mass-add`, `provider-propagation`, `providers` endpoint |
| ФТ-6: локальный и сетевой поиск | Go `search` tests, Docker `mass-search` |
| ФТ-7: поиск provider и получение трека | Docker `mass-replicate`, ручная загрузка найденного трека |
| ФТ-8: воспроизведение трека | Полуавтоматическая проверка Flutter player на локальном/загруженном файле |
| ФТ-9: избранное и плейлисты | Flutter `StorageService` tests, ручная проверка UI |
| ФТ-10: peer-info и QR | Flutter QR widget test, ручная проверка профиля |
| ФТ-11: сетевая диагностика | Go Control API tests, Docker `convergence`, `/metrics` |

## Нефункциональные требования

- Кроссплатформенность проверяется сборочными гайдами Android/Windows и Flutter-тестами моделей/виджетов.
- Отсутствие внешней СУБД проверяется тестами Hive и Badger datastore во временных директориях.
- Масштабируемость и работа в сети из `n` узлов проверяются Docker smoke/full сценариями.
- Надежность при отказе узлов проверяется Docker `churn`.
- Отсутствие центрального контент-сервера проверяется архитектурно и через provider-only DHT сценарии.
- Локальность приватных данных проверяется тестами локального хранения и отсутствием обязательной регистрации.

## Команды

```powershell
cd go-backend
$env:GOCACHE='C:\Users\ellev\Documents\IdeaProjects\CoTune\.gocache'
go test ./...
```

```powershell
cd flutter-app
flutter test
```

```bash
cd go-backend
bash docker/test_runner.sh smoke 3
```

