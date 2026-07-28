package middleware

import (
	"context"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
)

type professorContextKey string

const ProfessorKey professorContextKey = "professorUser"

// ProfessorUser é a identidade resolvida do professor autenticado no portal.
type ProfessorUser struct {
	ID       int64 // gestao_escolar.school_teachers.id
	UserID   int64 // auth.users.id
	TenantID int64
}

func GetProfessorUser(r *http.Request) *ProfessorUser {
	u, _ := r.Context().Value(ProfessorKey).(*ProfessorUser)
	return u
}

// RequireProfessorAuth exige escopo "portal_professor" (definido no login,
// RequireAuth) e um registo correspondente em gestao_escolar.school_teachers,
// injectando ProfessorUser no contexto. Dá ao portal do professor a mesma
// garantia que RequireAlunoAuth/RequireEncarregadoAuth dão aos outros dois
// portais — a identidade é resolvida e validada ao nível do router, não
// repetida (e potencialmente esquecida) em cada handler.
//
// Deve ser montado depois de RequireAuth no grupo de rotas.
func RequireProfessorAuth(pool *pgxpool.Pool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			u := GetUser(r)
			if u == nil || u.Escopo != "portal_professor" {
				JSONErr(w, "Acesso reservado a professores", http.StatusForbidden)
				return
			}

			var teacherID, tenantID int64
			err := pool.QueryRow(r.Context(), `
				SELECT id, tenant_id FROM gestao_escolar.school_teachers
				 WHERE user_id = $1 LIMIT 1`, u.ID,
			).Scan(&teacherID, &tenantID)
			if err != nil {
				JSONErr(w, "Professor não encontrado", http.StatusNotFound)
				return
			}

			ctx := context.WithValue(r.Context(), ProfessorKey, &ProfessorUser{
				ID: teacherID, UserID: u.ID, TenantID: tenantID,
			})
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
