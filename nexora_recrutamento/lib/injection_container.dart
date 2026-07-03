import 'package:get_it/get_it.dart';

import 'core/network/api_client.dart';
import 'core/rest_client/dio/dio_rest_client.dart';
import 'core/rest_client/rest_client.dart';
import 'core/storage/impl/secure_local_store.dart';
import 'core/storage/local_store.dart';

import 'features/applications/data/datasources/application_remote_datasource.dart';
import 'features/applications/data/repositories/application_repository_impl.dart';
import 'features/applications/domain/repositories/application_repository.dart';
import 'features/applications/domain/usecases/get_applications.dart';
import 'features/applications/domain/usecases/submit_application.dart';
import 'features/applications/presentation/bloc/application_bloc.dart';

import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/login.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/domain/usecases/register.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/jobs/data/datasources/job_remote_datasource.dart';
import 'features/jobs/data/repositories/job_repository_impl.dart';
import 'features/jobs/domain/repositories/job_repository.dart';
import 'features/jobs/domain/usecases/get_jobs.dart';
import 'features/jobs/domain/usecases/toggle_save_job.dart';
import 'features/jobs/presentation/bloc/job_bloc.dart';

// Configurável via --dart-define=BASE_URL=https://nexora.e258tech.tech
const _baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

final _getIt = GetIt.instance;

/// Ponto de entrada único para injecção de dependências.
/// Uso: `sl.authBloc()`, `sl.jobBloc()`, `sl.applicationBloc()`
final sl = ServiceLocator._();

class ServiceLocator {
  ServiceLocator._() {
    _register();
  }

  void _register() {
    // ── Core ──────────────────────────────────────────────────────────────────
    _getIt.registerSingleton<LocalStore>(const SecureLocalStore());

    _getIt.registerSingleton<RestClient>(
      DioRestClient(baseUrl: _baseUrl, store: _getIt()),
    );

    _getIt.registerSingleton<ApiClient>(ApiClient(_getIt()));

    // ── Datasources ───────────────────────────────────────────────────────────
    _getIt.registerSingleton<AuthRemoteDataSource>(
      AuthRemoteDataSourceImpl(_getIt()),
    );
    _getIt.registerSingleton<AuthLocalDataSource>(
      AuthLocalDataSourceImpl(_getIt()),
    );
    _getIt.registerSingleton<JobRemoteDataSource>(
      JobRemoteDataSourceImpl(_getIt()),
    );
    _getIt.registerSingleton<ApplicationRemoteDataSource>(
      ApplicationRemoteDataSourceImpl(_getIt()),
    );

    // ── Repositories ──────────────────────────────────────────────────────────
    _getIt.registerSingleton<AuthRepository>(
      AuthRepositoryImpl(remote: _getIt(), local: _getIt()),
    );
    _getIt.registerSingleton<JobRepository>(
      JobRepositoryImpl(remote: _getIt()),
    );
    // token vazio: a autenticação é gerida pelo AuthInterceptor no DioRestClient
    _getIt.registerSingleton<ApplicationRepository>(
      ApplicationRepositoryImpl(remote: _getIt(), token: ''),
    );

    // ── Use cases ─────────────────────────────────────────────────────────────
    _getIt.registerSingleton(Login(_getIt()));
    _getIt.registerSingleton(Register(_getIt()));
    _getIt.registerSingleton(Logout(_getIt()));
    _getIt.registerSingleton(GetCurrentUser(_getIt()));

    _getIt.registerSingleton(GetJobs(_getIt()));
    _getIt.registerSingleton(ToggleSaveJob(_getIt()));

    _getIt.registerSingleton(GetApplications(_getIt()));
    _getIt.registerSingleton(SubmitApplication(_getIt()));
  }

  // ── BLoC factories ────────────────────────────────────────────────────────

  AuthBloc authBloc() => AuthBloc(
        login: _getIt(),
        register: _getIt(),
        logout: _getIt(),
        getCurrentUser: _getIt(),
      );

  JobBloc jobBloc() => JobBloc(
        getJobs: _getIt(),
        toggleSave: _getIt(),
      );

  ApplicationBloc applicationBloc() => ApplicationBloc(
        getApplications: _getIt(),
        submitApplication: _getIt(),
      );
}
