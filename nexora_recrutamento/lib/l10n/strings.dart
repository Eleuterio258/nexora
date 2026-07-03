import 'package:flutter/widgets.dart';

class AppStrings {
  final String _l;
  const AppStrings._(this._l);

  static AppStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'pt' ? const AppStrings._('pt') : const AppStrings._('en');
  }

  bool get _pt => _l == 'pt';

  // ── Onboarding ─────────────────────────────────────────────────

  String get onbSkip => _pt ? 'Saltar' : 'Skip';
  String get onbNext => _pt ? 'Próximo' : 'Next';
  String get onbGetStarted => _pt ? 'Começar' : 'Get Started';
  String get onbHaveAccount => _pt ? 'Já tens uma conta? ' : 'Already have an account? ';
  String get onbSignIn => _pt ? 'Entrar' : 'Sign In';

  String get onbChipJobs => _pt ? '50k+ Vagas' : '50k+ Jobs';
  String get onbChipApply => _pt ? 'Candidatura Rápida' : 'Quick Apply';
  String get onbChipTracking => _pt ? 'Seguimento em Directo' : 'Live Tracking';
  String get onbChipHired => _pt ? 'Sê Contratado' : 'Get Hired';

  List<OnbSlideStrings> get onbSlides => _pt ? _slidesPt : _slidesEn;

  static const _slidesPt = [
    OnbSlideStrings(
      title: 'Encontra o Teu\nEmprego de Sonho',
      body: 'Explora milhares de vagas adaptadas às tuas competências e experiência. A tua próxima oportunidade está a um toque de distância.',
    ),
    OnbSlideStrings(
      title: 'Candidata-te\nCom Um Toque',
      body: 'Guarda o teu perfil uma vez e candidata-te a várias posições instantaneamente. Destaca-te junto dos recrutadores com um perfil completo e cuidado.',
    ),
    OnbSlideStrings(
      title: 'Acompanha Cada\nCandidatura',
      body: 'Mantém-te a par da tua pesquisa de emprego. Monitoriza estados, recebe actualizações de entrevistas e mensagens directas dos recrutadores.',
    ),
    OnbSlideStrings(
      title: 'Conquista\na Oferta',
      body: 'Recebe uma notificação no momento em que um recrutador mostrar interesse. Conversa, marca entrevistas e aceita propostas — tudo num só lugar.',
    ),
  ];

  static const _slidesEn = [
    OnbSlideStrings(
      title: 'Find Your\nDream Job',
      body: 'Browse thousands of job listings tailored to your skills and experience. Your next opportunity is just a tap away.',
    ),
    OnbSlideStrings(
      title: 'Apply With\nOne Tap',
      body: 'Save your profile once and apply to multiple positions instantly. Stand out to recruiters with a polished, complete profile.',
    ),
    OnbSlideStrings(
      title: 'Track Every\nApplication',
      body: 'Stay on top of your job search. Monitor statuses, get interview updates, and receive direct messages from recruiters.',
    ),
    OnbSlideStrings(
      title: 'Land the\nOffer',
      body: 'Get notified the moment a recruiter is interested. Chat, schedule interviews, and accept offers — all in one place.',
    ),
  ];

  // ── Auth ───────────────────────────────────────────────────────

  String get authLogin => _pt ? 'Entrar' : 'Sign In';
  String get authRegister => _pt ? 'Criar Conta' : 'Create Account';
  String get authEmail => _pt ? 'E-mail' : 'Email';
  String get authPassword => _pt ? 'Palavra-passe' : 'Password';
  String get authForgotPassword => _pt ? 'Esqueceste a palavra-passe?' : 'Forgot password?';
  String get authNoAccount => _pt ? 'Não tens conta? ' : "Don't have an account? ";
  String get authHaveAccount => _pt ? 'Já tens conta? ' : 'Already have an account? ';
  String get authName => _pt ? 'Nome completo' : 'Full name';

  // ── Common ─────────────────────────────────────────────────────

  String get commonSave => _pt ? 'Guardar' : 'Save';
  String get commonCancel => _pt ? 'Cancelar' : 'Cancel';
  String get commonBack => _pt ? 'Voltar' : 'Back';
  String get commonSearch => _pt ? 'Pesquisar' : 'Search';
  String get commonLoading => _pt ? 'A carregar…' : 'Loading…';
  String get commonError => _pt ? 'Ocorreu um erro' : 'Something went wrong';

  // ── Jobs ───────────────────────────────────────────────────────

  String get jobsTitle => _pt ? 'Vagas de Emprego' : 'Job Listings';
  String get jobsApply => _pt ? 'Candidatar-me' : 'Apply Now';
  String get jobsApplied => _pt ? 'Candidatura Enviada' : 'Applied';
  String get jobsSave => _pt ? 'Guardar Vaga' : 'Save Job';
  String get jobsFullTime => _pt ? 'Tempo Inteiro' : 'Full Time';
  String get jobsPartTime => _pt ? 'Meio Tempo' : 'Part Time';
  String get jobsRemote => _pt ? 'Remoto' : 'Remote';
  String get jobsHybrid => _pt ? 'Híbrido' : 'Hybrid';

  // ── Applications ───────────────────────────────────────────────

  String get appsTitle => _pt ? 'As Minhas Candidaturas' : 'My Applications';
  String get appsStatusReceived => _pt ? 'Recebida' : 'Received';
  String get appsStatusReview => _pt ? 'Em Análise' : 'In Review';
  String get appsStatusInterview => _pt ? 'Entrevista' : 'Interview';
  String get appsStatusRejected => _pt ? 'Rejeitada' : 'Rejected';
  String get appsStatusOffer => _pt ? 'Proposta' : 'Offer';

  // ── Profile ────────────────────────────────────────────────────

  String get profileTitle => _pt ? 'O Meu Perfil' : 'My Profile';
  String get profileExperience => _pt ? 'Experiência' : 'Experience';
  String get profileEducation => _pt ? 'Formação' : 'Education';
  String get profileSkills => _pt ? 'Competências' : 'Skills';
  String get profileLanguages => _pt ? 'Idiomas' : 'Languages';
  String get profileCv => _pt ? 'Currículo (CV)' : 'Resume (CV)';

  // ── Navigation ─────────────────────────────────────────────────

  String get navHome => _pt ? 'Início' : 'Home';
  String get navJobs => _pt ? 'Vagas' : 'Jobs';
  String get navApplications => _pt ? 'Candidaturas' : 'Applications';
  String get navMessages => _pt ? 'Mensagens' : 'Messages';
  String get navProfile => _pt ? 'Perfil' : 'Profile';

  // ── Notifications ──────────────────────────────────────────────

  String get notifTitle => _pt ? 'Notificações' : 'Notifications';
  String get notifEmpty => _pt ? 'Sem notificações' : 'No notifications';

  // ── Settings ───────────────────────────────────────────────────

  String get settingsTitle => _pt ? 'Definições' : 'Settings';
  String get settingsLanguage => _pt ? 'Idioma' : 'Language';
  String get settingsLogout => _pt ? 'Terminar Sessão' : 'Sign Out';
  String get settingsNotifications => _pt ? 'Notificações' : 'Notifications';
}

class OnbSlideStrings {
  final String title;
  final String body;
  const OnbSlideStrings({required this.title, required this.body});
}
