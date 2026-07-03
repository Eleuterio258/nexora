import 'package:get_it/get_it.dart';
import '../init/app_seeder.dart';
import '../local/local_storage/i_local_storage.dart';
import '../local/local_storage/secure_local_storage_impl.dart';
import '../local/storage_keys.dart';
import '../rest_client/rest_client.dart';
import '../rest_client/dio/dio_rest_client.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/student_portal/data/datasources/student_portal_remote_datasource.dart';
import '../../features/student_portal/data/repositories/student_portal_repository_impl.dart';
import '../../features/student_portal/domain/repositories/student_portal_repository.dart';
import '../../features/student_portal/domain/usecases/get_student_boletim_usecase.dart';
import '../../features/student_portal/domain/usecases/get_student_financeiro_usecase.dart';
import '../../features/student_portal/domain/usecases/get_student_home_data_usecase.dart';
import '../../features/student_portal/domain/usecases/get_student_presencas_usecase.dart';
import '../../features/student_portal/presentation/cubit/student_boletim_cubit.dart';
import '../../features/student_portal/presentation/cubit/student_financeiro_cubit.dart';
import '../../features/student_portal/presentation/cubit/student_home_cubit.dart';
import '../../features/student_portal/presentation/cubit/student_presencas_cubit.dart';
import '../../features/agenda/data/datasources/agenda_remote_datasource.dart';
import '../../features/agenda/data/repositories/agenda_repository_impl.dart';
import '../../features/agenda/domain/repositories/agenda_repository.dart';
import '../../features/agenda/domain/usecases/get_aulas_usecase.dart';
import '../../features/agenda/presentation/bloc/agenda_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Storage
  sl.registerLazySingleton<ILocalStorage>(SecureLocalStorageImpl.new);
  sl.registerLazySingleton(() => AppSeeder(sl()));

  // Network
  sl.registerLazySingleton<RestClient>(
    () => DioRestClient(
      getToken: () => sl<ILocalStorage>().read<String>(StorageKeys.authToken),
    ),
  );

  // Datasources
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(sl()),
  );
  sl.registerLazySingleton<StudentPortalRemoteDatasource>(
    () => StudentPortalRemoteDatasourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<StudentPortalRepository>(
    () => StudentPortalRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => GetStudentHomeDataUseCase(sl()));
  sl.registerLazySingleton(() => GetStudentBoletimUseCase(sl()));
  sl.registerLazySingleton(() => GetStudentFinanceiroUseCase(sl()));
  sl.registerLazySingleton(() => GetStudentPresencasUseCase(sl()));

  // BLoC — Auth
  sl.registerFactory(() => AuthBloc(loginUseCase: sl()));

  // Cubit — Student Portal
  sl.registerFactory(() => StudentHomeCubit(sl()));
  sl.registerFactory(() => StudentBoletimCubit(sl()));
  sl.registerFactory(() => StudentFinanceiroCubit(sl()));
  sl.registerFactory(() => StudentPresencasCubit(sl()));

  // ── Agenda ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AgendaRemoteDatasource>(() => AgendaRemoteDatasourceImpl(sl()));
  sl.registerLazySingleton<AgendaRepository>(() => AgendaRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetAulasUseCase(sl()));
  sl.registerFactory(() => AgendaBloc(getAulasUseCase: sl()));
}
