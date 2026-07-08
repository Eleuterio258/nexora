import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/deeplink/deep_link_service.dart';
import 'core/hive/hive_configure.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/jobs/domain/usecases/get_job_by_id.dart';
import 'firebase_options.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initHive();
  await openHiveBoxes();

  setupDependencies();
  getIt<AuthBloc>().add(const AuthCheckRequested());

  // Abre directamente o detalhe da vaga quando a app é lançada a partir de
  // um link nexoraapp://vaga/<id> partilhado (ver job_details_screen.dart).
  DeepLinkService(getJobById: getIt<GetJobById>()).start();

  runApp(const NexoraApp());
}
