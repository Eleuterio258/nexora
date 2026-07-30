import 'package:get_it/get_it.dart';

import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/domain/usecases/get_attendance_history_usecase.dart';
import '../../features/attendance/domain/usecases/get_today_status_usecase.dart';
import '../../features/attendance/domain/usecases/register_attendance_usecase.dart';
import '../../features/attendance/domain/usecases/verify_pin_usecase.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/enviar_mensagem_usecase.dart';
import '../../features/chat/domain/usecases/get_conversas_usecase.dart';
import '../../features/chat/domain/usecases/get_mensagens_usecase.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/ferias/data/datasources/ferias_remote_datasource.dart';
import '../../features/ferias/data/repositories/ferias_repository_impl.dart';
import '../../features/ferias/domain/repositories/ferias_repository.dart';
import '../../features/ferias/domain/usecases/cancelar_pedido_ferias_usecase.dart';
import '../../features/ferias/domain/usecases/criar_pedido_ferias_usecase.dart';
import '../../features/ferias/domain/usecases/get_meus_pedidos_ferias_usecase.dart';
import '../../features/ferias/domain/usecases/get_tipos_ausencia_usecase.dart';
import '../../features/ferias/presentation/bloc/ferias_bloc.dart';
import '../local/local_storege/flutter_secure_local_storege_imp.dart';
import '../local/local_storege/i_local_storege.dart';
import '../rest_client/dio/dio_rest_client.dart';
import '../rest_client/rest_client.dart';
import '../services/device_id_provider.dart';
import '../services/session_manager.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies({ILocalSecureStorege? secureStorage}) async {
  final storage = secureStorage ?? FlutterSecureLocalStoregeImp();
  final sessionManager = await SessionManager.create(storage);

  sl
    ..registerLazySingleton<SessionManager>(() => sessionManager)
    ..registerLazySingleton<ILocalSecureStorege>(() => storage)
    ..registerLazySingleton<RestClient>(() => DioRestClient(localStorege: sl()))
    ..registerLazySingleton<DeviceIdProvider>(() => DeviceIdProvider(sl()))
    ..registerLazySingleton<AttendanceRemoteDataSource>(
      () => AttendanceRemoteDataSourceImpl(restClient: sl()),
    )
    ..registerLazySingleton<AttendanceRepository>(
      () => AttendanceRepositoryImpl(
        remoteDataSource: sl(),
        deviceIdProvider: sl(),
      ),
    )
    ..registerLazySingleton<RegisterAttendanceUseCase>(
      () => RegisterAttendanceUseCase(sl()),
    )
    ..registerLazySingleton<VerifyPinUseCase>(() => VerifyPinUseCase(sl()))
    ..registerLazySingleton<GetAttendanceHistoryUseCase>(
      () => GetAttendanceHistoryUseCase(sl()),
    )
    ..registerLazySingleton<GetTodayStatusUseCase>(
      () => GetTodayStatusUseCase(sl()),
    )
    ..registerFactory<AttendanceBloc>(
      () => AttendanceBloc(
        registerAttendanceUseCase: sl(),
        verifyPinUseCase: sl(),
        getHistoryUseCase: sl(),
        getTodayStatusUseCase: sl(),
      ),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(restClient: sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl()),
    )
    ..registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl()))
    ..registerFactory<AuthBloc>(
      () => AuthBloc(loginUseCase: sl(), sessionManager: sl()),
    )
    ..registerLazySingleton<FeriasRemoteDataSource>(
      () => FeriasRemoteDataSourceImpl(restClient: sl()),
    )
    ..registerLazySingleton<FeriasRepository>(
      () => FeriasRepositoryImpl(remoteDataSource: sl()),
    )
    ..registerLazySingleton<GetTiposAusenciaUseCase>(
      () => GetTiposAusenciaUseCase(sl()),
    )
    ..registerLazySingleton<GetMeusPedidosFeriasUseCase>(
      () => GetMeusPedidosFeriasUseCase(sl()),
    )
    ..registerLazySingleton<CriarPedidoFeriasUseCase>(
      () => CriarPedidoFeriasUseCase(sl()),
    )
    ..registerLazySingleton<CancelarPedidoFeriasUseCase>(
      () => CancelarPedidoFeriasUseCase(sl()),
    )
    ..registerFactory<FeriasBloc>(
      () => FeriasBloc(
        getTiposAusenciaUseCase: sl(),
        getMeusPedidosUseCase: sl(),
        criarPedidoUseCase: sl(),
        cancelarPedidoUseCase: sl(),
      ),
    )
    ..registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(restClient: sl()),
    )
    ..registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(remoteDataSource: sl()),
    )
    ..registerLazySingleton<GetConversasUseCase>(
      () => GetConversasUseCase(sl()),
    )
    ..registerLazySingleton<GetMensagensUseCase>(
      () => GetMensagensUseCase(sl()),
    )
    ..registerLazySingleton<EnviarMensagemUseCase>(
      () => EnviarMensagemUseCase(sl()),
    )
    ..registerFactory<ChatBloc>(
      () => ChatBloc(
        getConversasUseCase: sl(),
        getMensagensUseCase: sl(),
        enviarMensagemUseCase: sl(),
      ),
    );
}
