import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cotune_mobile/services/qr_service.dart';

void main() {
  testWidgets('qrWidget renders QR image for peer info', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QRService.qrWidget(
            '{"peerId":"peer-1","addrs":["/ip4/127.0.0.1/tcp/4001"]}',
            size: 180,
          ),
        ),
      ),
    );

    expect(find.byType(QrImageView), findsOneWidget);
  });
}
