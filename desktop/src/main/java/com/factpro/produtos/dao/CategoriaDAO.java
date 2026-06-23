package com.factpro.produtos.dao;

import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;
import com.factpro.produtos.model.Categoria;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CategoriaDAO extends BaseDAO<Categoria> {

    private static final String TABLE = "categorias";

    private Categoria mapResultSet(ResultSet rs) throws SQLException {
        Categoria categoria = new Categoria();
        categoria.setId(rs.getLong("id"));
        categoria.setTenantId(rs.getObject("tenant_id") != null ? rs.getLong("tenant_id") : null);
        categoria.setNome(rs.getString("nome"));
        categoria.setDescricao(rs.getString("descricao"));
        categoria.setCor(rs.getString("cor"));
        categoria.setAtivo(rs.getObject("ativo") != null ? rs.getBoolean("ativo") : true);
        categoria.setCriadoEm(rs.getString("criado_em"));
        return categoria;
    }

    @Override
    public Categoria findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar categoria por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<Categoria> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY nome";
        List<Categoria> categorias = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                categorias.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar categorias", e);
        }
        return categorias;
    }

    @Override
    public Long save(Categoria categoria) {
        String sql = "INSERT INTO " + TABLE + " (tenant_id, nome, descricao, cor, ativo) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (categoria.getTenantId() != null) stmt.setLong(idx++, categoria.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, categoria.getNome());
            stmt.setString(idx++, categoria.getDescricao());
            stmt.setString(idx++, categoria.getCor());
            stmt.setBoolean(idx++, categoria.getAtivo() != null ? categoria.getAtivo() : true);
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar categoria: {}", categoria.getNome(), e);
            return null;
        }
    }

    @Override
    public boolean update(Categoria categoria) {
        String sql = "UPDATE " + TABLE + " SET tenant_id = ?, nome = ?, descricao = ?, cor = ?, ativo = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            if (categoria.getTenantId() != null) stmt.setLong(idx++, categoria.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, categoria.getNome());
            stmt.setString(idx++, categoria.getDescricao());
            stmt.setString(idx++, categoria.getCor());
            stmt.setBoolean(idx++, categoria.getAtivo() != null ? categoria.getAtivo() : true);
            stmt.setLong(idx++, categoria.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar categoria: {}", categoria.getId(), e);
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
            logger.error("Erro ao eliminar categoria: {}", id, e);
            return false;
        }
    }
}
