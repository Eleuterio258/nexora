package handlers

import (
	"encoding/json"
	"net/http"
	"time"
)

func (h *Handler) ListarConfiguracoesGlobais(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(r.Context(), `
		SELECT chave, valor, descricao, updated_at
		  FROM saas.global_settings
		 ORDER BY chave ASC`)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []map[string]any{}
	for rows.Next() {
		var item struct {
			Chave     string    `json:"chave"`
			Valor     *string   `json:"valor"`
			Descricao *string   `json:"descricao"`
			UpdatedAt time.Time `json:"updated_at"`
		}
		if err := rows.Scan(&item.Chave, &item.Valor, &item.Descricao, &item.UpdatedAt); err == nil {
			data = append(data, map[string]any{
				"chave":     item.Chave,
				"valor":     item.Valor,
				"descricao": item.Descricao,
				"updated_at": item.UpdatedAt,
			})
		}
	}

	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) ActualizarConfiguracaoGlobal(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Chave     string  `json:"chave"`
		Valor     *string `json:"valor"`
		Descricao *string `json:"descricao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Chave == "" {
		jsonErr(w, "chave é obrigatória", http.StatusBadRequest)
		return
	}

	var result struct {
		Chave     string    `json:"chave"`
		Valor     *string   `json:"valor"`
		Descricao *string   `json:"descricao"`
		UpdatedAt time.Time `json:"updated_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO saas.global_settings (chave, valor, descricao, updated_at)
		VALUES ($1, $2, $3, NOW())
		ON CONFLICT (chave)
		DO UPDATE SET
			valor = COALESCE($2, saas.global_settings.valor),
			descricao = COALESCE($3, saas.global_settings.descricao),
			updated_at = NOW()
		RETURNING chave, valor, descricao, updated_at`,
		body.Chave, body.Valor, body.Descricao).
		Scan(&result.Chave, &result.Valor, &result.Descricao, &result.UpdatedAt)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}
