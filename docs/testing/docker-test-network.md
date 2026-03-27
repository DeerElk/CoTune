# Docker тест-сеть backend

Локальная P2P тест-сеть для `go-backend` без Android-клиента.

## Быстрый старт

Из директории `go-backend`:

```powershell
Copy-Item .env.example .env
docker compose up -d --build --scale peer=10
bash docker/test_controller.sh list-peers
bash docker/test_controller.sh convergence
```

## Базовые сценарии

Поднять 50 peer:

```bash
docker compose up -d --build --scale peer=50
```

Churn:

```bash
bash docker/test_controller.sh churn 20 3
```

Массовое добавление треков:

```bash
bash docker/test_controller.sh mass-add 5
```

Массовый поиск:

```bash
bash docker/test_controller.sh mass-search load_track
```

## Control API

Основные endpoint-ы:

- `GET /status`
- `GET /peers`
- `GET /providers`
- `POST /addTrack`
- `POST /search`
- `POST /replicate`
- `POST /connect`
- `POST /disconnect`
- `POST /shutdown`
- `GET /metrics`

## Автораннер

```bash
bash docker/test_runner.sh smoke 10
bash docker/test_runner.sh full 50
```

Отчеты сохраняются в `go-backend/docker/reports/`.

## Остановка

```bash
docker compose down
```

С удалением volume-данных:

```bash
docker compose down -v
```
