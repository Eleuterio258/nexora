import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nexora_school/nexora_school_app.dart';
import 'core/di/injection.dart';
import 'features/branding/presentation/controllers/branding_controller.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await setupDependencies();

  // Aplica o branding guardado em cache o mais cedo possível, antes da
  // primeira frame, para evitar flash de cor por omissão.
  await sl<BrandingController>().loadFromCache();

  runApp(const NexoraSchoolApp());
}
