package handlers

import (
	"html/template"
	"net/http"
	"net/url"
	"time"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/auth/models"
)

const authorizationCodeExpiry = 90 * time.Second

// authorizeForm carrega os parâmetros OAuth2 do pedido original através de
// campos escondidos entre o GET (mostra o formulário) e o POST (submete
// credenciais) — evita ter de inventar uma sessão/cookie de autorização só
// para um fluxo que hoje não tem nenhum consumidor real além do cliente
// smoke-test (ver plano, secção "authorization_code"). Se um consumidor real
// aparecer (SPA, terceiros), um cookie de sessão passa a fazer sentido.
type authorizeForm struct {
	ClientID            string
	RedirectURI         string
	CodeChallenge       string
	CodeChallengeMethod string
	State               string
	Erro                string
}

var authorizeTemplate = template.Must(template.New("authorize").Parse(`<!DOCTYPE html>
<html lang="pt">
<head><meta charset="utf-8"><title>Nexora ERP — Iniciar sessão</title></head>
<body>
  <h1>Nexora ERP</h1>
  {{if .Erro}}<p style="color:red">{{.Erro}}</p>{{end}}
  <form method="POST" action="/oauth/authorize">
    <input type="hidden" name="client_id" value="{{.ClientID}}">
    <input type="hidden" name="redirect_uri" value="{{.RedirectURI}}">
    <input type="hidden" name="code_challenge" value="{{.CodeChallenge}}">
    <input type="hidden" name="code_challenge_method" value="{{.CodeChallengeMethod}}">
    <input type="hidden" name="state" value="{{.State}}">
    <label>Email <input type="email" name="username" required autofocus></label>
    <label>Password <input type="password" name="password" required></label>
    <button type="submit">Entrar</button>
  </form>
</body>
</html>`))

// oauthAuthorizeParams valida os parâmetros comuns ao GET e ao POST de
// /oauth/authorize. Devolve ok=false já com a resposta escrita — se o erro
// for de client_id/redirect_uri desconhecidos, NUNCA redirecciona (previne
// open-redirect); outros erros redireccionam com ?error=...&state=....
func (h *Handler) oauthAuthorizeParams(w http.ResponseWriter, r *http.Request) (client *models.OAuthClient, redirectURI, challenge, state string, ok bool) {
	clientID := r.FormValue("client_id")
	redirectURI = r.FormValue("redirect_uri")
	responseType := r.FormValue("response_type")
	challenge = r.FormValue("code_challenge")
	method := r.FormValue("code_challenge_method")
	state = r.FormValue("state")

	client, err := models.LoadOAuthClient(r.Context(), h.db, clientID)
	if err != nil {
		http.Error(w, "client_id desconhecido ou inactivo", http.StatusBadRequest)
		return nil, "", "", "", false
	}
	if !client.ValidRedirectURI(redirectURI) {
		http.Error(w, "redirect_uri não registado para este cliente", http.StatusBadRequest)
		return nil, "", "", "", false
	}
	// A partir daqui redirect_uri já está validado — erros seguintes podem
	// voltar ao cliente via redirect com ?error=...
	if !client.SupportsGrant("authorization_code") {
		redirectWithError(w, r, redirectURI, state, "unauthorized_client")
		return nil, "", "", "", false
	}
	if responseType != "code" {
		redirectWithError(w, r, redirectURI, state, "unsupported_response_type")
		return nil, "", "", "", false
	}
	if challenge == "" || method != "S256" {
		redirectWithError(w, r, redirectURI, state, "invalid_request")
		return nil, "", "", "", false
	}
	return client, redirectURI, challenge, state, true
}

func redirectWithError(w http.ResponseWriter, r *http.Request, redirectURI, state, code string) {
	u, err := url.Parse(redirectURI)
	if err != nil {
		http.Error(w, "redirect_uri inválido", http.StatusBadRequest)
		return
	}
	q := u.Query()
	q.Set("error", code)
	if state != "" {
		q.Set("state", state)
	}
	u.RawQuery = q.Encode()
	http.Redirect(w, r, u.String(), http.StatusFound)
}

// OAuthAuthorize implementa GET /oauth/authorize (mostra o formulário de
// login) e POST /oauth/authorize (autentica, gera o code, redirecciona).
func (h *Handler) OAuthAuthorize(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		h.oauthAuthorizeShowForm(w, r, "")
		return
	}
	h.oauthAuthorizeSubmit(w, r)
}

func (h *Handler) oauthAuthorizeShowForm(w http.ResponseWriter, r *http.Request, erro string) {
	_, redirectURI, challenge, state, ok := h.oauthAuthorizeParams(w, r)
	if !ok {
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	authorizeTemplate.Execute(w, authorizeForm{
		ClientID:            r.FormValue("client_id"),
		RedirectURI:         redirectURI,
		CodeChallenge:       challenge,
		CodeChallengeMethod: r.FormValue("code_challenge_method"),
		State:               state,
		Erro:                erro,
	})
}

func (h *Handler) oauthAuthorizeSubmit(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		http.Error(w, "corpo do pedido inválido", http.StatusBadRequest)
		return
	}
	client, redirectURI, challenge, state, ok := h.oauthAuthorizeParams(w, r)
	if !ok {
		return
	}

	username := r.FormValue("username")
	password := r.FormValue("password")
	u, err := h.findUserByCredentials(r.Context(), username, password)
	if err != nil || (u.tipo != "funcionario" && u.tipo != "superadmin") {
		// Mesma restrição do grant password (ver oauth_token.go) — contas de
		// portal não passam por aqui nesta fase.
		h.oauthAuthorizeShowForm(w, r, "Credenciais inválidas")
		return
	}

	// is_first_party salta o ecrã de consentimento — nenhum dos 3 clientes
	// seed (web-erp/android-app/smoke-test) é third-party hoje, mas o ramo
	// fica pronto para quando existir um.
	if !client.IsFirstParty {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.Write([]byte("<p>Este cliente requer consentimento explícito — funcionalidade ainda não implementada.</p>"))
		return
	}

	scope := ""
	if access, err := models.LoadUserAccess(r.Context(), h.db, u.userID, u.membershipID); err == nil {
		scope = scopeStringFromAccess(access)
	}

	code, err := randomOpaqueToken()
	if err != nil {
		redirectWithError(w, r, redirectURI, state, "server_error")
		return
	}
	_, err = h.db.Exec(r.Context(), `
		INSERT INTO auth.oauth_authorization_codes
			(code_hash, client_id, user_id, membership_id, redirect_uri, scope, code_challenge, code_challenge_method, expira_em)
		VALUES ($1, $2, $3, $4, $5, $6, $7, 'S256', $8)`,
		mw.HashToken(code), client.ID, u.userID, u.membershipID, redirectURI, scope, challenge,
		time.Now().Add(authorizationCodeExpiry),
	)
	if err != nil {
		redirectWithError(w, r, redirectURI, state, "server_error")
		return
	}

	dest, err := url.Parse(redirectURI)
	if err != nil {
		http.Error(w, "redirect_uri inválido", http.StatusBadRequest)
		return
	}
	q := dest.Query()
	q.Set("code", code)
	if state != "" {
		q.Set("state", state)
	}
	dest.RawQuery = q.Encode()
	http.Redirect(w, r, dest.String(), http.StatusFound)
}
