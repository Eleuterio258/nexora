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

func (h *Handler) incidentService() *services.IncidentService {
	return services.NewIncidentService(h.incidentRepo)
}

// --- Incident Types ---

func (h *Handler) ListarTiposOcorrencia(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	types, err := h.incidentService().ListIncidentTypes(r.Context(), u.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, types, http.StatusOK)
}

func (h *Handler) CriarTipoOcorrencia(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.IncidentType
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	if err := h.incidentService().CreateIncidentType(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrIncidentInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

// --- Incidents ---

func (h *Handler) ListarOcorrencias(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	q := r.URL.Query()
	studentID, _ := strconv.ParseInt(q.Get("student_id"), 10, 64)
	yearID, _ := strconv.ParseInt(q.Get("year_id"), 10, 64)

	incidents, err := h.incidentService().ListIncidents(r.Context(), u.TenantID, studentID, yearID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, incidents, http.StatusOK)
}

func (h *Handler) ObterOcorrencia(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	incident, err := h.incidentService().GetIncident(r.Context(), id, u.TenantID)
	if err != nil {
		if errors.Is(err, services.ErrIncidentNotFound) {
			jsonErr(w, err.Error(), http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, incident, http.StatusOK)
}

func (h *Handler) CriarOcorrencia(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.StudentIncident
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	input.ReportedBy = u.ID
	if err := h.incidentService().CreateIncident(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrIncidentInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

func (h *Handler) ActualizarOcorrencia(w http.ResponseWriter, r *http.Request) {
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
	if err := h.incidentService().UpdateIncident(r.Context(), id, u.TenantID, fields); err != nil {
		if errors.Is(err, services.ErrIncidentNotFound) {
			jsonErr(w, err.Error(), http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- Sanctions ---

func (h *Handler) CriarSancao(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.StudentSanction
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	input.AplicadoPor = u.ID
	if err := h.incidentService().CreateSanction(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrIncidentInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

// --- Merits ---

func (h *Handler) CriarMerito(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.StudentMerit
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	input.AtribuidoPor = &u.ID
	if err := h.incidentService().CreateMerit(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrIncidentInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}
