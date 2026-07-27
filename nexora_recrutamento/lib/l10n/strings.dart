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

  // Login screen
  String get loginWelcome => _pt ? 'Bem-vindo de volta!' : 'Welcome back!';
  String get loginSubtitle => _pt ? 'Entra para continuar na tua conta.' : 'Sign in to continue to your account.';
  String get loginEmailHint => _pt ? 'Insere o teu e-mail' : 'Enter your email';
  String get loginPasswordHint => _pt ? 'Insere a tua palavra-passe' : 'Enter your password';
  String get loginOrDivider => _pt ? 'OU' : 'OR';
  String get loginFillFields => _pt ? 'Preenche o e-mail e a palavra-passe.' : 'Please fill in email and password.';

  // Register screen
  String get registerTitle => _pt ? 'Criar Conta' : 'Create Account';
  String get registerSubtitle => _pt ? 'Junta-te à Nexora e encontra as melhores oportunidades de emprego.' : 'Join Nexora and find the best job opportunities.';
  String get registerConfirmPasswordHint => _pt ? 'Confirmar palavra-passe' : 'Confirm Password';
  String get registerAgreeTerms => _pt ? 'Concordo com os ' : 'I agree to the ';
  String get registerTermsAndConditions => _pt ? 'Termos e Condições' : 'Terms and Conditions';
  String get registerFillAllFields => _pt ? 'Preenche todos os campos.' : 'Please fill in all fields.';
  String get registerPasswordMinLength => _pt ? 'A palavra-passe deve ter pelo menos 6 caracteres.' : 'Password must be at least 6 characters.';
  String get registerPasswordsDoNotMatch => _pt ? 'As palavras-passe não coincidem.' : 'Passwords do not match.';
  String get registerAcceptTerms => _pt ? 'Tem de aceitar os Termos e Condições.' : 'You must accept the Terms and Conditions.';

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
  String get profilePersonalInfoTitle =>
      _pt ? 'Informações Pessoais' : 'Personal Info';
  String get profilePersonalInfoSubtitle => _pt
      ? 'Visualize e atualize os seus dados pessoais'
      : 'View and update your personal details';
  String get profileExperienceTitle => _pt ? 'Experiência' : 'Experience';
  String get profileExperienceSubtitle => _pt
      ? 'Adicione e gerencie a sua experiência profissional'
      : 'Add and manage your work experience';
  String get profileEducationTitle => _pt ? 'Formação' : 'Education';
  String get profileEducationSubtitle => _pt
      ? 'Adicione e gerencie a sua formação académica'
      : 'Add and manage your educational background';
  String get profileSettingsTitle => _pt ? 'Definições' : 'Settings';
  String get profileSettingsSubtitle => _pt
      ? 'Gerencie a sua conta e preferências'
      : 'Manage your account and preferences';
  String get profileLogoutTitle => _pt ? 'Terminar Sessão' : 'Logout';
  String get profileLogoutSubtitle =>
      _pt ? 'Sair da sua conta' : 'Sign out of your account';
  String get profileCompleteTitle =>
      _pt ? 'Complete o seu perfil' : 'Complete your profile';
  String get profileCompleteSubtitle => _pt
      ? 'Um perfil completo aumenta as suas hipóteses de ser contratado.'
      : 'A complete profile increases your chances of getting hired.';
  String get profileCompletePercent => _pt ? '%s Completo' : '%s Complete';

  // ── Personal Info ──────────────────────────────────────────────

  String get personalInfoTitle =>
      _pt ? 'Informações Pessoais' : 'Personal Info';
  String get personalInfoSave => _pt ? 'Guardar' : 'Save';
  String get personalInfoPhotoHint =>
      _pt ? 'Toque para alterar a foto' : 'Tap to change photo';
  String get personalInfoBasicDetails =>
      _pt ? 'Detalhes Básicos' : 'Basic Details';
  String get personalInfoFullName => _pt ? 'Nome Completo' : 'Full Name';
  String get personalInfoJobTitle => _pt ? 'Cargo' : 'Job Title';
  String get personalInfoLocation => _pt ? 'Localização' : 'Location';
  String get personalInfoContact => _pt ? 'Contacto' : 'Contact';
  String get personalInfoEmail => _pt ? 'E-mail' : 'Email';
  String get personalInfoPhone => _pt ? 'Telefone' : 'Phone';
  String get personalInfoAbout => _pt ? 'Sobre' : 'About';
  String get personalInfoBio => _pt ? 'Bio' : 'Bio';
  String get personalInfoSaveChanges =>
      _pt ? 'Guardar Alterações' : 'Save Changes';

  // ── Experience ─────────────────────────────────────────────────

  String get experienceTitle => _pt ? 'Experiência' : 'Experience';
  String get experienceAdd => _pt ? 'Adicionar Experiência' : 'Add Experience';
  String get experienceEmptyTitle =>
      _pt ? 'Ainda sem experiência' : 'No experience added yet';
  String get experienceEmptySub => _pt
      ? 'Adicione a sua experiência profissional para se destacar'
      : 'Add your work history to stand out';
  String get experienceEmptyAdd => _pt ? 'Adicionar Agora' : 'Add Now';
  String get experienceCurrent => _pt ? 'Actual' : 'Current';
  String get experienceJobTitle => _pt ? 'Cargo' : 'Job Title';
  String get experienceCompany => _pt ? 'Empresa' : 'Company';
  String get experienceLocation => _pt ? 'Localização' : 'Location';
  String get experienceStartDate => _pt ? 'Data Início' : 'Start Date';
  String get experienceEndDate => _pt ? 'Data Fim' : 'End Date';
  String get experienceDescription => _pt ? 'Descrição' : 'Description';

  // ── Education ──────────────────────────────────────────────────

  String get educationTitle => _pt ? 'Formação' : 'Education';
  String get educationAdd => _pt ? 'Adicionar Formação' : 'Add Education';
  String get educationEmptyTitle =>
      _pt ? 'Ainda sem formação' : 'No education added yet';
  String get educationEmptySub => _pt
      ? 'Adicione a sua formação académica'
      : 'Add your academic background';
  String get educationEmptyAdd => _pt ? 'Adicionar Agora' : 'Add Now';
  String get educationDegree => _pt ? 'Curso / Grau' : 'Degree / Course';
  String get educationInstitution => _pt ? 'Instituição' : 'Institution';
  String get educationLocation => _pt ? 'Localização' : 'Location';
  String get educationStartYear => _pt ? 'Ano Início' : 'Start Year';
  String get educationEndYear => _pt ? 'Ano Fim' : 'End Year';
  String get educationGrade => _pt ? 'Nota / Média' : 'Grade / CGPA';

  // ── Navigation ─────────────────────────────────────────────────

  String get navHome => _pt ? 'Início' : 'Home';
  String get navJobs => _pt ? 'Vagas' : 'Jobs';
  String get navApplications => _pt ? 'Candidaturas' : 'Applications';
  String get navMessages => _pt ? 'Mensagens' : 'Messages';
  String get navProfile => _pt ? 'Perfil' : 'Profile';

  // ── Notifications ──────────────────────────────────────────────

  String get notifTitle => _pt ? 'Notificações' : 'Notifications';
  String get notifEmpty => _pt ? 'Sem notificações' : 'No notifications';
  String get notifMarkAllRead =>
      _pt ? 'Marcar todas como lidas' : 'Mark all read';
  String get notifNew => _pt ? 'novas' : 'new';
  String get notifSubtitle => _pt
      ? 'Mantenha-se actualizado na sua procura de emprego'
      : 'Stay up to date with your job search';

  // ── Settings ───────────────────────────────────────────────────

  String get settingsTitle => _pt ? 'Definições' : 'Settings';
  String get settingsLanguage => _pt ? 'Idioma' : 'Language';
  String get settingsLogout => _pt ? 'Terminar Sessão' : 'Sign Out';
  String get settingsNotifications => _pt ? 'Notificações' : 'Notifications';
  String get settingsJobAlerts =>
      _pt ? 'Alertas de Vagas' : 'Job Alerts';
  String get settingsJobAlertsSub => _pt
      ? 'Novas vagas correspondentes ao seu perfil'
      : 'New jobs matching your profile';
  String get settingsAppUpdates => _pt
      ? 'Actualizações de Candidaturas'
      : 'Application Updates';
  String get settingsAppUpdatesSub => _pt
      ? 'Alterações de estado nas suas candidaturas'
      : 'Status changes on your applications';
  String get settingsMessages => _pt ? 'Mensagens' : 'Messages';
  String get settingsMessagesSub =>
      _pt ? 'Novas mensagens dos recrutadores' : 'New messages from recruiters';
  String get settingsPrivacy => _pt ? 'Privacidade' : 'Privacy';
  String get settingsProfileVisible =>
      _pt ? 'Perfil Visível' : 'Profile Visibility';
  String get settingsProfileVisibleSub =>
      _pt ? 'Tornar o seu perfil visível aos recrutadores'
      : 'Make your profile visible to recruiters';
  String get settingsAppearance => _pt ? 'Aparência' : 'Appearance';
  String get settingsDarkMode => _pt ? 'Modo Escuro' : 'Dark Mode';
  String get settingsDarkModeSub =>
      _pt ? 'Mudar para tema escuro' : 'Switch to dark theme';
  String get settingsAccount => _pt ? 'Conta' : 'Account';
  String get settingsChangePassword =>
      _pt ? 'Alterar Palavra-passe' : 'Change Password';
  String get settingsLanguagePt => _pt ? 'Português' : 'English';
  String get settingsHelp => _pt ? 'Ajuda e Suporte' : 'Help & Support';
  String get settingsAbout => _pt ? 'Sobre a Nexora' : 'About Nexora';
  String get settingsLogoutConfirm => _pt
      ? 'Tem a certeza que pretende terminar a sessão?'
      : 'Are you sure you want to log out?';
  String get settingsCancel => _pt ? 'Cancelar' : 'Cancel';
  String get settingsDeleteAccount =>
      _pt ? 'Eliminar Conta' : 'Delete Account';
}

class OnbSlideStrings {
  final String title;
  final String body;
  const OnbSlideStrings({required this.title, required this.body});
}
