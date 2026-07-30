package com.terminar.assiduidade.security;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PinHasherTest {

    private final PinHasher pinHasher = new PinHasher();

    @Test
    void hashCorrespondeAoPinOriginal() {
        String hash = pinHasher.hash("1234");
        assertTrue(pinHasher.matches("1234", hash));
    }

    @Test
    void hashNaoCorrespondeAPinErrado() {
        String hash = pinHasher.hash("1234");
        assertFalse(pinHasher.matches("9999", hash));
    }

    @Test
    void duasHashesDoMesmoPinSaoDiferentes() {
        String hash1 = pinHasher.hash("1234");
        String hash2 = pinHasher.hash("1234");
        assertNotEquals(hash1, hash2);
    }

    @Test
    void matchesComHashNuloDevolveFalse() {
        assertFalse(pinHasher.matches("1234", null));
    }

    @Test
    void matchesComHashCorrompidoDevolveFalse() {
        assertFalse(pinHasher.matches("1234", "formato-invalido"));
        assertFalse(pinHasher.matches("1234", "abc:salt:hash"));
        assertFalse(pinHasher.matches(null, pinHasher.hash("1234")));
    }
}
