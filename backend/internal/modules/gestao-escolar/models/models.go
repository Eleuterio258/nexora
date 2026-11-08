// Package models contém as structs de domínio do módulo Gestão Escolar.
package models

// ListResponse é a resposta padrão para listagens paginadas.
type ListResponse struct {
	Data  []any `json:"data"`
	Page  int   `json:"page"`
	Limit int   `json:"limit"`
	Total int64 `json:"total"`
}
