# Архитектура Bootstrap Peer

## Принципы проектирования

### 1. Bootstrap Peer НЕ является сервером

Bootstrap peer — это **обычный libp2p узел** с особыми свойствами:
- Участвует в DHT routing (Server mode)
- Принимает входящие соединения
- Помогает новым узлам найти других пиров
- **НЕ хранит данные**
- **НЕ индексирует контент**
- **НЕ стримит музыку**

### 2. Временность

Bootstrap peer нужен только для первых ~1000 устройств. После этого:
- Узлы уже подключены друг к другу через DHT
- Новые узлы могут использовать QR-коды существующих узлов
- Сеть становится самодостаточной

### 3. Отказоустойчивость

Если bootstrap peer выключен:
- Уже подключённые узлы продолжают работать
- Узлы могут найти друг друга через DHT
- Сеть продолжает функционировать

## Технические детали

### libp2p Host Configuration

```go
- Transport: TCP + QUIC
- Security: Noise
- Protocols: Identify, Ping
- NAT: AutoNAT service + Hole Punching
- Relay: v2 service enabled
```

### DHT Configuration

```go
- Mode: Server (participates in routing)
- Protocol Prefix: /cotune
- Bucket Size: 20
- Provider Records: Standard TTL (no pinning)
```

### Rate Limiting

Базовая защита обеспечивается libp2p defaults и системными лимитами.
При необходимости лимиты добавляются через внешний process manager (systemd, firewall, nftables).

## Жизненный цикл

1. **Запуск**: Bootstrap peer создаёт libp2p host и инициализирует DHT
2. **Готовность**: Peer готов принимать соединения и помогать с routing
3. **Работа**: Принимает соединения, помогает узлам найти друг друга
4. **Отключение**: Graceful shutdown, существующие узлы продолжают работать

## Безопасность

- Connection limits предотвращают DoS
- Rate limiting защищает от spam
- Graceful shutdown обеспечивает корректное закрытие соединений
- Нет логирования контента или peer traffic

## Масштабирование

Bootstrap peer рассчитан на:
- **1000+ одновременных соединений**
- **Частые reconnect'ы**
- **Churn** (высокая текучесть узлов)

## Мониторинг

Логируется:
- Подключения/отключения пиров
- Статистика каждые 60 секунд
- Ошибки и предупреждения

**НЕ логируется:**
- Peer traffic
- Контент
- Запросы поиска
