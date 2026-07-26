package handlers

import (
	"testing"

	"github.com/stretchr/testify/assert"

	"nexora/internal/modules/auth/models"
)

func TestScopeStringFromAccess_Superadmin(t *testing.T) {
	ua := &models.UserAccess{Tipo: "superadmin"}
	assert.Equal(t, "*", scopeStringFromAccess(ua))
}

func TestScopeStringFromAccess_Funcionario(t *testing.T) {
	ua := &models.UserAccess{
		Tipo: "funcionario",
		Modulos: []models.ModuloAcesso{
			{Modulo: "recursos-humanos", Acoes: []string{"aprovar_ausencias", "ver_funcionarios"}},
			{Modulo: "faturacao", Acoes: []string{"criar"}},
		},
	}
	assert.Equal(t,
		"recursos-humanos:aprovar_ausencias recursos-humanos:ver_funcionarios faturacao:criar",
		scopeStringFromAccess(ua))
}

func TestScopeStringFromAccess_SemPermissoes(t *testing.T) {
	ua := &models.UserAccess{Tipo: "funcionario", Modulos: []models.ModuloAcesso{}}
	assert.Equal(t, "", scopeStringFromAccess(ua))
}
