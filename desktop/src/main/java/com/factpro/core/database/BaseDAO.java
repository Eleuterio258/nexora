package com.factpro.core.database;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * Classe base para todos os DAOs (Data Access Objects).
 * Fornece métodos comuns de acesso a dados.
 *
 * @param <T> Tipo da entidade
 */
public abstract class BaseDAO<T> {
    
    protected final Logger logger = LoggerFactory.getLogger(getClass());
    
    /**
     * Obtém uma conexão da pool.
     */
    protected Connection getConnection() throws SQLException {
        return DatabaseManager.getInstance().getConnection();
    }
    
    /**
     * Encontra uma entidade pelo ID.
     */
    public abstract T findById(Long id);
    
    /**
     * Lista todas as entidades.
     */
    public abstract List<T> findAll();
    
    /**
     * Guarda uma nova entidade.
     * @return ID da entidade guardada
     */
    public abstract Long save(T entity);
    
    /**
     * Atualiza uma entidade existente.
     */
    public abstract boolean update(T entity);
    
    /**
     * Elimina uma entidade pelo ID.
     */
    public abstract boolean delete(Long id);
    
    /**
     * Fecha recursos de forma segura.
     */
    protected void closeResources(AutoCloseable... resources) {
        for (AutoCloseable resource : resources) {
            if (resource != null) {
                try {
                    resource.close();
                } catch (Exception e) {
                    logger.warn("Erro ao fechar recurso", e);
                }
            }
        }
    }
    
    /**
     * Executa uma query de contagem.
     */
    protected int count(String sql, Object... params) {
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            setParameters(stmt, params);
            
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            logger.error("Erro ao executar count: {}", sql, e);
            return 0;
        }
    }
    
    /**
     * Define parâmetros num PreparedStatement.
     */
    protected void setParameters(PreparedStatement stmt, Object... params) throws SQLException {
        if (params != null) {
            for (int i = 0; i < params.length; i++) {
                stmt.setObject(i + 1, params[i]);
            }
        }
    }
    
    /**
     * Retorna o último ID inserido.
     */
    protected Long getLastInsertedId(PreparedStatement stmt) throws SQLException {
        try (ResultSet rs = stmt.getGeneratedKeys()) {
            if (rs.next()) {
                return rs.getLong(1);
            }
        }
        return null;
    }
}
