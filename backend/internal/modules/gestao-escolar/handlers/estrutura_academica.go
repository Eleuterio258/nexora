package handlers

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/repositories"
	"nexora/internal/modules/gestao-escolar/services"
)

func (h *Handler) academicStructureService() *services.AcademicStructureService {
	return services.NewAcademicStructureService(h.academicRepo)
}

// --- Níveis ---

func (h *Handler) ListarNiveisEnsino(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	levels, err := h.academicStructureService().ListLevels(r.Context(), u.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, levels, http.StatusOK)
}

func (h *Handler) ObterNivelEnsino(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	level, err := h.academicStructureService().GetLevel(r.Context(), id, u.TenantID)
	if err != nil {
		if errors.Is(err, services.ErrAcademicNotFound) {
			jsonErr(w, "Nivel nao encontrado", http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, level, http.StatusOK)
}

func (h *Handler) CriarNivelEnsino(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.Level
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	if err := h.academicStructureService().CreateLevel(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrAcademicInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

func (h *Handler) ActualizarNivelEnsino(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	var fields map[string]any
	if err := json.NewDecoder(r.Body).Decode(&fields); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	if err := h.academicStructureService().UpdateLevel(r.Context(), id, u.TenantID, fields); err != nil {
		switch {
		case errors.Is(err, services.ErrAcademicNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrAcademicInvalidData):
			jsonErr(w, err.Error(), http.StatusBadRequest)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverNivelEnsino(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	if err := h.academicStructureService().DeleteLevel(r.Context(), id, u.TenantID); err != nil {
		switch {
		case errors.Is(err, services.ErrAcademicNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrAcademicHasChildren):
			jsonErr(w, err.Error(), http.StatusConflict)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- Séries ---

func (h *Handler) ListarSeries(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	levelID, _ := strconv.ParseInt(r.URL.Query().Get("level_id"), 10, 64)
	series, err := h.academicStructureService().ListSeries(r.Context(), u.TenantID, levelID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, series, http.StatusOK)
}

func (h *Handler) ObterSerie(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	series, err := h.academicStructureService().GetSeries(r.Context(), id, u.TenantID)
	if err != nil {
		if errors.Is(err, services.ErrAcademicNotFound) {
			jsonErr(w, "Serie nao encontrada", http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, series, http.StatusOK)
}

func (h *Handler) CriarSerie(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.Series
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	if err := h.academicStructureService().CreateSeries(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrAcademicInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

func (h *Handler) ActualizarSerie(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	var fields map[string]any
	if err := json.NewDecoder(r.Body).Decode(&fields); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	if err := h.academicStructureService().UpdateSeries(r.Context(), id, u.TenantID, fields); err != nil {
		switch {
		case errors.Is(err, services.ErrAcademicNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrAcademicInvalidData):
			jsonErr(w, err.Error(), http.StatusBadRequest)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverSerie(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	if err := h.academicStructureService().DeleteSeries(r.Context(), id, u.TenantID); err != nil {
		switch {
		case errors.Is(err, services.ErrAcademicNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrAcademicHasChildren):
			jsonErr(w, err.Error(), http.StatusConflict)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- Cursos ---

func (h *Handler) ListarCursos(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	levelID, _ := strconv.ParseInt(r.URL.Query().Get("level_id"), 10, 64)
	courses, err := h.academicStructureService().ListCourses(r.Context(), u.TenantID, levelID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, courses, http.StatusOK)
}

func (h *Handler) ObterCurso(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	course, err := h.academicStructureService().GetCourse(r.Context(), id, u.TenantID)
	if err != nil {
		if errors.Is(err, services.ErrAcademicNotFound) {
			jsonErr(w, "Curso nao encontrado", http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, course, http.StatusOK)
}

func (h *Handler) CriarCurso(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.Course
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	if err := h.academicStructureService().CreateCourse(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrAcademicInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

func (h *Handler) ActualizarCurso(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	var fields map[string]any
	if err := json.NewDecoder(r.Body).Decode(&fields); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	if err := h.academicStructureService().UpdateCourse(r.Context(), id, u.TenantID, fields); err != nil {
		switch {
		case errors.Is(err, services.ErrAcademicNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrAcademicInvalidData):
			jsonErr(w, err.Error(), http.StatusBadRequest)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverCurso(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	if err := h.academicStructureService().DeleteCourse(r.Context(), id, u.TenantID); err != nil {
		switch {
		case errors.Is(err, services.ErrAcademicNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrAcademicHasChildren):
			jsonErr(w, err.Error(), http.StatusConflict)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- Ciclos ---

func (h *Handler) ListarCiclos(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	levelID, _ := strconv.ParseInt(r.URL.Query().Get("level_id"), 10, 64)
	cycles, err := h.academicStructureService().ListCycles(r.Context(), u.TenantID, levelID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, cycles, http.StatusOK)
}

func (h *Handler) ObterCiclo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	cycle, err := h.academicStructureService().GetCycle(r.Context(), id, u.TenantID)
	if err != nil {
		if errors.Is(err, services.ErrAcademicNotFound) {
			jsonErr(w, "Ciclo nao encontrado", http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, cycle, http.StatusOK)
}

func (h *Handler) CriarCiclo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.Cycle
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	if err := h.academicStructureService().CreateCycle(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrAcademicInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

func (h *Handler) ActualizarCiclo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	var fields map[string]any
	if err := json.NewDecoder(r.Body).Decode(&fields); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	if err := h.academicStructureService().UpdateCycle(r.Context(), id, u.TenantID, fields); err != nil {
		switch {
		case errors.Is(err, services.ErrAcademicNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrAcademicInvalidData):
			jsonErr(w, err.Error(), http.StatusBadRequest)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverCiclo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	if err := h.academicStructureService().DeleteCycle(r.Context(), id, u.TenantID); err != nil {
		switch {
		case errors.Is(err, services.ErrAcademicNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrAcademicHasChildren):
			jsonErr(w, err.Error(), http.StatusConflict)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- Currículo (associação disciplina × curso/nível/série) ---

func (h *Handler) ListarCurriculo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	q := r.URL.Query()
	var filter repositories.ListCourseSubjectsFilter
	filter.CourseID, _ = strconv.ParseInt(q.Get("course_id"), 10, 64)
	filter.LevelID, _ = strconv.ParseInt(q.Get("level_id"), 10, 64)
	filter.SeriesID, _ = strconv.ParseInt(q.Get("series_id"), 10, 64)
	filter.SubjectID, _ = strconv.ParseInt(q.Get("subject_id"), 10, 64)
	items, err := h.academicStructureService().ListCourseSubjects(r.Context(), u.TenantID, filter)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, items, http.StatusOK)
}

func (h *Handler) ObterItemCurriculo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	item, err := h.academicStructureService().GetCourseSubject(r.Context(), id, u.TenantID)
	if err != nil {
		if errors.Is(err, services.ErrAcademicNotFound) {
			jsonErr(w, "Item de curriculo nao encontrado", http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, item, http.StatusOK)
}

func (h *Handler) CriarItemCurriculo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.CourseSubject
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	if err := h.academicStructureService().CreateCourseSubject(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrAcademicInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Dados invalidos ou associacao duplicada", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

func (h *Handler) ActualizarItemCurriculo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	var fields map[string]any
	if err := json.NewDecoder(r.Body).Decode(&fields); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	if err := h.academicStructureService().UpdateCourseSubject(r.Context(), id, u.TenantID, fields); err != nil {
		switch {
		case errors.Is(err, services.ErrAcademicNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrAcademicInvalidData):
			jsonErr(w, err.Error(), http.StatusBadRequest)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverItemCurriculo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	if err := h.academicStructureService().DeleteCourseSubject(r.Context(), id, u.TenantID); err != nil {
		switch {
		case errors.Is(err, services.ErrAcademicNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrAcademicHasChildren):
			jsonErr(w, err.Error(), http.StatusConflict)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- Períodos da disciplina no currículo ---

func (h *Handler) ListarPeriodosDisciplina(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	courseSubjectID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	terms, err := h.academicStructureService().ListCourseSubjectTerms(r.Context(), u.TenantID, courseSubjectID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, terms, http.StatusOK)
}

func (h *Handler) CriarPeriodoDisciplina(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	courseSubjectID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	var input models.CourseSubjectTerm
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	input.CourseSubjectID = courseSubjectID
	if err := h.academicStructureService().CreateCourseSubjectTerm(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrAcademicInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Dados invalidos ou periodo ja configurado", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

func (h *Handler) ActualizarPeriodoDisciplina(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "termId"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	var fields map[string]any
	if err := json.NewDecoder(r.Body).Decode(&fields); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	if err := h.academicStructureService().UpdateCourseSubjectTerm(r.Context(), id, u.TenantID, fields); err != nil {
		switch {
		case errors.Is(err, services.ErrAcademicNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, services.ErrAcademicInvalidData):
			jsonErr(w, err.Error(), http.StatusBadRequest)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverPeriodoDisciplina(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "termId"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	if err := h.academicStructureService().DeleteCourseSubjectTerm(r.Context(), id, u.TenantID); err != nil {
		switch {
		case errors.Is(err, services.ErrAcademicNotFound):
			jsonErr(w, err.Error(), http.StatusNotFound)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
