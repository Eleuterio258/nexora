package com.factpro.contas.dao;

import com.factpro.contas.model.ContaReceber;
import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ContaReceberDAO extends BaseDAO<ContaReceber> {

    private static final String TABLE = "contas_receber";

    private ContaReceber mapResultSet(ResultSet rs) throws SQLException {
        ContaReceber conta = new ContaReceber();
        conta.setId(rs.getLong("id"));
        conta.setClienteId(rs.getObject("cliente_id") != null ? rs.getLong("cliente_id") : null);
        conta.setVendaId(rs.getObject("venda_id") != null ? rs.getLong("venda_id") : null);
        conta.setValorTotal(rs.getDouble("valor_total"));
        conta.setValorPago(rs.getObject("valor_pago") != null ? rs.getDouble("valor_pago") : 0.0);
        conta.setValorPendente(rs.getDouble("valor_pendente"));
        conta.setStatus(rs.getString("status"));
        conta.setDataVencimento(rs.getString("data_vencimento"));
        conta.setCriadoEm(rs.getString("criado_em"));
        return conta;
    }

    @Override
    public ContaReceber findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar conta a receber por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<ContaReceber> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY criado_em DESC";
        List<ContaReceber> contas = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                contas.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar contas a receber", e);
        }
        return contas;
    }

    @Override
    public Long save(ContaReceber conta) {
        String sql = "INSERT INTO " + TABLE + " (cliente_id, venda_id, valor_total, valor_pago, " +
                     "valor_pendente, status, data_vencimento) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (conta.getClienteId() != null) stmt.setLong(idx++, conta.getClienteId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (conta.getVendaId() != null) stmt.setLong(idx++, conta.getVendaId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setDouble(idx++, conta.getValorTotal());
            stmt.setDouble(idx++, conta.getValorPago() != null ? conta.getValorPago() : 0.0);
            stmt.setDouble(idx++, conta.getValorPendente());
            stmt.setString(idx++, conta.getStatus() != null ? conta.getStatus() : "pendente");
            stmt.setString(idx++, conta.getDataVencimento());
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar conta a receber", e);
            return null;
        }
    }

    @Override
    public boolean update(ContaReceber conta) {
        String sql = "UPDATE " + TABLE + " SET cliente_id = ?, venda_id = ?, valor_total = ?, " +
                     "valor_pago = ?, valor_pendente = ?, status = ?, data_vencimento = ?, " +
                     "atualizado_em = CURRENT_TIMESTAMP WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            if (conta.getClienteId() != null) stmt.setLong(idx++, conta.getClienteId());
            else stmt.setNull(idx++, Types.BIGINT);
            if (conta.getVendaId() != null) stmt.setLong(idx++, conta.getVendaId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setDouble(idx++, conta.getValorTotal());
            stmt.setDouble(idx++, conta.getValorPago() != null ? conta.getValorPago() : 0.0);
            stmt.setDouble(idx++, conta.getValorPendente());
            stmt.setString(idx++, conta.getStatus());
            stmt.setString(idx++, conta.getDataVencimento());
            stmt.setLong(idx++, conta.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar conta a receber: {}", conta.getId(), e);
            return false;
        }
    }

    @Override
    public boolean delete(Long id) {
        String sql = "DELETE FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar conta a receber: {}", id, e);
            return false;
        }
    }

    public List<ContaReceber> findByClienteId(Long clienteId) {
        String sql = "SELECT * FROM " + TABLE + " WHERE cliente_id = ? ORDER BY criado_em DESC";
        List<ContaReceber> contas = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, clienteId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    contas.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar contas por cliente: {}", clienteId, e);
        }
        return contas;
    }

    public List<ContaReceber> findByStatus(String status) {
        String sql = "SELECT * FROM " + TABLE + " WHERE status = ? ORDER BY criado_em DESC";
        List<ContaReceber> contas = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, status);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    contas.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar contas por status: {}", status, e);
        }
        return contas;
    }

    public List<ContaReceber> findOverdue() {
        String sql = "SELECT * FROM " + TABLE + " WHERE status = 'pendente' AND data_vencimento < date('now') ORDER BY data_vencimento ASC";
        List<ContaReceber> contas = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                contas.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar contas vencidas", e);
        }
        return contas;
    }

    public List<ContaReceber> findByDateRange(String startDate, String endDate) {
        String sql = "SELECT * FROM " + TABLE + " WHERE data_vencimento BETWEEN ? AND ? ORDER BY data_vencimento DESC";
        List<ContaReceber> contas = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, startDate);
            stmt.setString(2, endDate);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    contas.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar contas por periodo", e);
        }
        return contas;
    }
}
