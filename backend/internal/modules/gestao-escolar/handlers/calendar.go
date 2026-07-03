package handlers

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/services"
)

func (h *Handler) calendarService() *services.CalendarService {
	return services.NewCalendarService(h.calendarRepo)
}

// --- Event Types ---

func (h *Handler) ListarTiposEvento(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	types, err := h.calendarService().ListEventTypes(r.Context(), u.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, types, http.StatusOK)
}

func (h *Handler) CriarTipoEvento(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.CalendarEventType
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	if err := h.calendarService().CreateEventType(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrCalendarInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

// --- Events ---

func (h *Handler) ListarEventosCalendario(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	q := r.URL.Query()
	yearID, _ := strconv.ParseInt(q.Get("year_id"), 10, 64)
	var start, end *time.Time
	if s := q.Get("start"); s != "" {
		if t, err := time.Parse("2006-01-02", s); err == nil {
			start = &t
		}
	}
	if e := q.Get("end"); e != "" {
		if t, err := time.Parse("2006-01-02", e); err == nil {
			end = &t
		}
	}

	events, err := h.calendarService().ListEvents(r.Context(), u.TenantID, yearID, start, end)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, events, http.StatusOK)
}

func (h *Handler) ObterEventoCalendario(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	event, err := h.calendarService().GetEvent(r.Context(), id, u.TenantID)
	if err != nil {
		if errors.Is(err, services.ErrCalendarNotFound) {
			jsonErr(w, err.Error(), http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, event, http.StatusOK)
}

func (h *Handler) CriarEventoCalendario(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.CalendarEvent
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	input.CreatedBy = &u.ID
	if err := h.calendarService().CreateEvent(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrCalendarInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

func (h *Handler) ActualizarEventoCalendario(w http.ResponseWriter, r *http.Request) {
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
	if err := h.calendarService().UpdateEvent(r.Context(), id, u.TenantID, fields); err != nil {
		if errors.Is(err, services.ErrCalendarNotFound) {
			jsonErr(w, err.Error(), http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverEventoCalendario(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	if err := h.calendarService().DeleteEvent(r.Context(), id, u.TenantID); err != nil {
		if errors.Is(err, services.ErrCalendarNotFound) {
			jsonErr(w, err.Error(), http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
