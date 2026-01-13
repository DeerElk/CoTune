# Cotune P2P backend (Go + libp2p)

Упрощённый децентрализованный аналог Tribler/Spotify: без серверов, без трекеров, без Tor/Onion, без экономики. Фронт на Flutter общается с Go-нодой через gomobile bind или HTTP API.

## Архитектура
- Каждый узел — полноценный peer libp2p: Host + Kademlia DHT + GossipSub.
- Гибрид поиска провайдеров треков: быстрый кэш через PubSub (TrackMeta), глобальная гарантия через DHT `Provide/FindProviders`.
- Чанки (файлы треков) лежат в `storagePath` (`<basePath>/tracks`).
- Автоповышение до relay: если есть публичный адрес — включаем circuit v2 relay. Можно принудительно через `/relay/enable`.
- Bootstrap: список из параметра, ENV `COTUNE_BOOTSTRAP`, сохранённых известных публичных/relay пиров, затем зашитый дефолт. QR/JSON на profile_screen передаёт эти multiaddr.

## Основные Go API (gomobile/HTTP)
Экспортируемые функции (gomobile): `StartNode(httpHostPort, listen, relaysCSV, basePath)`, `StopNode()`, `Status()`, `GetPeerInfoJson()`.

HTTP endpoints (локально на `httpHostPort`):
- `GET /status` — состояние ноды.
- `GET /peerinfo` — peerId + addrs (для QR/clipboard).
- `GET /known_peers` — сохранённые адреса.
- `GET /relays` — актуальные публичные/relay адреса (для QR/clipboard).
- `POST /connect` — тело: multiaddr строка или JSON `{peerId, addrs}`; подключение к узлу.
- `POST /relay/enable` — принудительно включить relay.
- `POST /share` — `{id, path, title, artist, checksum, recognized?}`: копирует файл внутрь, сохраняет метаданные, рассылает через PubSub и `Provide` в DHT.
- `POST /tag` — `{id, title?, artist?, checksum?, recognized?}`: обновить/подписать уже загруженный трек без повторной загрузки файла и переобъявить его.
- `GET /search?q=` — локальный поиск по загруженным метаданным (включая полученные по PubSub).
- `GET /search_providers?id=&max=` — вернуть адреса провайдеров (кэш из PubSub/хранилища, затем DHT).
- `GET /fetch?peer=&id=` — скачать трек у пира.
- `POST /like` — `{peer,id}`: скачать, добавить в свою библиотеку, переобъявить (репликация).
- `POST /announce` — переобъявить все локальные треки.
- `POST /relay_request` — найти известный relay (best-effort).

## Потоки данных
1. Добавление трека (`/share` или gomobile-обёртка): копия в `storagePath`, метаданные в BoltDB, PubSub публикация, DHT Provide.
2. Получение метаданных: подписка GossipSub `cotune:tracks` → локальный кэш ProviderAddrs в BoltDB.
3. Поиск: UI отправляет `/search` (локальный индекс) и `/search_providers` для конкретного trackID — сначала кэш, затем DHT.
4. Стрим: `/fetch` открывает libp2p stream `/cotune/file/1.0.0`, читает header+байты, кладёт в `storagePath`, сохраняет meta и re-announce.
5. Репликация/лайк: `/like` скачивает и объявляет трек, повышая доступность.
6. Дедуп/качество: merge правил в `storage.MergeAndSaveTrackMeta`: признаёт recognized версии, предпочитает больший размер (битрейт), объединяет провайдеров.

## Сборка Android .aar
Требуется gomobile и NDK. Пример для Windows/PowerShell:
```
$env:ANDROID_NDK_HOME="C:\Users\<you>\AppData\Local\Android\Sdk\ndk\21.4.7075529"
gomobile bind -target=android -ldflags="-checklinkname=0" -o cotune.aar ./...
```

## Минимальные настройки фронта (Flutter)
- При старте: вызвать `StartNode("127.0.0.1:48080", "/ip4/0.0.0.0/tcp/0", "<bootstrap_multiaddr>", "<app_data>/cotune")`.
- Для bootstrap через QR/clipboard: сериализовать `peerinfo` или список из `/relays`, передавать в `connect`.
- При добавлении/лайке: сначала положить файл во временное место, затем `/share` или `/like`.
- Для поиска: `/search?q=...` → список мета; для проигрывания выбрать trackID, вызвать `/search_providers` (опционально) и затем `/fetch?peer=<peer>&id=<id>`; реализовать параллельное скачивание с нескольких пиров на стороне Flutter плеера (по аналогии с торрент).

## Безопасность и ограничения
- Нет регистрации/авторизации; данные публичны в сети.
- Ограничение размера файла: upload 300 MiB, fetch 350 MiB.
- Нет Tor/onion, нет токенов/экономики, нет TrustChain.

