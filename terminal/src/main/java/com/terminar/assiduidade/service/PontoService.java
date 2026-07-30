package com.terminar.assiduidade.service;

import com.terminar.assiduidade.dao.RegistoPontoDao;
import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.model.MetodoAutenticacao;
import com.terminar.assiduidade.model.RegistoPonto;
import com.terminar.assiduidade.model.TipoMarcacao;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public class PontoService {

    private static final Duration INTERVALO_MINIMO = Duration.ofSeconds(10);

    private final RegistoPontoDao registoPontoDao = new RegistoPontoDao();
    private final ErpSyncService erpSyncService = new ErpSyncService();

    /** Sugere o próximo tipo de marcação com base no último registo do funcionário hoje. */
    public TipoMarcacao determineNextTipo(Long employeeId) {
        Optional<RegistoPonto> ultimo = registoPontoDao.findUltimoDoDia(employeeId, LocalDate.now());
        return proximoTipo(ultimo.map(RegistoPonto::getTipo).orElse(null));
    }

    /** Lógica pura (sem acesso a BD) usada por {@link #determineNextTipo}, testável isoladamente. */
    public TipoMarcacao proximoTipo(TipoMarcacao ultimoTipo) {
        if (ultimoTipo == null) {
            return TipoMarcacao.ENTRADA;
        }
        return switch (ultimoTipo) {
            case ENTRADA -> TipoMarcacao.SAIDA;
            case INICIO_PAUSA -> TipoMarcacao.FIM_PAUSA;
            case FIM_PAUSA, SAIDA -> TipoMarcacao.ENTRADA;
        };
    }

    public RegistoPonto registarMarcacao(Employee employee, TipoMarcacao tipo, MetodoAutenticacao metodo) {
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
            .tipo(tipo)
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
