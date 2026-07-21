package assiduidade

import (
	"context"
	"time"

	"nexora/internal/modules/recursos-humanos/models"
)

// eventoCalculo é a projecção de rh.eventos_assiduidade+rh.tipos_evento
// necessária para o motor de cálculo.
type eventoCalculo struct {
	Codigo       string
	Sentido      *string
	TipoPar      *string
	AfetaCalculo string
	OcorridoEm   time.Time
}

type horarioDia struct {
	HoraEntrada               *time.Duration
	HoraSaida                 *time.Duration
	IntervaloInicio           *time.Duration
	IntervaloFim              *time.Duration
	ToleranciaAtraso          time.Duration
	ToleranciaSaidaAntecipada time.Duration
	EhNocturno                bool
}

// RecalcularDia (re)calcula o resultado diário de um funcionário a partir dos
// eventos de rh.eventos_assiduidade da data indicada, aplicando as regras
// configuráveis resolvidas para o seu âmbito (cargo/departamento/empresa), e
// grava o resultado em rh.resultados_diarios. É idempotente: pode ser chamado
// tantas vezes quantas necessário (ex.: depois de uma correcção aprovada ou
// de uma mudança de regra) sem duplicar eventos nem resultados.
func (s *Service) RecalcularDia(ctx context.Context, tenantID, funcionarioID int64, data time.Time) (*models.ResultadoDiario, error) {
	cargoID, unitID, err := s.carregarAmbitoFuncionario(ctx, tenantID, funcionarioID)
	if err != nil {
		return nil, err
	}
	niveis := EscopoFuncionario(funcionarioID, cargoID, unitID)

	horarioID, cargaMinima, cargaMaxima, err := s.carregarHorarioVigente(ctx, tenantID, funcionarioID, data)
	if err != nil {
		return nil, err
	}

	var dia *horarioDia
	if horarioID != nil {
		dia, err = s.carregarHorarioDia(ctx, *horarioID, data)
		if err != nil {
			return nil, err
		}
	}

	eventos, err := s.carregarEventosDoDia(ctx, tenantID, funcionarioID, data)
	if err != nil {
		return nil, err
	}

	buckets := agruparPorTipoPar(eventos)

	resultado := &models.ResultadoDiario{
		TenantID:      tenantID,
		FuncionarioID: funcionarioID,
		DataReferencia: data,
		HorarioID:     horarioID,
	}

	trabalhado := buckets["trabalho"]
	remoto := buckets["remoto"]
	missao := buckets["missao"]
	intervalo := buckets["intervalo"]
	naoContabilizado := buckets["nenhum"]
	extraExplicito := buckets["extra"]

	// horas_trabalhadas é o vão entrada→saída menos as pausas nele contidas
	// (intervalo, saída temporária) — remoto/missão continuam dentro do vão
	// de trabalho (só são etiquetados como subcategoria, não descontados).
	horasTrabalhadas := trabalhado.total - intervalo.total - naoContabilizado.total
	if horasTrabalhadas < 0 {
		horasTrabalhadas = 0
	}
	setDuration(&resultado.HorasTrabalhadas, horasTrabalhadas)
	setDuration(&resultado.HorasNaoContabilizadas, naoContabilizado.total)
	setDuration(&resultado.HorasRemoto, remoto.total)
	setDuration(&resultado.HorasMissao, missao.total)
	setDuration(&resultado.HorasIntervalo, intervalo.total)

	// Ausências/justificações são eventos "únicos" (sem par) — sinalizam o
	// resultado directamente, sem contribuir para as durações calculadas.
	for _, ev := range eventos {
		if ev.AfetaCalculo == "ausencia" {
			resultado.Ausencia = true
			switch ev.Codigo {
			case "falta_justificada":
				resultado.FaltaJustificada = true
			case "falta_injustificada":
				resultado.FaltaInjustificada = true
			}
		}
	}

	if dia != nil {
		if valor, err := s.ResolverRegra(ctx, tenantID, "tolerancia_atraso", niveis); err == nil {
			if trabalhado.primeiraInicio != nil && dia.HoraEntrada != nil {
				esperado := *dia.HoraEntrada
				real := tempoDoDia(*trabalhado.primeiraInicio, data)
				tolerancia := time.Duration(intFromMap(valor, "minutos", 0)) * time.Minute
				if real-esperado > tolerancia {
					// Minutos de atraso reportados são o desvio total face ao
					// horário esperado (não descontando a tolerância), que
					// serve apenas de limiar para decidir se houve atraso.
					resultado.AtrasoMinutos = int32((real - esperado).Minutes())
				}
			}
		}
		if valor, err := s.ResolverRegra(ctx, tenantID, "tolerancia_saida_antecipada", niveis); err == nil {
			if trabalhado.ultimoFim != nil && dia.HoraSaida != nil {
				esperado := *dia.HoraSaida
				real := tempoDoDia(*trabalhado.ultimoFim, data)
				tolerancia := time.Duration(intFromMap(valor, "minutos", 0)) * time.Minute
				if real < esperado-tolerancia {
					resultado.SaidaAntecipadaMinutos = int32((esperado - real).Minutes())
				}
			}
		}
	}

	// Horas nocturnas: sobreposição dos intervalos de trabalho com a janela
	// nocturna configurada (regra trabalho_nocturno), reportadas como
	// subconjunto informativo de HorasTrabalhadas (não subtraídas).
	if valor, err := s.ResolverRegra(ctx, tenantID, "trabalho_nocturno", niveis); err == nil {
		inicioNoite, okI := stringFromMap(valor, "inicio_noite")
		fimNoite, okF := stringFromMap(valor, "fim_noite")
		if okI && okF {
			nocturnas := calcularHorasNocturnas(trabalhado.intervalos, inicioNoite, fimNoite)
			setDuration(&resultado.HorasNocturnas, nocturnas)
		}
	}

	// Horas normais/extra: o que exceder a carga diária esperada (regra ou
	// horário) é extra, com o tecto da regra max_horas_extra; blocos
	// explicitamente marcados como extra_inicio/extra_fim somam-se ao total.
	cargaEsperada := cargaMaxima
	if cargaEsperada == nil {
		cargaEsperada = cargaMinima
	}
	horasNormais := horasTrabalhadas
	horasExtraCalculada := extraExplicito.total
	if cargaEsperada != nil && horasTrabalhadas > *cargaEsperada {
		horasNormais = *cargaEsperada
		horasExtraCalculada += horasTrabalhadas - *cargaEsperada
	}
	if valor, err := s.ResolverRegra(ctx, tenantID, "max_horas_extra", niveis); err == nil {
		if maxHoras, ok := floatFromMap(valor, "horas"); ok {
			teto := time.Duration(maxHoras * float64(time.Hour))
			if horasExtraCalculada > teto {
				horasExtraCalculada = teto
			}
		}
	}
	setDuration(&resultado.HorasNormais, horasNormais)
	setDuration(&resultado.HorasExtra, horasExtraCalculada)

	// Ausência por falta de qualquer marcação num dia útil esperado (regra
	// ausencia_apos_periodo) — só se aplica quando há horário configurado
	// para esse dia da semana e nenhum evento foi recebido.
	if dia != nil && len(eventos) == 0 && !resultado.Ausencia {
		resultado.FaltaInjustificada = true
		resultado.Ausencia = true
	}

	if err := s.gravarResultadoDiario(ctx, resultado); err != nil {
		return nil, err
	}
	return resultado, nil
}

func (s *Service) carregarAmbitoFuncionario(ctx context.Context, tenantID, funcionarioID int64) (cargoID, unitID *int64, err error) {
	err = s.db.QueryRow(ctx, `
		SELECT cargo_id, unit_id FROM rh.funcionarios WHERE id = $1 AND tenant_id = $2`,
		funcionarioID, tenantID,
	).Scan(&cargoID, &unitID)
	return cargoID, unitID, err
}

func (s *Service) carregarHorarioVigente(ctx context.Context, tenantID, funcionarioID int64, data time.Time) (horarioID *int64, cargaMinima, cargaMaxima *time.Duration, err error) {
	err = s.db.QueryRow(ctx, `
		SELECT h.id, h.carga_diaria_minima, h.carga_diaria_maxima
		  FROM rh.funcionario_horarios fh
		  JOIN rh.horarios_trabalho h ON h.id = fh.horario_id
		 WHERE fh.tenant_id = $1 AND fh.funcionario_id = $2
		   AND fh.data_inicio <= $3::date
		   AND (fh.data_fim IS NULL OR fh.data_fim >= $3::date)
		   AND h.ativo = TRUE
		 ORDER BY fh.data_inicio DESC
		 LIMIT 1`,
		tenantID, funcionarioID, data,
	).Scan(&horarioID, &cargaMinima, &cargaMaxima)
	if err != nil {
		// Sem horário vigente associado: funcionário "sem horário fixo",
		// caso previsto no requisito — não é um erro.
		return nil, nil, nil, nil
	}
	return horarioID, cargaMinima, cargaMaxima, nil
}

func (s *Service) carregarHorarioDia(ctx context.Context, horarioID int64, data time.Time) (*horarioDia, error) {
	isoWeekday := int(data.Weekday())
	if isoWeekday == 0 {
		isoWeekday = 7
	}

	var d horarioDia
	err := s.db.QueryRow(ctx, `
		SELECT hora_entrada, hora_saida, intervalo_inicio, intervalo_fim,
		       tolerancia_atraso, tolerancia_saida_antecipada, eh_nocturno
		  FROM rh.horarios_dias
		 WHERE horario_id = $1 AND (data_especifica = $2::date OR dia_semana = $3)
		 ORDER BY data_especifica DESC NULLS LAST, ordem
		 LIMIT 1`,
		horarioID, data, isoWeekday,
	).Scan(&d.HoraEntrada, &d.HoraSaida, &d.IntervaloInicio, &d.IntervaloFim,
		&d.ToleranciaAtraso, &d.ToleranciaSaidaAntecipada, &d.EhNocturno)
	if err != nil {
		// Sem configuração para este dia da semana (ex.: fim-de-semana fora
		// do horário) — não é um erro, apenas não há expectativa de trabalho.
		return nil, nil
	}
	return &d, nil
}

func (s *Service) carregarEventosDoDia(ctx context.Context, tenantID, funcionarioID int64, data time.Time) ([]eventoCalculo, error) {
	rows, err := s.db.Query(ctx, `
		SELECT te.codigo, te.sentido, te.tipo_par, te.afeta_calculo, e.ocorrido_em
		  FROM rh.eventos_assiduidade e
		  JOIN rh.tipos_evento te ON te.id = e.tipo_evento_id
		 WHERE e.tenant_id = $1 AND e.funcionario_id = $2 AND e.data_referencia = $3::date
		   AND e.estado IN ('valido', 'aprovado', 'corrigido')
		 ORDER BY e.ocorrido_em`,
		tenantID, funcionarioID, data,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var eventos []eventoCalculo
	for rows.Next() {
		var ev eventoCalculo
		if err := rows.Scan(&ev.Codigo, &ev.Sentido, &ev.TipoPar, &ev.AfetaCalculo, &ev.OcorridoEm); err != nil {
			return nil, err
		}
		eventos = append(eventos, ev)
	}
	return eventos, rows.Err()
}

func (s *Service) gravarResultadoDiario(ctx context.Context, r *models.ResultadoDiario) error {
	return s.db.QueryRow(ctx, `
		INSERT INTO rh.resultados_diarios (
			tenant_id, funcionario_id, data_referencia, horario_id,
			horas_trabalhadas, horas_normais, horas_extra, horas_nocturnas,
			horas_remoto, horas_missao, horas_formacao, horas_intervalo, horas_nao_contabilizadas,
			atraso_minutos, saida_antecipada_minutos,
			ausencia, falta_justificada, falta_injustificada,
			versao_regra, recalculado_em
		) VALUES (
			$1, $2, $3::date, $4,
			$5, $6, $7, $8,
			$9, $10, $11, $12, $13,
			$14, $15,
			$16, $17, $18,
			1, NOW()
		)
		ON CONFLICT (tenant_id, funcionario_id, data_referencia)
		DO UPDATE SET
			horario_id = EXCLUDED.horario_id,
			horas_trabalhadas = EXCLUDED.horas_trabalhadas,
			horas_normais = EXCLUDED.horas_normais,
			horas_extra = EXCLUDED.horas_extra,
			horas_nocturnas = EXCLUDED.horas_nocturnas,
			horas_remoto = EXCLUDED.horas_remoto,
			horas_missao = EXCLUDED.horas_missao,
			horas_formacao = EXCLUDED.horas_formacao,
			horas_intervalo = EXCLUDED.horas_intervalo,
			horas_nao_contabilizadas = EXCLUDED.horas_nao_contabilizadas,
			atraso_minutos = EXCLUDED.atraso_minutos,
			saida_antecipada_minutos = EXCLUDED.saida_antecipada_minutos,
			ausencia = EXCLUDED.ausencia,
			falta_justificada = EXCLUDED.falta_justificada,
			falta_injustificada = EXCLUDED.falta_injustificada,
			versao_regra = rh.resultados_diarios.versao_regra + 1,
			recalculado_em = NOW(),
			updated_at = NOW()
		RETURNING id, versao_regra, created_at, updated_at`,
		r.TenantID, r.FuncionarioID, r.DataReferencia, r.HorarioID,
		r.HorasTrabalhadas, r.HorasNormais, r.HorasExtra, r.HorasNocturnas,
		r.HorasRemoto, r.HorasMissao, r.HorasFormacao, r.HorasIntervalo, r.HorasNaoContabilizadas,
		r.AtrasoMinutos, r.SaidaAntecipadaMinutos,
		r.Ausencia, r.FaltaJustificada, r.FaltaInjustificada,
	).Scan(&r.ID, &r.VersaoRegra, &r.CreatedAt, &r.UpdatedAt)
}

func setDuration(dst **time.Duration, d time.Duration) {
	if d == 0 {
		return
	}
	v := d
	*dst = &v
}

// tempoDoDia devolve o tempo decorrido desde a meia-noite de `referencia` até
// `instante`, no mesmo fuso horário de `instante` — usado para comparar
// eventos com as horas de rh.horarios_dias (armazenadas como INTERVAL
// "tempo desde a meia-noite").
func tempoDoDia(instante time.Time, referencia time.Time) time.Duration {
	meiaNoite := time.Date(referencia.Year(), referencia.Month(), referencia.Day(), 0, 0, 0, 0, instante.Location())
	return instante.Sub(meiaNoite)
}

func intFromMap(m map[string]any, chave string, def int) int {
	if v, ok := m[chave]; ok {
		switch n := v.(type) {
		case float64:
			return int(n)
		case int:
			return n
		}
	}
	return def
}

func floatFromMap(m map[string]any, chave string) (float64, bool) {
	if v, ok := m[chave]; ok {
		if n, ok := v.(float64); ok {
			return n, true
		}
	}
	return 0, false
}

func stringFromMap(m map[string]any, chave string) (string, bool) {
	if v, ok := m[chave]; ok {
		if s, ok := v.(string); ok {
			return s, true
		}
	}
	return "", false
}
