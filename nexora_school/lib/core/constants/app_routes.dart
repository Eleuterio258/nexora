class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String pinSetup = '/pin-setup';

  // Student
  static const String dashboard = '/dashboard';
  static const String grades = '/grades';
  static const String schedule = '/schedule';
  static const String tasks = '/tasks';
  static const String profile = '/profile';

  // Student extras
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String medals = '/medals';
  static const String ranking = '/ranking';
  static const String subjectDetail = '/subject-detail';
  static const String reportCard = '/report-card';
  static const String gradeEvolution = '/grade-evolution';
  static const String assessmentDetail = '/assessment-detail';
  static const String classDetail = '/class-detail';
  static const String dailySchedule = '/daily-schedule';
  static const String taskDetail = '/task-detail';
  static const String taskSubmissionSuccess = '/task-submission-success';
  static const String studentAttendance = '/student-attendance';

  // Communication
  static const String messages = '/messages';
  static const String conversation = '/conversation';
  static const String announcementDetail = '/announcement-detail';
  static const String composeMessage = '/compose-message';

  // Payments
  static const String payments = '/payments';
  static const String paymentHistory = '/payment-history';
  static const String paymentReceipt = '/payment-receipt';
  static const String paymentProcess = '/payment-process';

  // Documents
  static const String documentsCenter = '/documents-center';
  static const String documentRequest = '/document-request';
  static const String pdfViewer = '/pdf-viewer';

  // Teacher
  static const String teacherDashboard = '/teacher-dashboard';
  static const String gradeEntryClass = '/grade-entry-class';
  static const String gradeEntryStudents = '/grade-entry-students';
  static const String attendance = '/attendance';
  static const String classList = '/class-list';
  static const String classDetailTeacher = '/class-detail-teacher';
  static const String studentFileTeacher = '/student-file-teacher';
  static const String createTask = '/create-task';
  static const String createAnnouncement = '/create-announcement';
  static const String classReport = '/class-report';

  // Parent
  static const String parentDashboard = '/parent-dashboard';
  static const String childGrades = '/child-grades';
  static const String childAttendance = '/child-attendance';
  static const String requestMeeting = '/request-meeting';
  static const String parentPayments = '/parent-payments';

  // Admin
  static const String adminDashboard = '/admin-dashboard';
  static const String studentsManagement = '/students-management';
  static const String studentRecordAdmin = '/student-record-admin';
  static const String teachersManagement = '/teachers-management';
  static const String enrollment = '/enrollment';
  static const String reports = '/reports';

  // Calendar
  static const String calendar = '/calendar';
  static const String eventDetail = '/event-detail';

  // Attendance
  static const String justifyAbsence = '/justify-absence';
  static const String earlyExit = '/early-exit';

  // Settings
  static const String editProfile = '/edit-profile';
  static const String settingsMenu = '/settings-menu';
  static const String changePassword = '/change-password';
  static const String biometricsPin = '/biometrics-pin';
  static const String languageAccessibility = '/language-accessibility';
  static const String about = '/about';
  static const String helpFaq = '/help-faq';
  static const String reportProblem = '/report-problem';

  // Special states
  static const String emptyState = '/empty-state';
  static const String loadingState = '/loading-state';
  static const String networkError = '/network-error';
  static const String successConfirmation = '/success-confirmation';
  static const String offlineMode = '/offline-mode';
  static const String updateAvailable = '/update-available';
  static const String permissionRequest = '/permission-request';
  static const String sessionExpired = '/session-expired';
}
