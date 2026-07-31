package com.terminar.assiduidade.service;

import com.terminar.assiduidade.dao.EmployeeDao;
import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.security.PinHasher;

import java.util.List;
import java.util.UUID;

public class EmployeeService {

    private final EmployeeDao employeeDao = new EmployeeDao();
    private final PinHasher pinHasher = new PinHasher();

    public List<Employee> listar() {
        return employeeDao.findAll();
    }

    public Employee criar(String numero, String nome, String departamento) {
        String numeroNormalizado = normalizarObrigatorio(numero, "O número do funcionário é obrigatório");
        String nomeNormalizado = normalizarObrigatorio(nome, "O nome do funcionário é obrigatório");
        String departamentoNormalizado =
            departamento == null || departamento.isBlank() ? null : departamento.trim();
        employeeDao.findByNumero(numeroNormalizado).ifPresent(e -> {
            throw new AssiduidadeException("Já existe um funcionário com o número " + numeroNormalizado);
        });
        Employee employee = Employee.builder()
            .numero(numeroNormalizado)
            .nome(nomeNormalizado)
            .departamento(departamentoNormalizado)
            .qrCodeToken(UUID.randomUUID().toString())
            .ativo(true)
            .build();
        return employeeDao.save(employee);
    }

    public Employee actualizar(Employee employee) {
        employee.setNome(normalizarObrigatorio(employee.getNome(), "O nome do funcionário é obrigatório"));
        employee.setDepartamento(employee.getDepartamento() == null || employee.getDepartamento().isBlank()
            ? null : employee.getDepartamento().trim());
        return employeeDao.save(employee);
    }

    public Employee definirAtivo(Employee employee, boolean ativo) {
        employee.setAtivo(ativo);
        return employeeDao.save(employee);
    }

    public Employee definirPin(Employee employee, String pin) {
        if (pin == null || !pin.matches("\\d{4,8}")) {
            throw new AssiduidadeException("O PIN deve conter entre 4 e 8 dígitos");
        }
        employee.setPinHash(pinHasher.hash(pin));
        return employeeDao.save(employee);
    }

    /** "Enrola" uma digital simulada — não há SDK de biometria real integrado. */
    public Employee enrolarDigitalSimulada(Employee employee) {
        employee.setFingerprintTemplate("SIM:" + employee.getNumero() + ":" + UUID.randomUUID());
        return employeeDao.save(employee);
    }

    public Employee associarNfc(Employee employee, String nfcUid) {
        if (nfcUid == null || nfcUid.isBlank()) {
            throw new AssiduidadeException("UID do cartão NFC inválido");
        }
        employee.setNfcUid(nfcUid.trim().toUpperCase());
        return employeeDao.save(employee);
    }

    public Employee removerNfc(Employee employee) {
        employee.setNfcUid(null);
        return employeeDao.save(employee);
    }

    private String normalizarObrigatorio(String valor, String mensagem) {
        if (valor == null || valor.isBlank()) {
            throw new AssiduidadeException(mensagem);
        }
        return valor.trim();
    }
}
