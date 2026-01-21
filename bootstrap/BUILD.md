# Сборка Bootstrap Peer

## Быстрая сборка

```bash
cd bootstrap
go mod download
$env:GOOS="linux"
$env:GOARCH="amd64"
$env:CGO_ENABLED="0"
go build -o cotune-bootstrap main.go
```

Или используйте Makefile:

```bash
make build
```

## Запуск

### Базовый запуск (все интерфейсы, порт 4001)

```bash
./cotune-bootstrap
```

### С указанием конкретного IP

```bash
./cotune-bootstrap -listen "/ip4/84.201.172.91/tcp/4001,/ip4/84.201.172.91/udp/4001/quic-v1"
```

### С кастомным путём к ключу

```bash
./cotune-bootstrap -key /var/lib/cotune-bootstrap/bootstrap.key
```

**Важно:** При первом запуске будет создан файл ключа. Этот ключ обеспечивает стабильный peer ID при перезапусках. Сохраните этот файл в безопасном месте!

### С debug логированием

```bash
./cotune-bootstrap -log debug
```

## Проверка работы

После запуска вы увидите:

```
=== CoTune Bootstrap Peer ===
Peer ID: 12D3KooW...
Addresses:
  /ip4/84.201.172.91/tcp/4001/p2p/12D3KooW...
  /ip4/84.201.172.91/udp/4001/quic-v1/p2p/12D3KooW...

Bootstrap peer is ready!
```

## Использование в Android приложении

В Android приложении укажите bootstrap peer в формате multiaddr:

```
/ip4/84.201.172.91/tcp/4001/p2p/<PEER_ID>
```

Peer ID можно получить из логов bootstrap peer при запуске.

## Troubleshooting

**Проблема: "Failed to bind to address"**
- Убедитесь, что порты 4001 (TCP/UDP) не заняты
- Проверьте firewall правила

**Проблема: "No connections"**
- Убедитесь, что bootstrap peer имеет white/public IP
- Проверьте, что порты открыты в firewall
- Проверьте NAT настройки

**Проблема: "DHT bootstrap failed"**
- Это нормально для первого запуска
- DHT будет работать после подключения других узлов
