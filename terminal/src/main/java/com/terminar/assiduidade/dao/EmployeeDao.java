package com.terminar.assiduidade.dao;

import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.model.Employee;
import com.terminar.assiduidade.util.DatabaseManager;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class EmployeeDao {

    public Employee save(Employee employee) {
        if (employee.getId() == null) {
            return insert(employee);
        }
        return update(employee);
    }

    private Employee insert(Employee employee) {
        String sql = "INSERT INTO employee (numero, nome, departamento, pin_hash, qr_code_token, qr_totp_secret, "
                + "fingerprint_template, nfc_uid, ativo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getConnection(); PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bind(ps, employee);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    employee.setId(keys.getLong(1));
                }
            }
            return findById(employee.getId()).orElse(employee);
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao criar funcionário", e);
        }
    }

    private Employee update(Employee employee) {
        String sql = "UPDATE employee SET numero=?, nome=?, departamento=?, pin_hash=?, qr_code_token=?, qr_totp_secret=?, "
                + "fingerprint_template=?, nfc_uid=?, ativo=?, atualizado_em=CURRENT_TIMESTAMP WHERE id=?";
        try (Connection conn = DatabaseManager.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            bind(ps, employee);
            ps.setLong(10, employee.getId());
            ps.executeUpdate();
            return findById(employee.getId()).orElse(employee);
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao actualizar funcionário", e);
        }
    }

    private void bind(PreparedStatement ps, Employee employee) throws Exception {
        ps.setString(1, employee.getNumero());
        ps.setString(2, employee.getNome());
        ps.setString(3, employee.getDepartamento());
        ps.setString(4, employee.getPinHash());
        ps.setString(5, employee.getQrCodeToken());
        ps.setString(6, employee.getQrTotpSecret());
        ps.setString(7, employee.getFingerprintTemplate());
        ps.setString(8, employee.getNfcUid());
        ps.setInt(9, employee.isAtivo() ? 1 : 0);
    }

    public Optional<Employee> findById(Long id) {
        return findOneBy("id = ?", id);
    }

    public Optional<Employee> findByNumero(String numero) {
        return findOneBy("numero = ?", numero);
    }

    public Optional<Employee> findByQrCodeToken(String token) {
        return findOneBy("qr_code_token = ?", token);
    }

    public Optional<Employee> findByNfcUid(String nfcUid) {
        return findOneBy("nfc_uid = ?", nfcUid);
    }

    private Optional<Employee> findOneBy(String whereClause, Object param) {
        String sql = "SELECT * FROM employee WHERE " + whereClause;
        try (Connection conn = DatabaseManager.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setObject(1, param);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(map(rs));
                }
                return Optional.empty();
            }
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao consultar funcionário", e);
        }
    }

    public List<Employee> findAll() {
        String sql = "SELECT * FROM employee ORDER BY nome";
        List<Employee> result = new ArrayList<>();
        try (Connection conn = DatabaseManager.getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                result.add(map(rs));
            }
            return result;
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao listar funcionários", e);
        }
    }

    private Employee map(ResultSet rs) throws Exception {
        return Employee.builder()
                .id(rs.getLong("id"))
                .numero(rs.getString("numero"))
                .nome(rs.getString("nome"))
                .departamento(rs.getString("departamento"))
                .pinHash(rs.getString("pin_hash"))
                .qrCodeToken(rs.getString("qr_code_token"))
                .qrTotpSecret(rs.getString("qr_totp_secret"))
                .fingerprintTemplate(rs.getString("fingerprint_template"))
                .nfcUid(rs.getString("nfc_uid"))
                .ativo(rs.getInt("ativo") == 1)
                .criadoEm(toLocalDateTime(rs.getTimestamp("criado_em")))
                .atualizadoEm(toLocalDateTime(rs.getTimestamp("atualizado_em")))
                .build();
    }

    private java.time.LocalDateTime toLocalDateTime(Timestamp ts) {
        return ts == null ? null : ts.toLocalDateTime();
    }
}
