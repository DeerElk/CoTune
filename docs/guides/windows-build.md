# Windows: сборка и запуск

## Требования

- Flutter SDK с поддержкой Windows;
- Visual Studio с C++ workload;
- Go (рекомендуется, для автосборки daemon из CMake).

Включение платформы:

```powershell
flutter config --enable-windows-desktop
```

## Сборка и запуск

```powershell
cd flutter-app
flutter pub get
flutter run -d windows
```

## Как подключается daemon

При `flutter run -d windows` и `flutter build windows`:

- CMake пытается собрать `go-backend/cmd/daemon` в `cotune-daemon.exe`;
- если Go недоступен, используется prebuilt `go-backend/cotune-daemon.exe` (если файл существует).

## Явный путь к daemon (опционально)

```powershell
$env:COTUNE_DAEMON_PATH="C:\path\to\cotune-daemon.exe"
```

## Bootstrap-адреса (опционально)

```powershell
$env:COTUNE_BOOTSTRAP_ADDRS="/ip4/<ip>/udp/4001/quic-v1/p2p/<peer>,/ip4/<ip>/tcp/4001/p2p/<peer>"
```

Или через `--dart-define`:

```powershell
flutter run -d windows --dart-define=COTUNE_BOOTSTRAP_ADDRS="/ip4/<ip>/udp/4001/quic-v1/p2p/<peer>,/ip4/<ip>/tcp/4001/p2p/<peer>"
```

## Диагностика

- проверка запуска daemon - логи в консоли приложения;
- проверка сетевого статуса - карточка сети в `profile_screen`;
- если узлы не соединяются, проверьте входящие правила Windows Firewall для используемых TCP/UDP портов.
