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
                log.warn("Falha ao enviar evento de assiduidade para o ERP (registo {}) — fica para o "
                    + "reenvio periódico", registo.getId(), e);
            }
        }, "erp-event-forwarder");
        thread.setDaemon(true);
        thread.start();
    }

    /**
     * Reenvia marcações que ficaram por sincronizar (rede em baixo, ERP indisponível no
     * momento da marcação, etc.) — o envio em {@link #enviarEventoAsync} é best-effort e
     * "esquece" o registo se falhar; isto é a rede de segurança chamada periodicamente por
     * {@link #executarCicloAutomatico()}. O ERP é idempotente por event_hash, por isso reenviar
     * um registo já processado não duplica a marcação.
     */
    public void reenviarPendentes() {
        List<RegistoPonto> pendentes = registoPontoDao.findNaoSincronizados();
        for (RegistoPonto registo : pendentes) {
            try {
                erpApiClient.enviarEvento(registo);
                registoPontoDao.marcarSincronizado(registo.getId());
            } catch (Exception e) {
                log.warn("Reenvio ao ERP falhou de novo para o registo {} — tenta no próximo ciclo",
                    registo.getId(), e);
            }
        }
    }

    /** Um "tick" do ciclo automático: sincroniza funcionários e reenvia marcações pendentes. */
    public void executarCicloAutomatico() {
        if (!AppConfig.isApiSyncAtivo()) {
            return;
        }
        try {
            sincronizarFuncionarios();
        } catch (Exception e) {
            log.warn("Falha na sincronização periódica de funcionários com o ERP", e);
        }
        reenviarPendentes();
    }

    /**
     * Arranca o ciclo automático numa thread de fundo, a cada
     * {@code erp.sync.interval.seconds}. Chamado uma única vez no arranque da aplicação
     * (ver AssiduidadeTerminalApplication).
     */
    public void iniciarCicloAutomatico() {
        Thread thread = new Thread(() -> {
            while (true) {
                try {
                    Thread.sleep(AppConfig.getErpSyncIntervalSeconds() * 1000L);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    return;
                }
                try {
                    executarCicloAutomatico();
                } catch (Exception e) {
                    log.warn("Erro inesperado no ciclo automático de sincronização com o ERP", e);
                }
            }
        }, "erp-sync-scheduler");
        thread.setDaemon(true);
        thread.start();
    }
}
