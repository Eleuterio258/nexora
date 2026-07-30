package com.terminar.assiduidade.dao;

import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.util.DatabaseManager;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Optional;

/** Pares chave/valor editáveis em runtime (ecrã "Configurações" do admin). */
public class ConfiguracaoDao {

    public Optional<String> obter(String chave) {
        String sql = "SELECT valor FROM configuracao WHERE chave = ?";
        try (Connection conn = DatabaseManager.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, chave);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                String valor = rs.getString("valor");
                return (valor == null || valor.isBlank()) ? Optional.empty() : Optional.of(valor);
            }
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao ler configuração", e);
        }
    }

    public void guardar(String chave, String valor) {
        String sql = "INSERT INTO configuracao (chave, valor) VALUES (?, ?) "
            + "ON CONFLICT(chave) DO UPDATE SET valor = excluded.valor";
        try (Connection conn = DatabaseManager.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, chave);
            ps.setString(2, valor);
            ps.executeUpdate();
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao guardar configuração", e);
        }
    }
}
