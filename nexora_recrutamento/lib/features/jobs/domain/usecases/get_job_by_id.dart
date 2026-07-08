import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/job.dart';
import '../repositories/job_repository.dart';

class GetJobById extends UseCase<Job, GetJobByIdParams> {
  final JobRepository repository;
  const GetJobById(this.repository);

  @override
  Future<Either<Failure, Job>> call(GetJobByIdParams params) =>
      repository.getJobById(params.id);
}

class GetJobByIdParams extends Equatable {
  final int id;
  const GetJobByIdParams(this.id);

  @override
  List<Object?> get props => [id];
}
