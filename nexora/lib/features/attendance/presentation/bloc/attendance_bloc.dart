import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/usecases/get_attendance_history_usecase.dart';
import '../../domain/usecases/get_today_status_usecase.dart';
import '../../domain/usecases/register_attendance_usecase.dart';
import '../../domain/usecases/verify_pin_usecase.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final RegisterAttendanceUseCase registerAttendanceUseCase;
  final VerifyPinUseCase verifyPinUseCase;
  final GetAttendanceHistoryUseCase getHistoryUseCase;
  final GetTodayStatusUseCase getTodayStatusUseCase;

  AttendanceBloc({
    required this.registerAttendanceUseCase,
    required this.verifyPinUseCase,
    required this.getHistoryUseCase,
    required this.getTodayStatusUseCase,
  }) : super(AttendanceInitial()) {
    on<LoadAttendanceHistory>(_onLoadHistory);
    on<LoadTodayAttendanceStatus>(_onLoadTodayStatus);
    on<RegisterAttendance>(_onRegisterAttendance);
    on<VerifyAttendancePin>(_onVerifyPin);
    on<ResetAttendanceResult>(_onReset);
  }

  Future<void> _onLoadHistory(
    LoadAttendanceHistory event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    final result = await getHistoryUseCase(
      GetAttendanceHistoryParams(start: event.start, end: event.end),
    );
    result.fold(
      (failure) => emit(AttendanceFailure(message: failure.message)),
      (records) => emit(AttendanceHistoryLoaded(records: records)),
    );
  }

  Future<void> _onLoadTodayStatus(
    LoadTodayAttendanceStatus event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    final result = await getTodayStatusUseCase(const NoParams());
    result.fold(
      (failure) => emit(AttendanceFailure(message: failure.message)),
      (records) => emit(AttendanceTodayStatusLoaded(records: records)),
    );
  }

  Future<void> _onRegisterAttendance(
    RegisterAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    final result = await registerAttendanceUseCase(
      RegisterAttendanceParams(
        method: event.method,
        type: event.type,
        geoLat: event.geoLat,
        geoLng: event.geoLng,
        payload: event.payload,
      ),
    );
    result.fold(
      (failure) => emit(AttendanceFailure(message: failure.message)),
      (record) => emit(AttendanceRegistered(record: record)),
    );
  }

  Future<void> _onVerifyPin(
    VerifyAttendancePin event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    final result = await verifyPinUseCase(VerifyPinParams(pin: event.pin));
    result.fold(
      (failure) => emit(AttendanceFailure(message: failure.message)),
      (valid) => emit(AttendancePinVerified(valid: valid)),
    );
  }

  Future<void> _onReset(
    ResetAttendanceResult event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceInitial());
  }
}
