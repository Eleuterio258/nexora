import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/agenda/domain/entities/aula_entity.dart';
import '../../../../features/agenda/presentation/bloc/agenda_bloc.dart';
import '../../../../features/agenda/presentation/bloc/agenda_event.dart';
import '../../../../features/agenda/presentation/bloc/agenda_state.dart';

const _navy = Color(0xFF0D1B2A);

class AgendaTab extends StatelessWidget {
  const AgendaTab({super.key});

  @override
  Widget build(BuildContext context) => const _AgendaView();
}

// ── View principal ─────────────────────────────────────────────────────────────

class _AgendaView extends StatefulWidget {
  const _AgendaView();

  @override
  State<_AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<_AgendaView> with SingleTickerProviderStateMixin {
  static const _modes = [AgendaViewMode.dia, AgendaViewMode.card, AgendaViewMode.semana];

  static const _dayAbbr   = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
  static const _dayFull   = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
  static const _monthAbbr = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    context.read<AgendaBloc>().add(AgendaViewModeChanged(_modes[_tabController.index]));
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AgendaBloc, AgendaState>(
      listener: (context, state) {
        if (state is! AgendaLoaded) return;
        final idx = _modes.indexOf(state.viewMode);
        if (_tabController.index != idx) _tabController.animateTo(idx);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: BlocBuilder<AgendaBloc, AgendaState>(
            builder: (context, state) => switch (state) {
              AgendaInitial() || AgendaLoading() =>
                const Center(child: CircularProgressIndicator()),
              AgendaError(:final message) =>
                Center(child: Text(message, style: const TextStyle(color: AppColors.error))),
              AgendaLoaded() => _buildLoaded(context, state),
            },
          ),
        ),
      ),
    );
  }

  // ── Layout principal ───────────────────────────────────────────────────────

  Widget _buildLoaded(BuildContext context, AgendaLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agenda Escolar',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _navy),
              ),
              SizedBox(height: 4),
              Text(
                'Horário de aulas da semana.',
                style: TextStyle(fontSize: 13, color: Color(0xFF8E9BAE)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // TabBar
        _buildTabBar(),
        // Week strip (oculto no modo Semana)
        if (state.viewMode != AgendaViewMode.semana) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildWeekStrip(context, state),
          ),
        ],
        const SizedBox(height: 8),
        // Conteúdo
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DiaView(state: state, monthAbbr: _monthAbbr),
              _CardView(state: state),
              _SemanaView(state: state, dayAbbr: _dayAbbr, dayFull: _dayFull, monthAbbr: _monthAbbr),
            ],
          ),
        ),
      ],
    );
  }

  // ── TabBar ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.primary,
      indicatorWeight: 2.5,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: AppColors.primary,
      unselectedLabelColor: const Color(0xFFADB5BD),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      dividerColor: const Color(0xFFE5E7EB),
      dividerHeight: 1.5,
      tabs: const [
        Tab(icon: Icon(Icons.view_agenda_outlined, size: 16), text: 'Dia'),
        Tab(icon: Icon(Icons.grid_view_rounded, size: 16),    text: 'Cards'),
        Tab(icon: Icon(Icons.calendar_view_week_outlined, size: 16), text: 'Semana'),
      ],
    );
  }

  // ── Week strip ─────────────────────────────────────────────────────────────

  Widget _buildWeekStrip(BuildContext context, AgendaLoaded state) {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.weekDays.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day        = state.weekDays[i];
          final isSelected = i == state.selectedIndex;
          final hasClasses = state.weekdayHasClasses[day.weekday] ?? false;
          return InkWell(
            onTap: () => context.read<AgendaBloc>().add(AgendaWeekdayChanged(i)),
            borderRadius: BorderRadius.circular(8),
            splashColor: AppColors.primary.withValues(alpha: 0.15),
            highlightColor: AppColors.primary.withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? null : Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayAbbr[day.weekday - 1],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF8E9BAE),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : _navy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _monthAbbr[day.month - 1],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF8E9BAE),
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 5,
                    height: hasClasses ? 5 : 0,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.primary.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Tab: Dia ───────────────────────────────────────────────────────────────────

class _DiaView extends StatelessWidget {
  const _DiaView({required this.state, required this.monthAbbr});

  final AgendaLoaded state;
  final List<String> monthAbbr;

  @override
  Widget build(BuildContext context) {
    if (state.aulas.isEmpty) return const _EmptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: state.aulas.length,
      itemBuilder: (_, i) => _AulaCard(aula: state.aulas[i]),
    );
  }
}

// ── Tab: Cards ─────────────────────────────────────────────────────────────────

class _CardView extends StatelessWidget {
  const _CardView({required this.state});

  final AgendaLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.aulas.isEmpty) return const _EmptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: state.aulas.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _SubjectCard(aula: state.aulas[i]),
      ),
    );
  }
}

// ── Tab: Semana ────────────────────────────────────────────────────────────────

class _SemanaView extends StatelessWidget {
  const _SemanaView({
    required this.state,
    required this.dayAbbr,
    required this.dayFull,
    required this.monthAbbr,
  });

  final AgendaLoaded state;
  final List<String> dayAbbr;
  final List<String> dayFull;
  final List<String> monthAbbr;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: 5,
      itemBuilder: (_, i) {
        final day     = state.weekDays[i];
        final isToday = day.day == now.day && day.month == now.month && day.year == now.year;
        final aulas   = state.weekAulas[day.weekday] ?? [];
        return _DiaSectionCard(
          day: day,
          aulas: aulas,
          isToday: isToday,
          dayAbbr: dayAbbr,
          dayFull: dayFull,
          monthAbbr: monthAbbr,
        );
      },
    );
  }
}

// ── Widgets reutilizáveis ──────────────────────────────────────────────────────

class _AulaCard extends StatelessWidget {
  const _AulaCard({required this.aula});
  final AulaEntity aula;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(aula.icon, color: aula.color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        aula.subject,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navy),
                      ),
                    ),
                    Text(
                      aula.time,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: aula.color),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(aula.teacher, style: const TextStyle(fontSize: 12, color: Color(0xFF8E9BAE))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.description_outlined, size: 13, color: aula.color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        aula.activity,
                        style: TextStyle(fontSize: 12, color: aula.color, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E0), size: 20),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.aula});
  final AulaEntity aula;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: aula.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(aula.icon, color: aula.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aula.subject,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 3),
                Text(aula.teacher, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              ],
            ),
          ),
          Text(
            aula.time,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: aula.color),
          ),
        ],
      ),
    );
  }
}

class _DiaSectionCard extends StatelessWidget {
  const _DiaSectionCard({
    required this.day,
    required this.aulas,
    required this.isToday,
    required this.dayAbbr,
    required this.dayFull,
    required this.monthAbbr,
  });

  final DateTime day;
  final List<AulaEntity> aulas;
  final bool isToday;
  final List<String> dayAbbr;
  final List<String> dayFull;
  final List<String> monthAbbr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary.withValues(alpha: 0.08) : const Color(0xFFEEF0F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primary : const Color(0xFFE8ECF0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayAbbr[day.weekday - 1],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isToday ? Colors.white : const Color(0xFF8E9BAE),
                        ),
                      ),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.white : _navy,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          dayFull[day.weekday - 1],
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navy),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Hoje',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${day.day} ${monthAbbr[day.month - 1]}  •  ${aulas.length} aula${aulas.length != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8E9BAE)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (aulas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sem aulas', style: TextStyle(fontSize: 13, color: Color(0xFF8E9BAE))),
            )
          else
            ...aulas.asMap().entries.map((e) => _SemanaRow(aula: e.value, isLast: e.key == aulas.length - 1)),
        ],
      ),
    );
  }
}

class _SemanaRow extends StatelessWidget {
  const _SemanaRow({required this.aula, required this.isLast});
  final AulaEntity aula;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 6, 12, isLast ? 12 : 0),
      child: Row(
        children: [
          Icon(aula.icon, size: 16, color: aula.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aula.subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
                Text(aula.teacher, style: const TextStyle(fontSize: 11, color: Color(0xFF8E9BAE))),
              ],
            ),
          ),
          Text(aula.time, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: aula.color)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Text('Sem aulas hoje', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navy)),
            SizedBox(height: 6),
            Text('Aproveite o descanso!', style: TextStyle(fontSize: 13, color: Color(0xFF8E9BAE))),
          ],
        ),
      ),
    );
  }
}
