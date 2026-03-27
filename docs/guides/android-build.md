# Android: сборка и запуск

## Требования

- Go 1.24+;
- Android SDK и NDK;
- Flutter SDK;
- `protoc` (если нужно регенерировать protobuf).

## Сборка daemon для Android

Linux/macOS:

```bash
cd go-backend
./build_android.sh
```

Windows:

```bat
cd go-backend
build_android.bat
```

Скрипты собирают бинарники в `go-backend/build/android/` и копируют их в `flutter-app/android/app/src/main/jniLibs/`.

## Проверка Android-конфига

Убедитесь, что в `flutter-app/android/app/build.gradle.kts` настроены нужные ABI:

- `arm64-v8a`
- `armeabi-v7a`
- `x86_64`

## Запуск приложения

```bash
cd flutter-app
flutter pub get
flutter run
```

## Полезная диагностика

- логи daemon/bridge: `adb logcat | grep -i cotune`;
- проверка статуса IPC через экран профиля в приложении.
