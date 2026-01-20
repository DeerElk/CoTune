# CoTune Documentation

## Структура документации

- **[Architecture](ARCHITECTURE.md)** - Архитектура системы
- **[Android Build](ANDROID_BUILD.md)** - Инструкции по сборке для Android
- **[Protobuf IPC](PROTOBUF_IPC.md)** - Протокол IPC через Protobuf/gRPC
- **[Migration Guide](MIGRATION_PROTOBUF.md)** - Руководство по миграции на Protobuf
- **[TZ Compliance](TZ_COMPLIANCE_CHECK.md)** - Проверка соответствия техническому заданию
- **[Known Issues](KNOWN_ISSUES.md)** - Известные проблемы и их решения
- **[Implementation Summary](IMPLEMENTATION_SUMMARY.md)** - Сводка реализации
- **[Final Status](FINAL_STATUS_2024.md)** - Финальный статус проекта (100% соответствие ТЗ)

## Быстрый старт

1. Прочитайте [Architecture](ARCHITECTURE.md) для понимания системы
2. Следуйте [Android Build](ANDROID_BUILD.md) для сборки
3. Ознакомьтесь с [Protobuf IPC](PROTOBUF_IPC.md) для работы с IPC

## Статус проекта

**Соответствие ТЗ: ✅ 100%**

Все компоненты реализованы и работают:
- ✅ P2P сеть на libp2p v0.45.0
- ✅ DHT для provider records (только CTID → PeerID)
- ✅ CTR (Canonical Track Resolution) с audio decoder (MP3, WAV, FFmpeg)
- ✅ Поиск без flooding (FindProviders для токенов + протокол запроса индексов)
- ✅ Chunk-based streaming (64KB chunks, переключение провайдеров)
- ✅ Protobuf/gRPC IPC сервер (localhost TCP или Unix socket)
- ✅ Go protobuf код сгенерирован
- ✅ Dart protobuf код сгенерирован
- ✅ Kotlin bridge адаптирован для protobuf IPC

Статус: ✅ Готов к использованию
