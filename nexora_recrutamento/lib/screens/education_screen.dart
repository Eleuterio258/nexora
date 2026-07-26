import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/education/data/models/education_model.dart';
import '../features/education/presentation/bloc/education_bloc.dart';
import '../l10n/strings.dart';
import '../widgets/nexora_logo.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EducationBloc>().add(const EducationsLoadRequested());
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
          strings.educationTitle,
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
      body: BlocBuilder<EducationBloc, EducationState>(
        builder: (context, state) {
          if (state is EducationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final educations = state is EducationsLoaded
              ? state.educations
              : <EducationModel>[];

          if (educations.isEmpty) {
            return _EmptyState(
              icon: Icons.school_outlined,
              label: strings.educationEmptyTitle,
              sub: strings.educationEmptySub,
              onAdd: () => _showAddSheet(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: educations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _EduCard(
              edu: educations[i],
              onDelete: () => context
                  .read<EducationBloc>()
                  .add(EducationDeleted(educations[i].id)),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final education = await Navigator.push<EducationModel>(
      context,
      MaterialPageRoute(builder: (_) => const _AddEduScreen()),
    );
    if (education != null && context.mounted) {
      context.read<EducationBloc>().add(EducationCreated(education));
    }
  }
}

class _EduCard extends StatelessWidget {
  final EducationModel edu;
  final VoidCallback onDelete;

  const _EduCard({required this.edu, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(edu.id),
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
                      color: const Color(0xFF4A5568),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        edu.instituicao.isNotEmpty ? edu.instituicao[0] : 'I',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edu.curso,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1A2E2A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          edu.instituicao,
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
              if (edu.local != null && edu.local!.isNotEmpty) ...[
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
                      edu.local!,
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
                    '${edu.anoInicio ?? ''}${edu.anoFim != null ? ' — ${edu.anoFim}' : ''}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              if (edu.nota != null && edu.nota!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.grade_outlined,
                      size: 13,
                      color: kPrimary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      edu.nota!,
                      style: const TextStyle(
                        color: kPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddEduScreen extends StatefulWidget {
  const _AddEduScreen();

  @override
  State<_AddEduScreen> createState() => _AddEduScreenState();
}

class _AddEduScreenState extends State<_AddEduScreen> {
  final _cursoCtrl = TextEditingController();
  final _instituicaoCtrl = TextEditingController();
  final _localCtrl = TextEditingController();
  final _anoInicioCtrl = TextEditingController();
  final _anoFimCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();

  @override
  void dispose() {
    _cursoCtrl.dispose();
    _instituicaoCtrl.dispose();
    _localCtrl.dispose();
    _anoInicioCtrl.dispose();
    _anoFimCtrl.dispose();
    _notaCtrl.dispose();
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
          strings.educationAdd,
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
              label: strings.educationDegree,
              icon: Icons.school_outlined,
              controller: _cursoCtrl,
            ),
            const SizedBox(height: 12),
            _SheetField(
              label: strings.educationInstitution,
              icon: Icons.account_balance_outlined,
              controller: _instituicaoCtrl,
            ),
            const SizedBox(height: 12),
            _SheetField(
              label: strings.educationLocation,
              icon: Icons.location_on_outlined,
              controller: _localCtrl,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _SheetField(
                  label: strings.educationStartYear,
                  icon: Icons.calendar_today_outlined,
                  controller: _anoInicioCtrl,
                  keyboard: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetField(
                  label: strings.educationEndYear,
                  icon: Icons.calendar_today_outlined,
                  controller: _anoFimCtrl,
                  keyboard: TextInputType.number,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _SheetField(
              label: strings.educationGrade,
              icon: Icons.grade_outlined,
              controller: _notaCtrl,
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
                  strings.educationAdd,
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
    final curso = _cursoCtrl.text.trim();
    final instituicao = _instituicaoCtrl.text.trim();

    if (curso.isEmpty || instituicao.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Curso e instituição são obrigatórios')),
      );
      return;
    }

    final anoInicioText = _anoInicioCtrl.text.trim();
    final anoFimText = _anoFimCtrl.text.trim();

    final education = EducationModel(
      id: 0,
      candidatoId: 0,
      curso: curso,
      instituicao: instituicao,
      local: _localCtrl.text.trim().isEmpty ? null : _localCtrl.text.trim(),
      anoInicio: anoInicioText.isEmpty ? null : int.tryParse(anoInicioText),
      anoFim: anoFimText.isEmpty ? null : int.tryParse(anoFimText),
      nota: _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, education);
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboard;

  const _SheetField({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboard = TextInputType.text,
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
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
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
              strings.educationEmptyAdd,
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
