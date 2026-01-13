// lib/services/acoustic_id_service.dart
class AcousticIdService {
  /// Пытается распознать файл. Возвращает: { 'title': ..., 'artist': ... }
  /// или null если не распознано / недоступно.
  Future<Map<String, String>?> identify(String path) async {
    // Заглушка: возвращаем null — трактуется как "не распознано"
    // Позже сюда интегрировать вызов внешнего сервиса/локальной библиотеки.
    await Future.delayed(const Duration(milliseconds: 200)); // легкая задержка
    return null;
  }
}
