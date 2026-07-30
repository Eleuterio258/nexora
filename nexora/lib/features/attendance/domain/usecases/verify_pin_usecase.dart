import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/attendance_repository.dart';

class VerifyPinParams extends Equatable {
  final String pin;

  const VerifyPinParams({required this.pin});

  @override
  List<Object?> get props => [pin];
}

class VerifyPinUseCase implements UseCase<bool, VerifyPinParams> {
  final AttendanceRepository repository;

  VerifyPinUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(VerifyPinParams params) async {
    return await repository.verifyPin(params.pin);
  }
}
