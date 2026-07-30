package com.terminar.assiduidade.security;

import com.terminar.assiduidade.exception.AssiduidadeException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.ByteArrayOutputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;

/**
 * TOTP (RFC 6238), período de 60s e 6 dígitos — usado para validar o QR Code dinâmico
 * apresentado na app do funcionário (fora deste projecto) e lido pela câmara do terminal.
 * O segredo é partilhado uma única vez com a app do funcionário via {@link #gerarUriProvisionamento}.
 */
public class TotpUtil {

    private static final int PERIODO_SEGUNDOS = 60;
    private static final int DIGITOS = 6;
    private static final int TOLERANCIA_PASSOS = 1;
    private static final String ALGORITMO_HMAC = "HmacSHA1";
    private static final String ALFABETO_BASE32 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    private static final SecureRandom RANDOM = new SecureRandom();

    public String gerarSegredo() {
        byte[] bytes = new byte[20];
        RANDOM.nextBytes(bytes);
        return base32Encode(bytes);
    }

    /** Verifica o código contra o passo actual e os adjacentes (tolerância a desvio de relógio). */
    public boolean valida(String codigo, String segredoBase32) {
        if (codigo == null || !codigo.matches("\\d{" + DIGITOS + "}")
            || segredoBase32 == null || segredoBase32.isBlank()) {
            return false;
        }
        long passoAtual = System.currentTimeMillis() / 1000 / PERIODO_SEGUNDOS;
        byte[] chave = base32Decode(segredoBase32);
        for (long passo = passoAtual - TOLERANCIA_PASSOS; passo <= passoAtual + TOLERANCIA_PASSOS; passo++) {
            if (codigo.equals(gerarCodigo(chave, passo))) {
                return true;
            }
        }
        return false;
    }

    /** URI padrão otpauth:// para provisionamento numa app de autenticação (QR ou introdução manual). */
    public String gerarUriProvisionamento(String segredoBase32, String rotulo, String emissor) {
        String rotuloCodificado = urlEncode(emissor + ":" + rotulo);
        String emissorCodificado = urlEncode(emissor);
        return "otpauth://totp/" + rotuloCodificado
            + "?secret=" + segredoBase32
            + "&issuer=" + emissorCodificado
            + "&period=" + PERIODO_SEGUNDOS
            + "&digits=" + DIGITOS
            + "&algorithm=SHA1";
    }

    private String urlEncode(String texto) {
        return URLEncoder.encode(texto, StandardCharsets.UTF_8).replace("+", "%20");
    }

    private String gerarCodigo(byte[] chave, long passo) {
        try {
            byte[] dados = new byte[8];
            long valor = passo;
            for (int i = 7; i >= 0; i--) {
                dados[i] = (byte) (valor & 0xff);
                valor >>= 8;
            }
            Mac mac = Mac.getInstance(ALGORITMO_HMAC);
            mac.init(new SecretKeySpec(chave, ALGORITMO_HMAC));
            byte[] hash = mac.doFinal(dados);

            int offset = hash[hash.length - 1] & 0x0f;
            int binario = ((hash[offset] & 0x7f) << 24)
                | ((hash[offset + 1] & 0xff) << 16)
                | ((hash[offset + 2] & 0xff) << 8)
                | (hash[offset + 3] & 0xff);

            int modulo = (int) Math.pow(10, DIGITOS);
            return String.format("%0" + DIGITOS + "d", binario % modulo);
        } catch (Exception e) {
            throw new AssiduidadeException("Erro ao calcular código TOTP", e);
        }
    }

    private String base32Encode(byte[] dados) {
        StringBuilder sb = new StringBuilder();
        int bits = 0;
        int valor = 0;
        for (byte b : dados) {
            valor = (valor << 8) | (b & 0xff);
            bits += 8;
            while (bits >= 5) {
                sb.append(ALFABETO_BASE32.charAt((valor >>> (bits - 5)) & 0x1f));
                bits -= 5;
            }
        }
        if (bits > 0) {
            sb.append(ALFABETO_BASE32.charAt((valor << (5 - bits)) & 0x1f));
        }
        return sb.toString();
    }

    private byte[] base32Decode(String texto) {
        String limpo = texto.trim().toUpperCase().replace("=", "");
        ByteArrayOutputStream saida = new ByteArrayOutputStream();
        int bits = 0;
        int valor = 0;
        for (char c : limpo.toCharArray()) {
            int indice = ALFABETO_BASE32.indexOf(c);
            if (indice < 0) {
                continue;
            }
            valor = (valor << 5) | indice;
            bits += 5;
            if (bits >= 8) {
                saida.write((valor >>> (bits - 8)) & 0xff);
                bits -= 8;
            }
        }
        return saida.toByteArray();
    }
}
