package com.factpro.fornecedores.service;

import com.factpro.fornecedores.dao.FornecedorDAO;
import com.factpro.fornecedores.model.Fornecedor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Service for managing suppliers.
 */
public class FornecedorService {

    private static final Logger logger = LoggerFactory.getLogger(FornecedorService.class);

    private final FornecedorDAO fornecedorDAO;

    public FornecedorService(FornecedorDAO fornecedorDAO) {
        this.fornecedorDAO = fornecedorDAO;
    }

    public Fornecedor findById(Long id) {
        return fornecedorDAO.findById(id);
    }

    public List<Fornecedor> findAll() {
        return fornecedorDAO.findAll();
    }

    public Fornecedor save(Fornecedor fornecedor) {
        Long id = fornecedorDAO.save(fornecedor);
        if (id == null) {
            throw new RuntimeException("Falha ao guardar o fornecedor.");
        }
        fornecedor.setId(id);
        logger.info("Fornecedor saved: {} (ID: {})", fornecedor.getNome(), id);
        return fornecedor;
    }

    public Fornecedor update(Fornecedor fornecedor) {
        boolean updated = fornecedorDAO.update(fornecedor);
        if (!updated) {
            throw new RuntimeException("Falha ao atualizar o fornecedor.");
        }
        logger.info("Fornecedor updated: {} (ID: {})", fornecedor.getNome(), fornecedor.getId());
        return fornecedor;
    }

    public boolean delete(Long id) {
        boolean deleted = fornecedorDAO.delete(id);
        if (deleted) {
            logger.info("Fornecedor deleted: ID {}", id);
        } else {
            logger.warn("Failed to delete fornecedor: ID {}", id);
        }
        return deleted;
    }
}
