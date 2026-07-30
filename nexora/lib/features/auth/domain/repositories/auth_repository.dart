import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_result_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResultEntity>> login(String username, String password);
}
