package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/services"
	"nexora/internal/shared/contracts"
)

func (h *Handler) classService() *services.ClassService {
	return services.NewClassService(h.classRepo)
}

func (h *Handler) enrollmentService() *services.EnrollmentService {
	return services.NewEnrollmentService(h.enrollmentRepo, h.classRepo)
}

// --- Turmas (versão com validações) ---

// CriarTurmaV2 cria uma turma validando nível/série/curso e capacidade.
func (h *Handler) CriarTurmaV2(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.ClassCreate
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}

	class := models.Class{
		TenantID:          u.TenantID,
		SchoolYearID:      input.SchoolYearID,
		LevelID:           input.LevelID,
		SeriesID:          input.SeriesID,
		CourseID:          input.CourseID,
		Codigo:            input.Codigo,
		Nome:              input.Nome,
		Nivel:             input.Nivel,
		Turma:             input.Turma,
		Turno:             input.Turno,
		Sala:              input.Sala,
		Capacidade:        input.Capacidade,
		DirectorTeacherID: input.DirectorTeacherID,
	}

	if err := h.classService().Create(r.Context(), &class); err != nil {
		if errors.Is(err, services.ErrClassInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, class, http.StatusCreated)
}

// ActualizarTurmaV2 actualiza dados da turma.
func (h *Handler) ActualizarTurmaV2(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}

	var input models.ClassUpdate
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}

	fields := make(map[string]any)
	if input.SchoolYearID != nil {
		fields["school_year_id"] = *input.SchoolYearID
	}
	if input.LevelID != nil {
		fields["level_id"] = *input.LevelID
	}
	if input.SeriesID != nil {
		fields["series_id"] = *input.SeriesID
	}
	if input.CourseID != nil {
		fields["course_id"] = *input.CourseID
	}
	if input.Codigo != nil {
		fields["codigo"] = *input.Codigo
	}
	if input.Nome != nil {
		fields["nome"] = *input.Nome
	}
	if input.Nivel != nil {
		fields["nivel"] = *input.Nivel
	}
	if input.Turma != nil {
		fields["turma"] = *input.Turma
	}
	if input.Turno != nil {
		fields["turno"] = *input.Turno
	}
	if input.Sala != nil {
		fields["sala"] = *input.Sala
	}
	if input.Capacidade != nil {
		fields["capacidade"] = *input.Capacidade
	}
	if input.DirectorTeacherID != nil {
		fields["director_teacher_id"] = *input.DirectorTeacherID
	}
	if input.Activo != nil {
		fields["activo"] = *input.Activo
	}

	if err := h.classService().Update(r.Context(), id, u.TenantID, fields); err != nil {
		if errors.Is(err, services.ErrClassNotFound) {
			jsonErr(w, err.Error(), http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// --- Matrículas (versão com validações) ---

// CriarMatriculaV2 matricula um aluno com validações.
func (h *Handler) CriarMatriculaV2(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.EnrollmentCreate
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}

	dataMatricula, err := services.ParseDate(input.DataMatricula)
	if err != nil {
		jsonErr(w, "Data de matricula invalida", http.StatusBadRequest)
		return
	}

	enrollment := models.Enrollment{
		TenantID:      u.TenantID,
		SchoolYearID:  input.SchoolYearID,
		StudentID:     input.StudentID,
		ClassID:       input.ClassID,
		Numero:        input.Numero,
		DataMatricula: dataMatricula,
		Tipo:          input.Tipo,
		Observacoes:   input.Observacoes,
		CreatedBy:     &u.ID,
	}

	if err := h.enrollmentService().Create(r.Context(), &enrollment); err != nil {
		switch {
		case errors.Is(err, services.ErrEnrollmentInvalidData),
			errors.Is(err, services.ErrEnrollmentDuplicate),
			errors.Is(err, services.ErrEnrollmentDuplicateNum),
			errors.Is(err, services.ErrClassFull):
			jsonErr(w, err.Error(), http.StatusBadRequest)
		case errors.Is(err, services.ErrClassNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}

	// Notificar encarregados do aluno sobre a matrícula (capturar variáveis antes do go)
	studentID, tenantID, numero := enrollment.StudentID, enrollment.TenantID, enrollment.Numero
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		rows, err := h.db.Query(ctx, `
			SELECT g.email FROM gestao_escolar.school_guardians g
			WHERE g.student_id = $1 AND g.tenant_id = $2 AND g.email <> ''`,
			studentID, tenantID)
		if err != nil {
			return
		}
		defer rows.Close()
		for rows.Next() {
			var email string
			if rows.Scan(&email) == nil && h.notification != nil {
				h.notification.Send(ctx, contracts.Notification{
					TenantID:     tenantID,
					CanalTipo:    "email",
					Destinatario: email,
					Corpo:        fmt.Sprintf("Matricula n.%s confirmada com sucesso.", numero),
				})
			}
		}
	}()

	jsonOK(w, enrollment, http.StatusCreated)
}

// TransferirMatriculaV2 transfere aluno para outra turma.
func (h *Handler) TransferirMatriculaV2(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}

	var input models.EnrollmentTransfer
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}

	if err := h.enrollmentService().Transfer(r.Context(), id, u.TenantID, input); err != nil {
		switch {
		case errors.Is(err, services.ErrEnrollmentNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrEnrollmentInvalidData),
			errors.Is(err, services.ErrClassFull):
			jsonErr(w, err.Error(), http.StatusBadRequest)
		case errors.Is(err, services.ErrClassNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// CancelarMatriculaV2 cancela uma matrícula.
func (h *Handler) CancelarMatriculaV2(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}

	if err := h.enrollmentService().Cancel(r.Context(), id, u.TenantID); err != nil {
		if errors.Is(err, services.ErrEnrollmentNotFound) {
			jsonErr(w, err.Error(), http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
