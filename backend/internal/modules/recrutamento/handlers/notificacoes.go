package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

// configNotificacoesRecrutamento devolve a configuração de notificações do tenant.
func (h *Handler) configNotificacoesRecrutamento(ctx context.Context, tx pgx.Tx, tenantID int64) (map[string]bool, error) {
	cfg := map[string]bool{
		"canal_email":                    true,
		"canal_sms":                      false,
		"notificar_candidatura_recebida": true,
		"notificar_em_analise":           false,
		"notificar_entrevista_agendada":  true,
		"notificar_aprovada":             true,
		"notificar_rejeitada":            true,
		"notificar_contratado":           true,
	}
	var rowCfg struct {
		CanalEmail                   bool `json:"canal_email"`
		CanalSMS                     bool `json:"canal_sms"`
		NotificarCandidaturaRecebida bool `json:"notificar_candidatura_recebida"`
		NotificarEmAnalise           bool `json:"notificar_em_analise"`
		NotificarEntrevistaAgendada  bool `json:"notificar_entrevista_agendada"`
		NotificarAprovada            bool `json:"notificar_aprovada"`
		NotificarRejeitada           bool `json:"notificar_rejeitada"`
		NotificarContratado          bool `json:"notificar_contratado"`
	}
	err := tx.QueryRow(ctx, `
		SELECT canal_email, canal_sms, notificar_candidatura_recebida, notificar_em_analise,
		       notificar_entrevista_agendada, notificar_aprovada, notificar_rejeitada,
		       notificar_contratado
		  FROM config_notificacoes WHERE tenant_id=$1`, tenantID).
		Scan(&rowCfg.CanalEmail, &rowCfg.CanalSMS, &rowCfg.NotificarCandidaturaRecebida,
			&rowCfg.NotificarEmAnalise, &rowCfg.NotificarEntrevistaAgendada,
			&rowCfg.NotificarAprovada, &rowCfg.NotificarRejeitada, &rowCfg.NotificarContratado)
	if err != nil && err != pgx.ErrNoRows {
		return nil, err
	}
	cfg["canal_email"] = rowCfg.CanalEmail
	cfg["canal_sms"] = rowCfg.CanalSMS
	cfg["notificar_candidatura_recebida"] = rowCfg.NotificarCandidaturaRecebida
	cfg["notificar_em_analise"] = rowCfg.NotificarEmAnalise
	cfg["notificar_entrevista_agendada"] = rowCfg.NotificarEntrevistaAgendada
	cfg["notificar_aprovada"] = rowCfg.NotificarAprovada
	cfg["notificar_rejeitada"] = rowCfg.NotificarRejeitada
	cfg["notificar_contratado"] = rowCfg.NotificarContratado
	return cfg, nil
}

// templateRecrutamento busca ou cria um template padrão para o evento.
func (h *Handler) templateRecrutamento(ctx context.Context, tx pgx.Tx, tenantID int64, evento string) (*struct {
	ID        int64
	CanalTipo string
	Assunto   string
	Corpo     string
}, error) {
	var t struct {
		ID        int64
		CanalTipo string
		Assunto   string
		Corpo     string
	}
	err := tx.QueryRow(ctx, `
		SELECT id, canal_tipo, COALESCE(assunto,''), corpo
		  FROM notifications.notification_templates
		 WHERE tenant_id=$1 AND codigo=$2 AND activo=TRUE`, tenantID, "recrutamento_"+evento).
		Scan(&t.ID, &t.CanalTipo, &t.Assunto, &t.Corpo)
	if err == nil {
		return &t, nil
	}
	if err != pgx.ErrNoRows {
		return nil, err
	}

	// Criar template padrão
	canalTipo := "email"
	assunto, corpo := corpoTemplatePadrao(evento)
	var id int64
	err = tx.QueryRow(ctx, `
		INSERT INTO notifications.notification_templates
		  (tenant_id, codigo, canal_tipo, assunto, corpo, variaveis, activo)
		VALUES ($1,$2,$3,$4,$5,$6,TRUE) RETURNING id`,
		tenantID, "recrutamento_"+evento, canalTipo, assunto, corpo,
		json.RawMessage(`["nome","vaga_titulo","codigo_acompanhamento","estado","entrevista_data","entrevista_local","entrevista_link","numero_funcionario","data_admissao"]`)).Scan(&id)
	if err != nil {
		return nil, err
	}
	t.ID = id
	t.CanalTipo = canalTipo
	t.Assunto = assunto
	t.Corpo = corpo
	return &t, nil
}

func corpoTemplatePadrao(evento string) (assunto, corpo string) {
	switch evento {
	case "candidatura_recebida":
		return "Candidatura recebida — {{vaga_titulo}}",
			"Olá {{nome}},\n\nConfirmamos a receção da tua candidatura para a vaga {{vaga_titulo}}.\nCódigo de acompanhamento: {{codigo_acompanhamento}}\n\nPodes consultar o estado em qualquer momento.\n\nObrigado."
	case "em_analise":
		return "Candidatura em análise — {{vaga_titulo}}",
			"Olá {{nome}},\n\nA tua candidatura para {{vaga_titulo}} está em análise.\nCódigo: {{codigo_acompanhamento}}\n\nEntraremos em contacto brevemente."
	case "entrevista_agendada":
		return "Entrevista agendada — {{vaga_titulo}}",
			"Olá {{nome}},\n\nFoi agendada uma entrevista para a vaga {{vaga_titulo}}.\nData: {{entrevista_data}}\nLocal: {{entrevista_local}}\nLink: {{entrevista_link}}\n\nCódigo: {{codigo_acompanhamento}}"
	case "aprovada":
		return "Candidatura aprovada — {{vaga_titulo}}",
			"Parabéns {{nome}},\n\nA tua candidatura para {{vaga_titulo}} foi aprovada.\nEntraremos em contacto para os próximos passos.\nCódigo: {{codigo_acompanhamento}}"
	case "rejeitada":
		return "Candidatura não selecionada — {{vaga_titulo}}",
			"Olá {{nome}},\n\nAgradecemos o teu interesse na vaga {{vaga_titulo}}. Após análise, decidimos avançar com outro perfil.\nCódigo: {{codigo_acompanhamento}}"
	case "contratado":
		return "Bem-vindo à equipa — {{vaga_titulo}}",
			"Parabéns {{nome}},\n\nÉ com grande satisfação que te damos as boas-vindas. Foste seleccionado(a) para a vaga {{vaga_titulo}} e o teu processo de integração foi iniciado.\n\nNúmero de funcionário: {{numero_funcionario}}\nData de admissão: {{data_admissao}}\nCódigo de acompanhamento: {{codigo_acompanhamento}}\n\nO Departamento de Recursos Humanos entrará em contacto contigo com os próximos passos.\n\nBem-vindo(a)!"
	default:
		return "Atualização da candidatura", "Olá {{nome}},\n\nHouve uma atualização na tua candidatura para {{vaga_titulo}}.\nCódigo: {{codigo_acompanhamento}}"
	}
}

// substituirVariaveis faz replace simples de {{chave}} por valor.
func substituirVariaveis(texto string, vars map[string]string) string {
	for k, v := range vars {
		texto = strings.ReplaceAll(texto, "{{"+k+"}}", v)
	}
	return texto
}

// dadosCandidaturaParaNotif devolve os dados necessários para notificação.
// varsExtra permite injectar valores adicionais (ex.: número de funcionário na contratação).
func (h *Handler) dadosCandidaturaParaNotif(ctx context.Context, tx pgx.Tx, candidaturaID int64, varsExtra map[string]string) (map[string]string, string, string, error) {
	var nome, email, vagaTitulo, codigo, estado string
	var entrevistaData *time.Time
	var entrevistaLocal, entrevistaLink *string
	err := tx.QueryRow(ctx, `
		SELECT nome, email, vaga_titulo, codigo_acompanhamento, estado, entrevista_data, entrevista_local, entrevista_link
		  FROM candidaturas WHERE id=$1`, candidaturaID).Scan(
		&nome, &email, &vagaTitulo, &codigo, &estado, &entrevistaData, &entrevistaLocal, &entrevistaLink)
	if err != nil {
		return nil, "", "", err
	}

	dataFmt := ""
	if entrevistaData != nil {
		dataFmt = entrevistaData.Format("02/01/2006 15:04")
	}
	local := ""
	if entrevistaLocal != nil {
		local = *entrevistaLocal
	}
	link := ""
	if entrevistaLink != nil {
		link = *entrevistaLink
	}

	vars := map[string]string{
		"nome":                  nome,
		"vaga_titulo":           vagaTitulo,
		"codigo_acompanhamento": codigo,
		"estado":                estado,
		"entrevista_data":       dataFmt,
		"entrevista_local":      local,
		"entrevista_link":       link,
	}
	for k, v := range varsExtra {
		vars[k] = v
	}
	return vars, email, estado, nil
}

// notificarCandidatura dispara notificações conforme configuração do tenant.
// varsExtra permite injectar variáveis adicionais no template (ex.: contratação).
func (h *Handler) notificarCandidatura(ctx context.Context, tx pgx.Tx, tenantID, candidaturaID int64, evento string, varsExtra map[string]string) error {
	cfg, err := h.configNotificacoesRecrutamento(ctx, tx, tenantID)
	if err != nil {
		return err
	}

	chaveEvento := "notificar_" + evento
	if evento == "entrevista_agendada" {
		chaveEvento = "notificar_entrevista_agendada"
	}
	if !cfg[chaveEvento] {
		return nil
	}

	vars, email, _, err := h.dadosCandidaturaParaNotif(ctx, tx, candidaturaID, varsExtra)
	if err != nil {
		return err
	}
	if email == "" {
		return nil
	}

	tmpl, err := h.templateRecrutamento(ctx, tx, tenantID, evento)
	if err != nil {
		return err
	}

	assunto := substituirVariaveis(tmpl.Assunto, vars)
	corpo := substituirVariaveis(tmpl.Corpo, vars)

	// Canal email
	if cfg["canal_email"] {
		if _, err := tx.Exec(ctx, `
			INSERT INTO notifications.notification_messages
			  (tenant_id, template_id, canal_tipo, destinatario, assunto, corpo,
			   referencia_tipo, referencia_id, status, tentativas)
			VALUES ($1,$2,'email',$3,$4,$5,'recrutamento_candidatura',$6,'pendente',0)`,
			tenantID, tmpl.ID, email, assunto, corpo, candidaturaID); err != nil {
			return err
		}
	}

	// SMS: reutiliza o mesmo template se canal SMS estiver activo e houver telefone
	if cfg["canal_sms"] {
		var telefone string
		err := tx.QueryRow(ctx, `SELECT COALESCE(telefone,'') FROM candidaturas WHERE id=$1`, candidaturaID).Scan(&telefone)
		if err == nil && telefone != "" {
			// SMS usa corpo sem assunto
			if _, err := tx.Exec(ctx, `
				INSERT INTO notifications.notification_messages
				  (tenant_id, template_id, canal_tipo, destinatario, corpo,
				   referencia_tipo, referencia_id, status, tentativas)
				VALUES ($1,$2,'sms',$3,$4,'recrutamento_candidatura',$5,'pendente',0)`,
				tenantID, tmpl.ID, telefone, corpo, candidaturaID); err != nil {
				return err
			}
		}
	}

	// Registar nota do tipo sistema para histórico visível ao candidato
	nota := fmt.Sprintf("Notificação enviada (%s): %s", evento, assunto)
	_, err = tx.Exec(ctx, `
		INSERT INTO candidatura_notas (candidatura_id, autor, tipo, conteudo)
		VALUES ($1,'Sistema','sistema',$2)`, candidaturaID, nota)
	if err != nil {
		return err
	}

	// Push: só depois da transacção COMMITar é que a nota/candidatura ficam
	// visíveis a outras queries — por isso o envio é feito pelo chamador
	// (ver MoverCandidatura) após tx.Commit(), não aqui dentro da tx.
	return nil
}

// ObterConfigNotificacoes devolve a configuração de notificações do recrutamento.
func (h *Handler) ObterConfigNotificacoes(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var cfg struct {
		TenantID                     int64 `json:"tenant_id"`
		CanalEmail                   bool  `json:"canal_email"`
		CanalSMS                     bool  `json:"canal_sms"`
		NotificarCandidaturaRecebida bool  `json:"notificar_candidatura_recebida"`
		NotificarEmAnalise           bool  `json:"notificar_em_analise"`
		NotificarEntrevistaAgendada  bool  `json:"notificar_entrevista_agendada"`
		NotificarAprovada            bool  `json:"notificar_aprovada"`
		NotificarRejeitada           bool  `json:"notificar_rejeitada"`
		NotificarContratado          bool  `json:"notificar_contratado"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT tenant_id, canal_email, canal_sms, notificar_candidatura_recebida, notificar_em_analise,
		       notificar_entrevista_agendada, notificar_aprovada, notificar_rejeitada,
		       notificar_contratado
		  FROM config_notificacoes WHERE tenant_id=$1`, u.TenantID).Scan(
		&cfg.TenantID, &cfg.CanalEmail, &cfg.CanalSMS, &cfg.NotificarCandidaturaRecebida,
		&cfg.NotificarEmAnalise, &cfg.NotificarEntrevistaAgendada, &cfg.NotificarAprovada, &cfg.NotificarRejeitada,
		&cfg.NotificarContratado)
	if err == pgx.ErrNoRows {
		cfg.TenantID = u.TenantID
		cfg.CanalEmail = true
		cfg.NotificarCandidaturaRecebida = true
		cfg.NotificarEntrevistaAgendada = true
		cfg.NotificarAprovada = true
		cfg.NotificarRejeitada = true
		cfg.NotificarContratado = true
		jsonOK(w, cfg, http.StatusOK)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, cfg, http.StatusOK)
}

// ActualizarConfigNotificacoes actualiza a configuração de notificações do recrutamento.
func (h *Handler) ActualizarConfigNotificacoes(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var body struct {
		CanalEmail                   *bool `json:"canal_email"`
		CanalSMS                     *bool `json:"canal_sms"`
		NotificarCandidaturaRecebida *bool `json:"notificar_candidatura_recebida"`
		NotificarEmAnalise           *bool `json:"notificar_em_analise"`
		NotificarEntrevistaAgendada  *bool `json:"notificar_entrevista_agendada"`
		NotificarAprovada            *bool `json:"notificar_aprovada"`
		NotificarRejeitada           *bool `json:"notificar_rejeitada"`
		NotificarContratado          *bool `json:"notificar_contratado"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	_, err := h.db.Exec(r.Context(), `
		INSERT INTO config_notificacoes
		  (tenant_id, canal_email, canal_sms, notificar_candidatura_recebida, notificar_em_analise,
		   notificar_entrevista_agendada, notificar_aprovada, notificar_rejeitada,
		   notificar_contratado)
		VALUES ($1,COALESCE($2,TRUE),COALESCE($3,FALSE),COALESCE($4,TRUE),COALESCE($5,FALSE),COALESCE($6,TRUE),COALESCE($7,TRUE),COALESCE($8,TRUE),COALESCE($9,TRUE))
		ON CONFLICT (tenant_id) DO UPDATE SET
		  canal_email=COALESCE($2,config_notificacoes.canal_email),
		  canal_sms=COALESCE($3,config_notificacoes.canal_sms),
		  notificar_candidatura_recebida=COALESCE($4,config_notificacoes.notificar_candidatura_recebida),
		  notificar_em_analise=COALESCE($5,config_notificacoes.notificar_em_analise),
		  notificar_entrevista_agendada=COALESCE($6,config_notificacoes.notificar_entrevista_agendada),
		  notificar_aprovada=COALESCE($7,config_notificacoes.notificar_aprovada),
		  notificar_rejeitada=COALESCE($8,config_notificacoes.notificar_rejeitada),
		  notificar_contratado=COALESCE($9,config_notificacoes.notificar_contratado),
		  updated_at=NOW()`,
		u.TenantID, body.CanalEmail, body.CanalSMS, body.NotificarCandidaturaRecebida,
		body.NotificarEmAnalise, body.NotificarEntrevistaAgendada, body.NotificarAprovada, body.NotificarRejeitada,
		body.NotificarContratado)
	if err != nil {
		jsonErr(w, "Erro ao guardar configuração", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}
