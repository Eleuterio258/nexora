package com.terminar.assiduidade.service;

import com.terminar.assiduidade.dao.RegistoPontoDao;
import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.model.MetodoAutenticacao;
import com.terminar.assiduidade.model.RegistoPonto;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * O terminal não classifica a marcação como entrada/saída/pausa — só regista
 * uma sequência cronológica de pontos de presença (instante + método). É o
 * ERP, com as regras de assiduidade do tenant (horários, tolerâncias, turnos),
 * que interpreta o papel de cada marcação no dia (ver
 * assiduidade.InferirEntradaOuSaida e o motor de interpretação em
 * internal/modules/recursos-humanos/service/assiduidade/interpretacao.go).
 */
public class PontoService {

    private static final Duration INTERVALO_MINIMO = Duration.ofSeconds(10);

    private final RegistoPontoDao registoPontoDao = new RegistoPontoDao();
    private final ErpSyncService erpSyncService = new ErpSyncService();

    public RegistoPonto registarMarcacao(Employee employee, MetodoAutenticacao metodo) {
        Optional<RegistoPonto> ultimo = registoPontoDao.findUltimoDoDia(employee.getId(), LocalDate.now());
        if (ultimo.isPresent()) {
            Duration desdeUltimo = Duration.between(ultimo.get().getDataHora(), LocalDateTime.now());
            if (!desdeUltimo.isNegative() && desdeUltimo.compareTo(INTERVALO_MINIMO) < 0) {
                throw new AssiduidadeException("Marcação já registada há instantes — aguarde antes de repetir");
            }
        }
        RegistoPonto registo = RegistoPonto.builder()
            .employeeId(employee.getId())
            .employeeNumero(employee.getNumero())
            .employeeNome(employee.getNome())
            .metodo(metodo)
            .build();
        RegistoPonto guardado = registoPontoDao.insert(registo);
        erpSyncService.enviarEventoAsync(guardado);
        return guardado;
    }

    public List<RegistoPonto> registosDeHoje() {
        return registoPontoDao.findByDia(LocalDate.now());
    }
}
