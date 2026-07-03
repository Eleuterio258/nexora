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

func (h *Handler) teacherService() *services.TeacherService {
	return services.NewTeacherService(h.teacherRepo)
}

// ListarProfessores godoc
func (h *Handler) ListarProfessores(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	q := r.URL.Query()

	status := q.Get("status")
	search := q.Get("search")
	page, _ := strconv.Atoi(q.Get("page"))
	limit, _ := strconv.Atoi(q.Get("limit"))

	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20
	}

	teachers, total, err := h.teacherService().List(r.Context(), u.TenantID, status, search, page, limit)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	data := make([]any, len(teachers))
	for i := range teachers {
		data[i] = teachers[i]
	}

	jsonOK(w, models.ListResponse{Data: data, Page: page, Limit: limit, Total: total}, http.StatusOK)
}

// ObterProfessor godoc
func (h *Handler) ObterProfessor(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}

	teacher, err := h.teacherService().GetByID(r.Context(), id, u.TenantID)
	if err != nil {
		if errors.Is(err, services.ErrTeacherNotFound) {
			jsonErr(w, "Professor nao encontrado", http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, teacher, http.StatusOK)
}

// CriarProfessor godoc
func (h *Handler) CriarProfessor(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)

	var input models.TeacherCreate
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}

	teacher := models.Teacher{
		TenantID:                  u.TenantID,
		UserID:                    input.UserID,
		Codigo:                    input.Codigo,
		NomeCompleto:              input.NomeCompleto,
		Genero:                    input.Genero,
		Telefone:                  input.Telefone,
		Email:                     input.Email,
		DocumentoIdentificacao:    input.DocumentoIdentificacao,
		Especialidade:             input.Especialidade,
		CargaHorariaMaximaSemanal: input.CargaHorariaMaximaSemanal,
	}

	if err := h.teacherService().Create(r.Context(), &teacher); err != nil {
		switch {
		case errors.Is(err, services.ErrTeacherInvalidData):
			jsonErr(w, err.Error(), http.StatusBadRequest)
		case errors.Is(err, services.ErrTeacherCodeDuplicate):
			jsonErr(w, err.Error(), http.StatusConflict)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}

	// Criar funcionário no módulo RH automaticamente (se port disponível)
	if h.hr != nil && teacher.NomeCompleto != "" {
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
			defer cancel()
			empID, err := h.hr.CreateEmployee(ctx, contracts.HREmployee{
				TenantID:     teacher.TenantID,
				Nome:         teacher.NomeCompleto,
				Email:        teacher.Email,
				Telefone:     teacher.Telefone,
				NomeNumero:   fmt.Sprintf("PROF-%d", teacher.ID),
				DataAdmissao: time.Now(),
				Cargo:        teacher.Especialidade,
			})
			if err != nil || empID == 0 {
				return
			}
			// Ligar professor ao funcionário RH
			_, _ = h.db.Exec(ctx, `
				UPDATE gestao_escolar.school_teachers
				SET rh_employee_id = $1, updated_at = NOW()
				WHERE id = $2 AND tenant_id = $3`,
				empID, teacher.ID, teacher.TenantID)
		}()
	}

	jsonOK(w, teacher, http.StatusCreated)
}

// ActualizarProfessor godoc
func (h *Handler) ActualizarProfessor(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}

	var input models.TeacherUpdate
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}

	if err := h.teacherService().Update(r.Context(), id, u.TenantID, input); err != nil {
		switch {
		case errors.Is(err, services.ErrTeacherNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrTeacherInvalidData):
			jsonErr(w, err.Error(), http.StatusBadRequest)
		case errors.Is(err, services.ErrTeacherCodeDuplicate):
			jsonErr(w, err.Error(), http.StatusConflict)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// RemoverProfessor godoc
func (h *Handler) RemoverProfessor(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}

	if err := h.teacherService().Delete(r.Context(), id, u.TenantID); err != nil {
		if errors.Is(err, services.ErrTeacherNotFound) {
			jsonErr(w, err.Error(), http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
