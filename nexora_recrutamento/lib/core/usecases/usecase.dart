import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

abstract class UseCase<T, Params> {
  const UseCase();
  Future<Either<Failure, T>> call(Params params);
}

// Use when a use case requires no parameters.
class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object> get props => [];
}
