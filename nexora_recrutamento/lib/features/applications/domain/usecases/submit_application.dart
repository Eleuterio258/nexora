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
        jobTitle: params.jobTitle,
        nome: params.nome,
        email: params.email,
        telefone: params.telefone,
        coverLetter: params.coverLetter,
      );
}

class SubmitApplicationParams extends Equatable {
  final int jobId;
  final String jobTitle;
  final String nome;
  final String email;
  final String? telefone;
  final String coverLetter;
  const SubmitApplicationParams({
    required this.jobId,
    required this.jobTitle,
    required this.nome,
    required this.email,
    this.telefone,
    required this.coverLetter,
  });

  @override
  List<Object?> get props =>
      [jobId, jobTitle, nome, email, telefone, coverLetter];
}
