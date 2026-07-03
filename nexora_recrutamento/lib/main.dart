import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';
import 'core/hive/hive_configure.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await initHive();
  await openHiveBoxes();

  FlutterNativeSplash.remove();
  runApp(const NexoraApp());
}
