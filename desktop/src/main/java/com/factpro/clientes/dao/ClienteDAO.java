package com.factpro.clientes.dao;

import com.factpro.auth.PermissionChecker;
import com.factpro.clientes.model.Cliente;
import com.factpro.core.database.BaseDAO;
import com.factpro.core.database.DatabaseManager;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ClienteDAO extends BaseDAO<Cliente> {

    private static final String TABLE = "clientes";

    private Cliente mapResultSet(ResultSet rs) throws SQLException {
        Cliente cliente = new Cliente();
        cliente.setId(rs.getLong("id"));
        cliente.setTenantId(rs.getObject("tenant_id") != null ? rs.getLong("tenant_id") : null);
        cliente.setCodigo(rs.getString("codigo"));
        cliente.setNome(rs.getString("nome"));
        cliente.setEmail(rs.getString("email"));
        cliente.setTelefone(rs.getString("telefone"));
        cliente.setNif(rs.getString("nif"));
        cliente.setEndereco(rs.getString("endereco"));
        cliente.setLimiteCredito(rs.getObject("limite_credito") != null ? rs.getDouble("limite_credito") : null);
        cliente.setCreditoUsado(rs.getObject("credito_usado") != null ? rs.getDouble("credito_usado") : 0.0);
        cliente.setPontosFidelidade(rs.getObject("pontos_fidelidade") != null ? rs.getInt("pontos_fidelidade") : 0);
        cliente.setTipoPreco(rs.getString("tipo_preco"));
        cliente.setAtivo(rs.getObject("ativo") != null ? rs.getBoolean("ativo") : true);
        cliente.setCriadoEm(rs.getString("criado_em"));
        return cliente;
    }

    @Override
    public Cliente findById(Long id) {
        String sql = "SELECT * FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? mapResultSet(rs) : null;
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar cliente por id: {}", id, e);
            return null;
        }
    }

    @Override
    public List<Cliente> findAll() {
        String sql = "SELECT * FROM " + TABLE + " ORDER BY nome";
        List<Cliente> clientes = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                clientes.add(mapResultSet(rs));
            }
        } catch (SQLException e) {
            logger.error("Erro ao listar clientes", e);
        }
        return clientes;
    }

    public List<Cliente> findByNome(String nome) {
        String sql = "SELECT * FROM " + TABLE + " WHERE nome LIKE ? ORDER BY nome";
        List<Cliente> clientes = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, "%" + nome + "%");
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    clientes.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar clientes por nome: {}", nome, e);
        }
        return clientes;
    }

    @Override
    public Long save(Cliente cliente) {
        PermissionChecker.requireCreate("clientes");
        String sql = "INSERT INTO " + TABLE + " (tenant_id, codigo, nome, email, telefone, nif, endereco, " +
                     "limite_credito, credito_usado, pontos_fidelidade, tipo_preco, ativo) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            int idx = 1;
            if (cliente.getTenantId() != null) stmt.setLong(idx++, cliente.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, cliente.getCodigo());
            stmt.setString(idx++, cliente.getNome());
            stmt.setString(idx++, cliente.getEmail());
            stmt.setString(idx++, cliente.getTelefone());
            stmt.setString(idx++, cliente.getNif());
            stmt.setString(idx++, cliente.getEndereco());
            if (cliente.getLimiteCredito() != null) stmt.setDouble(idx++, cliente.getLimiteCredito());
            else stmt.setNull(idx++, Types.DOUBLE);
            stmt.setDouble(idx++, cliente.getCreditoUsado() != null ? cliente.getCreditoUsado() : 0.0);
            stmt.setInt(idx++, cliente.getPontosFidelidade() != null ? cliente.getPontosFidelidade() : 0);
            stmt.setString(idx++, cliente.getTipoPreco());
            stmt.setBoolean(idx++, cliente.getAtivo() != null ? cliente.getAtivo() : true);
            stmt.executeUpdate();
            return getLastInsertedId(stmt);
        } catch (SQLException e) {
            logger.error("Erro ao guardar cliente: {}", cliente.getNome(), e);
            return null;
        }
    }

    @Override
    public boolean update(Cliente cliente) {
        PermissionChecker.requireUpdate("clientes");
        String sql = "UPDATE " + TABLE + " SET tenant_id = ?, codigo = ?, nome = ?, email = ?, telefone = ?, " +
                     "nif = ?, endereco = ?, limite_credito = ?, credito_usado = ?, pontos_fidelidade = ?, " +
                     "tipo_preco = ?, ativo = ? WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            int idx = 1;
            if (cliente.getTenantId() != null) stmt.setLong(idx++, cliente.getTenantId());
            else stmt.setNull(idx++, Types.BIGINT);
            stmt.setString(idx++, cliente.getCodigo());
            stmt.setString(idx++, cliente.getNome());
            stmt.setString(idx++, cliente.getEmail());
            stmt.setString(idx++, cliente.getTelefone());
            stmt.setString(idx++, cliente.getNif());
            stmt.setString(idx++, cliente.getEndereco());
            if (cliente.getLimiteCredito() != null) stmt.setDouble(idx++, cliente.getLimiteCredito());
            else stmt.setNull(idx++, Types.DOUBLE);
            stmt.setDouble(idx++, cliente.getCreditoUsado() != null ? cliente.getCreditoUsado() : 0.0);
            stmt.setInt(idx++, cliente.getPontosFidelidade() != null ? cliente.getPontosFidelidade() : 0);
            stmt.setString(idx++, cliente.getTipoPreco());
            stmt.setBoolean(idx++, cliente.getAtivo() != null ? cliente.getAtivo() : true);
            stmt.setLong(idx++, cliente.getId());
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao atualizar cliente: {}", cliente.getId(), e);
            return false;
        }
    }

    @Override
    public boolean delete(Long id) {
        PermissionChecker.requireDelete("clientes");
        String sql = "DELETE FROM " + TABLE + " WHERE id = ?";
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, id);
            return stmt.executeUpdate() > 0;
        } catch (SQLException e) {
            logger.error("Erro ao eliminar cliente: {}", id, e);
            return false;
        }
    }

    public List<Cliente> findByCriteria(String search) {
        String sql = "SELECT * FROM " + TABLE + " WHERE nome LIKE ? OR email LIKE ? OR nif LIKE ? OR telefone LIKE ? ORDER BY nome";
        List<Cliente> clientes = new ArrayList<>();
        try (Connection conn = DatabaseManager.getInstance().getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            String pattern = "%" + search + "%";
            stmt.setString(1, pattern);
            stmt.setString(2, pattern);
            stmt.setString(3, pattern);
            stmt.setString(4, pattern);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    clientes.add(mapResultSet(rs));
                }
            }
        } catch (SQLException e) {
            logger.error("Erro ao buscar clientes por criteria: {}", search, e);
        }
        return clientes;
    }
}
