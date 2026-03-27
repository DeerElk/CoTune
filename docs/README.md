# Документация CoTune

Этот документ - единая точка входа по всей документации проекта.
Все рабочие материалы и эксплуатационные инструкции находятся только в `docs/`.

## С чего начать

### Для разработчика

1. Прочитайте [архитектуру](architecture/architecture.md).
2. Ознакомьтесь с [IPC API](api/protobuf-ipc.md).
3. Выберите платформенный гайд:
   - [Android](guides/android-build.md)
   - [Windows](guides/windows-build.md)

### Для QA

1. Поднимите локальную тест-сеть по [гайду Docker-тестирования](testing/docker-test-network.md).
2. Проверьте типовые проблемы в [документе по диагностике](operations/troubleshooting.md).
3. Используйте [релизный чеклист](release/release-checklist.md) для предрелизной проверки.

### Для Ops

1. Настройте bootstrap-peer по [операционному гайду](operations/bootstrap-deploy.md).
2. Проверьте [типовые инциденты и диагностику](operations/troubleshooting.md).
3. Перед релизом пройдите [релизный чеклист](release/release-checklist.md).

## Разделы документации

- `architecture/`
  - [Общая архитектура CoTune](architecture/architecture.md)
  - [Архитектура bootstrap-peer](architecture/bootstrap-peer.md)
- `api/`
  - [Protobuf/gRPC IPC](api/protobuf-ipc.md)
- `guides/`
  - [Сборка и запуск Android](guides/android-build.md)
  - [Сборка и запуск Windows](guides/windows-build.md)
- `testing/`
  - [Docker тест-сеть](testing/docker-test-network.md)
- `operations/`
  - [Развертывание bootstrap-peer](operations/bootstrap-deploy.md)
  - [Диагностика и типовые проблемы](operations/troubleshooting.md)
- `release/`
  - [Релизный чеклист](release/release-checklist.md)
