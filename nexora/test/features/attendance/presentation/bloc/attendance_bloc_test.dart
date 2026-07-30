import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexora/core/errors/failures.dart';
import 'package:nexora/core/usecases/usecase.dart';
import 'package:nexora/features/attendance/domain/entities/attendance_method.dart';
import 'package:nexora/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:nexora/features/attendance/domain/entities/attendance_status.dart';
import 'package:nexora/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:nexora/features/attendance/domain/usecases/get_attendance_history_usecase.dart';
import 'package:nexora/features/attendance/domain/usecases/get_today_status_usecase.dart';
import 'package:nexora/features/attendance/domain/usecases/register_attendance_usecase.dart';
import 'package:nexora/features/attendance/domain/usecases/verify_pin_usecase.dart';
import 'package:nexora/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:nexora/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:nexora/features/attendance/presentation/bloc/attendance_state.dart';

class MockRegisterAttendanceUseCase extends Mock
    implements RegisterAttendanceUseCase {}

class MockVerifyPinUseCase extends Mock implements VerifyPinUseCase {}

class MockGetAttendanceHistoryUseCase extends Mock
    implements GetAttendanceHistoryUseCase {}

class MockGetTodayStatusUseCase extends Mock implements GetTodayStatusUseCase {}

class FakeRegisterAttendanceParams extends Fake
    implements RegisterAttendanceParams {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RegisterAttendanceParams(
      method: AttendanceMethod.manual,
      type: AttendanceType.entrada,
    ));
  });
  late AttendanceBloc bloc;
  late MockRegisterAttendanceUseCase registerAttendanceUseCase;
  late MockVerifyPinUseCase verifyPinUseCase;
  late MockGetAttendanceHistoryUseCase getHistoryUseCase;
  late MockGetTodayStatusUseCase getTodayStatusUseCase;

  setUp(() {
    registerAttendanceUseCase = MockRegisterAttendanceUseCase();
    verifyPinUseCase = MockVerifyPinUseCase();
    getHistoryUseCase = MockGetAttendanceHistoryUseCase();
    getTodayStatusUseCase = MockGetTodayStatusUseCase();
    bloc = AttendanceBloc(
      registerAttendanceUseCase: registerAttendanceUseCase,
      verifyPinUseCase: verifyPinUseCase,
      getHistoryUseCase: getHistoryUseCase,
      getTodayStatusUseCase: getTodayStatusUseCase,
    );
  });

  tearDown(() => bloc.close());

  final tRecord = AttendanceRecordEntity(
    id: '1',
    type: AttendanceType.entrada,
    method: AttendanceMethod.manual,
    recordedAt: DateTime(2026, 7, 29, 9, 0),
  );

  group('RegisterAttendance', () {
    blocTest<AttendanceBloc, AttendanceState>(
      'emite AttendanceRegistered quando o registo é bem-sucedido',
      setUp: () {
        when(() => registerAttendanceUseCase(any()))
            .thenAnswer((_) async => Right(tRecord));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const RegisterAttendance(
        method: AttendanceMethod.manual,
        type: AttendanceType.entrada,
      )),
      expect: () => [
        AttendanceLoading(),
        AttendanceRegistered(record: tRecord),
      ],
      verify: (_) {
        verify(() => registerAttendanceUseCase(const RegisterAttendanceParams(
              method: AttendanceMethod.manual,
              type: AttendanceType.entrada,
            ))).called(1);
      },
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'emite AttendanceFailure quando o registo falha',
      setUp: () {
        when(() => registerAttendanceUseCase(any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Erro no servidor')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const RegisterAttendance(
        method: AttendanceMethod.manual,
        type: AttendanceType.entrada,
      )),
      expect: () => [
        AttendanceLoading(),
        const AttendanceFailure(message: 'Erro no servidor'),
      ],
    );
  });

  group('LoadTodayAttendanceStatus', () {
    blocTest<AttendanceBloc, AttendanceState>(
      'emite AttendanceTodayStatusLoaded com os registos de hoje',
      setUp: () {
        when(() => getTodayStatusUseCase(const NoParams()))
            .thenAnswer((_) async => Right([tRecord]));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadTodayAttendanceStatus()),
      expect: () => [
        AttendanceLoading(),
        AttendanceTodayStatusLoaded(records: [tRecord]),
      ],
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'emite AttendanceFailure quando falha o carregamento',
      setUp: () {
        when(() => getTodayStatusUseCase(const NoParams()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadTodayAttendanceStatus()),
      expect: () => [
        AttendanceLoading(),
        const AttendanceFailure(message: 'Sem ligação à rede.'),
      ],
    );
  });
}
