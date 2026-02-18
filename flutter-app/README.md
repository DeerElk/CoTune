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
  - `p2p_grpc_service.dart` — основной gRPC клиент daemon IPC
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
2. **IPC** через Protobuf/gRPC (localhost TCP)

Daemon должен быть собран и скопирован в `android/app/src/main/jniLibs/<arch>/cotune-daemon`.

## Windows (Desktop)

Приложение теперь поддерживает запуск на Windows как desktop-клиент.

### Что нужно

- Flutter SDK с включенной поддержкой Windows:
  - `flutter config --enable-windows-desktop`
- Visual Studio с C++ workload (для `flutter run -d windows`)
- Собранный `cotune-daemon.exe` из `go-backend`

### Сборка daemon для Windows

Из корня `go-backend`:

```powershell
go build -o cotune-daemon.exe ./cmd/daemon
```

### Как daemon попадает в Windows-сборку

При `flutter run -d windows` / `flutter build windows`:

- если установлен Go, CMake автоматически собирает `go-backend/cmd/daemon` в `cotune-daemon.exe` и кладет рядом с `cotune_mobile.exe`;
- если Go не установлен, но есть `go-backend/cotune-daemon.exe`, используется этот prebuilt binary.

Поэтому в нормальном случае ручной путь не нужен.

### Ручной путь к daemon (fallback)

Если нужен явный путь, задай переменную окружения:

```powershell
$env:COTUNE_DAEMON_PATH="C:\path\to\cotune-daemon.exe"
```

Или положи `cotune-daemon.exe` рядом с приложением (или в `bin/`).

Bootstrap для desktop теперь по умолчанию берется из встроенных адресов CoTune VPS.
При необходимости его можно переопределить через env или `--dart-define`.

Через переменную окружения:

```powershell
$env:COTUNE_BOOTSTRAP_ADDRS="/ip4/.../quic-v1/p2p/<peer>,/ip4/.../tcp/.../p2p/<peer>"
```

Или при сборке:

```powershell
flutter build windows --dart-define=COTUNE_BOOTSTRAP_ADDRS="/ip4/.../quic-v1/p2p/<peer>,/ip4/.../tcp/.../p2p/<peer>"
```

### Запуск Windows-приложения

```powershell
flutter run -d windows
```

### Ограничения Windows UI

- QR-сканер камерой отключен (кнопка неактивна); используйте ручной ввод peer info.
- QR-генерация и copy/share остаются доступными.

## 📝 Примечания

- Protobuf код для Dart сгенерирован в `lib/generated/`
- gRPC используется как основной IPC протокол
