package assiduidade

import (
	"testing"
	"time"
)

func at(hora string) time.Time {
	base := time.Date(2026, 7, 20, 0, 0, 0, 0, time.UTC)
	t, err := time.Parse("15:04", hora)
	if err != nil {
		panic(err)
	}
	return base.Add(time.Duration(t.Hour())*time.Hour + time.Duration(t.Minute())*time.Minute)
}

func atDia(dia int, hora string) time.Time {
	t := at(hora)
	return t.AddDate(0, 0, dia)
}

func sentido(s string) *string { return &s }
func tipoPar(s string) *string { return &s }

// Cenário 1 (flexível): entrada→intervalo→intervalo_fim→saída. O intervalo é
// descontado das horas trabalhadas.
func TestAgruparPorTipoPar_Flexivel(t *testing.T) {
	eventos := []eventoCalculo{
		{Codigo: "entrada", Sentido: sentido("inicio"), TipoPar: tipoPar("saida"), AfetaCalculo: "trabalho", OcorridoEm: at("07:55")},
		{Codigo: "intervalo_inicio", Sentido: sentido("inicio"), TipoPar: tipoPar("intervalo_fim"), AfetaCalculo: "intervalo", OcorridoEm: at("12:10")},
		{Codigo: "intervalo_fim", Sentido: sentido("fim"), TipoPar: tipoPar("intervalo_inicio"), AfetaCalculo: "intervalo", OcorridoEm: at("13:05")},
		{Codigo: "saida", Sentido: sentido("fim"), TipoPar: tipoPar("entrada"), AfetaCalculo: "trabalho", OcorridoEm: at("17:20")},
	}

	buckets := agruparPorTipoPar(eventos)

	wantTrabalho := at("17:20").Sub(at("07:55"))
	if buckets["trabalho"].total != wantTrabalho {
		t.Fatalf("trabalho = %v, want %v", buckets["trabalho"].total, wantTrabalho)
	}
	wantIntervalo := at("13:05").Sub(at("12:10"))
	if buckets["intervalo"].total != wantIntervalo {
		t.Fatalf("intervalo = %v, want %v", buckets["intervalo"].total, wantIntervalo)
	}

	horasTrabalhadas := buckets["trabalho"].total - buckets["intervalo"].total
	wantLiquido := 8*time.Hour + 30*time.Minute
	if horasTrabalhadas != wantLiquido {
		t.Fatalf("horas trabalhadas líquidas = %v, want %v", horasTrabalhadas, wantLiquido)
	}
}

// Cenário 3: múltiplos turnos no mesmo dia (dois pares entrada/saída
// distintos) somam-se no mesmo bucket "trabalho".
func TestAgruparPorTipoPar_MultiplosTurnos(t *testing.T) {
	eventos := []eventoCalculo{
		{Codigo: "entrada", Sentido: sentido("inicio"), TipoPar: tipoPar("saida"), AfetaCalculo: "trabalho", OcorridoEm: at("08:00")},
		{Codigo: "saida", Sentido: sentido("fim"), TipoPar: tipoPar("entrada"), AfetaCalculo: "trabalho", OcorridoEm: at("12:00")},
		{Codigo: "entrada", Sentido: sentido("inicio"), TipoPar: tipoPar("saida"), AfetaCalculo: "trabalho", OcorridoEm: at("14:00")},
		{Codigo: "saida", Sentido: sentido("fim"), TipoPar: tipoPar("entrada"), AfetaCalculo: "trabalho", OcorridoEm: at("18:00")},
	}

	buckets := agruparPorTipoPar(eventos)

	want := 8 * time.Hour
	if buckets["trabalho"].total != want {
		t.Fatalf("trabalho = %v, want %v (dois turnos de 4h)", buckets["trabalho"].total, want)
	}
	if len(buckets["trabalho"].intervalos) != 2 {
		t.Fatalf("esperados 2 intervalos de trabalho, obtidos %d", len(buckets["trabalho"].intervalos))
	}
}

// Cenário 4: saída temporária e regresso. saida_temporaria tem
// afeta_calculo="nenhum" (não é trabalho); o tempo fora não deve entrar no
// bucket "trabalho".
func TestAgruparPorTipoPar_SaidaTemporaria(t *testing.T) {
	eventos := []eventoCalculo{
		{Codigo: "entrada", Sentido: sentido("inicio"), TipoPar: tipoPar("saida"), AfetaCalculo: "trabalho", OcorridoEm: at("08:00")},
		{Codigo: "saida_temporaria", Sentido: sentido("inicio"), TipoPar: tipoPar("regresso_temporaria"), AfetaCalculo: "nenhum", OcorridoEm: at("10:00")},
		{Codigo: "regresso_temporaria", Sentido: sentido("fim"), TipoPar: tipoPar("saida_temporaria"), AfetaCalculo: "trabalho", OcorridoEm: at("10:45")},
		{Codigo: "saida", Sentido: sentido("fim"), TipoPar: tipoPar("entrada"), AfetaCalculo: "trabalho", OcorridoEm: at("12:30")},
	}

	buckets := agruparPorTipoPar(eventos)

	wantNenhum := 45 * time.Minute
	if buckets["nenhum"].total != wantNenhum {
		t.Fatalf("nenhum (não contabilizado) = %v, want %v", buckets["nenhum"].total, wantNenhum)
	}

	rawSpan := at("12:30").Sub(at("08:00"))
	horasTrabalhadas := buckets["trabalho"].total - buckets["nenhum"].total
	if buckets["trabalho"].total != rawSpan {
		t.Fatalf("trabalho bruto = %v, want %v", buckets["trabalho"].total, rawSpan)
	}
	wantLiquido := 3*time.Hour + 45*time.Minute
	if horasTrabalhadas != wantLiquido {
		t.Fatalf("horas trabalhadas líquidas = %v, want %v", horasTrabalhadas, wantLiquido)
	}
}

// Cenário 5: remoto e presencial no mesmo dia — remoto fica dentro do vão
// entrada→saída (não é descontado), mas é reportado num bucket próprio.
func TestAgruparPorTipoPar_RemotoEPresencial(t *testing.T) {
	eventos := []eventoCalculo{
		{Codigo: "entrada", Sentido: sentido("inicio"), TipoPar: tipoPar("saida"), AfetaCalculo: "trabalho", OcorridoEm: at("08:00")},
		{Codigo: "remoto_inicio", Sentido: sentido("inicio"), TipoPar: tipoPar("remoto_fim"), AfetaCalculo: "remoto", OcorridoEm: at("10:00")},
		{Codigo: "remoto_fim", Sentido: sentido("fim"), TipoPar: tipoPar("remoto_inicio"), AfetaCalculo: "remoto", OcorridoEm: at("12:00")},
		{Codigo: "saida", Sentido: sentido("fim"), TipoPar: tipoPar("entrada"), AfetaCalculo: "trabalho", OcorridoEm: at("17:00")},
	}

	buckets := agruparPorTipoPar(eventos)

	wantTrabalho := 9 * time.Hour
	if buckets["trabalho"].total != wantTrabalho {
		t.Fatalf("trabalho = %v, want %v", buckets["trabalho"].total, wantTrabalho)
	}
	wantRemoto := 2 * time.Hour
	if buckets["remoto"].total != wantRemoto {
		t.Fatalf("remoto = %v, want %v", buckets["remoto"].total, wantRemoto)
	}
}

// Cenário 6: entrada esquecida — um evento "fim" sem "inicio" aberto
// correspondente é ignorado (não gera duração negativa nem pânico), ficando
// disponível apenas como registo bruto para análise/correcção.
func TestAgruparPorTipoPar_EntradaEsquecida(t *testing.T) {
	eventos := []eventoCalculo{
		{Codigo: "intervalo_inicio", Sentido: sentido("inicio"), TipoPar: tipoPar("intervalo_fim"), AfetaCalculo: "intervalo", OcorridoEm: at("12:00")},
		{Codigo: "intervalo_fim", Sentido: sentido("fim"), TipoPar: tipoPar("intervalo_inicio"), AfetaCalculo: "intervalo", OcorridoEm: at("13:00")},
		{Codigo: "saida", Sentido: sentido("fim"), TipoPar: tipoPar("entrada"), AfetaCalculo: "trabalho", OcorridoEm: at("17:00")},
	}

	buckets := agruparPorTipoPar(eventos)

	if buckets["trabalho"].total != 0 {
		t.Fatalf("trabalho = %v, want 0 (saída sem entrada correspondente deve ser ignorada)", buckets["trabalho"].total)
	}
	wantIntervalo := time.Hour
	if buckets["intervalo"].total != wantIntervalo {
		t.Fatalf("intervalo = %v, want %v", buckets["intervalo"].total, wantIntervalo)
	}
}

// Cenário 2: turno nocturno que atravessa a meia-noite — as horas nocturnas
// são a sobreposição do intervalo de trabalho com a janela 22:00-06:00.
func TestCalcularHorasNocturnas_AtravessaMeiaNoite(t *testing.T) {
	intervalos := []intervalo{
		{Inicio: atDia(0, "22:00"), Fim: atDia(1, "06:00")},
	}

	nocturnas := calcularHorasNocturnas(intervalos, "22:00", "06:00")

	want := 8 * time.Hour
	if nocturnas != want {
		t.Fatalf("horas nocturnas = %v, want %v (turno inteiro dentro da janela nocturna)", nocturnas, want)
	}
}

func TestCalcularHorasNocturnas_ParcialmenteDentroDaJanela(t *testing.T) {
	// Turno das 18:00 às 23:00: só a partir das 22:00 é nocturno (1h).
	intervalos := []intervalo{
		{Inicio: atDia(0, "18:00"), Fim: atDia(0, "23:00")},
	}

	nocturnas := calcularHorasNocturnas(intervalos, "22:00", "06:00")

	want := time.Hour
	if nocturnas != want {
		t.Fatalf("horas nocturnas = %v, want %v", nocturnas, want)
	}
}

func TestCalcularHorasNocturnas_ForaDaJanela(t *testing.T) {
	intervalos := []intervalo{
		{Inicio: atDia(0, "08:00"), Fim: atDia(0, "17:00")},
	}

	nocturnas := calcularHorasNocturnas(intervalos, "22:00", "06:00")

	if nocturnas != 0 {
		t.Fatalf("horas nocturnas = %v, want 0", nocturnas)
	}
}
