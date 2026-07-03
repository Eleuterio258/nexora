package handlers

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/services"
)

func (h *Handler) timetableService() *services.TimetableService {
	return services.NewTimetableService(h.timetableRepo)
}

// --- Time Slots ---

func (h *Handler) ListarTimeSlots(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	slots, err := h.timetableService().ListTimeSlots(r.Context(), u.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, slots, http.StatusOK)
}

func (h *Handler) CriarTimeSlot(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.TimeSlot
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	if err := h.timetableService().CreateTimeSlot(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrTimetableInvalidData) || errors.Is(err, services.ErrTimetableInvalidSlot) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

// --- Timetable Entries ---

func (h *Handler) ListarHorarioTurma(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	classID, err := strconv.ParseInt(chi.URLParam(r, "class_id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	entries, err := h.timetableService().ListByClass(r.Context(), classID, u.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, entries, http.StatusOK)
}

func (h *Handler) ListarHorarioProfessor(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	teacherID, err := strconv.ParseInt(chi.URLParam(r, "teacher_id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	entries, err := h.timetableService().ListByTeacher(r.Context(), teacherID, u.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, entries, http.StatusOK)
}

func (h *Handler) CriarHorario(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.TimetableEntry
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	if err := h.timetableService().CreateEntry(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrTimetableInvalidData) || errors.Is(err, services.ErrTimetableConflict) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

func (h *Handler) ActualizarHorario(w http.ResponseWriter, r *http.Request) {
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
	if err := h.timetableService().UpdateEntry(r.Context(), id, u.TenantID, fields); err != nil {
		if errors.Is(err, services.ErrTimetableNotFound) {
			jsonErr(w, err.Error(), http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverHorario(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	if err := h.timetableService().DeleteEntry(r.Context(), id, u.TenantID); err != nil {
		if errors.Is(err, services.ErrTimetableNotFound) {
			jsonErr(w, err.Error(), http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
