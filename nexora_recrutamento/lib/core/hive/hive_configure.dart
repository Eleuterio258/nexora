import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/applications/data/models/application_hive_model.dart';
import '../../features/jobs/data/models/job_hive_model.dart';

// Nomes das boxes — usar sempre as constantes, nunca strings soltas.
class HiveBoxes {
  HiveBoxes._();
  static const String jobs = 'jobs_box';
  static const String applications = 'applications_box';
  static const String settings = 'settings_box';
}

/// Inicializa o Hive e regista todos os adaptadores.
/// Deve ser chamado em [main] antes de [runApp].
Future<void> initHive() async {
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  if (!Hive.isAdapterRegistered(JobHiveModelAdapter().typeId)) {
    Hive.registerAdapter(JobHiveModelAdapter());
  }
  if (!Hive.isAdapterRegistered(ApplicationHiveModelAdapter().typeId)) {
    Hive.registerAdapter(ApplicationHiveModelAdapter());
  }
}

/// Abre todas as boxes antecipadamente (melhora tempo de abertura inicial).
Future<void> openHiveBoxes() async {
  await Future.wait([
    Hive.openBox<JobHiveModel>(HiveBoxes.jobs),
    Hive.openBox<ApplicationHiveModel>(HiveBoxes.applications),
    Hive.openBox<String>(HiveBoxes.settings),
  ]);
}
