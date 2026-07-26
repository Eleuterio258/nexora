import 'package:get_it/get_it.dart';

import 'core/push/push_notification_service.dart';
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
import 'features/auth/domain/usecases/update_profile.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/jobs/data/datasources/job_local_datasource.dart';
import 'features/jobs/data/datasources/job_remote_datasource.dart';
import 'features/jobs/data/repositories/job_repository_impl.dart';
import 'features/jobs/domain/repositories/job_repository.dart';
import 'features/jobs/domain/usecases/get_job_by_id.dart';
import 'features/jobs/domain/usecases/get_jobs.dart';
import 'features/jobs/domain/usecases/toggle_save_job.dart';
import 'features/jobs/presentation/bloc/job_bloc.dart';

import 'features/education/data/datasources/education_remote_datasource.dart';
import 'features/education/data/repositories/education_repository_impl.dart';
import 'features/education/domain/repositories/education_repository.dart';
import 'features/education/domain/usecases/create_education.dart';
import 'features/education/domain/usecases/delete_education.dart';
import 'features/education/domain/usecases/get_educations.dart';
import 'features/education/domain/usecases/update_education.dart';
import 'features/education/presentation/bloc/education_bloc.dart';

import 'features/experience/data/datasources/experience_remote_datasource.dart';
import 'features/experience/data/repositories/experience_repository_impl.dart';
import 'features/experience/domain/repositories/experience_repository.dart';
import 'features/experience/domain/usecases/create_experience.dart';
import 'features/experience/domain/usecases/delete_experience.dart';
import 'features/experience/domain/usecases/get_experiences.dart';
import 'features/experience/domain/usecases/update_experience.dart';
import 'features/experience/presentation/bloc/experience_bloc.dart';

import 'features/messages/data/datasources/chat_socket_service.dart';
import 'features/messages/data/datasources/messages_remote_datasource.dart';
import 'features/messages/data/repositories/messages_repository_impl.dart';
import 'features/messages/domain/repositories/messages_repository.dart';
import 'features/messages/domain/usecases/get_conversation_messages.dart';
import 'features/messages/domain/usecases/get_conversations.dart';
import 'features/messages/domain/usecases/send_conversation_message.dart';
import 'features/messages/presentation/bloc/messages_bloc.dart';

import 'features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'features/notifications/data/repositories/notifications_repository_impl.dart';
import 'features/notifications/domain/repositories/notifications_repository.dart';
import 'features/notifications/domain/usecases/get_notifications.dart';
import 'features/notifications/domain/usecases/mark_all_notifications_as_read.dart';
import 'features/notifications/domain/usecases/mark_notification_as_read.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';

// Configurável via --dart-define=BASE_URL=https://nexora.e258tech.tech

final getIt = GetIt.instance;

void setupDependencies() {
  // ── Core ──────────────────────────────────────────────────────────────────
  getIt.registerSingleton<LocalStore>(const SecureLocalStore());

  getIt.registerSingleton<RestClient>(DioRestClient(localStore: getIt()));
  getIt.registerSingleton<PushNotificationService>(
    PushNotificationService(client: getIt()),
  );

  // ── Datasources ───────────────────────────────────────────────────────────
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(getIt()),
  );
  getIt.registerSingleton<AuthLocalDataSource>(
    AuthLocalDataSourceImpl(getIt()),
  );
  getIt.registerSingleton<JobRemoteDataSource>(
    JobRemoteDataSourceImpl(getIt()),
  );
  getIt.registerSingleton<JobLocalDataSource>(JobLocalDataSourceImpl());
  getIt.registerSingleton<ApplicationRemoteDataSource>(
    ApplicationRemoteDataSourceImpl(client: getIt()),
  );
  getIt.registerSingleton<MessagesRemoteDataSource>(
    MessagesRemoteDataSourceImpl(client: getIt()),
  );
  getIt.registerSingleton<ChatSocketService>(
    ChatSocketService(store: getIt()),
  );
  getIt.registerSingleton<ExperienceRemoteDataSource>(
    ExperienceRemoteDataSourceImpl(client: getIt()),
  );
  getIt.registerSingleton<EducationRemoteDataSource>(
    EducationRemoteDataSourceImpl(client: getIt()),
  );
  getIt.registerSingleton<NotificationsRemoteDataSource>(
    NotificationsRemoteDataSourceImpl(client: getIt()),
  );

  // ── Repositories ──────────────────────────────────────────────────────────
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(remote: getIt(), local: getIt()),
  );
  getIt.registerSingleton<JobRepository>(
    JobRepositoryImpl(remote: getIt(), local: getIt()),
  );

  getIt.registerSingleton<ApplicationRepository>(
    ApplicationRepositoryImpl(remote: getIt()),
  );
  getIt.registerSingleton<MessagesRepository>(
    MessagesRepositoryImpl(remote: getIt()),
  );
  getIt.registerSingleton<ExperienceRepository>(
    ExperienceRepositoryImpl(remote: getIt()),
  );
  getIt.registerSingleton<EducationRepository>(
    EducationRepositoryImpl(remote: getIt()),
  );
  getIt.registerSingleton<NotificationsRepository>(
    NotificationsRepositoryImpl(remote: getIt()),
  );

  // ── Use cases ─────────────────────────────────────────────────────────────
  getIt.registerSingleton(Login(getIt()));
  getIt.registerSingleton(Register(getIt()));
  getIt.registerSingleton(Logout(getIt()));
  getIt.registerSingleton(GetCurrentUser(getIt()));
  getIt.registerSingleton(UpdateProfile(getIt()));

  getIt.registerSingleton(GetJobs(getIt()));
  getIt.registerSingleton(GetJobById(getIt()));
  getIt.registerSingleton(ToggleSaveJob(getIt()));

  getIt.registerSingleton(GetApplications(getIt()));
  getIt.registerSingleton(SubmitApplication(getIt()));

  getIt.registerSingleton(GetConversations(getIt()));
  getIt.registerSingleton(GetConversationMessages(getIt()));
  getIt.registerSingleton(SendConversationMessage(getIt()));

  getIt.registerSingleton(GetExperiences(getIt()));
  getIt.registerSingleton(CreateExperience(getIt()));
  getIt.registerSingleton(UpdateExperience(getIt()));
  getIt.registerSingleton(DeleteExperience(getIt()));

  getIt.registerSingleton(GetEducations(getIt()));
  getIt.registerSingleton(CreateEducation(getIt()));
  getIt.registerSingleton(UpdateEducation(getIt()));
  getIt.registerSingleton(DeleteEducation(getIt()));

  getIt.registerSingleton(GetNotifications(getIt()));
  getIt.registerSingleton(MarkNotificationAsRead(getIt()));
  getIt.registerSingleton(MarkAllNotificationsAsRead(getIt()));

  getIt.registerSingleton<AuthBloc>(
    AuthBloc(
      login: getIt(),
      register: getIt(),
      logout: getIt(),
      getCurrentUser: getIt(),
      updateProfile: getIt(),
    ),
  );

  getIt.registerSingleton<JobBloc>(
    JobBloc(getJobs: getIt(), toggleSave: getIt()),
  );

  getIt.registerSingleton<ApplicationBloc>(
    ApplicationBloc(getApplications: getIt(), submitApplication: getIt()),
  );

  getIt.registerSingleton<MessagesBloc>(
    MessagesBloc(getConversations: getIt()),
  );

  getIt.registerSingleton<ExperienceBloc>(
    ExperienceBloc(
      getExperiences: getIt(),
      createExperience: getIt(),
      updateExperience: getIt(),
      deleteExperience: getIt(),
    ),
  );

  getIt.registerSingleton<EducationBloc>(
    EducationBloc(
      getEducations: getIt(),
      createEducation: getIt(),
      updateEducation: getIt(),
      deleteEducation: getIt(),
    ),
  );

  getIt.registerSingleton<NotificationsBloc>(
    NotificationsBloc(
      getNotifications: getIt(),
      markAsRead: getIt(),
      markAllAsRead: getIt(),
    ),
  );
}
