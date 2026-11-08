package middleware

import "net/http"

// acoesPorMetodo traduz o método HTTP no nome da acção registada em
// auditoria (ver AuditModule).
var acoesPorMetodo = map[string]string{
	http.MethodPost:   "criar",
	http.MethodPut:    "atualizar",
	http.MethodPatch:  "atualizar",
	http.MethodDelete: "eliminar",
}
