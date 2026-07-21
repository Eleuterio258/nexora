package assiduidade

import (
	"context"
	"encoding/json"
)

// NivelEscopo é um nível do âmbito de aplicação de uma regra (ex.: cargo,
// departamento, empresa). EntidadeID nil corresponde ao âmbito "empresa"
// (regra por omissão do tenant).
type NivelEscopo struct {
	Ambito     string
	EntidadeID *int64
}

// EscopoFuncionario constrói a cadeia de âmbitos, do mais específico ao mais
// genérico, resolvível com os dados hoje modelados em rh.funcionarios
// (cargo_id, unit_id). Equipa/turno/contrato ainda não têm associação directa
// ao funcionário no schema actual — ficam de fora até essa modelação existir,
// em vez de simular um âmbito que o sistema não consegue de facto resolver.
func EscopoFuncionario(funcionarioID int64, cargoID, unitID *int64) []NivelEscopo {
	return []NivelEscopo{
		{Ambito: "funcionario", EntidadeID: &funcionarioID},
		{Ambito: "cargo", EntidadeID: cargoID},
		{Ambito: "departamento", EntidadeID: unitID},
		{Ambito: "empresa", EntidadeID: nil},
	}
}

// ResolverRegra devolve o valor efectivo de uma regra configurável para um
// tipo de regra, percorrendo os níveis de âmbito fornecidos (do mais
// específico ao mais genérico) e devolvendo a primeira regra activa e
// vigente encontrada — a chamada regra "mais específica vence". Quando
// nenhum nível tem uma regra explícita, devolve os valores por omissão
// descritos em rh.tipos_regra.parametros.
func (s *Service) ResolverRegra(ctx context.Context, tenantID int64, tipoRegraCodigo string, niveis []NivelEscopo) (map[string]any, error) {
	tipoRegraID, defaults, err := s.carregarTipoRegra(ctx, tipoRegraCodigo)
	if err != nil {
		return nil, err
	}

	for _, nivel := range niveis {
		var valorRaw []byte
		var err error
		if nivel.EntidadeID != nil {
			err = s.db.QueryRow(ctx, `
				SELECT valor FROM rh.regras_assiduidade
				 WHERE tenant_id = $1 AND tipo_regra_id = $2 AND ambito = $3
				   AND entidade_id = $4 AND ativo = TRUE
				   AND data_inicio <= CURRENT_DATE
				   AND (data_fim IS NULL OR data_fim >= CURRENT_DATE)
				 ORDER BY prioridade DESC, data_inicio DESC
				 LIMIT 1`,
				tenantID, tipoRegraID, nivel.Ambito, *nivel.EntidadeID,
			).Scan(&valorRaw)
		} else {
			err = s.db.QueryRow(ctx, `
				SELECT valor FROM rh.regras_assiduidade
				 WHERE tenant_id = $1 AND tipo_regra_id = $2 AND ambito = $3
				   AND entidade_id IS NULL AND ativo = TRUE
				   AND data_inicio <= CURRENT_DATE
				   AND (data_fim IS NULL OR data_fim >= CURRENT_DATE)
				 ORDER BY prioridade DESC, data_inicio DESC
				 LIMIT 1`,
				tenantID, tipoRegraID, nivel.Ambito,
			).Scan(&valorRaw)
		}
		if err == nil {
			var valor map[string]any
			if jsonErr := json.Unmarshal(valorRaw, &valor); jsonErr == nil {
				return mesclarComDefaults(defaults, valor), nil
			}
		}
	}

	return defaults, nil
}

// carregarTipoRegra devolve o id do tipo de regra e os valores por omissão
// extraídos de rh.tipos_regra.parametros (formato
// {"campo": {"default": valor, ...}}).
func (s *Service) carregarTipoRegra(ctx context.Context, codigo string) (int64, map[string]any, error) {
	var id int64
	var parametrosRaw []byte
	err := s.db.QueryRow(ctx, `
		SELECT id, parametros FROM rh.tipos_regra WHERE codigo = $1`,
		codigo,
	).Scan(&id, &parametrosRaw)
	if err != nil {
		return 0, nil, err
	}

	var esquema map[string]map[string]any
	defaults := map[string]any{}
	if json.Unmarshal(parametrosRaw, &esquema) == nil {
		for campo, descricao := range esquema {
			if def, ok := descricao["default"]; ok {
				defaults[campo] = def
			}
		}
	}
	return id, defaults, nil
}

func mesclarComDefaults(defaults, valor map[string]any) map[string]any {
	resultado := make(map[string]any, len(defaults)+len(valor))
	for k, v := range defaults {
		resultado[k] = v
	}
	for k, v := range valor {
		resultado[k] = v
	}
	return resultado
}
