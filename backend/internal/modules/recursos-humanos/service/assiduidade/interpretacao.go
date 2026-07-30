package assiduidade

import "time"

// Papéis atribuídos a uma marcação depois de lida no contexto do dia.
const (
	PapelEntrada           = "entrada"
	PapelSaidaIntervalo    = "saida_intervalo"
	PapelRegressoIntervalo = "regresso_intervalo"
	PapelSaidaFinal        = "saida_final"
	// PapelAdicional é a marcação que confirma uma transição já representada
	// por outra do mesmo grupo. Continua gravada e visível na auditoria; só
	// não entra no cálculo.
	PapelAdicional = "adicional"
)

// MarcacaoInterpretada é a leitura de um evento bruto no contexto do dia.
type MarcacaoInterpretada struct {
	EventoID     int64
	OcorridoEm   time.Time
	MetodoCodigo *string
	Papel        string
	Utilizado    bool
	Grupo        int
}

// marcacaoBruta é a projecção de rh.eventos_assiduidade que o motor de
// interpretação precisa — só as marcações de presença (entrada/saída), não os
// eventos de tipo explícito (intervalo, missão, férias...).
type marcacaoBruta struct {
	ID           int64
	OcorridoEm   time.Time
	MetodoCodigo *string
}

// InterpretarMarcacoes lê uma sequência cronológica de marcações de presença e
// devolve o papel de cada uma no dia.
//
// O problema que resolve: uma marcação isolada não diz se é entrada ou saída.
// Decidir isso na gravação — por paridade, "a 1ª é entrada, a 2ª é saída" —
// parte do princípio de que ninguém marca duas vezes seguidas, e basta uma
// confirmação repetida no leitor para desalinhar o resto do dia inteiro. Aqui
// o papel é atribuído com a sequência toda à vista, o que torna a repetição
// inofensiva.
//
// Duas passagens:
//
//  1. Agrupar: marcações separadas por menos de `tolerancia` descrevem a mesma
//     transição (carregar duas vezes, confirmar a cara e passar o cartão, o
//     leitor da portaria e o do piso).
//
//  2. Atribuir papéis por posição do grupo: o 1º grupo é a entrada, os grupos
//     pares seguintes são regressos, os ímpares são saídas, e o último grupo,
//     se for uma saída, é a saída final.
//
// A marcação representativa de cada grupo é a PRIMEIRA, excepto na saída final,
// onde conta a ÚLTIMA: a primeira marca é o instante em que a pessoa se
// apresentou ao leitor, mas depois da saída final não há mais presença
// registada — quem se despede às 17:29 e volta a marcar às 17:31 saiu de facto
// às 17:31.
//
// Um dia com um número ímpar de grupos acaba numa entrada sem saída (ex.:
// esqueceu-se de marcar à saída). Esse último grupo fica como
// entrada/regresso, sem par: o cálculo ignora-o e a auditoria mostra-o —
// inventar uma saída seria fabricar horas que ninguém registou.
func InterpretarMarcacoes(marcacoes []marcacaoBruta, tolerancia time.Duration) []MarcacaoInterpretada {
	if len(marcacoes) == 0 {
		return nil
	}

	grupos := agruparMarcacoes(marcacoes, tolerancia)
	ultimoGrupo := len(grupos) - 1

	var out []MarcacaoInterpretada
	for i, grupo := range grupos {
		papel := papelDoGrupo(i, i == ultimoGrupo)

		// Índice da marcação que representa o grupo.
		representante := 0
		if papel == PapelSaidaFinal {
			representante = len(grupo) - 1
		}

		for j, m := range grupo {
			marcacao := MarcacaoInterpretada{
				EventoID:     m.ID,
				OcorridoEm:   m.OcorridoEm,
				MetodoCodigo: m.MetodoCodigo,
				Papel:        PapelAdicional,
				Grupo:        i,
			}
			if j == representante {
				marcacao.Papel = papel
				marcacao.Utilizado = true
			}
			out = append(out, marcacao)
		}
	}
	return out
}

// agruparMarcacoes junta marcações consecutivas separadas por menos do que a
// tolerância. A comparação é com a marcação anterior, não com a primeira do
// grupo: uma sequência de confirmações a cada 2 minutos é a mesma transição,
// mesmo que a última já esteja a 10 minutos da primeira.
func agruparMarcacoes(marcacoes []marcacaoBruta, tolerancia time.Duration) [][]marcacaoBruta {
	grupos := [][]marcacaoBruta{{marcacoes[0]}}
	for i := 1; i < len(marcacoes); i++ {
		anterior := marcacoes[i-1]
		atual := marcacoes[i]
		if atual.OcorridoEm.Sub(anterior.OcorridoEm) <= tolerancia {
			ultimo := len(grupos) - 1
			grupos[ultimo] = append(grupos[ultimo], atual)
			continue
		}
		grupos = append(grupos, []marcacaoBruta{atual})
	}
	return grupos
}

// papelDoGrupo traduz a posição do grupo no dia para o seu papel: grupos pares
// são presenças (entrada, regressos), ímpares são ausências (saída para
// intervalo, saída final).
func papelDoGrupo(indice int, ultimo bool) string {
	if indice%2 == 0 {
		if indice == 0 {
			return PapelEntrada
		}
		return PapelRegressoIntervalo
	}
	if ultimo {
		return PapelSaidaFinal
	}
	return PapelSaidaIntervalo
}

// eventosCalculoDeMarcacoes converte as marcações utilizadas em eventos
// entrada/saída para o motor de cálculo, que continua a emparelhá-los em
// agruparPorTipoPar. O que muda face ao modelo anterior não é o cálculo: é
// quais os eventos que lá chegam e com que sentido.
//
// O par entrada→saída_intervalo e regresso→saída_final entram como pares de
// trabalho; o vão entre a saída para intervalo e o regresso é o intervalo, e
// é devolvido à parte por não ser um par de eventos mas o espaço entre dois
// pares.
func eventosCalculoDeMarcacoes(marcacoes []MarcacaoInterpretada) (eventos []eventoCalculo, intervalo time.Duration) {
	sentidoInicio, sentidoFim := "inicio", "fim"
	parSaida, parEntrada := "saida", "entrada"

	var inicioIntervalo *time.Time
	for _, m := range marcacoes {
		if !m.Utilizado {
			continue
		}
		switch m.Papel {
		case PapelEntrada, PapelRegressoIntervalo:
			eventos = append(eventos, eventoCalculo{
				Codigo: "entrada", Sentido: &sentidoInicio, TipoPar: &parSaida,
				AfetaCalculo: "trabalho", OcorridoEm: m.OcorridoEm,
			})
			if m.Papel == PapelRegressoIntervalo && inicioIntervalo != nil {
				intervalo += m.OcorridoEm.Sub(*inicioIntervalo)
				inicioIntervalo = nil
			}
		case PapelSaidaIntervalo, PapelSaidaFinal:
			eventos = append(eventos, eventoCalculo{
				Codigo: "saida", Sentido: &sentidoFim, TipoPar: &parEntrada,
				AfetaCalculo: "trabalho", OcorridoEm: m.OcorridoEm,
			})
			if m.Papel == PapelSaidaIntervalo {
				instante := m.OcorridoEm
				inicioIntervalo = &instante
			}
		}
	}
	return eventos, intervalo
}
