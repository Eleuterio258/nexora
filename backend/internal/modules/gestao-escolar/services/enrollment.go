package services

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/repositories"
)

// EnrollmentService lógica de negócio de matrículas.
type EnrollmentService struct {
	repo      *repositories.EnrollmentRepository
	classRepo *repositories.ClassRepository
	classSvc  *ClassService
}

// NewEnrollmentService cria serviço de matrículas.
func NewEnrollmentService(repo *repositories.EnrollmentRepository, classRepo *repositories.ClassRepository) *EnrollmentService {
	return &EnrollmentService{
		repo:      repo,
		classRepo: classRepo,
		classSvc:  NewClassService(classRepo),
	}
}

var (
	ErrEnrollmentNotFound      = errors.New("matricula nao encontrada")
	ErrEnrollmentInvalidData   = errors.New("dados da matricula invalidos")
	ErrEnrollmentDuplicate     = errors.New("aluno ja matriculado no ano lectivo")
	ErrEnrollmentDuplicateNum  = errors.New("numero de matricula ja existe")
	ErrEnrollmentClassFull     = errors.New("turma sem vagas disponiveis")
	ErrEnrollmentAlreadyActive = errors.New("ja existe matricula activa para este aluno")
)

func (s *EnrollmentService) normalize(e *models.Enrollment) {
	e.Numero = strings.TrimSpace(e.Numero)
	e.Tipo = strings.ToLower(strings.TrimSpace(e.Tipo))
	if e.Tipo == "" {
		e.Tipo = "nova"
	}
	e.Status = "activa"
}

// Create matricula um aluno com validações de negócio.
func (s *EnrollmentService) Create(ctx context.Context, e *models.Enrollment) error {
	s.normalize(e)

	if e.TenantID == 0 || e.StudentID == 0 || e.ClassID == 0 || e.Numero == "" {
		return ErrEnrollmentInvalidData
	}

	// Obter turma e ano lectivo
	class, err := s.classSvc.GetByID(ctx, e.ClassID, e.TenantID)
	if err != nil {
		return err
	}
	if e.SchoolYearID == nil || *e.SchoolYearID == 0 {
		e.SchoolYearID = class.SchoolYearID
	}
	if e.SchoolYearID == nil || *e.SchoolYearID == 0 {
		return ErrEnrollmentInvalidData
	}

	// Validar capacidade
	if err := s.classSvc.CheckCapacity(ctx, e.ClassID, e.TenantID); err != nil {
		return err
	}

	// Impedir matrícula dupla no mesmo ano
	existing, err := s.repo.GetActiveByStudentAndYear(ctx, e.StudentID, *e.SchoolYearID, e.TenantID)
	if err != nil {
		return err
	}
	if existing != nil {
		return ErrEnrollmentDuplicate
	}

	// Verificar número de matrícula único
	exists, err := s.repo.ExistsByNumber(ctx, e.Numero, e.TenantID, 0)
	if err != nil {
		return err
	}
	if exists {
		return ErrEnrollmentDuplicateNum
	}

	return s.repo.Create(ctx, e)
}

// GetByID obtém uma matrícula.
func (s *EnrollmentService) GetByID(ctx context.Context, id, tenantID int64) (*models.Enrollment, error) {
	e, err := s.repo.GetByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrEnrollmentNotFound
	}
	return e, err
}

// Transfer move aluno para outra turma.
func (s *EnrollmentService) Transfer(ctx context.Context, id, tenantID int64, input models.EnrollmentTransfer) error {
	if input.ClassID == 0 {
		return ErrEnrollmentInvalidData
	}

	e, err := s.GetByID(ctx, id, tenantID)
	if err != nil {
		return err
	}
	if e.Status != "activa" {
		return ErrEnrollmentNotFound
	}

	// Validar capacidade da nova turma
	if err := s.classSvc.CheckCapacity(ctx, input.ClassID, tenantID); err != nil {
		return err
	}

	return s.repo.Transfer(ctx, id, tenantID, input.ClassID, input.Motivo)
}

// Cancel cancela uma matrícula.
func (s *EnrollmentService) Cancel(ctx context.Context, id, tenantID int64) error {
	if err := s.repo.Cancel(ctx, id, tenantID); err != nil {
		if err == pgx.ErrNoRows {
			return ErrEnrollmentNotFound
		}
		return err
	}
	return nil
}

// ParseDate auxiliar para parsing de datas.
func ParseDate(value string) (time.Time, error) {
	if value == "" {
		return time.Now(), nil
	}
	return time.Parse("2006-01-02", value)
}
