package com.terminar.assiduidade.dao;

import com.terminar.assiduidade.exception.AssiduidadeException;
import com.terminar.assiduidade.model.MetodoAutenticacao;
import com.terminar.assiduidade.model.RegistoPonto;
import com.terminar.assiduidade.model.TipoMarcacao;
import com.terminar.assiduidade.util.DatabaseManager;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class RegistoPontoDao {

    /** Formato em que o SQLite guarda data_hora — o mesmo do CURRENT_TIMESTAMP. */
    private static final DateTimeFormatter DATA_HORA = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * data_hora passa a ser escrita explicitamente, em hora local, em vez de
     * ficar ao cargo do DEFAULT CURRENT_TIMESTAMP da tabela.
     *
     * O CURRENT_TIMESTAMP do SQLite é UTC, mas todo o resto da aplicação
     * trabalha em hora local: PontoService compara o último registo com
     * LocalDateTime.now() e findUltimoDoDia/findByDia comparam date(data_hora)
     * com LocalDate.now(). Misturar os dois deslocava tudo pelo offset do fuso
     * — em Moçambique (UTC+2) a diferença calculada era sempre ~2h a mais, e a
     * guarda de 10 segundos contra marcações repetidas nunca chegava a
     * disparar; as consultas por dia divergiam entre as 22h e a meia-noite.
     *
     * A conversão para UTC passa a ser feita só na fronteira que precisa dela,
     * ao enviar o evento para o ERP (ErpApiClient).
     */
    public RegistoPonto insert(RegistoPonto registo) {
        if (registo.getDataHora() == null) {
            registo.setDataHora(LocalDateTime.now().truncatedTo(ChronoUnit.SECONDS));
        }
        String sql = "INSERT INTO registo_ponto (employee_id, employee_numero, employee_nome, tipo, metodo, "
            + "observacao, data_hora) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, registo.getEmployeeId());
            ps.setString(2, registo.getEmployeeNumero());
            ps.setString(3, registo.getEmployeeNome());
            ps.setString(4, registo.getTipo().name());
            ps.setString(5, registo.getMetodo().name());
            ps.setString(6, registo.getObservacao());
            ps.setString(7, registo.getDataHora().format(DATA_HORA));
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    registo.setId(keys.getLong(1));
                }
            }
            return findById(registo.getId()).orElse(registo);
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao registar marcação de ponto", e);
        }
    }

    public void marcarSincronizado(Long id) {
        String sql = "UPDATE registo_ponto SET sincronizado = 1 WHERE id = ?";
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            ps.executeUpdate();
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao marcar registo como sincronizado", e);
        }
    }

    public Optional<RegistoPonto> findById(Long id) {
        String sql = "SELECT * FROM registo_ponto WHERE id = ?";
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(map(rs)) : Optional.empty();
            }
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao consultar registo de ponto", e);
        }
    }

    public Optional<RegistoPonto> findUltimoDoDia(Long employeeId, LocalDate dia) {
        String sql = "SELECT * FROM registo_ponto WHERE employee_id = ? AND date(data_hora) = date(?) "
            + "ORDER BY data_hora DESC LIMIT 1";
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, employeeId);
            ps.setString(2, dia.toString());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(map(rs)) : Optional.empty();
            }
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao consultar último registo do dia", e);
        }
    }

    /** Registos ainda não confirmados no ERP — candidatos a reenvio periódico. */
    public List<RegistoPonto> findNaoSincronizados() {
        String sql = "SELECT * FROM registo_ponto WHERE sincronizado = 0 ORDER BY data_hora";
        List<RegistoPonto> result = new ArrayList<>();
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                result.add(map(rs));
            }
            return result;
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao listar registos não sincronizados", e);
        }
    }

    public List<RegistoPonto> findByDia(LocalDate dia) {
        String sql = "SELECT * FROM registo_ponto WHERE date(data_hora) = date(?) ORDER BY data_hora DESC";
        List<RegistoPonto> result = new ArrayList<>();
        try (Connection conn = DatabaseManager.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, dia.toString());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(map(rs));
                }
                return result;
            }
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao listar registos do dia", e);
        }
    }

    private RegistoPonto map(ResultSet rs) throws Exception {
        return RegistoPonto.builder()
            .id(rs.getLong("id"))
            .employeeId(rs.getLong("employee_id"))
            .employeeNumero(rs.getString("employee_numero"))
            .employeeNome(rs.getString("employee_nome"))
            .tipo(TipoMarcacao.valueOf(rs.getString("tipo")))
            .metodo(MetodoAutenticacao.valueOf(rs.getString("metodo")))
            .dataHora(rs.getTimestamp("data_hora").toLocalDateTime())
            .sincronizado(rs.getInt("sincronizado") == 1)
            .observacao(rs.getString("observacao"))
            .build();
    }
}
