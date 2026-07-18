package handlers

import (
	"context"
	"fmt"
	"net/http"
	"strconv"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/zishang520/socket.io/v2/socket"

	mw "nexora/internal/middleware"
	authModels "nexora/internal/modules/auth/models"
)

// RealtimeServer é o servidor Socket.IO da conversa candidato↔recrutador.
// É construído independentemente do Handler para poder ser passado como
// dependência a New(), tal como já acontece com push.Service.
type RealtimeServer struct {
	io        *socket.Server
	db        *pgxpool.Pool
	jwtSecret string
}

// realtimeIdentity identifica quem está do outro lado do socket — ou um
// candidato (sessão de portal) ou um funcionário (JWT do ERP), nunca ambos.
type realtimeIdentity struct {
	CandidatoID   *int64
	FuncionarioID *int64
	TenantID      int64
}

func candidaturaRoom(candidaturaID int64) socket.Room {
	return socket.Room(fmt.Sprintf("candidatura:%d", candidaturaID))
}

// NewRealtimeServer cria o servidor Socket.IO e regista a validação de
// handshake e o evento join_candidatura. Seguro chamar com db == nil (usado
// por cmd/testrouter) — a ligação à BD só é usada dentro dos callbacks por
// ligação, nunca na construção.
func NewRealtimeServer(db *pgxpool.Pool, jwtSecret string) *RealtimeServer {
	rs := &RealtimeServer{db: db, jwtSecret: jwtSecret, io: socket.NewServer(nil, nil)}

	// A autenticação corre como middleware (Server.Use), não dentro do
	// callback de "connection": o middleware garante que nenhum pacote do
	// cliente é entregue antes de next() ser chamado, evitando uma corrida
	// em que o cliente emite join_candidatura mal recebe o "connect" e o
	// servidor ainda não acabou de validar a sessão (o que dropava o evento
	// silenciosamente quando isto corria dentro do handler de "connection").
	rs.io.Use(func(client *socket.Socket, next func(*socket.ExtendedError)) {
		auth, _ := client.Handshake().Auth.(map[string]any)
		rawToken, _ := auth["token"].(string)
		if rawToken == "" {
			next(socket.NewExtendedError("token em falta", nil))
			return
		}

		if identity, ok := rs.authCandidato(rawToken); ok {
			client.SetData(identity)
			next(nil)
			return
		}
		if identity, ok := rs.authFuncionario(rawToken); ok {
			client.SetData(identity)
			next(nil)
			return
		}
		next(socket.NewExtendedError("sessão inválida ou expirada", nil))
	})

	rs.io.On("connection", func(clients ...any) {
		client := clients[0].(*socket.Socket)
		identity := client.Data().(*realtimeIdentity)

		client.On("join_candidatura", func(args ...any) {
			if len(args) == 0 {
				return
			}
			candidaturaID, ok := toInt64(args[0])
			if !ok {
				client.Emit("join_error", "candidatura_id inválido")
				return
			}

			if !rs.podeAcederCandidatura(identity, candidaturaID) {
				client.Emit("join_error", "candidatura não encontrada")
				return
			}

			client.Join(candidaturaRoom(candidaturaID))
			client.Emit("joined", candidaturaID)
		})
	})

	return rs
}

// authCandidato valida o token de sessão do portal de candidatos — mesma
// query usada por internal/middleware/candidato_auth.go's RequireCandidatoAuth.
func (rs *RealtimeServer) authCandidato(rawToken string) (*realtimeIdentity, bool) {
	var candidatoID, tenantID int64
	err := rs.db.QueryRow(context.Background(), `
		SELECT c.id, c.tenant_id
		  FROM recrutamento.candidato_sessions s
		  JOIN recrutamento.candidatos c ON c.id = s.candidato_id
		 WHERE s.token_hash = $1
		   AND s.revogado_em IS NULL
		   AND s.expira_em > NOW()
		   AND c.ativo = true`,
		mw.HashToken(rawToken),
	).Scan(&candidatoID, &tenantID)
	if err != nil {
		return nil, false
	}
	return &realtimeIdentity{CandidatoID: &candidatoID, TenantID: tenantID}, true
}

// authFuncionario valida um JWT de funcionário do ERP — mesma lógica de
// internal/ws/client.go's ServeWS (JWT + sessão activa em auth.sessions) —
// mais uma verificação de permissão recrutamento:ver_candidaturas, já que
// aqui não há middleware de rota a fazer esse papel.
func (rs *RealtimeServer) authFuncionario(rawToken string) (*realtimeIdentity, bool) {
	token, err := jwt.Parse(rawToken, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("signing method inválido")
		}
		return []byte(rs.jwtSecret), nil
	})
	if err != nil || !token.Valid {
		return nil, false
	}
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, false
	}
	sub, ok1 := claims["sub"].(float64)
	tid, ok2 := claims["tid"].(float64)
	if !ok1 || !ok2 {
		return nil, false
	}
	userID, tenantID := int64(sub), int64(tid)
	membershipID, _ := claims["mid"].(float64)

	var ativa bool
	rs.db.QueryRow(context.Background(), `
		SELECT ativa FROM auth.sessions WHERE token_hash=$1 AND user_id=$2`,
		mw.HashToken(rawToken), userID).Scan(&ativa)
	if !ativa {
		return nil, false
	}

	access, err := authModels.LoadUserAccess(context.Background(), rs.db, userID, int64(membershipID))
	if err != nil || !access.Can("recrutamento", "ver_candidaturas") {
		return nil, false
	}

	return &realtimeIdentity{FuncionarioID: &userID, TenantID: tenantID}, true
}

// podeAcederCandidatura confirma que a identidade autenticada tem acesso à
// candidatura pedida: um candidato só à sua própria, um funcionário a
// qualquer uma do seu tenant (mesmo alcance que o GET /candidaturas/{id} REST
// já lhes concede, protegido por essa mesma permissão verificada no handshake).
func (rs *RealtimeServer) podeAcederCandidatura(identity *realtimeIdentity, candidaturaID int64) bool {
	var existe bool
	if identity.CandidatoID != nil {
		rs.db.QueryRow(context.Background(), `
			SELECT EXISTS(SELECT 1 FROM recrutamento.candidaturas
			               WHERE id=$1 AND candidato_id=$2 AND tenant_id=$3)`,
			candidaturaID, *identity.CandidatoID, identity.TenantID).Scan(&existe)
	} else {
		rs.db.QueryRow(context.Background(), `
			SELECT EXISTS(SELECT 1 FROM recrutamento.candidaturas
			               WHERE id=$1 AND tenant_id=$2)`,
			candidaturaID, identity.TenantID).Scan(&existe)
	}
	return existe
}

// EmitNovaMensagem publica uma nota/mensagem para todos os sockets ligados à
// sala da candidatura — equivalente em tempo real ao notificarCandidatoPush,
// mas para quem tem a app/painel aberto. Nunca bloqueia; sem clientes na
// sala é um no-op silencioso.
func (rs *RealtimeServer) EmitNovaMensagem(nota CandidaturaNota) {
	rs.io.To(candidaturaRoom(nota.CandidaturaID)).Emit("nova_mensagem", nota)
}

// Handler devolve o http.Handler a montar no router (ver router.go).
func (rs *RealtimeServer) Handler() http.Handler {
	return rs.io.ServeHandler(nil)
}

func toInt64(v any) (int64, bool) {
	switch n := v.(type) {
	case float64:
		return int64(n), true
	case int64:
		return n, true
	case int:
		return int64(n), true
	case string:
		parsed, err := strconv.ParseInt(n, 10, 64)
		return parsed, err == nil
	default:
		return 0, false
	}
}
