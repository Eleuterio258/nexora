package assiduidade

import "time"

// bucket acumula a duração total e os intervalos concretos de um grupo de
// eventos emparelhados que partilham o mesmo afeta_calculo (ex.: todos os
// pares entrada/saída contribuem para o bucket "trabalho").
type bucket struct {
	total          time.Duration
	primeiraInicio *time.Time
	ultimoFim      *time.Time
	intervalos     []intervalo
}

type intervalo struct {
	Inicio time.Time
	Fim    time.Time
}

// agruparPorTipoPar empareilha eventos "inicio"/"fim" do mesmo tipo_par em
// ordem cronológica (ex.: entrada→saída, intervalo_inicio→intervalo_fim,
// remoto_inicio→remoto_fim) e acumula a duração de cada par no bucket do seu
// afeta_calculo. Eventos "unico" (férias, formação, faltas, ...) não são
// emparelhados aqui — são tratados directamente pelo chamador a partir da
// lista de eventos. Um "fim" sem "inicio" aberto correspondente é ignorado
// para efeitos de cálculo (o evento em si permanece gravado para análise,
// conforme o requisito de não bloquear por registos em falta).
func agruparPorTipoPar(eventos []eventoCalculo) map[string]bucket {
	abertos := map[string]eventoCalculo{}
	buckets := map[string]bucket{}

	for _, ev := range eventos {
		if ev.Sentido == nil {
			continue
		}
		family := familyKey(ev)
		switch *ev.Sentido {
		case "inicio":
			abertos[family] = ev
		case "fim":
			inicio, ok := abertos[family]
			if !ok {
				continue
			}
			delete(abertos, family)

			dur := ev.OcorridoEm.Sub(inicio.OcorridoEm)
			if dur <= 0 {
				continue
			}

			b := buckets[inicio.AfetaCalculo]
			b.total += dur
			ii, ff := inicio.OcorridoEm, ev.OcorridoEm
			if b.primeiraInicio == nil || ii.Before(*b.primeiraInicio) {
				b.primeiraInicio = &ii
			}
			if b.ultimoFim == nil || ff.After(*b.ultimoFim) {
				b.ultimoFim = &ff
			}
			b.intervalos = append(b.intervalos, intervalo{Inicio: ii, Fim: ff})
			buckets[inicio.AfetaCalculo] = b
		}
	}
	return buckets
}

// familyKey identifica um par entrada/saída independentemente de qual dos
// dois códigos aparece primeiro (tipo_par é simétrico: entrada.tipo_par =
// "saida", saida.tipo_par = "entrada").
func familyKey(ev eventoCalculo) string {
	if ev.TipoPar == nil {
		return ev.Codigo
	}
	if ev.Codigo < *ev.TipoPar {
		return ev.Codigo + "|" + *ev.TipoPar
	}
	return *ev.TipoPar + "|" + ev.Codigo
}

// calcularHorasNocturnas soma a sobreposição de cada intervalo de trabalho
// com a janela nocturna configurada (regra trabalho_nocturno), suportando
// janelas que atravessam a meia-noite (ex.: 22:00-06:00).
func calcularHorasNocturnas(intervalos []intervalo, inicioNoiteStr, fimNoiteStr string) time.Duration {
	inicioNoite, err1 := parseHHMM(inicioNoiteStr)
	fimNoite, err2 := parseHHMM(fimNoiteStr)
	if err1 != nil || err2 != nil {
		return 0
	}

	var total time.Duration
	for _, iv := range intervalos {
		total += sobreposicaoComJanelaNocturna(iv.Inicio, iv.Fim, inicioNoite, fimNoite)
	}
	return total
}

func sobreposicaoComJanelaNocturna(inicio, fim time.Time, janelaInicio, janelaFim time.Duration) time.Duration {
	var total time.Duration
	cursor := time.Date(inicio.Year(), inicio.Month(), inicio.Day(), 0, 0, 0, 0, inicio.Location())
	for cursor.Before(fim) {
		for _, janela := range janelasNocturnasDoDia(cursor, janelaInicio, janelaFim) {
			total += sobreposicao(inicio, fim, janela.inicio, janela.fim)
		}
		cursor = cursor.AddDate(0, 0, 1)
	}
	return total
}

type janelaTempo struct{ inicio, fim time.Time }

func janelasNocturnasDoDia(dia time.Time, janelaInicio, janelaFim time.Duration) []janelaTempo {
	inicio := dia.Add(janelaInicio)
	if janelaFim > janelaInicio {
		return []janelaTempo{{inicio: inicio, fim: dia.Add(janelaFim)}}
	}
	// Janela atravessa a meia-noite (ex.: 22:00-06:00): parte da noite
	// anterior (até à meia-noite deste dia) + parte da madrugada deste dia.
	return []janelaTempo{
		{inicio: inicio, fim: dia.AddDate(0, 0, 1)},
		{inicio: dia, fim: dia.Add(janelaFim)},
	}
}

func sobreposicao(aInicio, aFim, bInicio, bFim time.Time) time.Duration {
	inicio := aInicio
	if bInicio.After(inicio) {
		inicio = bInicio
	}
	fim := aFim
	if bFim.Before(fim) {
		fim = bFim
	}
	if fim.After(inicio) {
		return fim.Sub(inicio)
	}
	return 0
}

func parseHHMM(s string) (time.Duration, error) {
	t, err := time.Parse("15:04", s)
	if err != nil {
		return 0, err
	}
	return time.Duration(t.Hour())*time.Hour + time.Duration(t.Minute())*time.Minute, nil
}
