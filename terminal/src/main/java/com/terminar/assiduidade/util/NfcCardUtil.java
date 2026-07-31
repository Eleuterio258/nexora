package com.terminar.assiduidade.util;

import javax.smartcardio.Card;
import javax.smartcardio.CardChannel;
import javax.smartcardio.CardException;
import javax.smartcardio.CardTerminal;
import javax.smartcardio.CommandAPDU;
import javax.smartcardio.ResponseAPDU;
import javax.smartcardio.TerminalFactory;
import java.util.List;

/**
 * Leitura de cartões NFC/contactless via PC/SC (javax.smartcardio, incluído no JDK — sem
 * dependência extra). Funciona com qualquer leitor compatível PC/SC (ex.: ACR122U e
 * equivalentes — no Windows precisa do driver PC/SC da ACS instalado, para o leitor aparecer
 * como "ACS ACR122U PICC Interface" nos leitores do sistema). O comando "FF CA 00 00 00" é a
 * pseudo-APDU standard PC/SC Parte 10 para obter o UID de um cartão contactless.
 */
public class NfcCardUtil {

    private static final byte[] APDU_GET_UID = {(byte) 0xFF, (byte) 0xCA, 0x00, 0x00, 0x00};
    private static final String NOME_PREFERIDO = "ACR122";

    /**
     * Lista os leitores PC/SC disponíveis. Devolve lista vazia quando o serviço de smart card
     * está activo mas não tem nenhum leitor registado (SCARD_E_NO_READERS_AVAILABLE — situação
     * normal, ex.: ACR122U ainda sem driver instalado), tal como quando a lista vem vazia sem
     * erro. Lança excepção só se o subsistema PC/SC em si não existir/estiver inacessível.
     */
    public List<CardTerminal> listarLeitores() throws Exception {
        try {
            return TerminalFactory.getDefault().terminals().list();
        } catch (CardException e) {
            if (e.getCause() != null && e.getCause().getMessage() != null
                && e.getCause().getMessage().contains("SCARD_E_NO_READERS_AVAILABLE")) {
                return List.of();
            }
            throw e;
        }
    }

    /**
     * Escolhe o leitor a usar quando há mais do que um PC/SC ligado (ex.: leitor interno do
     * portátil + ACR122U USB): dá preferência ao ACR122U pelo nome, caindo para o primeiro
     * leitor da lista se não houver nenhum com esse nome.
     */
    public CardTerminal escolherLeitor(List<CardTerminal> leitores) {
        return leitores.stream()
            .filter(t -> t.getName().toUpperCase().contains(NOME_PREFERIDO))
            .findFirst()
            .orElse(leitores.get(0));
    }

    /**
     * Aguarda até {@code timeoutMs} por um cartão no leitor indicado e devolve o UID em
     * hexadecimal maiúsculo (ex.: "04A1B2C3"), ou {@code null} se não apareceu nenhum cartão
     * dentro do tempo limite.
     */
    public String lerUid(CardTerminal terminal, int timeoutMs) throws Exception {
        if (!terminal.waitForCardPresent(timeoutMs)) {
            return null;
        }
        Card card = terminal.connect("*");
        try {
            CardChannel channel = card.getBasicChannel();
            ResponseAPDU resposta = channel.transmit(new CommandAPDU(APDU_GET_UID));
            if (resposta.getSW() != 0x9000) {
                return null;
            }
            return paraHex(resposta.getData());
        } finally {
            card.disconnect(false);
        }
    }

    private String paraHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02X", b));
        }
        return sb.toString();
    }
}
