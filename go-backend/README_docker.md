# CoTune Docker Test Network

Локальная P2P тест-сеть для `go-backend` без Android.
Локальный bootstrap не создается: каждый контейнер подключается к внешнему VPS bootstrap.

## Быстрый запуск (Windows + PowerShell)

В директории `go-backend`:

```powershell
Copy-Item .env.example .env
```

В `.env` уже прописаны ваши два bootstrap-адреса:

```env
BOOTSTRAP_MULTIADDR=/ip4/84.201.172.91/udp/4001/quic-v1/p2p/12D3KooWN9yd5yKtJkAitShdz6CSD71cJ666JFEargFMWX6SaanY,/ip4/84.201.172.91/tcp/4001/p2p/12D3KooWN9yd5yKtJkAitShdz6CSD71cJ666JFEargFMWX6SaanY
```

Запуск:

```powershell
docker compose up -d --build --scale peer=10
bash docker/test_controller.sh list-peers
bash docker/test_controller.sh convergence
```

## 1) Как поднять 10 peers

```bash
docker compose up -d --build --scale peer=10
```

## 2) Как поднять 50 peers

```bash
docker compose up -d --build --scale peer=50
```

## 3) Как запустить churn test

```bash
bash docker/test_controller.sh churn 20 3
```

- `20` — число stop/start итераций
- `3` — пауза в секундах

## 4) Как проверить DHT convergence

```bash
bash docker/test_controller.sh convergence
```

Ожидаемые поля:
- `routing` (`routing_table_size`)
- `providers` (`provider_count`)
- `connected` (`connected_peers`)

## 5) Как смотреть логи конкретного peer

```bash
docker compose ps
docker logs -f <container_name_or_id>
```

Логи структурированные (JSON), с `peer_id`, `routing_table_size`, `dht_bucket_info`, `provider_count`.

## 6) Как замерять provider propagation time

```bash
bash docker/test_controller.sh provider-propagation <CTID>
```

Скрипт циклически опрашивает `/providers?ctid=<CTID>&max=50` на всех контейнерах и печатает общее время до сходимости.

## 7) Массовые сценарии из контроллера

```bash
# Добавление треков (по 5 на peer)
bash docker/test_controller.sh mass-add 5

# Поиск
bash docker/test_controller.sh mass-search load_track

# Репликация по CTID
bash docker/test_controller.sh mass-replicate <CTID>

# Имитация плохой сети
bash docker/test_controller.sh latency 150 3 60
```

## 8) Control API endpoints + curl примеры

Найдите host-port одного peer:

```bash
CID=$(docker compose ps -q peer | head -n1)
PORT=$(docker port "$CID" 8080/tcp | awk -F: 'NR==1{print $2}')
```

### `GET /status`
```bash
curl -s "http://127.0.0.1:${PORT}/status"
```

### `GET /peers`
```bash
curl -s "http://127.0.0.1:${PORT}/peers"
```

### `GET /providers`
```bash
curl -s "http://127.0.0.1:${PORT}/providers"
curl -s "http://127.0.0.1:${PORT}/providers?ctid=<CTID>&max=20"
```

### `POST /addTrack`
```bash
curl -s -X POST "http://127.0.0.1:${PORT}/addTrack" \
  -H "Content-Type: application/json" \
  -d '{"path":"/etc/hosts","title":"docker_track","artist":"docker_artist"}'
```

### `POST /search`
```bash
curl -s -X POST "http://127.0.0.1:${PORT}/search" \
  -H "Content-Type: application/json" \
  -d '{"query":"docker_track","max":20}'
```

### `POST /replicate`
```bash
# Вариант 1: объявить уже локальный track_id
curl -s -X POST "http://127.0.0.1:${PORT}/replicate" \
  -H "Content-Type: application/json" \
  -d '{"track_id":"<TRACK_ID>"}'

# Вариант 2: скачать по CTID и сохранить локально
curl -s -X POST "http://127.0.0.1:${PORT}/replicate" \
  -H "Content-Type: application/json" \
  -d '{"ctid":"<CTID>","output_path":"/data-root/replica.bin"}'
```

### `POST /disconnect`
```bash
curl -s -X POST "http://127.0.0.1:${PORT}/disconnect" \
  -H "Content-Type: application/json" \
  -d '{"peer_id":"<PEER_ID>"}'
```

### `POST /connect`
```bash
# По multiaddr
curl -s -X POST "http://127.0.0.1:${PORT}/connect" \
  -H "Content-Type: application/json" \
  -d '{"multiaddr":"/ip4/84.201.172.91/tcp/4001/p2p/12D3KooWN9yd5yKtJkAitShdz6CSD71cJ666JFEargFMWX6SaanY"}'
```

### `POST /shutdown`
```bash
curl -s -X POST "http://127.0.0.1:${PORT}/shutdown"
```

### `GET /metrics`
```bash
curl -s "http://127.0.0.1:${PORT}/metrics"
```

## 9) Автораннер тестов

Smoke-run:

```bash
bash docker/test_runner.sh smoke 10
```

Full-run (добавляет churn + latency):

```bash
bash docker/test_runner.sh full 50
```

Отчеты сохраняются в `docker/reports/run_<mode>_<timestamp>.json`.

## 10) Остановка

```bash
docker compose down
```

С удалением volume-данных:

```bash
docker compose down -v
rm -rf data
```

## 11) Troubleshooting bootstrap

Если в логах peers есть:

- `dial tcp4 84.201.172.91:4001: connect: connection refused`
- `timeout: no recent network activity`

значит bootstrap на VPS недоступен по соответствующему transport.

Проверка peer ID на VPS:

```bash
./cotune-bootstrap -key /var/lib/cotune-bootstrap/bootstrap.key -print-peer-id
```

Проверка, что peer id не уехал:

```bash
./cotune-bootstrap \
  -key /var/lib/cotune-bootstrap/bootstrap.key \
  -expect-peer-id 12D3KooWN9yd5yKtJkAitShdz6CSD71cJ666JFEargFMWX6SaanY \
  -listen "/ip4/0.0.0.0/tcp/4001,/ip4/0.0.0.0/udp/4001/quic-v1"
```
