package com.terminar.assiduidade.util;

import javax.smartcardio.Card;
import javax.smartcardio.CardChannel;
import javax.smartcardio.CardTerminal;
import javax.smartcardio.CommandAPDU;
import javax.smartcardio.ResponseAPDU;
import javax.smartcardio.TerminalFactory;
import java.util.List;

/**
 * Leitura de cartões NFC/contactless via PC/SC (javax.smartcardio, incluído no JDK — sem
 * dependência extra). Funciona com qualquer leitor compatível PC/SC (ex.: ACR122U e
 * equivalentes). O comando "FF CA 00 00 00" é a pseudo-APDU standard PC/SC Parte 10 para obter
 * o UID de um cartão contactless.
 */
public class NfcCardUtil {

    private static final byte[] APDU_GET_UID = {(byte) 0xFF, (byte) 0xCA, 0x00, 0x00, 0x00};

    /** Lista os leitores PC/SC disponíveis. Lança excepção se o subsistema PC/SC não existir. */
    public List<CardTerminal> listarLeitores() throws Exception {
        return TerminalFactory.getDefault().terminals().list();
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
