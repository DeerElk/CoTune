# Protobuf/gRPC IPC

## Назначение

CoTune использует Protobuf/gRPC как основной IPC между Flutter-клиентом и локальным Go daemon.

## Базовые параметры

- транспорт: gRPC по localhost TCP (по умолчанию `127.0.0.1:7777`);
- схема: `go-backend/api/cotune.proto`;
- сервер: `go-backend/internal/api/proto`.

## Основные методы

- `Status` - проверка статуса daemon;
- `PeerInfo` - информация о текущем peer;
- `KnownPeers` - известные пиры;
- `Connect` - подключение к peer/multiaddr;
- `Search` - поиск треков;
- `SearchProviders` - поиск провайдеров по `CTID`;
- `Fetch` - скачивание трека из сети;
- `Share` - публикация трека в сеть;
- `Announce` - ручной announce;
- `Relays`, `RelayEnable`, `RelayRequest` - управление relay-функциями.

## Генерация кода

### Go

```bash
cd go-backend
./generate_proto.sh
```

Windows:

```bat
cd go-backend
generate_proto.bat
```

### Dart

```bash
cd flutter-app
./generate_proto_dart.sh
```

Windows:

```bat
cd flutter-app
generate_proto_dart.bat
```

### Kotlin

Kotlin/Java код генерируется Gradle автоматически из `android/app/src/main/proto/cotune.proto` при сборке Android-проекта.

## Проверка IPC

1. Запустите daemon с флагом `-proto`.
2. Запустите клиент.
3. Убедитесь, что `Status` возвращает ответ без ошибок.
