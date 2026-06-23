package com.factpro.vendas.dao;

import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;
import com.factpro.vendas.model.Pagamento;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PagamentoDAO extends BaseDAO<Pagamento> {

    private static final String TABLE = "pagamentos";

    private Pagamento mapResultSet(ResultSet rs) throws SQLException {
        Pagamento pagamento = new Pagamento();
        pagamento.setId(rs.getLong("id"));
        pagamento.setVendaId(rs.getObject("venda_id") != null ? rs.getLong("venda_id") : null);
        pagamento.setMetodo(rs.getString("metodo"));
        pagamento.setValor(rs.getObject("valor") != null ? rs.getDouble("valor") : 0.0);
        pagamento.setReferencia(rs.getString("referencia"));
        pagamento.setTransacaoId(rs.getString("transacao_id"));
        pagamento.setStatus(rs.getString("status"));
        pagamento.setProcessadoEm(rs.getString("processado_em"));
        pagamento.setCriadoEm(rs.getString("criado_em"));
        return pagamento;
    }

    @Override
    public Pagamento findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar pagamento por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<Pagamento> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY criado_em DESC";
        List<Pagamento> pagamentos = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                pagamentos.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar pagamentos", e);
        }
        return pagamentos;
    }

    public List<Pagamento> findByVendaId(Long vendaId) {
        String sql = "SELECT * FROM " + TABLE + " WHERE venda_id = ? ORDER BY criado_em";
        List<Pagamento> pagamentos = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, vendaId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    pagamentos.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar pagamentos da venda: {}", vendaId, e);
        }
        return pagamentos;
    }

    @Override
    public Long save(Pagamento pagamento) {
        String sql = "INSERT INTO " + TABLE + " (venda_id, metodo, valor, referencia, transacao_id, status) " +
                     "VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            stmt.setLong(idx++, pagamento.getVendaId());
            stmt.setString(idx++, pagamento.getMetodo());
            stmt.setDouble(idx++, pagamento.getValor() != null ? pagamento.getValor() : 0.0);
            stmt.setString(idx++, pagamento.getReferencia());
            stmt.setString(idx++, pagamento.getTransacaoId());
            stmt.setString(idx++, pagamento.getStatus() != null ? pagamento.getStatus() : "pendente");
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar pagamento", e);
            return null;
        }
    }

    @Override
    public boolean update(Pagamento pagamento) {
        String sql = "UPDATE " + TABLE + " SET venda_id = ?, metodo = ?, valor = ?, referencia = ?, " +
                     "transacao_id = ?, status = ?, processado_em = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            stmt.setLong(idx++, pagamento.getVendaId());
            stmt.setString(idx++, pagamento.getMetodo());
            stmt.setDouble(idx++, pagamento.getValor() != null ? pagamento.getValor() : 0.0);
            stmt.setString(idx++, pagamento.getReferencia());
            stmt.setString(idx++, pagamento.getTransacaoId());
            stmt.setString(idx++, pagamento.getStatus());
            stmt.setString(idx++, pagamento.getProcessadoEm());
            stmt.setLong(idx++, pagamento.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar pagamento: {}", pagamento.getId(), e);
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
            logger.error("Erro ao eliminar pagamento: {}", id, e);
            return false;
        }
    }
}
