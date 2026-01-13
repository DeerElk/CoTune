import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;

/// Top-level функция для использования в compute().
Future<String> computeMd5(String path) async {
  final bytes = await File(path).readAsBytes();
  return crypto.md5.convert(bytes).toString();
}
