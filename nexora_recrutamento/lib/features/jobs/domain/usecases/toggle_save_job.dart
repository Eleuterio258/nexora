import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/job.dart';
import '../repositories/job_repository.dart';

class ToggleSaveJob extends UseCase<Unit, ToggleSaveJobParams> {
  final JobRepository repository;
  const ToggleSaveJob(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ToggleSaveJobParams params) => params.save
      ? repository.saveJob(params.job)
      : repository.unsaveJob(params.job.id);
}

class ToggleSaveJobParams extends Equatable {
  final Job job;
  final bool save;
  const ToggleSaveJobParams({required this.job, required this.save});

  @override
  List<Object> get props => [job, save];
}
