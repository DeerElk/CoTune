import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('tracks');
  await Hive.openBox('artists');
  await Hive.openBox('playlists');

  runApp(const CotuneApp());
}
