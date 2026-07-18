package handlers

import (
	"context"
	"testing"

	"github.com/pashagolub/pgxmock/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"nexora/internal/modules/auth/models"
)

// expectLoadUserAccess mocka as queries que models.LoadUserAccess emite, na
// mesma ordem/forma usada em internal/modules/auth/models/rbac_test.go, para
// que gatewayAppRole possa ser testado com permissões reais (não é possível
// construir um models.UserAccess directamente fora do pacote models, porque
// o campo `permissoes` usado por Can() é privado).
func expectLoadUserAccess(t *testing.T, mock pgxmock.PgxPoolIface, tipo string, cargoPerms [][2]string) {
	t.Helper()

	userRows := pgxmock.NewRows([]string{"tenant_id", "tipo", "escopo", "cargo_id", "cargo_nome"}).
		AddRow(int64(1), tipo, "erp", (*int64)(nil), (*string)(nil))
	mock.ExpectQuery("SELECT COALESCE\\(m\\.tenant_id, 0\\).*").
		WithArgs(int64(10), int64(5)).
		WillReturnRows(userRows)

	if tipo == "superadmin" {
		return
	}

	directRows := pgxmock.NewRows([]string{"modulo", "acao"})
	for _, p := range cargoPerms {
		directRows.AddRow(p[0], p[1])
	}
	mock.ExpectQuery("SELECT\\s+modulo,\\s+acao\\s+FROM\\s+permissoes_diretas").
		WithArgs(int64(10)).
		WillReturnRows(directRows)

	tipoRows := pgxmock.NewRows([]string{"modulo", "acao"})
	mock.ExpectQuery("SELECT\\s+modulo,\\s+acao\\s+FROM\\s+auth\\.permissoes_tipo").
		WithArgs(tipo).
		WillReturnRows(tipoRows)

	disabledRows := pgxmock.NewRows([]string{"modulo"})
	mock.ExpectQuery("SELECT\\s+modulo\\s+FROM\\s+saas\\.tenant_modules").
		WithArgs(int64(1)).
		WillReturnRows(disabledRows)

	featuresRows := pgxmock.NewRows([]string{"key"})
	mock.ExpectQuery("SELECT\\s+fc\\.key").
		WithArgs(int64(1), int64(1)).
		WillReturnRows(featuresRows)
}

func TestGatewayAppRole_Superadmin(t *testing.T) {
	mock, err := pgxmock.NewPool()
	require.NoError(t, err)
	defer mock.Close()

	expectLoadUserAccess(t, mock, "superadmin", nil)

	ua, err := models.LoadUserAccess(context.Background(), mock, 10, 5)
	require.NoError(t, err)

	assert.Equal(t, "ADMIN_SISTEMA", gatewayAppRole(ua))
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestGatewayAppRole_GestorComPermissaoAprovarAusencias(t *testing.T) {
	mock, err := pgxmock.NewPool()
	require.NoError(t, err)
	defer mock.Close()

	expectLoadUserAccess(t, mock, "funcionario", [][2]string{
		{"recursos-humanos", "ver_funcionarios"},
		{"recursos-humanos", "aprovar_ausencias"},
	})

	ua, err := models.LoadUserAccess(context.Background(), mock, 10, 5)
	require.NoError(t, err)

	assert.Equal(t, "GESTOR_RH", gatewayAppRole(ua))
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestGatewayAppRole_ColaboradorSemPermissoesDeGestao(t *testing.T) {
	mock, err := pgxmock.NewPool()
	require.NoError(t, err)
	defer mock.Close()

	expectLoadUserAccess(t, mock, "funcionario", [][2]string{
		{"recursos-humanos", "ver_funcionarios"},
	})

	ua, err := models.LoadUserAccess(context.Background(), mock, 10, 5)
	require.NoError(t, err)

	assert.Equal(t, "COLABORADOR", gatewayAppRole(ua))
	assert.NoError(t, mock.ExpectationsWereMet())
}
