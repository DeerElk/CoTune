# Android Build Instructions - Go Daemon Process

## Архитектура

Используется подход с отдельным Go daemon процессом:
- Go daemon компилируется как нативный бинарник для Android (executable)
- Kotlin запускает daemon через ProcessBuilder
- Общение через Protobuf/gRPC IPC (localhost TCP или Unix socket)

## Требования

- Go 1.24.6+
- Android NDK (рекомендуется версия 25.x)
- Android SDK
- Flutter SDK
- Protocol Buffers compiler (`protoc`) для генерации Dart кода (опционально, код уже сгенерирован)
- Gradle protobuf плагин автоматически генерирует Kotlin/Java код при сборке

## Сборка Go Daemon для Android

### Linux/macOS

```bash
cd go-backend
chmod +x build_android.sh
./build_android.sh
```

### Windows

```cmd
cd go-backend
build_android.bat
```

Скрипты создадут бинарники в `build/android/`:
- `arm64-v8a/cotune-daemon`
- `armeabi-v7a/cotune-daemon`
- `x86_64/cotune-daemon`

## Интеграция в Android проект

### 1. Копирование бинарников

**Автоматически**: Скрипты сборки автоматически копируют бинарники в Flutter проект.

**Вручную** (если нужно):
```bash
# Linux/macOS
cp -r go-backend/build/android/* flutter-app/android/app/src/main/jniLibs/

# Windows
xcopy /E /I go-backend\build\android\* flutter-app\android\app\src\main\jniLibs\
```

### 2. Проверка build.gradle.kts

Убедитесь, что в `flutter-app/android/app/build.gradle.kts` есть:

```kotlin
android {
    ndk {
        abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
    }
    
    packaging {
        jniLibs {
            useLegacyPackaging = false
            pickFirsts += listOf("**/cotune-daemon")
        }
    }
}
```

### 3. Проверка AndroidManifest.xml

Убедитесь, что есть необходимые permissions (уже есть в проекте).

## Запуск Daemon

Kotlin bridge (`CotuneNodePlugin.kt`) автоматически:
1. Находит `cotune-daemon` бинарник в native library directory
2. Запускает его как процесс с параметрами (`-proto` для IPC адреса)
3. Проверяет Protobuf/gRPC IPC для подтверждения запуска
4. Останавливает процесс при необходимости

**IPC протокол**: Protobuf/gRPC через localhost TCP (по умолчанию `127.0.0.1:7777`) или Unix socket

## Структура файлов

```
go-backend/
├── cmd/daemon/main.go          # Go daemon entry point
├── api/cotune.proto            # Protobuf schema
├── build_android.sh            # Linux/macOS build script
├── build_android.bat           # Windows build script
└── build/android/              # Output directory
    ├── arm64-v8a/cotune-daemon
    ├── armeabi-v7a/cotune-daemon
    └── x86_64/cotune-daemon

flutter-app/android/app/src/main/
├── jniLibs/                    # Native binaries (copy here)
│   ├── arm64-v8a/cotune-daemon
│   ├── armeabi-v7a/cotune-daemon
│   └── x86_64/cotune-daemon
└── kotlin/ru/apps78/cotune/
    └── CotuneNodePlugin.kt     # Kotlin bridge (protobuf client)
```

## Тестирование

1. Соберите Go daemon для Android
2. Скопируйте библиотеки в jniLibs
3. Соберите Flutter APK
4. Установите на устройство
5. Проверьте логи: `adb logcat | grep -i cotune`

## Troubleshooting

### Проблема: бинарник не найден

**Решение**: Убедитесь, что:
- `cotune-daemon` файлы находятся в правильных директориях `jniLibs/`
- ABI фильтры соответствуют собранным бинарникам
- Права на выполнение установлены (`chmod +x` на Linux/macOS)

### Проблема: daemon не запускается

**Решение**:
- Проверьте логи через `adb logcat | grep -i cotune`
- Убедитесь, что Protobuf IPC порт доступен (по умолчанию `127.0.0.1:7777`)
- Проверьте permissions в AndroidManifest.xml
- Убедитесь, что бинарник имеет права на выполнение

### Проблема: ошибка компиляции Go

**Решение**:
- Убедитесь, что NDK установлен и путь правильный
- Проверьте версию Go (должна быть 1.24.6+)
- Убедитесь, что CGO_ENABLED=1
- Проект использует libp2p v0.32.2 (стабильная версия без проблем webtransport)
