import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexora/core/errors/failures.dart';
import 'package:nexora/features/attendance/domain/entities/attendance_method.dart';
import 'package:nexora/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:nexora/features/attendance/domain/entities/attendance_status.dart';
import 'package:nexora/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:nexora/features/attendance/domain/usecases/register_attendance_usecase.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  late RegisterAttendanceUseCase useCase;
  late MockAttendanceRepository repository;

  setUp(() {
    repository = MockAttendanceRepository();
    useCase = RegisterAttendanceUseCase(repository);
  });

  const tParams = RegisterAttendanceParams(
    method: AttendanceMethod.manual,
    type: AttendanceType.entrada,
  );

  final tRecord = AttendanceRecordEntity(
    id: '1',
    type: AttendanceType.entrada,
    method: AttendanceMethod.manual,
    recordedAt: DateTime(2026, 7, 29, 9, 0),
  );

  test('deve devolver AttendanceRecordEntity quando o registo for bem-sucedido', () async {
    when(() => repository.registerAttendance(tParams))
        .thenAnswer((_) async => Right(tRecord));

    final result = await useCase(tParams);

    expect(result, Right(tRecord));
    verify(() => repository.registerAttendance(tParams)).called(1);
  });

  test('deve devolver Failure quando o registo falhar', () async {
    when(() => repository.registerAttendance(tParams))
        .thenAnswer((_) async => const Left(ServerFailure()));

    final result = await useCase(tParams);

    expect(result, const Left(ServerFailure()));
    verify(() => repository.registerAttendance(tParams)).called(1);
  });
}
