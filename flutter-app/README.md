# CoTune Mobile — Flutter приложение

Flutter UI приложение для CoTune — децентрализованной P2P музыкальной сети.

## 📱 Структура

- **`lib/screens/`** — UI экраны:
  - `search_screen.dart` — Поиск треков в P2P сети
  - `my_music_screen.dart` — Локальная музыка пользователя
  - `profile_screen.dart` — Информация о пире, QR код
  - `qr_scan_screen.dart` — Сканирование QR для подключения
  - `player_fullscreen.dart` — Полноэкранный плеер

- **`lib/services/`** — Сервисы:
  - `p2p_service.dart` — P2P сервис (HTTP API, deprecated, будет заменен на gRPC)
  - `p2p_grpc_service.dart` — gRPC клиент (готов к использованию после генерации protobuf)
  - `storage_service.dart` — Локальное хранилище (Hive)
  - `audio_player_service.dart` — Аудио плеер
  - `qr_service.dart` — Генерация/сканирование QR кодов

- **`lib/generated/`** — Сгенерированный protobuf код (Dart)

## 🚀 Запуск

### Требования

- Flutter SDK 3.10+
- Dart SDK 3.3+
- protoc (Protocol Buffers compiler)
- protoc-gen-dart плагин: `dart pub global activate protoc_plugin`

### Установка зависимостей

```bash
cd flutter-app
flutter pub get
```

### Генерация Protobuf кода

```bash
# Linux/macOS
./generate_proto_dart.sh

# Windows
generate_proto_dart.bat
```

Это создаст файлы в `lib/generated/`.

### Запуск на устройстве

```bash
flutter run
```

## 📦 Зависимости

- **provider** — Управление состоянием
- **hive** — Локальное хранилище
- **just_audio** — Аудио плеер
- **grpc** — gRPC клиент
- **protobuf** — Protobuf поддержка
- **mobile_scanner** — QR сканер
- **qr_flutter** — QR генератор

## 🔧 Использование

Приложение использует Go daemon через:
1. **Kotlin Bridge** (`CotuneNodePlugin.kt`) — запускает daemon процесс
2. **IPC** через Protobuf/gRPC (localhost TCP) или HTTP (deprecated)

Daemon должен быть собран и скопирован в `android/app/src/main/jniLibs/<arch>/cotune-daemon`.

## 📝 Примечания

- Protobuf код для Dart сгенерирован в `lib/generated/`
- Для полного перехода на gRPC нужно обновить `p2p_service.dart` для использования `p2p_grpc_service.dart`
- HTTP API временно поддерживается для обратной совместимости
