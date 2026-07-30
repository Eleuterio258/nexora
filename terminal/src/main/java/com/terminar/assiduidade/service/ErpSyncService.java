package com.terminar.assiduidade.service;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.dao.EmployeeDao;
import com.terminar.assiduidade.dao.RegistoPontoDao;
import com.terminar.assiduidade.integration.ErpApiClient;
import com.terminar.assiduidade.integration.FuncionarioErp;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.model.RegistoPonto;
import lombok.extern.slf4j.Slf4j;

import java.util.List;
import java.util.Optional;

/**
 * Integração híbrida com o Nexora ERP: o ERP é autoritativo para identidade
 * (nome/número/activo), mas PIN/QR/NFC/digital continuam geridos só neste
 * terminal (o ERP não os expõe a dispositivos — ver FuncionarioErp). Cada
 * marcação de ponto confirmada localmente é também enviada ao ERP.
 */
@Slf4j
public class ErpSyncService {

    private final EmployeeDao employeeDao = new EmployeeDao();
    private final EmployeeService employeeService = new EmployeeService();
    private final RegistoPontoDao registoPontoDao = new RegistoPontoDao();
    private final ErpApiClient erpApiClient = new ErpApiClient();

    public record ResultadoSincronizacao(int total, int novos, int actualizados) {
    }

    /** GET .../assiduidade/funcionarios — cria/actualiza nome, número e estado activo. */
    public ResultadoSincronizacao sincronizarFuncionarios() {
        List<FuncionarioErp> funcionarios = erpApiClient.listarFuncionarios();
        int novos = 0;
        int actualizados = 0;
        for (FuncionarioErp f : funcionarios) {
            Optional<Employee> existente = employeeDao.findByNumero(f.getEmployeeCode());
            if (existente.isPresent()) {
                Employee employee = existente.get();
                boolean mudou = !f.getFullName().equals(employee.getNome()) || f.isActive() != employee.isAtivo();
                if (mudou) {
                    employee.setNome(f.getFullName());
                    employee.setAtivo(f.isActive());
                    employeeDao.save(employee);
                    actualizados++;
                }
            } else {
                Employee novo = employeeService.criar(f.getEmployeeCode(), f.getFullName(), null);
                novo.setAtivo(f.isActive());
                employeeDao.save(novo);
                novos++;
            }
        }
        return new ResultadoSincronizacao(funcionarios.size(), novos, actualizados);
    }

    /** Envio best-effort em thread separada — nunca bloqueia nem falha a marcação local. */
    public void enviarEventoAsync(RegistoPonto registo) {
        if (!AppConfig.isApiSyncAtivo()) {
            return;
        }
        Thread thread = new Thread(() -> {
            try {
                erpApiClient.enviarEvento(registo);
                registoPontoDao.marcarSincronizado(registo.getId());
            } catch (Exception e) {
                log.warn("Falha ao enviar evento de assiduidade para o ERP (registo {})", registo.getId(), e);
            }
        }, "erp-event-forwarder");
        thread.setDaemon(true);
        thread.start();
    }
}
