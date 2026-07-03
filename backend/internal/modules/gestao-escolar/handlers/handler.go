package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/modules/gestao-escolar/repositories"
	"nexora/internal/shared/contracts"
	"nexora/internal/storage"
)

// Handler agrega as dependências HTTP do módulo escolar.
// Todos os ports são injectados em runtime — baixo acoplamento.
type Handler struct {
	db             *pgxpool.Pool
	cfg            *config.Config
	storage        storage.Provider
	teacherRepo    *repositories.TeacherRepository
	academicRepo   *repositories.AcademicStructureRepository
	classRepo      *repositories.ClassRepository
	enrollmentRepo *repositories.EnrollmentRepository
	timetableRepo  *repositories.TimetableRepository
	calendarRepo   *repositories.CalendarRepository
	incidentRepo   *repositories.IncidentRepository
	gradeRepo      *repositories.GradeRepository
	feeRepo        *repositories.FeeRepository
	// Ports de integração com outros módulos do ERP (Ports & Adapters)
	treasury     contracts.TreasuryPort
	financial    contracts.FinancialPort
	accounting   contracts.AccountingPort
	invoicing    contracts.InvoicingPort
	notification contracts.NotificationPort
	hr           contracts.HRPort
	client       contracts.ClientPort
	approval     contracts.ApprovalPort
	sysConfig    contracts.SystemConfigPort
}

// Ports agrupa todos os ports de integração para injecção no Handler.
type Ports struct {
	Storage      storage.Provider
	Treasury     contracts.TreasuryPort
	Financial    contracts.FinancialPort
	Accounting   contracts.AccountingPort
	Invoicing    contracts.InvoicingPort
	Notification contracts.NotificationPort
	HR           contracts.HRPort
	Client       contracts.ClientPort
	Approval     contracts.ApprovalPort
	SysConfig    contracts.SystemConfigPort
}

// New cria um novo handler do módulo escolar com os ports injectados.
func New(db *pgxpool.Pool, cfg *config.Config, ports Ports) *Handler {
	return &Handler{
		db:             db,
		cfg:            cfg,
		storage:        ports.Storage,
		teacherRepo:    repositories.NewTeacherRepository(db),
		academicRepo:   repositories.NewAcademicStructureRepository(db),
		classRepo:      repositories.NewClassRepository(db),
		enrollmentRepo: repositories.NewEnrollmentRepository(db),
		timetableRepo:  repositories.NewTimetableRepository(db),
		calendarRepo:   repositories.NewCalendarRepository(db),
		incidentRepo:   repositories.NewIncidentRepository(db),
		gradeRepo:      repositories.NewGradeRepository(db),
		feeRepo:        repositories.NewFeeRepository(db),
		treasury:       ports.Treasury,
		financial:      ports.Financial,
		accounting:     ports.Accounting,
		invoicing:      ports.Invoicing,
		notification:   ports.Notification,
		hr:             ports.HR,
		client:         ports.Client,
		approval:       ports.Approval,
		sysConfig:      ports.SysConfig,
	}
}

func jsonOK(w http.ResponseWriter, v any, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func jsonErr(w http.ResponseWriter, msg string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}
