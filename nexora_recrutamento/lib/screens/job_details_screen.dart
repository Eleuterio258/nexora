import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../features/applications/presentation/bloc/application_bloc.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/jobs/domain/entities/job.dart';
import '../features/jobs/presentation/bloc/job_bloc.dart';
import '../widgets/nexora_logo.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job job;
  const JobDetailsScreen({super.key, required this.job});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  int _tab = 0;
  bool _descExpanded = true;
  bool _reqExpanded = true;
  late bool _saved;

  Job get job => widget.job;

  @override
  void initState() {
    super.initState();
    _saved = widget.job.isSaved;
  }

  void _toggleSave() {
    final save = !_saved;
    setState(() => _saved = save);
    context.read<JobBloc>().add(JobSaveToggled(job: job, save: save));
  }

  void _share(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    // nexoraapp://vaga/<id> — abre directamente este ecrã em quem já tem a
    // app instalada (ver DeepLinkService, registado em main.dart).
    final link = 'nexoraapp://vaga/${job.id}';
    SharePlus.instance.share(
      ShareParams(
        subject: job.title,
        text: 'Vaga: ${job.title} — ${job.company}\n'
            '${job.location} · ${job.type}\n\n'
            'Vê os detalhes na app Nexora Recrutamento:\n$link',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }

  void _openApplySheet(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie sessão para se candidatar.')),
      );
      return;
    }
    final user = authState.user;
    // ApplicationBloc é global (app.dart) — a folha de candidatura reutiliza-o
    // e, ao terminar, o próprio bloc é o que já alimenta Applications/Dashboard.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ApplySheet(job: job, nome: user.nome, email: user.email),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2E2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            NexoraLogoIcon(size: 22),
            SizedBox(width: 8),
            Text(
              'NEXORA',
              style: TextStyle(
                color: Color(0xFF1A2E2A),
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _saved ? Icons.bookmark : Icons.bookmark_border,
              color: const Color(0xFF1A2E2A),
            ),
            onPressed: _toggleSave,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2E2A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Meta chips row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (job.category.isNotEmpty)
                          _MetaChip(icon: Icons.work_outline, label: job.category),
                        if (job.category.isNotEmpty) const SizedBox(width: 10),
                        _MetaChip(
                            icon: Icons.location_on_outlined, label: job.location),
                        const SizedBox(width: 10),
                        _MetaChip(icon: Icons.business_outlined, label: job.type),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Company card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      boxShadow: [
                        BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const NexoraLogoIcon(size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      job.company,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFF1A2E2A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: kPrimary, size: 16),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                job.numberOfPositions > 1
                                    ? '${job.numberOfPositions} vagas disponíveis'
                                    : '1 vaga disponível',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tab bar
                  Row(
                    children: [
                      _TabItem(
                          label: 'Descrição',
                          active: _tab == 0,
                          onTap: () => setState(() => _tab = 0)),
                      const SizedBox(width: 24),
                      _TabItem(
                          label: 'Requisitos',
                          active: _tab == 1,
                          onTap: () => setState(() => _tab = 1)),
                      const SizedBox(width: 24),
                      _TabItem(
                          label: 'Benefícios',
                          active: _tab == 2,
                          onTap: () => setState(() => _tab = 2)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),

                  // ── Tab 0: Descrição ──
                  if (_tab == 0) ...[
                    _ExpandableSection(
                      icon: Icons.description_outlined,
                      title: 'Sobre a função',
                      expanded: _descExpanded,
                      onToggle: () =>
                          setState(() => _descExpanded = !_descExpanded),
                      child: Text(
                        (job.about != null && job.about!.isNotEmpty)
                            ? job.about!
                            : job.description,
                        style: const TextStyle(
                            color: Color(0xFF4A5568), fontSize: 14, height: 1.6),
                      ),
                    ),
                    if (job.responsibilities.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _ExpandableSection(
                        icon: Icons.work_history_outlined,
                        title: 'Responsabilidades',
                        expanded: _reqExpanded,
                        onToggle: () =>
                            setState(() => _reqExpanded = !_reqExpanded),
                        child: Column(
                          children: job.responsibilities
                              .map((r) => _BulletItem(r))
                              .toList(),
                        ),
                      ),
                    ],
                  ],

                  // ── Tab 1: Requisitos ──
                  if (_tab == 1) ...[
                    if (job.requiredQualifications.isNotEmpty)
                      _ExpandableSection(
                        icon: Icons.school_outlined,
                        title: 'Requisitos obrigatórios',
                        expanded: _descExpanded,
                        onToggle: () =>
                            setState(() => _descExpanded = !_descExpanded),
                        child: Column(
                          children: job.requiredQualifications
                              .map((r) => _BulletItem(r))
                              .toList(),
                        ),
                      ),
                    if (job.preferredQualifications.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _ExpandableSection(
                        icon: Icons.star_outline,
                        title: 'Preferenciais',
                        expanded: _reqExpanded,
                        onToggle: () =>
                            setState(() => _reqExpanded = !_reqExpanded),
                        child: Column(
                          children: job.preferredQualifications
                              .map((r) => _BulletItem(r))
                              .toList(),
                        ),
                      ),
                    ],
                    if (job.requiredQualifications.isEmpty &&
                        job.preferredQualifications.isEmpty)
                      Text(
                        'Sem requisitos específicos indicados para esta vaga.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                  ],

                  // ── Tab 2: Benefícios ──
                  if (_tab == 2) ...[
                    if (job.benefits.isNotEmpty)
                      _BenefitCard(
                        icon: Icons.celebration_outlined,
                        title: 'O que oferecemos',
                        items: job.benefits,
                      )
                    else
                      Text(
                        'Sem benefícios específicos indicados para esta vaga.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Bottom action bar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                job.deadline != null ? 'Prazo' : 'Regime',
                                style: const TextStyle(
                                  color: Color(0xFF9AA5B1),
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                job.deadline != null
                                    ? '${job.deadline!.day.toString().padLeft(2, '0')}/${job.deadline!.month.toString().padLeft(2, '0')}/${job.deadline!.year}'
                                    : job.type,
                                style: const TextStyle(
                                  color: Color(0xFF1A2E2A),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        BlocBuilder<ApplicationBloc, ApplicationState>(
                          builder: (context, state) {
                            final jaCandidatou = state is ApplicationsLoaded &&
                                state.applications
                                    .any((a) => a.jobId == job.id);
                            return SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: jaCandidatou
                                    ? null
                                    : () => _openApplySheet(context),
                                icon: Icon(
                                  jaCandidatou
                                      ? Icons.check_circle_outline
                                      : Icons.send_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  jaCandidatou
                                      ? 'Já se candidatou'
                                      : 'Candidatar-me',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.grey.shade300,
                                  disabledForegroundColor:
                                      Colors.grey.shade600,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _BarAction(
                            icon: Icons.bookmark_border_rounded,
                            label: 'Guardar',
                            onTap: _toggleSave,
                            active: _saved,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BarAction(
                            icon: Icons.share_outlined,
                            label: 'Partilhar',
                            onTap: () => _share(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplySheet extends StatefulWidget {
  final Job job;
  final String nome;
  final String email;
  const _ApplySheet({required this.job, required this.nome, required this.email});

  @override
  State<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<_ApplySheet> {
  final _coverCtrl = TextEditingController();

  @override
  void dispose() {
    _coverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ApplicationBloc, ApplicationState>(
      listener: (context, state) {
        if (state is ApplicationSubmitted) {
          Navigator.pop(context);
          // Actualiza a lista partilhada para Applications/Dashboard reflectirem já a nova candidatura.
          context.read<ApplicationBloc>().add(const ApplicationsLoadRequested());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Candidatura enviada com sucesso!')),
          );
        } else if (state is ApplicationFailureState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Candidatar-me a ${widget.job.title}',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A2E2A)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _coverCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Escreva uma breve carta de apresentação (opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<ApplicationBloc, ApplicationState>(
              builder: (context, state) {
                final loading = state is ApplicationLoading;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () => context.read<ApplicationBloc>().add(
                              ApplicationSubmitRequested(
                                jobId: widget.job.id,
                                jobTitle: widget.job.title,
                                nome: widget.nome,
                                email: widget.email,
                                coverLetter: _coverCtrl.text.trim(),
                              ),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.white),
                          )
                        : const Text('Enviar candidatura'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabItem(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? kPrimary : Colors.grey.shade500,
              fontWeight:
                  active ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          if (active)
            Container(
              height: 2,
              width: label.length * 7.0,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandableSection({
    required this.icon,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: kPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A2E2A),
                  ),
                ),
              ),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 14),
          child,
        ],
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: kPrimary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFF4A5568), fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: kPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A2E2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    decoration: const BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF4A5568),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _BarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFE8F8F0)
              : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? kPrimary : const Color(0xFF4A5568),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? kPrimary : const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
