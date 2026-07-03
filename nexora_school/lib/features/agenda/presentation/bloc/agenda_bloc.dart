import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/aula_entity.dart';
import '../../domain/usecases/get_aulas_usecase.dart';
import 'agenda_event.dart';
import 'agenda_state.dart';

class AgendaBloc extends Bloc<AgendaEvent, AgendaState> {
  AgendaBloc({required GetAulasUseCase getAulasUseCase})
      : _getAulas = getAulasUseCase,
        super(const AgendaInitial()) {
    on<AgendaStarted>(_onStarted);
    on<AgendaWeekdayChanged>(_onWeekdayChanged);
    on<AgendaViewModeChanged>(_onViewModeChanged);
  }

  final GetAulasUseCase _getAulas;

  Future<Map<int, List<AulaEntity>>> _computeWeekAulas() async {
    final map = <int, List<AulaEntity>>{};
    for (var wd = 1; wd <= 7; wd++) {
      final result = await _getAulas(wd);
      map[wd] = result.fold((_) => [], (l) => l);
    }
    return map;
  }

  Future<void> _onStarted(AgendaStarted event, Emitter<AgendaState> emit) async {
    emit(const AgendaLoading());
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final selectedIndex = now.weekday - 1;
    final weekAulas = await _computeWeekAulas();
    final weekdayHasClasses = {
      for (final e in weekAulas.entries) e.key: e.value.isNotEmpty,
    };

    emit(AgendaLoaded(
      aulas: weekAulas[weekDays[selectedIndex].weekday] ?? [],
      viewMode: AgendaViewMode.dia,
      selectedIndex: selectedIndex,
      weekDays: weekDays,
      weekdayHasClasses: weekdayHasClasses,
      weekAulas: weekAulas,
    ));
  }

  Future<void> _onWeekdayChanged(AgendaWeekdayChanged event, Emitter<AgendaState> emit) async {
    final current = state;
    if (current is! AgendaLoaded) return;

    final result = await _getAulas(current.weekDays[event.index].weekday);
    result.fold(
      (_) => emit(const AgendaError('Erro ao carregar agenda.')),
      (aulas) => emit(current.copyWith(aulas: aulas, selectedIndex: event.index)),
    );
  }

  void _onViewModeChanged(AgendaViewModeChanged event, Emitter<AgendaState> emit) {
    final current = state;
    if (current is! AgendaLoaded) return;

    if (event.mode != AgendaViewMode.semana) {
      final todayIndex = DateTime.now().weekday - 1;
      final todayAulas = current.weekAulas[current.weekDays[todayIndex].weekday] ?? [];
      emit(current.copyWith(
        viewMode: event.mode,
        selectedIndex: todayIndex,
        aulas: todayAulas,
      ));
    } else {
      emit(current.copyWith(viewMode: event.mode));
    }
  }
}
