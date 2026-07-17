package models

import (
	"context"
	"testing"

	"github.com/pashagolub/pgxmock/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestLoadUserAccess_SuperadminBypass(t *testing.T) {
	mock, err := pgxmock.NewPool()
	require.NoError(t, err)
	defer mock.Close()

	rows := pgxmock.NewRows([]string{"tenant_id", "tipo", "escopo", "cargo_id", "cargo_nome"}).
		AddRow(int64(1), "superadmin", "erp", (*int64)(nil), (*string)(nil))

	mock.ExpectQuery("SELECT COALESCE\\(m\\.tenant_id, 0\\).*").
		WithArgs(int64(1), int64(0)).
		WillReturnRows(rows)

	ua, err := LoadUserAccess(context.Background(), mock, 1, 0)
	require.NoError(t, err)

	assert.True(t, ua.Can("faturacao", "ver"))
	assert.True(t, ua.Can("gestao-escolar", "gerir_alunos"))
	assert.Empty(t, ua.Modulos)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestLoadUserAccess_FiltraEscopo(t *testing.T) {
	tests := []struct {
		name        string
		escopo      string
		cargoID     int64
		cargoPerms  [][2]string
		directPerms [][2]string
		wantModulos []string
		wantCan     [][2]string
		notWantCan  [][2]string
	}{
		{
			name:        "erp ve todos os modulos do cargo",
			escopo:      "erp",
			cargoID:     1,
			cargoPerms:  [][2]string{{"faturacao", "ver"}, {"gestao-escolar", "gerir_alunos"}},
			wantModulos: []string{"faturacao", "gestao-escolar"},
			wantCan:     [][2]string{{"faturacao", "ver"}, {"gestao-escolar", "gerir_alunos"}},
		},
		{
			name:        "escola ve apenas gestao-escolar",
			escopo:      "escola",
			cargoID:     2,
			cargoPerms:  [][2]string{{"gestao-escolar", "gerir_alunos"}},
			wantModulos: []string{"gestao-escolar"},
			wantCan:     [][2]string{{"gestao-escolar", "gerir_alunos"}},
			notWantCan:  [][2]string{{"faturacao", "ver"}},
		},
		{
			name:        "escola com permissao direta nao-escolar e filtrada",
			escopo:      "escola",
			cargoID:     2,
			cargoPerms:  [][2]string{{"gestao-escolar", "gerir_alunos"}},
			directPerms: [][2]string{{"faturacao", "ver"}},
			wantModulos: []string{"gestao-escolar"},
			wantCan:     [][2]string{{"gestao-escolar", "gerir_alunos"}},
			notWantCan:  [][2]string{{"faturacao", "ver"}},
		},
		{
			name:        "sem cargo e escopo escola nao herda permissoes de outro modulo",
			escopo:      "escola",
			cargoID:     0, // sem cargo
			directPerms: [][2]string{{"gestao-escolar", "ver"}, {"faturacao", "ver"}},
			wantModulos: []string{"gestao-escolar"},
			wantCan:     [][2]string{{"gestao-escolar", "ver"}},
			notWantCan:  [][2]string{{"faturacao", "ver"}},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mock, err := pgxmock.NewPool()
			require.NoError(t, err)
			defer mock.Close()

			var cargoIDPtr *int64
			var cargoNome *string
			if tt.cargoID != 0 {
				cargoIDPtr = &tt.cargoID
				n := "Cargo"
				cargoNome = &n
			}

			userRows := pgxmock.NewRows([]string{"tenant_id", "tipo", "escopo", "cargo_id", "cargo_nome"}).
				AddRow(int64(1), "funcionario", tt.escopo, cargoIDPtr, cargoNome)
			mock.ExpectQuery("SELECT COALESCE\\(m\\.tenant_id, 0\\).*").
				WithArgs(int64(10), int64(5)).
				WillReturnRows(userRows)

			if tt.cargoID != 0 {
				cargoRows := pgxmock.NewRows([]string{"modulo", "acao"})
				for _, p := range tt.cargoPerms {
					cargoRows.AddRow(p[0], p[1])
				}
				mock.ExpectQuery("SELECT\\s+modulo,\\s+acao\\s+FROM\\s+permissoes_cargo").
					WithArgs(tt.cargoID).
					WillReturnRows(cargoRows)
			}

			directRows := pgxmock.NewRows([]string{"modulo", "acao"})
			for _, p := range tt.directPerms {
				directRows.AddRow(p[0], p[1])
			}
			mock.ExpectQuery("SELECT\\s+modulo,\\s+acao\\s+FROM\\s+permissoes_diretas").
				WithArgs(int64(10)).
				WillReturnRows(directRows)

			tipoRows := pgxmock.NewRows([]string{"modulo", "acao"})
			mock.ExpectQuery("SELECT\\s+modulo,\\s+acao\\s+FROM\\s+auth\\.permissoes_tipo").
				WithArgs("funcionario").
				WillReturnRows(tipoRows)

			disabledRows := pgxmock.NewRows([]string{"modulo"})
			mock.ExpectQuery("SELECT\\s+modulo\\s+FROM\\s+saas\\.tenant_modules").
				WithArgs(int64(1)).
				WillReturnRows(disabledRows)

			featuresRows := pgxmock.NewRows([]string{"key"})
			mock.ExpectQuery("SELECT\\s+fc\\.key").
				WithArgs(int64(1), int64(1)).
				WillReturnRows(featuresRows)

			ua, err := LoadUserAccess(context.Background(), mock, 10, 5)
			require.NoError(t, err)

			got := make([]string, 0, len(ua.Modulos))
			for _, m := range ua.Modulos {
				got = append(got, m.Modulo)
			}
			for _, m := range tt.wantModulos {
				assert.Contains(t, got, m, "esperava módulo %s", m)
			}
			for _, m := range tt.wantCan {
				assert.True(t, ua.Can(m[0], m[1]), "devia poder %s/%s", m[0], m[1])
			}
			for _, m := range tt.notWantCan {
				assert.False(t, ua.Can(m[0], m[1]), "não devia poder %s/%s", m[0], m[1])
			}
			assert.NoError(t, mock.ExpectationsWereMet())
		})
	}
}
