# Архитектура bootstrap-peer

## Назначение

Bootstrap-peer нужен для initial discovery: новый узел подключается к нему и получает возможность найти остальных участников сети.

Bootstrap-peer не является центральным сервером контента и не хранит музыку.

## Что делает bootstrap-peer

- принимает входящие libp2p-соединения;
- участвует в DHT routing (server mode);
- помогает новым узлам получить initial peer set.

## Что bootstrap-peer не делает

- не индексирует контент;
- не хранит треки;
- не стримит аудио;
- не выполняет роль единственной точки отказа.

## Техническая модель

- transport: TCP + QUIC;
- security: Noise;
- DHT: server mode;
- NAT: порт-маппинг и NAT service;
- поддержка hole punching.

## Эксплуатационный контур

- должен иметь стабильный публичный адрес;
- должен сохранять приватный ключ для неизменного `peer_id`;
- обычно публикуется минимум по двум multiaddr: TCP и QUIC.

Практическое развертывание: [docs/operations/bootstrap-deploy.md](../operations/bootstrap-deploy.md).
