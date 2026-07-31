package com.terminar.assiduidade.service;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.dao.EmployeeDao;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.security.PinHasher;

import java.util.Optional;

public class AuthService {

    private final EmployeeDao employeeDao = new EmployeeDao();
    private final PinHasher pinHasher = new PinHasher();

    /** PIN identifica o funcionário por si só (não é pedido nº de funcionário no ecrã). */
    public Optional<Employee> authenticateByPin(String pin) {
        if (pin == null || pin.isBlank()) {
            return Optional.empty();
        }
        return employeeDao.findAll().stream()
            .filter(Employee::isAtivo)
            .filter(e -> pinHasher.matches(pin, e.getPinHash()))
            .findFirst();
    }

    /**
     * QR fixo do funcionário — Modo 1 (ver ANALISE de "ler e ver"): o mesmo código
     * permanente que está impresso no crachá ou na app Nexo do funcionário. Identificação
     * puramente local, sem chamada ao ERP — o QR em si não é um segredo temporário.
     */
    public Optional<Employee> authenticateByQrToken(String token) {
        if (token == null || token.isBlank()) {
            return Optional.empty();
        }
        return employeeDao.findByQrCodeToken(token.trim()).filter(Employee::isAtivo);
    }

    public Optional<Employee> authenticateByNfcUid(String nfcUid) {
        if (nfcUid == null || nfcUid.isBlank()) {
            return Optional.empty();
        }
        return employeeDao.findByNfcUid(nfcUid.trim().toUpperCase()).filter(Employee::isAtivo);
    }

    /**
     * Digital sempre simulada — não há SDK de biometria real integrado nesta aplicação.
     * Como não existe leitor real, a simulação identifica o primeiro funcionário activo
     * com modelo de impressão digital registado (não é pedido nº de funcionário no ecrã).
     */
    public Optional<Employee> authenticateByFingerprintSimulado() {
        if (!AppConfig.isFingerprintSimulation()) {
            return Optional.empty();
        }
        return employeeDao.findAll().stream()
            .filter(Employee::isAtivo)
            .filter(e -> e.getFingerprintTemplate() != null && !e.getFingerprintTemplate().isBlank())
            .findFirst();
    }
}
