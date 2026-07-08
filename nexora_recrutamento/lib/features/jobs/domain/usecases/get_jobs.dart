import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/job.dart';
import '../repositories/job_repository.dart';

class GetJobs extends UseCase<List<Job>, GetJobsParams> {
  final JobRepository repository;
  const GetJobs(this.repository);

  @override
  Future<Either<Failure, List<Job>>> call(GetJobsParams params) => repository
      .getJobs(category: params.category, query: params.query, tenantId: params.tenantId);
}

class GetJobsParams extends Equatable {
  final String? category;
  final String? query;
  final int? tenantId;
  const GetJobsParams({this.category, this.query, this.tenantId});

  @override
  List<Object?> get props => [category, query, tenantId];
}
