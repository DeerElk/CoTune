# Protobuf IPC Protocol

## Обзор

CoTune использует Protobuf/gRPC для IPC между Kotlin bridge и Go daemon вместо HTTP API.

## Протокол

- **Транспорт**: gRPC через localhost TCP или Unix socket
- **Формат**: Protocol Buffers v3
- **Схема**: `api/cotune.proto`

## Генерация кода

### Go (сервер)

Код уже сгенерирован в `api/proto/`. Для регенерации:

```bash
# Linux/macOS
./generate_proto.sh

# Windows
generate_proto.bat
```

Требования:
- `protoc` (Protocol Buffers compiler)
- `protoc-gen-go` и `protoc-gen-go-grpc` плагины

### Kotlin (клиент)

✅ **Kotlin код автоматически генерируется Gradle** при сборке проекта.

**Настройка**:
- Proto файл скопирован в `android/app/src/main/proto/cotune.proto`
- Gradle protobuf плагин настроен в `build.gradle.kts`
- Код генерируется в `build/generated/source/proto/main/kotlin/` при сборке

**Не требуется** ручная генерация через `protoc` - Gradle делает это автоматически.

**Используемые библиотеки**:
- `io.grpc:grpc-kotlin-stub:1.4.1`
- `com.google.protobuf:protobuf-kotlin:3.25.3`
- `io.grpc:grpc-protobuf:1.62.2`

### Dart (клиент)

✅ Dart код сгенерирован в `flutter-app/lib/generated/`.

Для регенерации:

```bash
cd flutter-app
./generate_proto_dart.sh  # Linux/macOS
# или
generate_proto_dart.bat   # Windows
```

Требования:
- `protoc` (Protocol Buffers compiler)
- `protoc-gen-dart`: `dart pub global activate protoc_plugin`

Используемые пакеты:
- `protobuf: ^3.1.0`
- `grpc: ^4.0.0`

## Использование

### Go Daemon

Daemon запускается с флагом `-proto`:

```bash
./cotune-daemon -proto 127.0.0.1:7777
# или Unix socket:
./cotune-daemon -proto unix:///tmp/cotune.sock
```

### Kotlin Client

✅ **Реализован**: `CotuneGrpcClient.kt` использует сгенерированный код через reflection.

После сборки Android проекта, Gradle автоматически сгенерирует Kotlin/Java protobuf классы, и клиент будет использовать их напрямую.

**Текущая реализация**: Использует reflection для работы с Java protobuf классами, которые генерируются Gradle при сборке.

**После генерации** можно использовать напрямую:

```kotlin
val client = CotuneGrpcClient("127.0.0.1:7777")
client.connect()
val isRunning = client.status()
val peerInfo = client.getPeerInfo()
```

### Dart Client

Пример использования gRPC клиента в Dart:

```dart
final channel = ClientChannel(
  '127.0.0.1',
  port: 7777,
  options: ChannelOptions(credentials: ChannelCredentials.insecure()),
);
final stub = CotuneServiceClient(channel);

// Вызов метода
final request = StatusRequest();
final response = await stub.status(request);
```

## Миграция с HTTP

✅ **Миграция завершена**: Flutter теперь использует gRPC по умолчанию.

Старый HTTP API (`-http` флаг) помечен как deprecated, но все еще поддерживается для обратной совместимости как fallback. `P2PService` автоматически использует gRPC с fallback на HTTP при необходимости.

Новый код должен использовать `P2PGrpcService` напрямую или через `P2PService` с `useGrpc = true` (по умолчанию).

## Endpoints

Все методы определены в `cotune.proto`:
- `Status` - проверка статуса daemon
- `PeerInfo` - информация о peer
- `KnownPeers` - список известных пиров
- `Connect` - подключение к пиру
- `Search` - поиск треков
- `SearchProviders` - поиск провайдеров для CTID
- `Fetch` - скачивание трека
- `Share` - публикация трека
- `Announce` - ручной announce
- `Relays` - список relay адресов
- `RelayEnable` - включение relay
- `RelayRequest` - запрос relay соединения
