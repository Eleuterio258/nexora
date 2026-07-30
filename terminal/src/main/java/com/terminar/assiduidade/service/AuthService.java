package com.terminar.assiduidade.service;

import com.terminar.assiduidade.config.AppConfig;
import com.terminar.assiduidade.dao.EmployeeDao;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.security.PinHasher;
import com.terminar.assiduidade.security.TotpUtil;

import java.util.Optional;

public class AuthService {

    private final EmployeeDao employeeDao = new EmployeeDao();
    private final PinHasher pinHasher = new PinHasher();
    private final TotpUtil totpUtil = new TotpUtil();

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
     * Aceita tanto o token estático (crachá impresso) como um código dinâmico TOTP de 6
     * dígitos, gerado a cada 60s numa app do funcionário (fora deste projecto). O código
     * dinâmico não identifica sozinho o funcionário, por isso é validado contra o segredo
     * de todos os funcionários activos com QR dinâmico configurado.
     */
    public Optional<Employee> authenticateByQrToken(String token) {
        if (token == null || token.isBlank()) {
            return Optional.empty();
        }
        String texto = token.trim();
        Optional<Employee> porTokenEstatico = employeeDao.findByQrCodeToken(texto).filter(Employee::isAtivo);
        if (porTokenEstatico.isPresent()) {
            return porTokenEstatico;
        }
        if (!texto.matches("\\d{6}")) {
            return Optional.empty();
        }
        return employeeDao.findAll().stream()
            .filter(Employee::isAtivo)
            .filter(e -> e.getQrTotpSecret() != null && !e.getQrTotpSecret().isBlank())
            .filter(e -> totpUtil.valida(texto, e.getQrTotpSecret()))
            .findFirst();
    }

    /** Identifica o funcionário pelo número, para lhe mostrar o próprio QR Code (modo "para ser lido"). */
    public Optional<Employee> authenticateByNumero(String numero) {
        if (numero == null || numero.isBlank()) {
            return Optional.empty();
        }
        return employeeDao.findByNumero(numero.trim()).filter(Employee::isAtivo);
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
