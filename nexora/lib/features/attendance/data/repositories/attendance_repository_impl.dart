import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/device_id_provider.dart';
import '../../domain/entities/attendance_record_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  final DeviceIdProvider deviceIdProvider;

  AttendanceRepositoryImpl({
    required this.remoteDataSource,
    required this.deviceIdProvider,
  });

  Future<String> _deviceId() => deviceIdProvider.getOrCreate();

  @override
  Future<Either<Failure, AttendanceRecordEntity>> registerAttendance(
    RegisterAttendanceParams params,
  ) async {
    try {
      final result = await remoteDataSource.registerAttendance(
        deviceId: await _deviceId(),
        method: params.method.value,
        type: params.type.value,
        geoLat: params.geoLat,
        geoLng: params.geoLng,
        payload: params.payload,
      );
      return Right(result.toEntity());
    } on TimeoutException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: _cleanError(e)));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String pin) async {
    try {
      final valid = await remoteDataSource.verifyPin(
        deviceId: await _deviceId(),
        pin: pin,
      );
      return Right(valid);
    } on TimeoutException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: _cleanError(e)));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceRecordEntity>>> getHistory(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final records = await remoteDataSource.getHistory(
        start: start,
        end: end,
      );
      return Right(records.map((r) => r.toEntity()).toList());
    } on TimeoutException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: _cleanError(e)));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceRecordEntity>>> getTodayStatus() async {
    try {
      final records = await remoteDataSource.getTodayStatus();
      return Right(records.map((r) => r.toEntity()).toList());
    } on TimeoutException catch (_) {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: _cleanError(e)));
    }
  }

  String _cleanError(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }
}
