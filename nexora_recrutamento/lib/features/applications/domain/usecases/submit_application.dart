import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/application.dart';
import '../repositories/application_repository.dart';

class SubmitApplication extends UseCase<Application, SubmitApplicationParams> {
  final ApplicationRepository repository;
  const SubmitApplication(this.repository);

  @override
  Future<Either<Failure, Application>> call(SubmitApplicationParams params) =>
      repository.submitApplication(
        jobId: params.jobId,
        coverLetter: params.coverLetter,
      );
}

class SubmitApplicationParams extends Equatable {
  final int jobId;
  final String coverLetter;
  const SubmitApplicationParams({required this.jobId, required this.coverLetter});

  @override
  List<Object> get props => [jobId, coverLetter];
}
