package com.factpro.fornecedores.dao;

import com.factpro.auth.PermissionChecker;
import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;
import com.factpro.fornecedores.model.Fornecedor;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class FornecedorDAO extends BaseDAO<Fornecedor> {

    private static final String TABLE = "fornecedores";

    private Fornecedor mapResultSet(ResultSet rs) throws SQLException {
        Fornecedor fornecedor = new Fornecedor();
        fornecedor.setId(rs.getLong("id"));
        fornecedor.setTenantId(rs.getObject("tenant_id") != null ? rs.getLong("tenant_id") : null);
        fornecedor.setNome(rs.getString("nome"));
        fornecedor.setContato(rs.getString("contato"));
        fornecedor.setTelefone(rs.getString("telefone"));
        fornecedor.setEmail(rs.getString("email"));
        fornecedor.setEndereco(rs.getString("endereco"));
        fornecedor.setNif(rs.getString("nif"));
        fornecedor.setAtivo(rs.getObject("ativo") != null ? rs.getBoolean("ativo") : true);
        fornecedor.setCriadoEm(rs.getString("criado_em"));
        fornecedor.setAtualizadoEm(rs.getString("atualizado_em"));
        return fornecedor;
    }

    @Override
    public Fornecedor findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar fornecedor por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<Fornecedor> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY nome";
        List<Fornecedor> fornecedores = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                fornecedores.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar fornecedores", e);
        }
        return fornecedores;
    }

    @Override
    public Long save(Fornecedor fornecedor) {
        PermissionChecker.requireCreate("fornecedores");
        String sql = "INSERT INTO " + TABLE + " (tenant_id, nome, contato, telefone, email, endereco, nif, ativo) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (fornecedor.getTenantId() != null) stmt.setLong(idx++, fornecedor.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, fornecedor.getNome());
            stmt.setString(idx++, fornecedor.getContato());
            stmt.setString(idx++, fornecedor.getTelefone());
            stmt.setString(idx++, fornecedor.getEmail());
            stmt.setString(idx++, fornecedor.getEndereco());
            stmt.setString(idx++, fornecedor.getNif());
            stmt.setBoolean(idx++, fornecedor.getAtivo() != null ? fornecedor.getAtivo() : true);
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar fornecedor: {}", fornecedor.getNome(), e);
            return null;
        }
    }

    @Override
    public boolean update(Fornecedor fornecedor) {
        PermissionChecker.requireUpdate("fornecedores");
        String sql = "UPDATE " + TABLE + " SET tenant_id = ?, nome = ?, contato = ?, telefone = ?, " +
                     "email = ?, endereco = ?, nif = ?, ativo = ?, atualizado_em = datetime('now') WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            if (fornecedor.getTenantId() != null) stmt.setLong(idx++, fornecedor.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, fornecedor.getNome());
            stmt.setString(idx++, fornecedor.getContato());
            stmt.setString(idx++, fornecedor.getTelefone());
            stmt.setString(idx++, fornecedor.getEmail());
            stmt.setString(idx++, fornecedor.getEndereco());
            stmt.setString(idx++, fornecedor.getNif());
            stmt.setBoolean(idx++, fornecedor.getAtivo() != null ? fornecedor.getAtivo() : true);
            stmt.setLong(idx++, fornecedor.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar fornecedor: {}", fornecedor.getId(), e);
            return false;
        }
    }

    @Override
    public boolean delete(Long id) {
        PermissionChecker.requireDelete("fornecedores");
        String sql = "DELETE FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar fornecedor: {}", id, e);
            return false;
        }
    }
}
