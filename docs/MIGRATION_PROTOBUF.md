# Миграция на Protobuf IPC

## Статус

✅ **Go Backend**: Protobuf сервер реализован и работает
✅ **Go Protobuf код**: Сгенерирован и используется (`api/proto/`)
✅ **Kotlin Bridge**: Адаптирован (использует `-proto` флаг, создан `CotuneGrpcClient.kt`)
✅ **Kotlin Protobuf код**: Gradle настроен для автоматической генерации (генерируется при сборке)
✅ **Dart Services**: Реализован (`p2p_grpc_service.dart` с полной функциональностью)
✅ **Dart Protobuf код**: Сгенерирован (`lib/generated/`)
✅ **Flutter переход на gRPC**: `P2PService` использует gRPC по умолчанию с fallback на HTTP

## Что сделано

1. ✅ Создана protobuf схема (`api/cotune.proto`)
2. ✅ Реализован protobuf/gRPC сервер в Go (`internal/api/proto/server.go`)
3. ✅ Обновлен `cmd/daemon/main.go` для использования protobuf сервера
4. ✅ Обновлены скрипты сборки (убраны упоминания gomobile, исправлен формат бинарника)
5. ✅ Обновлена документация (ANDROID_BUILD.md, PROTOBUF_IPC.md)
6. ✅ Исправлена ошибка линтера в search.go
7. ✅ Kotlin bridge обновлен для использования `-proto` флага
8. ✅ Создан `CotuneGrpcClient.kt` (заглушка, требует генерации protobuf кода)
9. ✅ Создан `p2p_grpc_service.dart` (заглушка, требует генерации protobuf кода)
10. ✅ Добавлены зависимости для gRPC в `build.gradle.kts` и `pubspec.yaml`

## ✅ Всё сделано

### Kotlin Bridge

1. ✅ Зависимости добавлены в `build.gradle.kts`:
```kotlin
dependencies {
    implementation("io.grpc:grpc-kotlin-stub:1.4.1")
    implementation("io.grpc:grpc-protobuf:1.62.2")
    implementation("com.google.protobuf:protobuf-kotlin:3.25.3")
}
```

2. ✅ Proto файл скопирован в `android/app/src/main/proto/cotune.proto`
3. ✅ Gradle protobuf плагин настроен для автоматической генерации Java и Kotlin кода
4. ✅ `CotuneGrpcClient.kt` реализован с поддержкой сгенерированного кода
5. ✅ `CotuneNodePlugin.kt` обновлен для использования gRPC клиента

**Примечание**: Kotlin protobuf код автоматически генерируется Gradle при сборке проекта в `build/generated/source/proto/main/kotlin/`. Не требуется ручная генерация через `protoc`.

### Dart Services

1. ✅ Зависимости добавлены в `pubspec.yaml`:
```yaml
dependencies:
  protobuf: ^3.1.0
  grpc: ^4.0.0
```

2. ✅ Dart код сгенерирован (`lib/generated/cotune.pb.dart` и `cotune.pbgrpc.dart`)

3. ✅ `p2p_grpc_service.dart` полностью реализован с использованием сгенерированного кода

4. ✅ `p2p_service.dart` обновлен для использования gRPC по умолчанию (параметр `useGrpc = true`)

**Примечание**: Flutter теперь использует gRPC по умолчанию с автоматическим fallback на HTTP при необходимости.

## ✅ Текущий статус

- ✅ **Go protobuf код**: Сгенерирован и используется (`api/proto/`)
- ✅ **Dart protobuf код**: Сгенерирован (`lib/generated/`)
- ✅ **Kotlin protobuf код**: Gradle настроен для автоматической генерации (генерируется при сборке)
- ✅ **Flutter использование**: Использует gRPC по умолчанию с fallback на HTTP

## ✅ Миграция завершена

Все компоненты переведены на gRPC:
1. ✅ `p2p_service.dart` использует `p2p_grpc_service.dart` по умолчанию
2. ✅ Используется сгенерированный protobuf код из `lib/generated/`
3. ✅ Все вызовы API используют gRPC методы

## Проверка

Для проверки работы:
1. Запустить daemon с `-proto 127.0.0.1:7777` (через Kotlin bridge автоматически)
2. Flutter автоматически подключится через gRPC
3. Kotlin bridge использует gRPC для проверки статуса daemon
4. HTTP API доступен как fallback (опционально)

**Статус**: ✅ Полная миграция на Protobuf/gRPC завершена. Все компоненты работают через gRPC.
