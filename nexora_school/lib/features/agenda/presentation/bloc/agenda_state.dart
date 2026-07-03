import 'package:equatable/equatable.dart';
import '../../domain/entities/aula_entity.dart';
import 'agenda_event.dart';

sealed class AgendaState extends Equatable {
  const AgendaState();
  @override
  List<Object?> get props => [];
}

class AgendaInitial extends AgendaState {
  const AgendaInitial();
}

class AgendaLoading extends AgendaState {
  const AgendaLoading();
}

class AgendaLoaded extends AgendaState {
  const AgendaLoaded({
    required this.aulas,
    required this.viewMode,
    required this.selectedIndex,
    required this.weekDays,
    required this.weekdayHasClasses,
    required this.weekAulas,
  });

  final List<AulaEntity> aulas;
  final AgendaViewMode viewMode;
  final int selectedIndex;
  final List<DateTime> weekDays;
  final Map<int, bool> weekdayHasClasses;
  final Map<int, List<AulaEntity>> weekAulas;

  AgendaLoaded copyWith({
    List<AulaEntity>? aulas,
    AgendaViewMode? viewMode,
    int? selectedIndex,
    List<DateTime>? weekDays,
    Map<int, bool>? weekdayHasClasses,
    Map<int, List<AulaEntity>>? weekAulas,
  }) =>
      AgendaLoaded(
        aulas: aulas ?? this.aulas,
        viewMode: viewMode ?? this.viewMode,
        selectedIndex: selectedIndex ?? this.selectedIndex,
        weekDays: weekDays ?? this.weekDays,
        weekdayHasClasses: weekdayHasClasses ?? this.weekdayHasClasses,
        weekAulas: weekAulas ?? this.weekAulas,
      );

  @override
  List<Object?> get props => [aulas, viewMode, selectedIndex, weekDays, weekdayHasClasses, weekAulas];
}

class AgendaError extends AgendaState {
  const AgendaError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
