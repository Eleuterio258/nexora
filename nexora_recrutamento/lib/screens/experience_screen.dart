import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/experience/data/models/experience_model.dart';
import '../features/experience/presentation/bloc/experience_bloc.dart';
import '../l10n/strings.dart';
import '../widgets/nexora_logo.dart';

class ExperienceScreen extends StatefulWidget {
  const ExperienceScreen({super.key});

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExperienceBloc>().add(const ExperiencesLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5EE),
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          strings.experienceTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 26),
            onPressed: () => _showAddSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<ExperienceBloc, ExperienceState>(
        builder: (context, state) {
          if (state is ExperienceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final experiences = state is ExperiencesLoaded
              ? state.experiences
              : <ExperienceModel>[];

          if (experiences.isEmpty) {
            return _EmptyState(
              icon: Icons.work_outline,
              label: strings.experienceEmptyTitle,
              sub: strings.experienceEmptySub,
              onAdd: () => _showAddSheet(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: experiences.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _ExpCard(
              exp: experiences[i],
              onDelete: () => context
                  .read<ExperienceBloc>()
                  .add(ExperienceDeleted(experiences[i].id)),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final experience = await Navigator.push<ExperienceModel>(
      context,
      MaterialPageRoute(builder: (_) => const _AddExpScreen()),
    );
    if (experience != null && context.mounted) {
      context.read<ExperienceBloc>().add(ExperienceCreated(experience));
    }
  }
}

class _ExpCard extends StatelessWidget {
  final ExperienceModel exp;
  final VoidCallback onDelete;

  const _ExpCard({required this.exp, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Dismissible(
      key: ValueKey(exp.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: Color(0x07000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        exp.empresa.isNotEmpty ? exp.empresa[0] : 'E',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                exp.cargo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: Color(0xFF1A2E2A),
                                ),
                              ),
                            ),
                            if (exp.actual)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F8F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  strings.experienceCurrent,
                                  style: const TextStyle(
                                    color: kPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          exp.empresa,
                          style: const TextStyle(
                            color: Color(0xFF4A5568),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (exp.local != null && exp.local!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      exp.local!,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${exp.dataInicio}${exp.dataFim != null ? ' — ${exp.dataFim}' : ''}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              if (exp.descricao != null && exp.descricao!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  exp.descricao!,
                  style: const TextStyle(
                    color: Color(0xFF4A5568),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddExpScreen extends StatefulWidget {
  const _AddExpScreen();

  @override
  State<_AddExpScreen> createState() => _AddExpScreenState();
}

class _AddExpScreenState extends State<_AddExpScreen> {
  final _cargoCtrl = TextEditingController();
  final _empresaCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _dataInicioCtrl = TextEditingController();
  final _dataFimCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  bool _actual = false;

  @override
  void dispose() {
    _cargoCtrl.dispose();
    _empresaCtrl.dispose();
    _localCtrl.dispose();
    _dataInicioCtrl.dispose();
    _dataFimCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5EE),
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          strings.experienceAdd,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetField(
              label: strings.experienceJobTitle,
              icon: Icons.work_outline,
              controller: _cargoCtrl,
            ),
            const SizedBox(height: 12),
            _SheetField(
              label: strings.experienceCompany,
              icon: Icons.business_outlined,
              controller: _empresaCtrl,
            ),
            const SizedBox(height: 12),
            _SheetField(
              label: strings.experienceLocation,
              icon: Icons.location_on_outlined,
              controller: _localCtrl,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _SheetField(
                  label: strings.experienceStartDate,
                  icon: Icons.calendar_today_outlined,
                  controller: _dataInicioCtrl,
                  hint: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetField(
                  label: strings.experienceEndDate,
                  icon: Icons.calendar_today_outlined,
                  controller: _dataFimCtrl,
                  hint: 'YYYY-MM-DD',
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _actual,
                  onChanged: (v) => setState(() => _actual = v ?? false),
                  activeColor: kPrimary,
                ),
                Text(
                  strings.experienceCurrent,
                  style: const TextStyle(
                    color: Color(0xFF1A2E2A),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SheetField(
              label: strings.experienceDescription,
              icon: Icons.notes_outlined,
              controller: _descricaoCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  strings.experienceAdd,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final cargo = _cargoCtrl.text.trim();
    final empresa = _empresaCtrl.text.trim();
    final dataInicio = _dataInicioCtrl.text.trim();

    if (cargo.isEmpty || empresa.isEmpty || dataInicio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargo, empresa e data de início são obrigatórios')),
      );
      return;
    }

    final dataFim = _dataFimCtrl.text.trim();
    final experience = ExperienceModel(
      id: 0,
      candidatoId: 0,
      cargo: cargo,
      empresa: empresa,
      local: _localCtrl.text.trim().isEmpty ? null : _localCtrl.text.trim(),
      dataInicio: dataInicio,
      dataFim: dataFim.isEmpty ? null : dataFim,
      actual: _actual,
      descricao: _descricaoCtrl.text.trim().isEmpty
          ? null
          : _descricaoCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, experience);
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;

  const _SheetField({
    required this.label,
    required this.icon,
    required this.controller,
    this.maxLines = 1,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            color: Color(0xFF9AA5B1),
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: kPrimary, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: kPrimary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A2E2A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(
              color: Color(0xFF9AA5B1),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              strings.experienceEmptyAdd,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
