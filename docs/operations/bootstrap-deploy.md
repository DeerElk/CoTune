# Развертывание bootstrap-peer

## Назначение

Bootstrap-peer обеспечивает initial discovery для узлов CoTune и участвует в DHT routing.

## Требования

- Linux-сервер с публичным IP;
- открытые порты `4001/tcp` и `4001/udp`;
- сохранение приватного ключа между перезапусками.

## Сборка

```bash
cd bootstrap
go mod download
go build -o cotune-bootstrap main.go
```

## Рекомендуемый запуск

```bash
./cotune-bootstrap \
  -listen "/ip4/0.0.0.0/tcp/4001,/ip4/0.0.0.0/udp/4001/quic-v1" \
  -key /var/lib/cotune-bootstrap/bootstrap.key \
  -expect-peer-id <EXPECTED_PEER_ID>
```

Проверить `peer_id` по ключу:

```bash
./cotune-bootstrap -key /var/lib/cotune-bootstrap/bootstrap.key -print-peer-id
```

## systemd (production)

Рекомендуется использовать unit-файл `bootstrap/systemd/cotune-bootstrap.service` и запускать сервис от отдельного пользователя.

Базовые команды:

```bash
sudo systemctl daemon-reload
sudo systemctl enable cotune-bootstrap
sudo systemctl restart cotune-bootstrap
sudo systemctl status cotune-bootstrap --no-pager -l
```

Логи:

```bash
sudo journalctl -u cotune-bootstrap -n 200 --no-pager
```
