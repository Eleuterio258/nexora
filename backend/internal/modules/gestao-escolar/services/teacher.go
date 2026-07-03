package services

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/repositories"
)

// TeacherService contém a lógica de negócio de professores.
type TeacherService struct {
	repo *repositories.TeacherRepository
}

// NewTeacherService cria um novo serviço de professores.
func NewTeacherService(repo *repositories.TeacherRepository) *TeacherService {
	return &TeacherService{repo: repo}
}

var (
	ErrTeacherNotFound      = errors.New("professor nao encontrado")
	ErrTeacherCodeDuplicate = errors.New("codigo de professor ja existe")
	ErrTeacherInvalidData   = errors.New("dados do professor invalidos")
	ErrTeacherOverloaded    = errors.New("professor excede carga horaria maxima")
)

func (s *TeacherService) normalizeTeacher(t *models.Teacher) {
	t.Codigo = strings.TrimSpace(t.Codigo)
	t.NomeCompleto = strings.TrimSpace(t.NomeCompleto)
	t.Email = strings.TrimSpace(t.Email)
	t.Telefone = strings.TrimSpace(t.Telefone)
	t.Status = strings.ToLower(strings.TrimSpace(t.Status))
	if t.Status == "" {
		t.Status = "activo"
	}
	if t.CargaHorariaMaximaSemanal <= 0 {
		t.CargaHorariaMaximaSemanal = 40
	}
}

// Create cria um novo professor após validações.
func (s *TeacherService) Create(ctx context.Context, t *models.Teacher) error {
	s.normalizeTeacher(t)

	if t.TenantID == 0 {
		return ErrTeacherInvalidData
	}
	if t.Codigo == "" || t.NomeCompleto == "" {
		return ErrTeacherInvalidData
	}

	exists, err := s.repo.ExistsByCode(ctx, t.Codigo, t.TenantID, 0)
	if err != nil {
		return err
	}
	if exists {
		return ErrTeacherCodeDuplicate
	}

	return s.repo.Create(ctx, t)
}

// GetByID obtém um professor pelo ID.
func (s *TeacherService) GetByID(ctx context.Context, id, tenantID int64) (*models.Teacher, error) {
	t, err := s.repo.GetByID(ctx, id, tenantID)
	if err == pgx.ErrNoRows {
		return nil, ErrTeacherNotFound
	}
	return t, err
}

// List lista professores.
func (s *TeacherService) List(ctx context.Context, tenantID int64, status, search string, page, limit int) ([]models.Teacher, int64, error) {
	return s.repo.List(ctx, tenantID, status, search, page, limit)
}

// Update actualiza um professor.
func (s *TeacherService) Update(ctx context.Context, id, tenantID int64, input models.TeacherUpdate) error {
	fields := make(map[string]any)

	if input.Codigo != nil {
		code := strings.TrimSpace(*input.Codigo)
		if code == "" {
			return ErrTeacherInvalidData
		}
		exists, err := s.repo.ExistsByCode(ctx, code, tenantID, id)
		if err != nil {
			return err
		}
		if exists {
			return ErrTeacherCodeDuplicate
		}
		fields["codigo"] = code
	}
	if input.UserID != nil {
		fields["user_id"] = *input.UserID
	}
	if input.NomeCompleto != nil {
		if strings.TrimSpace(*input.NomeCompleto) == "" {
			return ErrTeacherInvalidData
		}
		fields["nome_completo"] = strings.TrimSpace(*input.NomeCompleto)
	}
	if input.Genero != nil {
		fields["genero"] = strings.TrimSpace(*input.Genero)
	}
	if input.Telefone != nil {
		fields["telefone"] = strings.TrimSpace(*input.Telefone)
	}
	if input.Email != nil {
		fields["email"] = strings.TrimSpace(*input.Email)
	}
	if input.DocumentoIdentificacao != nil {
		fields["documento_identificacao"] = strings.TrimSpace(*input.DocumentoIdentificacao)
	}
	if input.Especialidade != nil {
		fields["especialidade"] = strings.TrimSpace(*input.Especialidade)
	}
	if input.CargaHorariaMaximaSemanal != nil {
		if *input.CargaHorariaMaximaSemanal <= 0 {
			return ErrTeacherInvalidData
		}
		fields["carga_horaria_maxima_semanal"] = *input.CargaHorariaMaximaSemanal
	}
	if input.Status != nil {
		status := strings.ToLower(strings.TrimSpace(*input.Status))
		if status != "activo" && status != "inactivo" && status != "suspenso" {
			return ErrTeacherInvalidData
		}
		fields["status"] = status
	}

	if len(fields) == 0 {
		return ErrTeacherInvalidData
	}

	if err := s.repo.Update(ctx, id, tenantID, fields); err != nil {
		if err == pgx.ErrNoRows {
			return ErrTeacherNotFound
		}
		return err
	}
	return nil
}

// Delete inactiva um professor.
func (s *TeacherService) Delete(ctx context.Context, id, tenantID int64) error {
	if err := s.repo.Delete(ctx, id, tenantID); err != nil {
		if err == pgx.ErrNoRows {
			return ErrTeacherNotFound
		}
		return err
	}
	return nil
}

// ValidateWorkload verifica se uma nova atribuição de horário respeita a carga máxima.
func (s *TeacherService) ValidateWorkload(ctx context.Context, teacherID, tenantID int64, additionalHours int) error {
	teacher, err := s.GetByID(ctx, teacherID, tenantID)
	if err != nil {
		return err
	}
	workload, err := s.repo.WeeklyWorkload(ctx, teacherID, tenantID)
	if err != nil {
		return err
	}
	if workload+additionalHours > teacher.CargaHorariaMaximaSemanal {
		return ErrTeacherOverloaded
	}
	return nil
}
