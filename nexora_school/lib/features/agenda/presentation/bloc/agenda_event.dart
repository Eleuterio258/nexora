import 'package:equatable/equatable.dart';

enum AgendaViewMode { dia, card, semana }

sealed class AgendaEvent extends Equatable {
  const AgendaEvent();
  @override
  List<Object?> get props => [];
}

class AgendaStarted extends AgendaEvent {}

class AgendaWeekdayChanged extends AgendaEvent {
  const AgendaWeekdayChanged(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class AgendaViewModeChanged extends AgendaEvent {
  const AgendaViewModeChanged(this.mode);
  final AgendaViewMode mode;
  @override
  List<Object?> get props => [mode];
}
