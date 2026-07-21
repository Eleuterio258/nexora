package assiduidade

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/recursos-humanos/models"
	"nexora/internal/pkg/geo"
)

// ErrTipoEventoDesconhecido é devolvido quando o código de tipo de evento não
// existe no catálogo do tenant (rh.tipos_evento).
var ErrTipoEventoDesconhecido = errors.New("tipo de evento desconhecido para este tenant")

// RegistarEventoInput são os dados necessários para gravar um evento de
// assiduidade, independentemente da origem (hardware, self-service, manual).
type RegistarEventoInput struct {
	FuncionarioID  int64
	TipoEventoCodigo string
	MetodoCodigo   *string
	OcorridoEm     time.Time
	DataReferencia *time.Time // opcional; por omissão usa a data civil de OcorridoEm
	Origem         string
	DispositivoID  *int64
	QRTokenID      *int64
	NFCTagID       *int64
	Latitude       *float64
	Longitude      *float64
	LocalidadeID   *int64
	FotoURL        *string
	DocumentoURL   *string
	RegistadoPor   *int64 // nil para marcação automática (hardware)
	Motivo         *string
	Observacoes    *string
	IPOrigem       *string
	UserAgent      *string
	EstadoForcado  *string // usado por correcoes.go para gravar o evento gerado já como "corrigido"
	EventoPaiID    *int64  // liga o evento gerado por uma correcção ao evento original, quando existir
}

// RegistarEvento grava um evento de assiduidade independente (registo bruto +
// classificação por tipo de evento). Nunca sobrescreve um evento existente:
// duplicados exactos (mesmo funcionário, tipo, origem, dispositivo e
// instante) devolvem o evento já gravado em vez de criar uma linha nova.
//
// data_referencia por omissão é a data civil de OcorridoEm — a atribuição do
// dia correcto para turnos que atravessam a meia-noite é responsabilidade do
// motor de cálculo (calculo.go), que agrupa eventos por janela de turno, não
// por dia civil. Isto mantém RegistarEvento uma escrita "burra", conforme a
// separação bruto/calculado pedida no requisito (secção 13).
func (s *Service) RegistarEvento(ctx context.Context, tenantID int64, in RegistarEventoInput) (*models.EventoAssiduidade, error) {
	tipoEventoID, err := s.resolverTipoEventoID(ctx, tenantID, in.TipoEventoCodigo)
	if err != nil {
		return nil, err
	}

	var metodoID *int64
	if in.MetodoCodigo != nil {
		id, err := s.resolverMetodoID(ctx, tenantID, *in.MetodoCodigo)
		if err != nil {
			return nil, err
		}
		metodoID = &id
	}

	dataReferencia := in.OcorridoEm
	if in.DataReferencia != nil {
		dataReferencia = *in.DataReferencia
	}

	var dentroGeofence *bool
	if in.Latitude != nil && in.Longitude != nil && in.LocalidadeID != nil {
		dentro, err := s.validarGeofence(ctx, *in.LocalidadeID, *in.Latitude, *in.Longitude)
		if err == nil {
			dentroGeofence = &dentro
		}
	}

	// Fora do geofence só passa a estado "fora_localizacao" (para análise —
	// nunca bloqueia o registo, requisito secção 4) quando a regra
	// "marcacao_somente_empresa" estiver activa para este funcionário/tenant.
	// Sem latitude/longitude (ex.: hardware biométrico fixo, sem GPS) não há
	// o que validar — fica "valido" por omissão.
	estado := "valido"
	if dentroGeofence != nil && !*dentroGeofence {
		if s.exigeMarcacaoDentroDaEmpresa(ctx, tenantID, in.FuncionarioID) {
			estado = "fora_localizacao"
		}
	}
	if in.EstadoForcado != nil {
		estado = *in.EstadoForcado
	}

	hash := hashEventoAssiduidade(tenantID, in.FuncionarioID, tipoEventoID, in.Origem, in.DispositivoID, in.OcorridoEm)

	if existente, err := s.buscarEventoPorHash(ctx, tenantID, hash); err != nil {
		return nil, err
	} else if existente != nil {
		return existente, nil
	}

	var ev models.EventoAssiduidade
	err = s.db.QueryRow(ctx, `
		INSERT INTO rh.eventos_assiduidade (
			tenant_id, funcionario_id, tipo_evento_id, metodo_id,
			ocorrido_em, data_referencia, origem, dispositivo_id, qr_token_id, nfc_tag_id,
			latitude, longitude, localidade_id, dentro_geofence,
			foto_url, documento_url, estado, registado_por, motivo, observacoes,
			evento_pai_id, ip_origem, user_agent, hash_digital
		) VALUES (
			$1, $2, $3, $4,
			$5, $6::date, $7, $8, $9, $10,
			$11, $12, $13, $14,
			$15, $16, $17, $18, $19, $20,
			$21, $22, $23, $24
		)
		RETURNING id, tenant_id, funcionario_id, tipo_evento_id, metodo_id,
			ocorrido_em, data_referencia, origem, dispositivo_id, qr_token_id, nfc_tag_id,
			latitude, longitude, localidade_id, dentro_geofence,
			foto_url, documento_url, estado, registado_por, motivo, observacoes,
			evento_pai_id, duplicado_de_id, ip_origem, user_agent, hash_digital,
			created_at, updated_at`,
		tenantID, in.FuncionarioID, tipoEventoID, metodoID,
		in.OcorridoEm, dataReferencia, in.Origem, in.DispositivoID, in.QRTokenID, in.NFCTagID,
		in.Latitude, in.Longitude, in.LocalidadeID, dentroGeofence,
		in.FotoURL, in.DocumentoURL, estado, in.RegistadoPor, in.Motivo, in.Observacoes,
		in.EventoPaiID, in.IPOrigem, in.UserAgent, hash,
	).Scan(
		&ev.ID, &ev.TenantID, &ev.FuncionarioID, &ev.TipoEventoID, &ev.MetodoID,
		&ev.OcorridoEm, &ev.DataReferencia, &ev.Origem, &ev.DispositivoID, &ev.QRTokenID, &ev.NFCTagID,
		&ev.Latitude, &ev.Longitude, &ev.LocalidadeID, &ev.DentroGeofence,
		&ev.FotoURL, &ev.DocumentoURL, &ev.Estado, &ev.RegistadoPor, &ev.Motivo, &ev.Observacoes,
		&ev.EventoPaiID, &ev.DuplicadoDeID, &ev.IPOrigem, &ev.UserAgent, &ev.HashDigital,
		&ev.CreatedAt, &ev.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	if valorNovo, jsonErr := json.Marshal(ev); jsonErr == nil {
		_ = RegistarAuditoria(ctx, s.db, AuditoriaEntry{
			TenantID:    tenantID,
			Tabela:      "eventos_assiduidade",
			RegistoID:   ev.ID,
			Operacao:    "INSERT",
			ValorNovo:   valorNovo,
			AlteradoPor: in.RegistadoPor,
			Motivo:      in.Motivo,
			IPOrigem:    in.IPOrigem,
			EstadoNovo:  &ev.Estado,
		})
	}

	return &ev, nil
}

func (s *Service) resolverTipoEventoID(ctx context.Context, tenantID int64, codigo string) (int64, error) {
	var id int64
	err := s.db.QueryRow(ctx, `
		SELECT id FROM rh.tipos_evento
		 WHERE tenant_id = $1 AND codigo = $2 AND ativo = TRUE`,
		tenantID, codigo,
	).Scan(&id)
	if err != nil {
		// "não encontrado" é o único caso que justifica o erro específico —
		// qualquer outro erro (ligação perdida, timeout, etc.) deve
		// propagar-se tal como é, para não mascarar a causa real atrás de
		// uma mensagem de "tipo desconhecido" enganosa.
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, ErrTipoEventoDesconhecido
		}
		return 0, fmt.Errorf("resolver tipo de evento %q: %w", codigo, err)
	}
	return id, nil
}

func (s *Service) resolverMetodoID(ctx context.Context, tenantID int64, codigo string) (int64, error) {
	var id int64
	err := s.db.QueryRow(ctx, `
		SELECT id FROM rh.metodos_marcacao
		 WHERE tenant_id = $1 AND codigo = $2 AND ativo = TRUE`,
		tenantID, codigo,
	).Scan(&id)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, fmt.Errorf("método de marcação desconhecido: %s", codigo)
		}
		return 0, fmt.Errorf("resolver método de marcação %q: %w", codigo, err)
	}
	return id, nil
}

// validarGeofence reaproveita a mesma fórmula de Haversine já usada em
// recursos-humanos/handlers/assiduidade_integracao.go para o endpoint
// consultivo GET /assiduidade/geofence/validar — aqui aplicada de facto no
// momento de gravar o evento, em vez de ficar só disponível como consulta
// externa nunca chamada pelo pipeline de escrita.
func (s *Service) validarGeofence(ctx context.Context, unidadeID int64, lat, lon float64) (bool, error) {
	var unidadeLat, unidadeLon *float64
	var raioMetros *float64
	err := s.db.QueryRow(ctx, `
		SELECT latitude, longitude, raio_metros
		  FROM rh.unidades_organizacionais
		 WHERE id = $1`,
		unidadeID,
	).Scan(&unidadeLat, &unidadeLon, &raioMetros)
	if err != nil {
		return false, err
	}
	if unidadeLat == nil || unidadeLon == nil || raioMetros == nil {
		// Sem geofence configurado para esta unidade: permissivo por omissão,
		// mesmo comportamento do endpoint consultivo existente.
		return true, nil
	}
	distancia := geo.HaversineMeters(lat, lon, *unidadeLat, *unidadeLon)
	return distancia <= *raioMetros, nil
}

// exigeMarcacaoDentroDaEmpresa resolve a regra configurável
// "marcacao_somente_empresa" para o âmbito do funcionário — devolve false
// (permissivo) sempre que a regra não estiver activa ou não for possível
// resolvê-la, para nunca bloquear marcações por falha na resolução de regras.
func (s *Service) exigeMarcacaoDentroDaEmpresa(ctx context.Context, tenantID, funcionarioID int64) bool {
	cargoID, unitID, err := s.carregarAmbitoFuncionario(ctx, tenantID, funcionarioID)
	if err != nil {
		return false
	}
	valor, err := s.ResolverRegra(ctx, tenantID, "marcacao_somente_empresa", EscopoFuncionario(funcionarioID, cargoID, unitID))
	if err != nil {
		return false
	}
	ativo, _ := valor["ativo"].(bool)
	return ativo
}

func (s *Service) buscarEventoPorHash(ctx context.Context, tenantID int64, hash string) (*models.EventoAssiduidade, error) {
	var ev models.EventoAssiduidade
	err := s.db.QueryRow(ctx, `
		SELECT id, tenant_id, funcionario_id, tipo_evento_id, metodo_id,
			ocorrido_em, data_referencia, origem, dispositivo_id, qr_token_id, nfc_tag_id,
			latitude, longitude, localidade_id, dentro_geofence,
			foto_url, documento_url, estado, registado_por, motivo, observacoes,
			evento_pai_id, duplicado_de_id, ip_origem, user_agent, hash_digital,
			created_at, updated_at
		  FROM rh.eventos_assiduidade
		 WHERE tenant_id = $1 AND hash_digital = $2`,
		tenantID, hash,
	).Scan(
		&ev.ID, &ev.TenantID, &ev.FuncionarioID, &ev.TipoEventoID, &ev.MetodoID,
		&ev.OcorridoEm, &ev.DataReferencia, &ev.Origem, &ev.DispositivoID, &ev.QRTokenID, &ev.NFCTagID,
		&ev.Latitude, &ev.Longitude, &ev.LocalidadeID, &ev.DentroGeofence,
		&ev.FotoURL, &ev.DocumentoURL, &ev.Estado, &ev.RegistadoPor, &ev.Motivo, &ev.Observacoes,
		&ev.EventoPaiID, &ev.DuplicadoDeID, &ev.IPOrigem, &ev.UserAgent, &ev.HashDigital,
		&ev.CreatedAt, &ev.UpdatedAt,
	)
	if err != nil {
		return nil, nil //nolint:nilerr // "não encontrado" não é um erro aqui
	}
	return &ev, nil
}

func hashEventoAssiduidade(tenantID, funcionarioID, tipoEventoID int64, origem string, dispositivoID *int64, ocorridoEm time.Time) string {
	dev := int64(0)
	if dispositivoID != nil {
		dev = *dispositivoID
	}
	s := fmt.Sprintf("%d|%d|%d|%s|%d|%s", tenantID, funcionarioID, tipoEventoID, origem, dev, ocorridoEm.Format(time.RFC3339))
	return fmt.Sprintf("%x", sha256.Sum256([]byte(s)))
}
