# Cotune Bootstrap Node

Первая bootstrap-нода для децентрализованной P2P-сети Cotune. Помогает первым устройствам найти друг друга в сети.

## Возможности

- **Relay (circuit v2)**: Позволяет устройствам за NAT подключаться друг к другу
- **DHT (server mode)**: Работает как сервер DHT для поиска пиров
- **NAT traversal**: Помогает с пробросом портов
- **Постоянный Peer ID**: Использует сохраненный приватный ключ для стабильного идентификатора

## Как работает система без bootstrap-ноды

После того как первые устройства подключились к сети через bootstrap-ноду:

1. **Устройства сохраняют relay-адреса**: При подключении устройства сохраняют адреса других устройств (включая relay-серверы) в локальное хранилище (known peers).

2. **QR-коды содержат relay-адреса**: Когда устройство генерирует QR-код на экране профиля, оно включает:
   - Свой Peer ID и адреса
   - Список известных relay-адресов (из known peers)

3. **Новые устройства подключаются через QR**: Новое устройство может отсканировать QR-код от другого устройства и подключиться к сети через relay-адреса из QR.

4. **Автоматическое использование known peers**: При следующем запуске устройство автоматически использует сохраненные relay-адреса из known peers для подключения к сети (если bootstrap-нода недоступна).

5. **Устройства становятся relay**: Устройства с публичным IP автоматически становятся relay-серверами и начинают помогать другим устройствам подключаться.

**Вывод**: Bootstrap-нода нужна только для первоначального подключения первых устройств. После этого система становится полностью децентрализованной - устройства находят друг друга через QR-коды и relay-адреса, которые они передают друг другу.

## Сборка

```bash
cd server/cotune-node
go mod tidy
go build -o cotune-bootstrap main.go
```

## Запуск

### Локальный запуск (для тестирования)

```bash
./cotune-bootstrap -listen /ip4/0.0.0.0/tcp/4001
```

### С указанием публичного IP

```bash
./cotune-bootstrap -listen /ip4/0.0.0.0/tcp/4001 -public-ip 84.201.172.91
```

Или через переменную окружения:

```bash
PUBLIC_IP=84.201.172.91 ./cotune-bootstrap -listen /ip4/0.0.0.0/tcp/4001
```

### Установка как systemd service

1. Скопируйте бинарник в нужную директорию:
   ```bash
   sudo cp cotune-bootstrap /home/deerelk/cotune-node/
   sudo chmod +x /home/deerelk/cotune-node/cotune-bootstrap
   ```

2. Скопируйте service файл:
   ```bash
   sudo cp ../cotune-bootstrap.service /etc/systemd/system/
   ```

3. Отредактируйте пути в `/etc/systemd/system/cotune-bootstrap.service` под вашу систему

4. Запустите сервис:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable cotune-bootstrap
   sudo systemctl start cotune-bootstrap
   ```

5. Проверьте статус:
   ```bash
   sudo systemctl status cotune-bootstrap
   sudo journalctl -u cotune-bootstrap -f
   ```

## Приватный ключ

При первом запуске автоматически генерируется файл `bootstrap.key` с приватным ключом в base64. Этот ключ определяет постоянный Peer ID ноды.

**Важно**: Сохраните этот файл! Без него нода получит новый Peer ID при следующем запуске.

## Использование в приложении

Peer ID и адреса bootstrap-ноды должны быть указаны в `node.go`:

```go
var defaultBootstrapAddrs = []string{
    "/ip4/84.201.172.91/tcp/4001/p2p/12D3KooWPg8PavCBcMzooYYHbnoEN5YttQng3YGABvVwkbM5gvPb",
}
```

После запуска bootstrap-нода выведет свой Peer ID и multiaddrs, которые нужно использовать в приложении.

## Проверка работы

После запуска нода выведет:
- Peer ID
- Список multiaddrs для подключения
- Статус включенных функций (Relay, DHT, NAT traversal)

В логах будут отображаться входящие подключения и количество активных соединений каждые 30 секунд.

