// Comando one-off: migra os dados existentes de rh.presencas (modelo
// "1 entrada + 1 saída por dia") para rh.eventos_assiduidade (modelo de
// eventos independentes), Fase F do sistema flexível de assiduidade.
//
// Cada linha de rh.presencas gera, quando aplicável:
//   - um evento "entrada" (se hora_entrada estiver preenchida);
//   - um evento "saida" (se hora_saida estiver preenchida);
//   - um evento "falta_injustificada" (se tipo='falta').
//
// Idempotente e retomável: reaproveita assiduidade.Service.RegistarEvento,
// que deduplica por hash (tenant+funcionário+tipo+origem+instante) — correr
// este comando mais que uma vez, ou voltar a correr depois de uma falha a
// meio (ex.: ligação perdida), não duplica eventos já gravados. Por isso
// cada linha é gravada com a sua própria escrita autocommit em vez de uma
// única transacção a cobrir as 741 linhas — uma falha de rede a meio só
// perde a linha em curso, não o trabalho já feito.
//
// horas_extra (coluna agregada NUMERIC) não tem instantes de início/fim
// precisos na origem, por isso não gera um par extra_inicio/extra_fim
// fabricado — fica registado apenas no texto de observações do evento de
// entrada, para não perder a informação nem inventar dados que não existem.
//
// Uso:
//
//	DATABASE_URL=postgres://... go run ./cmd/migrate-presencas-eventos
package main

import (
	"context"
	"fmt"
	"log"
	"strings"
	"time"

	"nexora/config"
	"nexora/internal/db"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
)

type presencaRow struct {
	ID            int64
	TenantID      int64
	FuncionarioID int64
	Data          time.Time
	HoraEntrada   *string
	HoraSaida     *string
	HorasExtra    float64
	Tipo          *string
	Observacoes   *string
}

func main() {
	cfg := config.Load()
	pool := db.Connect(cfg.DatabaseURL)
	defer pool.Close()

	ctx := context.Background()

	rows, err := pool.Query(ctx, `
		SELECT id, tenant_id, funcionario_id, data, hora_entrada, hora_saida,
		       horas_extra, tipo, observacoes
		  FROM rh.presencas
		 ORDER BY id`)
	if err != nil {
		log.Fatalf("query rh.presencas: %v", err)
	}
	var presencas []presencaRow
	for rows.Next() {
		var p presencaRow
		if err := rows.Scan(&p.ID, &p.TenantID, &p.FuncionarioID, &p.Data, &p.HoraEntrada, &p.HoraSaida,
			&p.HorasExtra, &p.Tipo, &p.Observacoes); err != nil {
			log.Printf("scan presenca: %v", err)
			continue
		}
		presencas = append(presencas, p)
	}
	rows.Close()
	log.Printf("rh.presencas: %d linhas a processar", len(presencas))

	svc := assiduidade.NewService(pool)

	inicio := time.Now()
	var entradas, saidas, faltas, erros int
	for i, p := range presencas {
		if i > 0 && i%25 == 0 {
			log.Printf("progresso: %d/%d linhas (%s decorridos)", i, len(presencas), time.Since(inicio).Round(time.Second))
		}
		origem := "importacao"
		var metodoCodigo *string
		if p.Observacoes != nil && strings.Contains(*p.Observacoes, "Registo via hardware") {
			origem = "biometria"
			m := "biometria"
			metodoCodigo = &m
		}

		if p.HoraEntrada != nil && *p.HoraEntrada != "" {
			if t, perr := time.Parse("2006-01-02 15:04", p.Data.Format("2006-01-02")+" "+*p.HoraEntrada); perr == nil {
				obs := fmt.Sprintf("Migrado de rh.presencas id=%d", p.ID)
				if p.HorasExtra > 0 {
					obs += fmt.Sprintf(" | horas_extra (legado, sem instantes precisos)=%.2f", p.HorasExtra)
				}
				_, err := svc.RegistarEvento(ctx, p.TenantID, assiduidade.RegistarEventoInput{
					FuncionarioID:    p.FuncionarioID,
					TipoEventoCodigo: "entrada",
					MetodoCodigo:     metodoCodigo,
					OcorridoEm:       t,
					DataReferencia:   &p.Data,
					Origem:           origem,
					Observacoes:      &obs,
				})
				if err != nil {
					log.Printf("presenca id=%d entrada: %v", p.ID, err)
					erros++
				} else {
					entradas++
				}
			}
		}

		if p.HoraSaida != nil && *p.HoraSaida != "" {
			if t, perr := time.Parse("2006-01-02 15:04", p.Data.Format("2006-01-02")+" "+*p.HoraSaida); perr == nil {
				obs := fmt.Sprintf("Migrado de rh.presencas id=%d", p.ID)
				_, err := svc.RegistarEvento(ctx, p.TenantID, assiduidade.RegistarEventoInput{
					FuncionarioID:    p.FuncionarioID,
					TipoEventoCodigo: "saida",
					MetodoCodigo:     metodoCodigo,
					OcorridoEm:       t,
					DataReferencia:   &p.Data,
					Origem:           origem,
					Observacoes:      &obs,
				})
				if err != nil {
					log.Printf("presenca id=%d saida: %v", p.ID, err)
					erros++
				} else {
					saidas++
				}
			}
		}

		if p.Tipo != nil && *p.Tipo == "falta" {
			// Sem instante real (é uma ausência, não uma marcação) — usa
			// meio-dia como âncora estável para data_referencia/ocorrido_em.
			t := time.Date(p.Data.Year(), p.Data.Month(), p.Data.Day(), 12, 0, 0, 0, p.Data.Location())
			obs := fmt.Sprintf("Migrado de rh.presencas id=%d (tipo=falta)", p.ID)
			_, err := svc.RegistarEvento(ctx, p.TenantID, assiduidade.RegistarEventoInput{
				FuncionarioID:    p.FuncionarioID,
				TipoEventoCodigo: "falta_injustificada",
				OcorridoEm:       t,
				DataReferencia:   &p.Data,
				Origem:           "importacao",
				Observacoes:      &obs,
			})
			if err != nil {
				log.Printf("presenca id=%d falta: %v", p.ID, err)
				erros++
			} else {
				faltas++
			}
		}
	}

	log.Printf("migração concluída em %s: %d eventos 'entrada', %d 'saida', %d 'falta_injustificada', %d erros (de %d linhas de rh.presencas)",
		time.Since(inicio).Round(time.Second), entradas, saidas, faltas, erros, len(presencas))
	if erros > 0 {
		log.Printf("nota: %d linhas com erro — voltar a correr este comando é seguro (RegistarEvento deduplica), só reprocessa o que falhou", erros)
	}
}
