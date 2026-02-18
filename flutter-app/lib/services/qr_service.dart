// lib/services/qr_service.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QRService {
  QRService._(); // static-only

  /// Возвращает виджет QR-кода для UI
  static Widget qrWidget(
    String data, {
    double size = 220,
    EdgeInsets padding = const EdgeInsets.all(8),
  }) {
    return Container(
      color: Colors.white,
      padding: padding,
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        gapless: true,
      ),
    );
  }

  /// Рендерит QR в PNG-байты.
  static Future<Uint8List> renderQrToPngBytes(
    String data, {
    int size = 800,
  }) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );

    final byteData = await painter.toImageData(size.toDouble());
    if (byteData == null) {
      throw Exception('Не удалось срендерить QR');
    }
    return byteData.buffer.asUint8List();
  }

  /// Сохраняет PNG-файл во временную директорию и возвращает File.
  static Future<File> saveQrToTempFile(
    String data, {
    int size = 1000,
    String filenamePrefix = 'cotune_qr',
  }) async {
    final bytes = await renderQrToPngBytes(data, size: size);
    final tmp = await getTemporaryDirectory();
    final filename =
        '${filenamePrefix}_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${tmp.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Поделиться QR-изображением + текстом.
  /// Fallback: если не удалось — пробует текст, затем копирует в буфер.
  static Future<void> shareQr(
      BuildContext ctx,
      String data, {
        int size = 1000,
      }) async {
    try {
      final file = await saveQrToTempFile(data, size: size);
      final xfile = XFile(file.path, mimeType: 'image/png');

      await SharePlus.instance.share(
        ShareParams(
          files: [xfile],
          text: data,
        ),
      );
      return;
    } catch (_) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: data,
          ),
        );
        return;
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: data));
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text(
                'Не удалось поделиться — peer info скопирован в буфер',
              ),
            ),
          );
        }
      }
    }
  }

  /// Копирует строку в буфер обмена и показывает Snackbar.
  static Future<void> copyToClipboard(
    BuildContext ctx,
    String data, {
    String? successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: data));
    if (ctx.mounted) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text(successMessage ?? 'Скопировано')));
    }
  }
}
