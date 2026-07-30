import 'package:equatable/equatable.dart';

import '../../domain/entities/attendance_record_entity.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceHistoryLoaded extends AttendanceState {
  final List<AttendanceRecordEntity> records;

  const AttendanceHistoryLoaded({required this.records});

  @override
  List<Object?> get props => [records];
}

class AttendanceTodayStatusLoaded extends AttendanceState {
  final List<AttendanceRecordEntity> records;

  const AttendanceTodayStatusLoaded({required this.records});

  @override
  List<Object?> get props => [records];
}

class AttendanceRegistered extends AttendanceState {
  final AttendanceRecordEntity record;

  const AttendanceRegistered({required this.record});

  @override
  List<Object?> get props => [record];
}

class AttendancePinVerified extends AttendanceState {
  final bool valid;

  const AttendancePinVerified({required this.valid});

  @override
  List<Object?> get props => [valid];
}

class AttendanceFailure extends AttendanceState {
  final String message;

  const AttendanceFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
