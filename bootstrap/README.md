# CoTune Bootstrap Peer

## Что это?

Bootstrap peer — это **временная точка входа** в P2P-сеть CoTune для первых ~1000 устройств.

## Важно: Bootstrap Peer НЕ является сервером

Bootstrap peer:
- ✅ Помогает новым узлам получить initial peer set
- ✅ Участвует в DHT routing (Server mode)
- ✅ Принимает входящие соединения
- ✅ Помогает узлам discover'ить других пиров

Bootstrap peer НЕ:
- ❌ Хранит данные
- ❌ Индексирует треки
- ❌ Стримит музыку
- ❌ Участвует в поиске контента
- ❌ Является single point of failure

## Архитектура

Bootstrap peer — это **обычный libp2p узел** со следующими свойствами:

1. **DHT Server Mode**: Участвует в routing, но не хранит provider records дольше стандартного TTL
2. **Always Available**: Должен быть всегда доступен для новых узлов
3. **Stable Multiaddr**: Имеет стабильный адрес (white IP)
4. **Connection Handling**: Поддерживает большое количество краткоживущих соединений
5. **No Application Logic**: Не выполняет application-level протоколы (`/cotune/stream/*`, CTR, etc.)

## Технологии

- **Go 1.24.6+**
- **libp2p v0.45.0**
- **Kademlia DHT** (Server mode)
- **TCP + QUIC** транспорты
- **Noise** security
- **Identify + Ping** протоколы
- **AutoNAT** (server mode)
- **Relay v2** (optional, не принудительный)

## Установка и запуск

### Требования

- Ubuntu 22.04+ (или другой Linux)
- White/public IPv4 (желательно IPv6)
- Порты 4001 (TCP/UDP) открыты в firewall

### Сборка

```bash
cd bootstrap
go mod download
go build -o cotune-bootstrap main.go
```

### Запуск

**Базовый запуск:**
```bash
./cotune-bootstrap \
  -listen "/ip4/0.0.0.0/tcp/4001,/ip4/0.0.0.0/udp/4001/quic-v1"
```

При первом запуске будет создан файл `bootstrap.key` с приватным ключом. Этот ключ обеспечивает стабильный peer ID при перезапусках.

**С кастомным путём к ключу:**
```bash
./cotune-bootstrap \
  -listen "/ip4/0.0.0.0/tcp/4001,/ip4/0.0.0.0/udp/4001/quic-v1" \
  -key /var/lib/cotune-bootstrap/bootstrap.key
```

**С кастомными адресами:**
```bash
./cotune-bootstrap \
  -listen "/ip4/YOUR_PUBLIC_IP/tcp/4001,/ip6/YOUR_IPV6/udp/4001/quic-v1"
```

### Флаги

- `-listen`: Comma-separated список адресов для прослушивания (default: `/ip4/0.0.0.0/tcp/4001,/ip4/0.0.0.0/udp/4001/quic-v1`)
- `-key`: Путь к файлу приватного ключа (default: `bootstrap.key`). Ключ будет сгенерирован при первом запуске и сохранён для стабильного peer ID.
- `-log`: Уровень логирования: `debug`, `info`, `warn`, `error` (default: `info`)
- `-print-peer-id`: Напечатать peer ID для ключа `-key` и завершиться
- `-expect-peer-id`: Проверить peer ID на старте (если не совпадает — процесс завершится с ошибкой)

Проверка корректного peer ID перед деплоем:

```bash
./cotune-bootstrap -key /var/lib/cotune-bootstrap/bootstrap.key -print-peer-id
```

Если Android/Go peers используют старый peer ID, будет `failed to negotiate security protocol: EOF`.
В этом случае обновите bootstrap multiaddr в клиентах на актуальный `peer_id`.

### Переменные окружения

Можно использовать переменные окружения вместо флагов:

```bash
export COTUNE_LISTEN="/ip4/0.0.0.0/tcp/4001"
export COTUNE_RELAY=false
export COTUNE_LOG=info
```

## Как это работает

1. **Новый узел подключается** к bootstrap peer
2. **Bootstrap peer помогает** узлу найти других пиров через DHT
3. **Узел получает initial peer set** и начинает работать с сетью
4. **После этого** узел может работать независимо от bootstrap peer

Bootstrap peer **не является критической точкой**:
- Если bootstrap peer выключен, уже подключённые узлы продолжают работать
- Узлы могут найти друг друга через DHT
- Сеть продолжает функционировать

## Масштабирование

Bootstrap peer рассчитан на:
- **1000+ одновременных соединений**
- **Частые reconnect'ы**
- **Churn** (высокая текучесть узлов)

## Безопасность

Bootstrap peer имеет:
- **Connection limits**: Максимум 2000 одновременных соединений
- **Rate limiting**: Защита от connection spam
- **Graceful shutdown**: Корректное закрытие соединений

## Мониторинг

Bootstrap peer логирует:
- Подключения/отключения пиров
- Статистику каждые 60 секунд (количество соединений, уникальных пиров)
- Ошибки и предупреждения

**НЕ логируется:**
- Peer traffic
- Контент
- Запросы поиска

## Отключение Bootstrap Peer

Bootstrap peer можно **безболезненно отключить** после того, как сеть выросла:

1. Узлы уже подключены друг к другу через DHT
2. Новые узлы могут использовать QR-коды существующих узлов
3. Сеть продолжает работать без bootstrap peer

**Процесс отключения:**

1. Убедитесь, что в сети достаточно активных узлов (100+)
2. Постепенно уменьшите количество bootstrap peer'ов
3. Мониторьте подключения новых узлов
4. После полного отключения новые узлы используют QR/peer info для подключения

## FAQ

**Q: Нужен ли bootstrap peer постоянно?**  
A: Нет, только для первых ~1000 устройств. После этого сеть самодостаточна.

**Q: Что произойдёт, если bootstrap peer упадёт?**  
A: Уже подключённые узлы продолжат работать. Новые узлы не смогут подключиться через bootstrap, но могут использовать QR-коды.

**Q: Может ли bootstrap peer быть bottleneck'ом?**  
A: Нет, bootstrap peer только помогает с initial discovery. После этого узлы работают напрямую друг с другом.

**Q: Нужно ли несколько bootstrap peer'ов?**  
A: Рекомендуется 1-3 bootstrap peer'а для отказоустойчивости на начальном этапе.

**Q: Может ли bootstrap peer хранить данные?**  
A: Нет, это нарушает архитектуру. Bootstrap peer только помогает с routing.

## Лицензия

См. LICENSE в корне проекта.
