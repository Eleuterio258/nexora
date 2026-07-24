package ws

import (
	"encoding/json"
	"sync"
)

// Event types enviados ao cliente
const (
	EvtMessage           = "message"
	EvtMessageAck        = "message_ack"
	EvtTyping            = "typing"
	EvtStopTyping        = "stop_typing"
	EvtJoined            = "joined"
	EvtUserOnline        = "user_online"
	EvtUserOffline       = "user_offline"
	EvtError             = "error"
	EvtNotification      = "notification"
	EvtNotificationCount = "notification_count"

	// Eventos de negócio POS (item 7 do plano-mudancas-backend-paycore-mobile.md)
	EvtVendaCriada       = "venda_criada"
	EvtPagamentoRecebido = "pagamento_recebido"
)

// Envelope é o envelope JSON de todos os eventos WebSocket.
type Envelope struct {
	Type string `json:"type"`
	Data any    `json:"data"`
}

func encode(evtType string, data any) []byte {
	b, _ := json.Marshal(Envelope{Type: evtType, Data: data})
	return b
}

// Hub mantém todos os clientes ligados e faz broadcast por sala (conversa_id).
type Hub struct {
	mu      sync.RWMutex
	clients map[*Client]struct{}         // todos os clientes
	rooms   map[int64]map[*Client]struct{} // conversa_id → clientes
}

func NewHub() *Hub {
	return &Hub{
		clients: make(map[*Client]struct{}),
		rooms:   make(map[int64]map[*Client]struct{}),
	}
}

func (h *Hub) Register(c *Client) {
	h.mu.Lock()
	h.clients[c] = struct{}{}
	h.mu.Unlock()
	h.BroadcastAll(encode(EvtUserOnline, map[string]any{"user_id": c.UserID}))
}

func (h *Hub) Unregister(c *Client) {
	h.mu.Lock()
	delete(h.clients, c)
	for convID, room := range h.rooms {
		delete(room, c)
		if len(room) == 0 {
			delete(h.rooms, convID)
		}
	}
	h.mu.Unlock()
	h.BroadcastAll(encode(EvtUserOffline, map[string]any{"user_id": c.UserID}))
}

func (h *Hub) JoinRoom(c *Client, conversaID int64) {
	h.mu.Lock()
	if h.rooms[conversaID] == nil {
		h.rooms[conversaID] = make(map[*Client]struct{})
	}
	h.rooms[conversaID][c] = struct{}{}
	h.mu.Unlock()
}

func (h *Hub) LeaveRoom(c *Client, conversaID int64) {
	h.mu.Lock()
	if room := h.rooms[conversaID]; room != nil {
		delete(room, c)
		if len(room) == 0 {
			delete(h.rooms, conversaID)
		}
	}
	h.mu.Unlock()
}

// BroadcastRoom envia para todos os clientes numa conversa.
func (h *Hub) BroadcastRoom(conversaID int64, msg []byte) {
	h.mu.RLock()
	room := h.rooms[conversaID]
	h.mu.RUnlock()
	for c := range room {
		select {
		case c.send <- msg:
		default:
			close(c.send)
		}
	}
}

// SendToUser envia para todas as ligações WS do utilizador com o userID dado.
func (h *Hub) SendToUser(userID int64, msg []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()
	for c := range h.clients {
		if c.UserID == userID {
			select {
			case c.send <- msg:
			default:
			}
		}
	}
}

// SendEvent codifica e envia um evento de negócio a um utilizador — usado por
// handlers fora do package ws (ex. pos.CriarVenda) para notificar em tempo
// real sem precisar de conhecer o formato interno do envelope.
func (h *Hub) SendEvent(userID int64, evtType string, data any) {
	h.SendToUser(userID, encode(evtType, data))
}

// BroadcastAll envia para todos os clientes ligados.
func (h *Hub) BroadcastAll(msg []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()
	for c := range h.clients {
		select {
		case c.send <- msg:
		default:
		}
	}
}

// OnlineUsers devolve lista de user_ids ligados.
func (h *Hub) OnlineUsers() []int64 {
	h.mu.RLock()
	defer h.mu.RUnlock()
	ids := make([]int64, 0, len(h.clients))
	seen := make(map[int64]struct{})
	for c := range h.clients {
		if _, ok := seen[c.UserID]; !ok {
			ids = append(ids, c.UserID)
			seen[c.UserID] = struct{}{}
		}
	}
	return ids
}
