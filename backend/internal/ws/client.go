package ws

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/gorilla/websocket"
	"github.com/jackc/pgx/v5/pgxpool"
)

func sha256sum(s string) [32]byte { return sha256.Sum256([]byte(s)) }

const (
	writeWait  = 10 * time.Second
	pongWait   = 60 * time.Second
	pingPeriod = (pongWait * 9) / 10
	maxMsgSize = 8192
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

// Client representa uma ligação WebSocket de um utilizador.
type Client struct {
	hub      *Hub
	conn     *websocket.Conn
	send     chan []byte
	db       *pgxpool.Pool
	UserID   int64
	TenantID int64
}

// Incoming é o formato das mensagens enviadas pelo cliente.
type Incoming struct {
	Type         string `json:"type"`
	ConversaID   int64  `json:"conversa_id"`
	Conteudo     string `json:"conteudo"`
	TipoMensagem string `json:"tipo_mensagem"`
	NotifID      int64  `json:"notif_id"`
}

// ServeWS faz o upgrade HTTP → WebSocket e inicia as goroutines de I/O.
// Autentica via query param ?token= (WebSocket não suporta headers custom no browser).
func ServeWS(hub *Hub, db *pgxpool.Pool, jwtSecret string, w http.ResponseWriter, r *http.Request) {
	rawToken := r.URL.Query().Get("token")
	if rawToken == "" {
		h := r.Header.Get("Authorization")
		if strings.HasPrefix(h, "Bearer ") {
			rawToken = h[7:]
		}
	}
	if rawToken == "" {
		http.Error(w, "token em falta", http.StatusUnauthorized)
		return
	}

	token, err := jwt.Parse(rawToken, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("signing method inválido")
		}
		return []byte(jwtSecret), nil
	})
	if err != nil || !token.Valid {
		http.Error(w, "token inválido", http.StatusUnauthorized)
		return
	}
	claims, _ := token.Claims.(jwt.MapClaims)
	userID   := int64(claims["sub"].(float64))
	tenantID := int64(claims["tid"].(float64))

	// Verificar sessão activa na BD
	var ativa bool
	tokenHash := fmt.Sprintf("%x", sha256sum(rawToken))
	db.QueryRow(r.Context(), `
		SELECT s.ativa FROM auth.sessions s
		 WHERE s.token_hash=$1 AND s.user_id=$2`,
		tokenHash, userID).Scan(&ativa)
	if !ativa {
		http.Error(w, "sessão revogada", http.StatusUnauthorized)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("[ws] upgrade error: %v", err)
		return
	}

	c := &Client{
		hub:      hub,
		conn:     conn,
		send:     make(chan []byte, 256),
		db:       db,
		UserID:   userID,
		TenantID: tenantID,
	}

	hub.Register(c)

	// Enviar lista de utilizadores online ao novo cliente
	c.send <- encode(EvtJoined, map[string]any{
		"user_id":      c.UserID,
		"online_users": hub.OnlineUsers(),
	})

	// Enviar contagem de notificações não lidas
	go c.sendUnreadCount()

	go c.writePump()
	go c.readPump()
}

func (c *Client) readPump() {
	defer func() {
		c.hub.Unregister(c)
		c.conn.Close()
	}()
	c.conn.SetReadLimit(maxMsgSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, raw, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseNormalClosure) {
				log.Printf("[ws] read error user=%d: %v", c.UserID, err)
			}
			break
		}
		c.handleIncoming(raw)
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()
	for {
		select {
		case msg, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				return
			}
		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (c *Client) handleIncoming(raw []byte) {
	var inc Incoming
	if err := json.Unmarshal(raw, &inc); err != nil {
		c.send <- encode(EvtError, "mensagem inválida")
		return
	}

	switch inc.Type {

	case "join":
		if inc.ConversaID == 0 { return }
		// Verificar que o utilizador é participante
		if !c.isParticipant(inc.ConversaID) {
			c.send <- encode(EvtError, "sem acesso a esta conversa")
			return
		}
		c.hub.JoinRoom(c, inc.ConversaID)

	case "leave":
		if inc.ConversaID == 0 { return }
		c.hub.LeaveRoom(c, inc.ConversaID)

	case "message":
		if inc.ConversaID == 0 || inc.Conteudo == "" { return }
		if !c.isParticipant(inc.ConversaID) {
			c.send <- encode(EvtError, "sem acesso a esta conversa")
			return
		}
		msgID := c.persistMessage(inc.ConversaID, inc.Conteudo)
		if msgID == 0 { return }

		// Buscar nome do autor
		var autorNome string
		c.db.QueryRow(context.Background(),
			`SELECT nome FROM auth.users WHERE id=$1`, c.UserID).Scan(&autorNome)

		payload := map[string]any{
			"id":           msgID,
			"conversa_id":  inc.ConversaID,
			"autor_id":     c.UserID,
			"autor_nome":   autorNome,
			"conteudo":     inc.Conteudo,
			"tipo":         "texto",
			"created_at":   time.Now().UTC().Format(time.RFC3339),
			"minha":        false,
		}
		msg := encode(EvtMessage, payload)
		c.hub.BroadcastRoom(inc.ConversaID, msg)

	case "typing":
		if inc.ConversaID == 0 { return }
		c.hub.BroadcastRoom(inc.ConversaID, encode(EvtTyping, map[string]any{
			"user_id": c.UserID, "conversa_id": inc.ConversaID,
		}))

	case "stop_typing":
		if inc.ConversaID == 0 { return }
		c.hub.BroadcastRoom(inc.ConversaID, encode(EvtStopTyping, map[string]any{
			"user_id": c.UserID, "conversa_id": inc.ConversaID,
		}))

	case "mark_read":
		if inc.NotifID == 0 { return }
		c.db.Exec(context.Background(), `
			UPDATE utilizadores.user_notifications
			   SET lida = TRUE, lida_em = NOW()
			 WHERE id = $1 AND user_id = $2`,
			inc.NotifID, c.UserID)
		go c.sendUnreadCount()

	case "mark_all_read":
		c.db.Exec(context.Background(), `
			UPDATE utilizadores.user_notifications
			   SET lida = TRUE, lida_em = NOW()
			 WHERE user_id = $1 AND lida = FALSE`,
			c.UserID)
		c.send <- encode(EvtNotificationCount, map[string]any{"total": 0})
	}
}

func (c *Client) sendUnreadCount() {
	var total int
	c.db.QueryRow(context.Background(), `
		SELECT COUNT(*) FROM utilizadores.user_notifications
		 WHERE user_id = $1 AND lida = FALSE`, c.UserID).Scan(&total)
	c.send <- encode(EvtNotificationCount, map[string]any{"total": total})
}

func (c *Client) isParticipant(conversaID int64) bool {
	var ok bool
	c.db.QueryRow(context.Background(), `
		SELECT EXISTS(SELECT 1 FROM chat_participantes WHERE conversa_id=$1 AND user_id=$2)`,
		conversaID, c.UserID).Scan(&ok)
	return ok
}

func (c *Client) persistMessage(conversaID int64, conteudo string) int64 {
	var id int64
	c.db.QueryRow(context.Background(), `
		INSERT INTO chat_mensagens (conversa_id, autor_id, conteudo, tipo)
		VALUES ($1,$2,$3,'texto') RETURNING id`,
		conversaID, c.UserID, conteudo).Scan(&id)
	return id
}
